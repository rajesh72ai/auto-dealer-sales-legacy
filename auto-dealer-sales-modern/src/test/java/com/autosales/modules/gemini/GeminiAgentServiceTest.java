package com.autosales.modules.gemini;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.AgentConversationService;
import com.autosales.modules.agent.AgentCostService;
import com.autosales.modules.agent.TokenQuotaService;
import com.autosales.modules.agent.action.ActionRegistry;
import com.autosales.modules.agent.action.ActionService;
import com.autosales.modules.agent.action.AgentToolCallAuditService;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.dto.ProposalResponse;
import com.autosales.modules.agent.dto.AgentRequest;
import com.autosales.modules.agent.dto.AgentResponse;
import com.autosales.modules.agent.entity.AgentConversation;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.vertexai.api.Tool;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * B2 unit tests — verifies the propose-marker pattern and tool-call audit
 * recorder are wired correctly through {@link GeminiAgentService}. The
 * {@link VertexAiGeminiClient} is mocked so these tests do not call Vertex AI.
 */
@ExtendWith(MockitoExtension.class)
class GeminiAgentServiceTest {

    @Mock private VertexAiGeminiClient client;
    @Mock private GeminiToolCatalog toolCatalog;
    @Mock private AgentConversationService conversationService;
    @Mock private TokenQuotaService quotaService;
    @Mock private AgentCostService costService;
    @Mock private CurrentUserContext userContext;
    @Mock private ActionService actionService;
    @Mock private ActionRegistry actionRegistry;
    @Mock private AgentToolCallAuditService auditService;

    private final ObjectMapper mapper = new ObjectMapper();
    private GeminiAgentService agentService;

    @BeforeEach
    void setUp() {
        // Auth context — same pattern as OpenClaw test
        SecurityContext ctx = SecurityContextHolder.createEmptyContext();
        ctx.setAuthentication(new UsernamePasswordAuthenticationToken("ADMIN001", "x", List.of()));
        SecurityContextHolder.setContext(ctx);

        // Default mocks — only needed by some tests, hence lenient
        lenient().when(client.isConfigured()).thenReturn(true);
        lenient().when(client.getDisplayModel()).thenReturn("google/gemini-2.5-flash");
        lenient().when(quotaService.check(anyString()))
                .thenReturn(new TokenQuotaService.QuotaCheck(true, 0, 200000));
        lenient().when(costService.computeTurn(anyInt(), anyInt()))
                .thenReturn(new AgentCostService.TurnCost(
                        10, 5, 15,
                        java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO,
                        "USD"));
        lenient().when(userContext.current())
                .thenReturn(new CurrentUserContext.Snapshot("ADMIN001", UserRole.ADMIN, "DLR01"));
        lenient().when(toolCatalog.getReadToolNames())
                .thenReturn(List.of("list_deals", "get_stock_aging"));
        lenient().when(toolCatalog.getTools())
                .thenReturn(Collections.<Tool>emptyList());
        lenient().when(actionRegistry.all()).thenReturn(Collections.emptyList());

        agentService = new GeminiAgentService(client, toolCatalog, conversationService,
                quotaService, costService, userContext, actionService, actionRegistry,
                auditService, mapper);
    }

    @Test
    void invoke_extractsProposalMarker_andCallsActionServicePropose() {
        // Gemini returns text with a propose marker at the end
        String reply = "I'll create that lead for you.\n\n" +
                "[[PROPOSE]]{\"toolName\":\"create_lead\",\"payload\":{\"firstName\":\"John\",\"lastName\":\"Doe\"}}[[/PROPOSE]]";
        VertexAiGeminiClient.Reply geminiReply = new VertexAiGeminiClient.Reply(
                reply, 100, 50, List.of());
        when(client.complete(anyList(), anyList(), any())).thenReturn(geminiReply);

        AgentConversation created = AgentConversation.builder()
                .conversationId("conv-x").userId("ADMIN001").model("google/gemini-2.5-flash").build();
        when(conversationService.create(eq("ADMIN001"), isNull(), anyString(), anyString()))
                .thenReturn(created);

        ProposalResponse expectedProposal = ProposalResponse.builder()
                .token("tok-123").toolName("create_lead").tier("A").build();
        when(actionService.propose(any(CurrentUserContext.Snapshot.class), eq("create_lead"),
                anyMap(), eq("conv-x")))
                .thenReturn(expectedProposal);

        // Act
        AgentResponse resp = agentService.invoke(
                new AgentRequest(null, null, null, "Create lead for John Doe"));

        // Assert: marker is stripped from the reply text
        assertNotNull(resp.reply());
        assertFalse(resp.reply().contains("[[PROPOSE]]"), "marker should be stripped");
        assertFalse(resp.reply().contains("[[/PROPOSE]]"), "close marker should be stripped");
        assertTrue(resp.reply().contains("I'll create that lead"), "prose preserved");

        // Assert: propose was called with the right toolName + payload
        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, Object>> payloadCap = ArgumentCaptor.forClass(Map.class);
        verify(actionService).propose(any(CurrentUserContext.Snapshot.class),
                eq("create_lead"), payloadCap.capture(), eq("conv-x"));
        assertEquals("John", payloadCap.getValue().get("firstName"));
        assertEquals("Doe", payloadCap.getValue().get("lastName"));

        // Assert: response carries the proposal
        assertNotNull(resp.proposal());
        assertEquals("tok-123", resp.proposal().getToken());
        assertNull(resp.proposalError());
    }

    @Test
    void invoke_handlesProposeFailureGracefullyAsProposalError() {
        String reply = "Doing that now.\n[[PROPOSE]]{\"toolName\":\"create_lead\",\"payload\":{}}[[/PROPOSE]]";
        VertexAiGeminiClient.Reply geminiReply = new VertexAiGeminiClient.Reply(
                reply, 100, 50, List.of());
        when(client.complete(anyList(), anyList(), any())).thenReturn(geminiReply);

        when(conversationService.create(anyString(), isNull(), anyString(), anyString()))
                .thenReturn(AgentConversation.builder().conversationId("conv-y").userId("ADMIN001").build());

        when(actionService.propose(any(CurrentUserContext.Snapshot.class), eq("create_lead"),
                anyMap(), anyString()))
                .thenThrow(new SecurityException("Your role (SALESPERSON) is not permitted to execute create_lead"));

        AgentResponse resp = agentService.invoke(
                new AgentRequest(null, null, null, "Make it so"));

        assertNull(resp.proposal(), "no proposal on failure");
        assertNotNull(resp.proposalError());
        assertTrue(resp.proposalError().contains("not permitted"));
    }

    @Test
    void invoke_passesRecorderToClient_thatPersistsReadToolCalls() {
        VertexAiGeminiClient.Reply reply = new VertexAiGeminiClient.Reply(
                "5 vehicles", 100, 30, List.of());
        when(client.complete(anyList(), anyList(), any())).thenReturn(reply);
        when(conversationService.create(anyString(), isNull(), anyString(), anyString()))
                .thenReturn(AgentConversation.builder().conversationId("conv-z").userId("ADMIN001").build());

        // Capture the recorder argument
        ArgumentCaptor<VertexAiGeminiClient.ToolCallRecorder> recorderCap =
                ArgumentCaptor.forClass(VertexAiGeminiClient.ToolCallRecorder.class);

        agentService.invoke(new AgentRequest(null, null, null, "How many vehicles?"));

        verify(client).complete(anyList(), anyList(), recorderCap.capture());
        VertexAiGeminiClient.ToolCallRecorder recorder = recorderCap.getValue();
        assertNotNull(recorder, "GeminiAgentService must pass a non-null recorder");

        // Simulate a tool call against the captured recorder
        recorder.record("get_stock_summary", Map.of("dealerCode", "DLR01"),
                "{\"total\":5}", 123L, false);

        verify(auditService).recordReadToolCall(
                any(CurrentUserContext.Snapshot.class),
                eq("conv-z"),
                eq("get_stock_summary"),
                eq(Map.of("dealerCode", "DLR01")),
                eq("{\"total\":5}"),
                eq(123L),
                eq(false));
    }

    @Test
    void invoke_returnsFallback_whenClientNotConfigured() {
        when(client.isConfigured()).thenReturn(false);

        AgentResponse resp = agentService.invoke(new AgentRequest(null, null, null, "hi"));

        assertTrue(resp.reply().toLowerCase().contains("not configured"));
        verify(client, never()).complete(anyList(), anyList(), any());
    }
}
