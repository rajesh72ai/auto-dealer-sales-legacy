package com.autosales.modules.agent;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionService;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.dto.AgentRequest;
import com.autosales.modules.agent.dto.AgentResponse;
import com.autosales.modules.agent.entity.AgentConversation;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgentServiceTest {

    @Mock private OpenClawClient openClawClient;
    @Mock private OpenClawStreamClient streamClient;
    @Mock private AgentConversationService conversationService;
    @Mock private TokenQuotaService quotaService;
    @Mock private AgentCostService costService;
    @Mock private ActionService actionService;
    @Mock private CurrentUserContext userContext;
    @Spy  private ObjectMapper mapper = new ObjectMapper();
    @InjectMocks private AgentService agentService;

    @BeforeEach
    void authAs() {
        SecurityContext ctx = SecurityContextHolder.createEmptyContext();
        ctx.setAuthentication(new UsernamePasswordAuthenticationToken("ADMIN001", "x", List.of()));
        SecurityContextHolder.setContext(ctx);
        lenient().when(quotaService.check(anyString()))
                .thenReturn(new TokenQuotaService.QuotaCheck(true, 0, 200000));
        lenient().when(costService.computeTurn(anyInt(), anyInt()))
                .thenReturn(new AgentCostService.TurnCost(
                        0, 0, 0,
                        java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO,
                        "USD"));
        lenient().when(userContext.current())
                .thenReturn(new CurrentUserContext.Snapshot("ADMIN001", UserRole.ADMIN, "DLR01"));
    }

    private OpenClawClient.CompletionResponse mockReply(String text, int totalTokens) {
        return new OpenClawClient.CompletionResponse(
                List.of(new OpenClawClient.Choice(
                        new OpenClawClient.Message("assistant", text), "stop")),
                new OpenClawClient.Usage(10, totalTokens - 10, totalTokens));
    }

    @Test
    void invoke_returnsFallbackWhenGatewayNotConfigured() {
        when(openClawClient.isConfigured()).thenReturn(false);
        when(openClawClient.getModel()).thenReturn("anthropic/claude-sonnet-4-6");

        AgentResponse resp = agentService.invoke(
                new AgentRequest(null, null, null, "hi"));

        assertTrue(resp.reply().toLowerCase().contains("not configured"));
        verify(openClawClient, never()).complete(any());
    }

    @Test
    void invoke_persistent_createsNewConversationAndPersistsTurn() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("anthropic/claude-sonnet-4-6");
        AgentConversation created = AgentConversation.builder()
                .conversationId("conv-new").userId("ADMIN001").model("m").build();
        when(conversationService.create(eq("ADMIN001"), isNull(), anyString(), eq("List dealers")))
                .thenReturn(created);
        when(openClawClient.complete(anyList()))
                .thenReturn(mockReply("DLR01\nDLR02", 150));

        AgentResponse resp = agentService.invoke(
                new AgentRequest(null, null, null, "List dealers"));

        assertEquals("DLR01\nDLR02", resp.reply());
        assertEquals("conv-new", resp.conversationId());
        verify(conversationService).appendTurn("conv-new", "List dealers", "DLR01\nDLR02", 150, 10, 140);
    }

    @Test
    void invoke_persistent_replaysExistingHistory() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("m");
        AgentConversation existing = AgentConversation.builder()
                .conversationId("conv-1").userId("ADMIN001").build();
        when(conversationService.findById("conv-1")).thenReturn(Optional.of(existing));
        when(conversationService.loadReplayMessages("conv-1"))
                .thenReturn(List.of(Map.of("role", "user", "content", "prior")));
        when(openClawClient.complete(anyList())).thenReturn(mockReply("ok", 50));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Map<String, Object>>> cap = ArgumentCaptor.forClass(List.class);
        agentService.invoke(new AgentRequest(null, null, "conv-1", "next"));
        verify(openClawClient).complete(cap.capture());

        List<Map<String, Object>> sent = cap.getValue();
        // Expected order: [system user-context, prior assistant/user, next]
        assertEquals(3, sent.size());
        assertEquals("system", sent.get(0).get("role"));
        assertEquals("prior", sent.get(1).get("content"));
        assertEquals("next", sent.get(2).get("content"));
        verify(conversationService).appendTurn("conv-1", "next", "ok", 50, 10, 40);
    }

    @Test
    void invoke_persistent_rejectsConversationOwnedByAnotherUser() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("m");
        AgentConversation other = AgentConversation.builder()
                .conversationId("conv-1").userId("OTHER_USER").build();
        when(conversationService.findById("conv-1")).thenReturn(Optional.of(other));

        AgentResponse resp = agentService.invoke(
                new AgentRequest(null, null, "conv-1", "hi"));

        assertEquals("Conversation not found.", resp.reply());
        verify(openClawClient, never()).complete(any());
        verify(conversationService, never()).appendTurn(any(), any(), any(), anyInt());
    }

    @Test
    void invoke_legacyMode_passesMessagesThroughWithoutPersistence() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("m");
        when(openClawClient.complete(anyList())).thenReturn(mockReply("reply", 20));

        AgentResponse resp = agentService.invoke(new AgentRequest(
                List.of(new AgentRequest.Message("user", "legacy")),
                null, null, null));

        assertEquals("reply", resp.reply());
        assertNull(resp.conversationId());
        verify(conversationService, never()).create(any(), any(), any(), any());
        verify(conversationService, never()).appendTurn(any(), any(), any(), anyInt());
    }

    @Test
    void invoke_handlesAgentExceptionGracefully() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("m");
        AgentConversation created = AgentConversation.builder()
                .conversationId("c1").userId("ADMIN001").build();
        when(conversationService.create(any(), any(), any(), any())).thenReturn(created);
        when(openClawClient.complete(anyList()))
                .thenThrow(new OpenClawClient.AgentException("rate-limited"));

        AgentResponse resp = agentService.invoke(new AgentRequest(null, null, null, "hi"));

        assertEquals("rate-limited", resp.reply());
        assertEquals("c1", resp.conversationId());
        verify(conversationService, never()).appendTurn(any(), any(), any(), anyInt());
    }

    @Test
    void invoke_handlesEmptyChoicesFromGateway() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("m");
        when(conversationService.create(any(), any(), any(), any()))
                .thenReturn(AgentConversation.builder().conversationId("c1").userId("ADMIN001").build());
        when(openClawClient.complete(anyList()))
                .thenReturn(new OpenClawClient.CompletionResponse(List.of(), null));

        AgentResponse resp = agentService.invoke(new AgentRequest(null, null, null, "hi"));

        assertTrue(resp.reply().toLowerCase().contains("no response"));
    }

    @Test
    void invoke_refusesWhenTokenQuotaExceeded() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("anthropic/claude-sonnet-4-6");
        when(quotaService.check("ADMIN001"))
                .thenReturn(new TokenQuotaService.QuotaCheck(false, 250000, 200000));

        AgentResponse resp = agentService.invoke(
                new AgentRequest(null, null, null, "hi"));

        assertTrue(resp.reply().toLowerCase().contains("token limit"));
        assertTrue(resp.reply().contains("250000"));
        verify(openClawClient, never()).complete(any());
        verify(conversationService, never()).create(any(), any(), any(), any());
    }

    @Test
    void isAvailableAndGetModel_delegateToClient() {
        when(openClawClient.isConfigured()).thenReturn(true);
        when(openClawClient.getModel()).thenReturn("anthropic/claude-sonnet-4-6");
        assertTrue(agentService.isAvailable());
        assertEquals("anthropic/claude-sonnet-4-6", agentService.getModel());
    }
}
