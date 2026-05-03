package com.autosales.modules.agent;

import com.autosales.modules.agent.dto.AgentRequest;
import com.autosales.modules.agent.dto.AgentResponse;
import com.autosales.modules.agent.entity.AgentConversation;
import com.autosales.modules.agent.entity.AgentMessageEntity;
import com.autosales.modules.agent.repository.AgentMessageRepository;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/agent")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
public class AgentController {

    private final AgentService agentService;
    private final AgentConversationService conversationService;
    private final AgentMessageRepository messageRepository;
    private final AgentCostService costService;

    public AgentController(AgentService agentService,
                           AgentConversationService conversationService,
                           AgentMessageRepository messageRepository,
                           AgentCostService costService) {
        this.agentService = agentService;
        this.conversationService = conversationService;
        this.messageRepository = messageRepository;
        this.costService = costService;
    }

    @PostMapping
    public ResponseEntity<AgentResponse> invoke(@RequestBody AgentRequest request) {
        return ResponseEntity.ok(agentService.invoke(request));
    }

    @PostMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(@RequestBody AgentRequest request) {
        SseEmitter emitter = new SseEmitter(180_000L);
        agentService.stream(request, emitter);
        return emitter;
    }

    @GetMapping("/cost")
    public ResponseEntity<Map<String, Object>> cost(
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(required = false) String userId) {
        java.time.LocalDate fromDate = from == null || from.isBlank()
                ? java.time.LocalDate.now().minusDays(30)
                : java.time.LocalDate.parse(from);
        java.time.LocalDate toDate = to == null || to.isBlank()
                ? java.time.LocalDate.now()
                : java.time.LocalDate.parse(to);
        String effectiveUser = userId != null && !userId.isBlank() ? userId : currentUserId();
        return ResponseEntity.ok(costService.summary(effectiveUser, fromDate, toDate));
    }

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> info() {
        // Derive the human-readable label from the live provider so we don't
        // mis-advertise "Claude via OpenClaw" when running on Gemini (and vice
        // versa). The model id format is e.g. "google/gemini-2.5-flash" or
        // "anthropic/claude-sonnet-4-6" — both impls already return this.
        String model = agentService.getModel();
        String label = labelFor(model);
        return ResponseEntity.ok(Map.of(
                "available", agentService.isAvailable(),
                "model", model,
                "label", label,
                "skill", "autosales-api",
                "features", Map.of(
                        "streaming", true,
                        "persistentMemory", true,
                        "compositeTools", true,
                        "externalDataSources", List.of("nhtsa")
                )
        ));
    }

    private static String labelFor(String model) {
        if (model == null) return "AutoSales Agent";
        if (model.startsWith("google/")) return "AutoSales Agent (Gemini on Vertex AI)";
        if (model.startsWith("anthropic/")) return "AutoSales Agent (Claude via OpenClaw)";
        return "AutoSales Agent (" + model + ")";
    }

    // --- Conversation management ---

    @GetMapping("/conversations")
    public ResponseEntity<List<Map<String, Object>>> listConversations() {
        String userId = currentUserId();
        List<AgentConversation> list = conversationService.listForUser(userId);
        List<Map<String, Object>> out = list.stream().map(c -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("conversationId", c.getConversationId());
            m.put("title", c.getTitle());
            m.put("turnCount", c.getTurnCount());
            m.put("tokenTotal", c.getTokenTotal());
            m.put("model", c.getModel());
            m.put("createdTs", c.getCreatedTs());
            m.put("updatedTs", c.getUpdatedTs());
            return m;
        }).collect(Collectors.toList());
        return ResponseEntity.ok(out);
    }

    @GetMapping("/conversations/{conversationId}")
    public ResponseEntity<Map<String, Object>> getConversation(@PathVariable String conversationId) {
        String userId = currentUserId();
        Optional<AgentConversation> conv = conversationService.findById(conversationId);
        if (conv.isEmpty() || !conv.get().getUserId().equals(userId)) {
            return ResponseEntity.notFound().build();
        }
        List<AgentMessageEntity> msgs = messageRepository.findByConversationIdOrderBySeqAsc(conversationId);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("conversationId", conv.get().getConversationId());
        body.put("title", conv.get().getTitle());
        body.put("turnCount", conv.get().getTurnCount());
        body.put("tokenTotal", conv.get().getTokenTotal());
        body.put("model", conv.get().getModel());
        body.put("messages", msgs.stream().map(m -> {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("role", m.getRole());
            row.put("content", m.getContent());
            row.put("seq", m.getSeq());
            row.put("createdTs", m.getCreatedTs());
            return row;
        }).collect(Collectors.toList()));
        return ResponseEntity.ok(body);
    }

    @DeleteMapping("/conversations/{conversationId}")
    public ResponseEntity<Void> deleteConversation(@PathVariable String conversationId) {
        String userId = currentUserId();
        Optional<AgentConversation> conv = conversationService.findById(conversationId);
        if (conv.isEmpty() || !conv.get().getUserId().equals(userId)) {
            return ResponseEntity.notFound().build();
        }
        conversationService.delete(conversationId);
        return ResponseEntity.noContent().build();
    }

    private String currentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.getName() != null) ? auth.getName() : "anonymous";
    }
}
