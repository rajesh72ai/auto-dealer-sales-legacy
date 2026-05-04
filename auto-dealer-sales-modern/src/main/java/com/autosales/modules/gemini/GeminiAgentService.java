package com.autosales.modules.gemini;

import com.autosales.modules.agent.AgentConversationService;
import com.autosales.modules.agent.AgentCostService;
import com.autosales.modules.agent.AgentService;
import com.autosales.modules.agent.TokenQuotaService;
import com.autosales.modules.agent.action.ActionRegistry;
import com.autosales.modules.agent.action.ActionService;
import com.autosales.modules.agent.action.AgentToolCallAuditService;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.ProposalMarkerScanner;
import com.autosales.modules.agent.action.dto.ProposalResponse;
import com.autosales.modules.agent.dto.AgentRequest;
import com.autosales.modules.agent.dto.AgentResponse;
import com.autosales.modules.agent.entity.AgentConversation;
import com.autosales.modules.discovery.AutoToolDescriptor;
import com.autosales.modules.discovery.KeywordRetrievalService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.vertexai.api.Tool;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * AgentService backed by Vertex AI Gemini with native function calling.
 *
 * <p>B2 scope: full Phase 3 Safe Action Framework wiring on the Gemini path.
 *
 * <ul>
 *   <li><b>Read tools</b> (28-tool catalog minus writes) are exposed to Gemini as
 *       native {@code FunctionDeclaration}s. Gemini calls them autonomously; each
 *       call is persisted to {@code agent_tool_call_audit} with tier={@code R}.</li>
 *   <li><b>Write tools</b> (the 9 {@code ActionHandler} beans: create_lead,
 *       apply_incentive, mark_arrived, etc.) are NOT exposed for function calling.
 *       The system instruction teaches Gemini to emit a
 *       {@code [[PROPOSE]]{toolName, payload}[[/PROPOSE]]} marker at the end of its
 *       reply. The scanner extracts it; we call
 *       {@link ActionService#propose} in-process; the React widget renders a
 *       ProposalCard and the user clicks Execute to commit.</li>
 * </ul>
 *
 * <p>This is the same propose/confirm/commit flow used by
 * {@link com.autosales.modules.agent.OpenClawAgentService} on master — the
 * Phase 3 framework is LLM-agnostic; only the transport of the marker convention
 * needed reinstating for the new model.
 */
@Service
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class GeminiAgentService implements AgentService {

    private static final Logger log = LoggerFactory.getLogger(GeminiAgentService.class);

    /**
     * System instruction injected on every turn. Gives Gemini its identity,
     * tool mandate, the Write-Tool Protocol (propose marker for side-effecting
     * actions), and lightweight domain rules. Layered with the per-turn
     * {@code prependUserContext} which adds the current caller's identity + role.
     */
    private static final String SYSTEM_INSTRUCTION_TEMPLATE = """
            You are AUTOSALES, an AI assistant for automobile dealership operations.

            ## ⚠ ACTION-REQUEST PROTOCOL — MANDATORY SEQUENCE ⚠

            For EVERY action request (read OR write), follow this protocol IN
            ORDER. Do NOT shortcut by reading conversation history first — start
            from scratch every time. Recent conversation context can be wrong,
            stale, or biased toward a previous flow.

              STEP 1 — Identify named entities in the user's message.
                       (e.g., "Jane Smith" = a customer; "DL01000003" = a deal;
                        "VIN 1HGCM..." = a vehicle.)

              STEP 2 — For EACH named entity, call the appropriate read tool to
                       verify it exists and fetch its real data. This is
                       NON-NEGOTIABLE. Even if the same name appeared in earlier
                       turns, RE-VERIFY now — don't assume.

                       Customers : find_customer(dealerCode, lastName, firstName?)
                                   FIRST — preferred over list_customers (which
                                   paginates and misses recent inserts).
                       Deals     : get_deal(dealNumber)
                       Vehicles  : get_vehicle(vin) or decode_vin(vin)
                       Leads     : list_leads(dealerCode) and scan
                       Recalls   : nhtsa_recall_lookup(vin) for VIN-specific,
                                   list_recalls() for broad lookups.
                       (Other entities follow the same pattern.)

              STEP 3 — Use the results of those lookups to compose your action.
                       If an entity exists, use its id directly. If it doesn't,
                       decline gracefully OR (for write actions) propose
                       creating the prerequisite first.

              STEP 4 — ONLY AFTER steps 1-3, consult the conversation history
                       for additional context (user preferences, prior choices,
                       in-flight workflow state). History supplements lookups;
                       it does NOT substitute for them.

            Why this matters: in a previous test, after creating customer
            "Rajesh Ramadurai" the user immediately asked to create a lead for
            "Jane Smith". The agent reasoned from recent conversation context
            ("we just onboarded a new customer; Jane must be new too") and
            asked for Jane's customer fields — even though Jane was already
            in the system as customer #82. Calling find_customer(DLR01, Smith)
            would have caught it. The conversation context lied; the lookup
            doesn't.

            ## Read tools (function calling)

            You have access to many read-only tools (see the function
            declarations attached to this turn). USE THEM for any factual
            question — never invent data. The catalog covers dealers,
            vehicles, customers, deals, leads, finance applications, stock,
            warranty, recalls, batch reports, calculators, and federal data
            (NHTSA recalls + vPIC VIN decode).

            ### Multi-step queries
            Chain tool calls as needed (e.g., list_customers → get_customer →
            list_deals). For compound questions ("what closed today AND
            commissions?"), you may emit multiple function_call parts in one
            response — they will execute in parallel.

            ### Filter / sort / aggregate IN YOUR REASONING (IMPORTANT)
            When the user asks for a filter, sort, or aggregation that the
            tool does NOT directly expose (e.g. "deals from the last 7 days",
            "vehicles aged > 90 days sorted by date", "average finance amount
            this month"), do NOT decline. Instead:

              1. Call the closest list_* tool with size=100 (the page-size
                 cap) so you have a generous set of records to work with.
              2. Filter / sort / aggregate the returned records in your own
                 reasoning — examine the relevant fields (dealDate,
                 stockedDate, financeAmount, etc.) and compute the answer.
              3. Return only the rows that match. State the filter you
                 applied so the user can verify ("filtered to dealDate >=
                 2026-04-26").
              4. If the page-100 result was full (suggesting more matches
                 exist beyond the first page), say so honestly: "showing
                 100 of N total — let me know if you want more."

            Decline only when the data volume genuinely exceeds what one
            page-100 fetch can cover (e.g. cross-dealer scans of thousands
            of rows, or aggregations over months of history). In those
            cases, log a capability gap with category=REPORT_GAP and
            note that a SQL surface (planned) would handle it natively.

            DO NOT decline by saying "the tool only supports X filter" when
            you can fetch and filter yourself — that's the work the agent
            exists to do.

            ## Write tools (Write-Tool Protocol — IMPORTANT)

            For these write actions, DO NOT use function calling. Instead, at
            the END of your reply, emit a single block exactly like this:

                [[PROPOSE]]{"toolName":"<name>","payload":{...}}[[/PROPOSE]]

            The user will see a preview card and approve before any database
            change happens. You write the prose explanation BEFORE the marker;
            the marker JSON itself is hidden from the user but is parsed by the
            backend.

            Available write actions and their required role:

            %WRITE_TOOLS%

            If the caller's role does not permit a requested write, politely
            decline and name the role required — do not emit the marker.

            ### Asking the user for missing data (IMPORTANT)
            When you need data from the user to satisfy a write tool, ALWAYS:
              1. Quote the EXACT field names from the payload schema above
                 (e.g. addressLine1, stateCode, cellPhone — not "address" or
                 "phone").
              2. Mention the format constraints (e.g. "stateCode must be 2
                 uppercase letters like MI, not Michigan"; "cellPhone is 10
                 digits with no dashes").
              3. List one field per line so the user can fill them in clearly.
              4. After the user replies, map their input back to those exact
                 field names in the payload — never collapse 'addressLine1,
                 city, stateCode, zipCode' into a single 'address' string.

            ### Pre-requisites for writes (machine-enforced)
            Many writes require references to existing entities (e.g.,
            create_lead requires an existing customerId). The framework
            ENFORCES these — if you propose without the referenced entity,
            the response will carry a `prerequisiteGap` envelope describing
            exactly what is missing and which satisfier action(s) can fill
            it. The user/UI handles the gap card; you don't need to
            simulate the chain in prose.

            Best practice nonetheless:
              - When the user mentions an entity that may exist (e.g.
                "create a lead for Robert Garcia"), call the finder
                (list_customers) FIRST. If a single match is obvious, use
                that customerId in the proposal directly.
              - When the user is clearly creating something new (e.g.
                "new customer Jane Smith, phone 555-1234, 123 Main St,
                Detroit, MI 48201"), include all customer fields the user
                mentioned — the prereq framework will detect that the
                customerId is still missing and chain create_customer
                with the data you've collected.

            ## Capability-gap logging (IMPORTANT)

            When a user asks for a capability your tools do NOT support — for
            example a query you cannot answer because no matching read tool
            exists, or a write you cannot perform because no ActionHandler is
            registered — BEFORE declining to the user, call the tool
            log_capability_gap with ALL of these fields populated from the
            conversation context (NEVER call with empty fields):

              - requestedCapability: short label of what the user asked for
                (e.g. "filter deals by date range", "delete user")
              - category: READ_GAP (data the agent can't fetch),
                WRITE_GAP (action the agent can't perform),
                INTEGRATION_GAP (external system not wired),
                REPORT_GAP (analytic the agent can't compute),
                UI_GAP (workflow that belongs in the UI)
              - userInput: the user's original prompt VERBATIM — copy the
                exact text from the most recent user message
              - scenarioDescription: one sentence describing the business
                scenario (e.g. "Sales manager reviewing deals closed in the
                last week")
              - agentReasoning: one sentence on WHY this couldn't be served
                (e.g. "list_deals tool does not expose a date filter")
              - priorityHint: LOW / MEDIUM / HIGH (default MEDIUM)
              - suggestedAlternative: optional — the closest workaround the
                agent CAN perform

            AFTER calling log_capability_gap, your reply to the user MUST
            include — explicitly, not implicitly — that their request was
            logged. Use this pattern (paraphrase the wording but keep ALL
            three elements):

              1. Honest "today" framing — what you can't do, framed as
                 current limitation, NOT permanent. Examples:
                   "That's not something I can do today"
                   "I'm not able to do that right now"

              2. Explicit acknowledgement of the log — so the user knows
                 their feedback wasn't dropped on the floor. Example:
                   "I've logged your request to our capability backlog so
                    the product team can review it for a future release."

              3. Pivot to what you CAN do — closest workaround, or an
                 invitation to ask something else. Example:
                   "In the meantime, is there anything dealership-related
                    I can help with?"

            Example reply (combining all three):
              "Ordering food from external services isn't something I can
               do today — I'm focused on dealership operations. I've logged
               your request to our capability backlog so the product team
               can review it for a future release. In the meantime, is
               there anything about your inventory, deals, or customers
               I can help with?"

            Bare declines WITHOUT the log-acknowledgement are a bug — they
            leave the user feeling unheard. NEVER hallucinate data to fill
            the gap.

            ## NHTSA federal data (when to use which tool)

            For recall questions:
              - If the user names a SPECIFIC VIN — call nhtsa_recall_lookup(vin)
                to hit the federal NHTSA recallsByVin API. This returns the
                authoritative, live list of campaigns affecting that exact car.
              - For BROAD recall questions (campaigns by make/model, all our
                stored campaigns) — call list_recalls (our local DB).
              - For maximum coverage on a vehicle the dealership owns: call
                BOTH and merge — nhtsa_recall_lookup first for federal data,
                then list_recalls to surface any internal annotations.

            For VIN decoding:
              - decode_vin (our internal heuristic) is fast and good enough for
                routine prefix lookups.
              - nhtsa_vin_decode (vPIC) is the authoritative federal source —
                use when the user asks for canonical / detailed data, or when
                decode_vin returns minimal info.

            ## Domain rules

              - Dealer codes look like DLR01-DLR12 (12 dealers)
              - Deal numbers look like D-00000123 or DL01000123
              - VINs are 17 characters
              - Vehicle aging beyond 60 days is a warning signal
              - APR depends on credit tier (Excellent/Good/Fair/Poor)
              - Warranty claims escalate after 14 days unresolved

            ## Output guidelines

              - Use markdown tables for tabular data
              - Keep responses concise — bullet points over prose
              - When tools return errors, explain clearly and suggest the next step
              - Redact full SSNs to last 4 digits
              - Never expose raw API keys, JWT tokens, or password hashes
            """;

    /**
     * How many auto-discovered descriptors to surface per turn. ~15 keeps the
     * extra prompt overhead small (each FunctionDeclaration is ~50-100 tokens)
     * while giving the model real coverage beyond the curated 32-tool catalog.
     */
    private static final int AUTO_DISCOVERY_TOP_K = 15;

    private final VertexAiGeminiClient client;
    private final GeminiToolCatalog toolCatalog;
    private final AgentConversationService conversationService;
    private final TokenQuotaService quotaService;
    private final AgentCostService costService;
    private final CurrentUserContext userContext;
    private final ActionService actionService;
    private final ActionRegistry actionRegistry;
    private final AgentToolCallAuditService auditService;
    private final ObjectMapper mapper;
    private final KeywordRetrievalService keywordRetrieval;
    private final AutoToolGeminiBuilder autoBuilder;

    /** Cached system instruction with read/write tool lists baked in. */
    private final String systemInstruction;

    public GeminiAgentService(VertexAiGeminiClient client,
                              GeminiToolCatalog toolCatalog,
                              AgentConversationService conversationService,
                              TokenQuotaService quotaService,
                              AgentCostService costService,
                              CurrentUserContext userContext,
                              ActionService actionService,
                              ActionRegistry actionRegistry,
                              AgentToolCallAuditService auditService,
                              ObjectMapper mapper,
                              KeywordRetrievalService keywordRetrieval,
                              AutoToolGeminiBuilder autoBuilder) {
        this.client = client;
        this.toolCatalog = toolCatalog;
        this.conversationService = conversationService;
        this.quotaService = quotaService;
        this.costService = costService;
        this.userContext = userContext;
        this.actionService = actionService;
        this.actionRegistry = actionRegistry;
        this.auditService = auditService;
        this.mapper = mapper;
        this.keywordRetrieval = keywordRetrieval;
        this.autoBuilder = autoBuilder;
        this.systemInstruction = buildSystemInstruction();
    }

    @Override
    public AgentResponse invoke(AgentRequest request) {
        String model = client.getDisplayModel();

        if (!client.isConfigured()) {
            return new AgentResponse(
                    "The Gemini agent is not configured on this environment. Set GEMINI_PROJECT_ID env var.",
                    model, request.conversationId());
        }

        String userId = resolveUserId();
        TokenQuotaService.QuotaCheck quota = quotaService.check(userId);
        if (!quota.allowed()) {
            return new AgentResponse(quota.friendlyRejection(), model, request.conversationId());
        }

        boolean persistent = request.userMessage() != null && !request.userMessage().isBlank();
        String conversationId = request.conversationId();
        List<Map<String, Object>> messages = new ArrayList<>();

        if (persistent) {
            if (conversationId == null || conversationId.isBlank()) {
                AgentConversation created = conversationService.create(userId, null, model, request.userMessage());
                conversationId = created.getConversationId();
            } else {
                Optional<AgentConversation> existing = conversationService.findById(conversationId);
                if (existing.isPresent() && !existing.get().getUserId().equals(userId)) {
                    return new AgentResponse("Conversation not found.", model, null);
                }
                messages.addAll(conversationService.loadReplayMessages(conversationId));
            }
            Map<String, Object> userEntry = new LinkedHashMap<>();
            userEntry.put("role", "user");
            userEntry.put("content", request.userMessage());
            messages.add(userEntry);
        } else if (request.messages() != null) {
            for (AgentRequest.Message msg : request.messages()) {
                Map<String, Object> entry = new LinkedHashMap<>();
                entry.put("role", msg.role());
                entry.put("content", msg.content());
                messages.add(entry);
            }
        }

        try {
            CurrentUserContext.Snapshot user = userContext.current();
            prependSystemAndUserContext(messages, user);

            // Per-tool-call audit recorder — captures every read function_call Gemini
            // makes inside its agent loop. Closed-over conversationId so each row is
            // properly scoped in the trace UI.
            final String convIdFinal = conversationId;
            VertexAiGeminiClient.ToolCallRecorder recorder = (toolName, args, result, elapsedMs, errored) -> {
                try {
                    auditService.recordReadToolCall(user, convIdFinal, toolName, args, result, elapsedMs, errored);
                } catch (Exception auditErr) {
                    log.warn("Failed to persist read-tool audit for {}: {}", toolName, auditErr.getMessage());
                }
            };

            // B-discovery Path A: keyword-score the auto-extracted catalog
            // against the user's latest message and merge the top matches with
            // the curated tool list. KeywordRetrievalService already filters
            // to PUBLIC_READ/INTERNAL_READ + GET-only; AutoDescriptorRouter
            // re-checks at invocation time.
            List<Tool> mergedTools = mergeWithAutoDiscovered(
                    toolCatalog.getTools(), latestUserMessage(messages));

            VertexAiGeminiClient.Reply reply = client.complete(messages, mergedTools, recorder);
            String rawText = reply.text() == null ? "" : reply.text();

            // Extract proposal marker (if any) from the reply and run propose() in-process.
            ProposalMarkerScanner scanner = new ProposalMarkerScanner();
            scanner.onDelta(rawText);
            scanner.flush();
            String text = scanner.cleanedContent();
            ProposalResult proposalResult = maybeRunProposal(scanner, conversationId, user);
            ProposalResponse proposal = proposalResult != null ? proposalResult.proposal() : null;
            String proposalError = (proposalResult != null && proposalResult.hasError())
                    ? proposalResult.error() : null;

            int prompt = reply.promptTokens();
            int completion = reply.completionTokens();
            int tokens = prompt + completion;
            log.info("Gemini turn complete: prompt={} completion={} total={} toolCalls={} persistent={} proposal={}",
                    prompt, completion, tokens, reply.toolCalls().size(), persistent, proposal != null);

            if (persistent && conversationId != null) {
                conversationService.appendTurn(conversationId, request.userMessage(), text, tokens, prompt, completion);
            }

            AgentCostService.TurnCost turnCost = costService.computeTurn(prompt, completion);
            AgentResponse.TurnUsage turnUsage = new AgentResponse.TurnUsage(
                    turnCost.promptTokens(), turnCost.completionTokens(), turnCost.totalTokens(),
                    turnCost.inputCost(), turnCost.outputCost(), turnCost.totalCost(),
                    turnCost.currency(), false /* Gemini reports real token counts */);
            return new AgentResponse(text, model, conversationId, turnUsage, proposal, proposalError);
        } catch (VertexAiGeminiClient.GeminiException e) {
            return new AgentResponse(e.getMessage(), model, conversationId);
        }
    }

    @Override
    public void stream(AgentRequest request, SseEmitter emitter) {
        // B2: still non-streaming on the wire. We invoke synchronously then emit
        // delta + (proposal | proposal-error)? + done — same SSE event surface
        // OpenClawAgentService uses, so the AgentWidget React code is unchanged.
        try {
            AgentResponse resp = invoke(request);
            try {
                emitter.send(SseEmitter.event().name("delta").data(resp.reply() == null ? "" : resp.reply()));
                if (resp.proposal() != null) {
                    emitter.send(SseEmitter.event().name("proposal").data(toJsonString(resp.proposal())));
                } else if (resp.proposalError() != null) {
                    Map<String, String> errPayload = new LinkedHashMap<>();
                    errPayload.put("message", resp.proposalError());
                    emitter.send(SseEmitter.event().name("proposal-error").data(toJsonEscaped(errPayload)));
                }
                Map<String, String> done = new LinkedHashMap<>();
                done.put("reply", resp.reply() == null ? "" : resp.reply());
                done.put("conversationId", resp.conversationId() == null ? "" : resp.conversationId());
                done.put("model", resp.model() == null ? "" : resp.model());
                if (resp.usage() != null) {
                    done.put("promptTokens", String.valueOf(resp.usage().promptTokens()));
                    done.put("completionTokens", String.valueOf(resp.usage().completionTokens()));
                    done.put("totalTokens", String.valueOf(resp.usage().totalTokens()));
                    done.put("totalCost", resp.usage().totalCost() == null ? "0" : resp.usage().totalCost().toPlainString());
                    done.put("currency", resp.usage().currency() == null ? "USD" : resp.usage().currency());
                    done.put("estimated", "false");
                }
                emitter.send(SseEmitter.event().name("done").data(toJsonEscaped(done)));
            } catch (Exception ignore) { /* client disconnected */ }
            emitter.complete();
        } catch (Exception e) {
            log.warn("Gemini stream failed", e);
            try {
                emitter.send(SseEmitter.event().name("error").data("Agent error: " + e.getMessage()));
            } catch (Exception ignore) { }
            emitter.complete();
        }
    }

    @Override
    public boolean isAvailable() {
        return client.isConfigured();
    }

    @Override
    public String getModel() {
        return client.getDisplayModel();
    }

    private String resolveUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getName() != null) return auth.getName();
        return "anonymous";
    }

    /**
     * Walk the conversation in reverse and pull the most recent user-role
     * message. That's what we feed to {@link KeywordRetrievalService} —
     * the LLM's own intermediate model turns aren't useful retrieval
     * input, only the human's actual question.
     */
    private String latestUserMessage(List<Map<String, Object>> messages) {
        for (int i = messages.size() - 1; i >= 0; i--) {
            Map<String, Object> m = messages.get(i);
            if ("user".equals(m.get("role"))) {
                Object content = m.get("content");
                return content == null ? "" : content.toString();
            }
        }
        return "";
    }

    /**
     * Build the per-turn tools list — combines the curated
     * {@link GeminiToolCatalog} declarations with auto-discovered
     * {@link AutoToolDescriptor}s into a SINGLE {@link Tool}. Vertex AI
     * rejects multi-Tool inputs when they contain function declarations
     * ({@code INVALID_ARGUMENT: Multiple tools are supported only when
     * they are all search tools}), so we flatten into one Tool here. When
     * retrieval returns nothing, the curated list is returned unchanged.
     */
    private List<Tool> mergeWithAutoDiscovered(List<Tool> curated, String userMessage) {
        List<AutoToolDescriptor> retrieved =
                keywordRetrieval.retrieve(userMessage, AUTO_DISCOVERY_TOP_K);
        if (retrieved.isEmpty()) {
            return curated;
        }

        com.google.cloud.vertexai.api.Tool.Builder mergedBuilder =
                com.google.cloud.vertexai.api.Tool.newBuilder();
        java.util.Set<String> seenNames = new java.util.HashSet<>();
        if (curated != null) {
            for (Tool t : curated) {
                for (com.google.cloud.vertexai.api.FunctionDeclaration fd : t.getFunctionDeclarationsList()) {
                    mergedBuilder.addFunctionDeclarations(fd);
                    seenNames.add(fd.getName());
                }
            }
        }
        int added = 0;
        for (AutoToolDescriptor d : retrieved) {
            if (seenNames.contains(d.getName())) continue; // curated wins on collision
            com.google.cloud.vertexai.api.FunctionDeclaration fd = autoBuilder.toFunctionDeclaration(d);
            if (fd == null) continue;
            mergedBuilder.addFunctionDeclarations(fd);
            seenNames.add(fd.getName());
            added++;
        }
        if (added == 0) return curated;

        log.info("Auto-discovery: surfaced {} extra read tools for this turn (top match name='{}')",
                added, retrieved.get(0).getName());
        return List.of(mergedBuilder.build());
    }

    /**
     * Builds the system instruction with the live read-tool list and write-tool
     * roles baked in. Done once at construction; tool catalogs do not change at
     * runtime.
     */
    private String buildSystemInstruction() {
        String readToolList = String.join(", ", toolCatalog.getReadToolNames());
        StringBuilder writeList = new StringBuilder();
        actionRegistry.all().forEach(handler -> {
            writeList.append("  - ").append(handler.toolName())
                    .append(" (tier=").append(handler.tier().getCode())
                    .append(", roles=");
            if (handler.allowedRoles() != null && !handler.allowedRoles().isEmpty()) {
                handler.allowedRoles().forEach(r -> writeList.append(r.name()).append("/"));
                writeList.setLength(writeList.length() - 1);
            } else {
                writeList.append("any");
            }
            writeList.append(") — ").append(handler.endpointDescriptor()).append("\n");
            // Surface payload schema hints so the LLM knows the exact field
            // names + constraints — eliminates the "address as one string"
            // class of validation errors and lets the LLM ask the user for
            // structured data using the right field names.
            String schema = handler.payloadSchemaHint();
            if (schema != null && !schema.isBlank()) {
                writeList.append("    payload schema:\n");
                // Indent nested for readability; each line of the hint already
                // starts with "  - " so we add one more level.
                for (String line : schema.split("\n")) {
                    writeList.append("    ").append(line).append("\n");
                }
            }
        });
        return SYSTEM_INSTRUCTION_TEMPLATE
                .replace("%READ_TOOLS%", readToolList.isBlank() ? "(none registered)" : readToolList)
                .replace("%WRITE_TOOLS%", writeList.length() == 0 ? "  (none registered)" : writeList.toString());
    }

    /**
     * Prepends two system messages — the static system instruction (identity,
     * tool mandate, Write-Tool Protocol, domain rules) and a per-call
     * user-context line so Gemini knows who's calling and which dealer they're
     * scoped to. Same pattern as OpenClawAgentService.
     */
    private void prependSystemAndUserContext(List<Map<String, Object>> messages, CurrentUserContext.Snapshot user) {
        Map<String, Object> sys = new LinkedHashMap<>();
        sys.put("role", "system");
        sys.put("content", systemInstruction);
        messages.add(0, sys);

        if (user != null) {
            StringBuilder sb = new StringBuilder("Current caller: id=");
            sb.append(user.getUserId() != null ? user.getUserId() : "anonymous");
            if (user.getRole() != null) sb.append(", role=").append(user.getRole().name());
            if (user.getDealerCode() != null) sb.append(", dealer=").append(user.getDealerCode());
            sb.append(". When the user says 'my dealership' or omits a dealerCode, use this dealer code.");
            sb.append(" Enforce the Write-Tool Protocol role gates above; if the caller's role isn't permitted for the requested write, decline and name the role required.");

            Map<String, Object> ctx = new LinkedHashMap<>();
            ctx.put("role", "system");
            ctx.put("content", sb.toString());
            messages.add(1, ctx);
        }
    }

    /**
     * Result of a proposal attempt — either a successful proposal or an error message.
     */
    record ProposalResult(ProposalResponse proposal, String error) {
        static ProposalResult success(ProposalResponse p) { return new ProposalResult(p, null); }
        static ProposalResult failure(String msg) { return new ProposalResult(null, msg); }
        boolean hasError() { return error != null; }
    }

    @SuppressWarnings("unchecked")
    private ProposalResult maybeRunProposal(ProposalMarkerScanner scanner,
                                            String conversationId,
                                            CurrentUserContext.Snapshot user) {
        if (!scanner.hasProposal()) return null;
        try {
            Map<String, Object> envelope = mapper.readValue(scanner.extractedJson(),
                    new TypeReference<Map<String, Object>>() {});
            String toolName = (String) envelope.get("toolName");
            if (toolName == null || toolName.isBlank()) {
                log.warn("Proposal block missing toolName: {}", scanner.extractedJson());
                return null;
            }
            Object rawPayload = envelope.get("payload");
            Map<String, Object> payload = (rawPayload instanceof Map)
                    ? (Map<String, Object>) rawPayload
                    : Map.of();
            ProposalResponse resp = actionService.propose(user, toolName, payload, conversationId);
            return ProposalResult.success(resp);
        } catch (Exception e) {
            log.warn("Proposal failed (will emit proposal-error): {}", e.getMessage());
            return ProposalResult.failure(e.getMessage());
        }
    }

    private String toJsonString(Object o) {
        try {
            return mapper.writeValueAsString(o);
        } catch (Exception e) {
            return "{}";
        }
    }

    private String toJsonEscaped(Map<String, String> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, String> e : map.entrySet()) {
            if (!first) sb.append(",");
            first = false;
            sb.append("\"").append(e.getKey()).append("\":\"")
              .append(e.getValue()
                      .replace("\\", "\\\\")
                      .replace("\"", "\\\"")
                      .replace("\n", "\\n")
                      .replace("\r", "\\r")
                      .replace("\t", "\\t"))
              .append("\"");
        }
        sb.append("}");
        return sb.toString();
    }
}
