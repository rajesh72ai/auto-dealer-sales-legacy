package com.autosales.modules.agent.action;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.dto.ExecutionResult;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.agent.action.dto.ProposalResponse;
import com.autosales.modules.agent.action.entity.AgentActionProposal;
import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ActionServiceTest {

    @Mock private ActionRegistry registry;
    @Mock private ConfirmationTokenService tokenService;
    @Mock private AgentToolCallAuditService auditService;
    @Mock private CurrentUserContext userContext;
    @Spy  private ObjectMapper mapper = new ObjectMapper();
    @Spy  private PrerequisiteResolver prerequisiteResolver = new PrerequisiteResolver();
    @Mock private com.autosales.modules.agent.AgentConversationService conversationService;
    @InjectMocks private ActionService actionService;

    private CurrentUserContext.Snapshot adminSnap;
    private CurrentUserContext.Snapshot salesSnap;
    private FakeHandler handler;

    @BeforeEach
    void setUp() {
        adminSnap = new CurrentUserContext.Snapshot("ADMIN001", UserRole.ADMIN, "DLR01");
        salesSnap = new CurrentUserContext.Snapshot("SALES001", UserRole.SALESPERSON, "DLR01");
        handler = new FakeHandler("fake", Tier.A, Set.of(UserRole.ADMIN, UserRole.SALESPERSON), false);
    }

    @Test
    void propose_success_writesAuditAndReturnsToken() {
        when(userContext.current()).thenReturn(adminSnap);
        when(registry.require("fake")).thenReturn(handler);
        when(tokenService.create(any(), any(), any(), any(), any(), any(), any()))
                .thenAnswer(inv -> pendingProposal("T-1", "ADMIN001"));

        ProposalResponse resp = actionService.propose("fake",
                Map.of("vin", "1HGCM82633A123456"), "conv-1");

        assertEquals("T-1", resp.getToken());
        assertEquals("fake", resp.getToolName());
        assertEquals("A", resp.getTier());
        assertNotNull(resp.getPreview());
        verify(auditService).recordProposed(eq(adminSnap), eq("conv-1"), eq("T-1"),
                eq("fake"), eq("A"), anyString(), eq("POST"),
                any(), any(), eq(false));
    }

    @Test
    void propose_rejectsUnauthorizedRole() {
        CurrentUserContext.Snapshot financeSnap =
                new CurrentUserContext.Snapshot("FIN001", UserRole.FINANCE, "DLR01");
        when(userContext.current()).thenReturn(financeSnap);
        when(registry.require("fake")).thenReturn(handler);

        SecurityException ex = assertThrows(SecurityException.class,
                () -> actionService.propose("fake", Map.of(), null));
        assertTrue(ex.getMessage().contains("not permitted"));
        verify(tokenService, never()).create(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void propose_rejectsUnknownTool() {
        when(userContext.current()).thenReturn(adminSnap);
        when(registry.require("ghost")).thenThrow(new IllegalArgumentException("Unknown or unauthorised agent tool: ghost"));

        assertThrows(IllegalArgumentException.class,
                () -> actionService.propose("ghost", Map.of(), null));
    }

    @Test
    void confirm_success_executesAndRecordsExecuted() {
        when(userContext.current()).thenReturn(adminSnap);
        AgentActionProposal p = pendingProposal("T-2", "ADMIN001");
        p.setPayloadJson("{\"k\":\"v\"}");
        p.setPayloadHash(ConfirmationTokenService.hash(p.getPayloadJson()));
        when(tokenService.validate("T-2", "ADMIN001")).thenReturn(p);
        when(registry.require("fake")).thenReturn(handler);

        AgentToolCallAudit audit = AgentToolCallAudit.builder().auditId(123L).build();
        when(auditService.recordExecuted(any(), any(), any(), any(), any(), any(), any(), any(), any(), anyInt(), anyLong(), anyBoolean(), any()))
                .thenReturn(audit);

        ExecutionResult r = actionService.confirm("T-2");
        assertEquals("EXECUTED", r.getStatus());
        assertEquals(123L, r.getAuditId());
        assertEquals("fake", r.getToolName());
        verify(tokenService).markConfirmed("T-2", 123L);
    }

    @Test
    void confirm_detectsTamperedPayload() {
        when(userContext.current()).thenReturn(adminSnap);
        AgentActionProposal p = pendingProposal("T-3", "ADMIN001");
        p.setPayloadJson("{\"k\":\"v\"}");
        p.setPayloadHash("deadbeef"); // wrong hash
        when(tokenService.validate("T-3", "ADMIN001")).thenReturn(p);
        when(registry.require("fake")).thenReturn(handler);

        assertThrows(SecurityException.class, () -> actionService.confirm("T-3"));
    }

    @Test
    void confirm_handlerFailure_recordsFailedAndRethrows() {
        when(userContext.current()).thenReturn(adminSnap);
        AgentActionProposal p = pendingProposal("T-4", "ADMIN001");
        p.setPayloadJson("{}");
        p.setPayloadHash(ConfirmationTokenService.hash("{}"));
        when(tokenService.validate("T-4", "ADMIN001")).thenReturn(p);
        FakeHandler boomHandler = new FakeHandler("fake", Tier.A,
                Set.of(UserRole.ADMIN), false) {
            @Override
            public Object execute(Map<String, Object> p1, CurrentUserContext.Snapshot u) {
                throw new RuntimeException("downstream exploded");
            }
        };
        when(registry.require("fake")).thenReturn(boomHandler);

        assertThrows(RuntimeException.class, () -> actionService.confirm("T-4"));
        verify(auditService).recordFailed(any(), any(), eq("T-4"), eq("fake"), eq("A"),
                any(), eq("POST"), any(), any(), anyLong());
    }

    @Test
    void expireStaleForConversation_noConversationId_isNoOp() {
        int n = actionService.expireStaleForConversationAndAnnotate(null);
        assertEquals(0, n);
        verifyNoInteractions(conversationService);
        verifyNoInteractions(tokenService);
    }

    @Test
    void expireStaleForConversation_blank_isNoOp() {
        int n = actionService.expireStaleForConversationAndAnnotate("   ");
        assertEquals(0, n);
        verifyNoInteractions(conversationService);
        verifyNoInteractions(tokenService);
    }

    @Test
    void expireStaleForConversation_nothingExpired_doesNotAnnotate() {
        when(tokenService.expireStaleForConversation("conv-x")).thenReturn(List.of());
        int n = actionService.expireStaleForConversationAndAnnotate("conv-x");
        assertEquals(0, n);
        verify(conversationService, never()).appendSystemNote(any(), any());
    }

    @Test
    void expireStaleForConversation_singleProposal_writesSingleToolNote() {
        AgentActionProposal stale = pendingProposal("T-stale-1", "ADMIN001");
        stale.setToolName("create_customer");
        stale.setStatus("EXPIRED");
        when(tokenService.expireStaleForConversation("conv-9")).thenReturn(List.of(stale));

        int n = actionService.expireStaleForConversationAndAnnotate("conv-9");

        assertEquals(1, n);
        org.mockito.ArgumentCaptor<String> noteCap = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(conversationService).appendSystemNote(eq("conv-9"), noteCap.capture());
        String note = noteCap.getValue();
        assertTrue(note.contains("create_customer"), "note should name the abandoned tool");
        assertTrue(note.contains("expired"), "note should signal expiry");
        assertTrue(note.contains("Do NOT re-propose"), "note should forbid resurfacing");
    }

    @Test
    void expireStaleForConversation_multipleProposals_listsAllToolsInNote() {
        AgentActionProposal a = pendingProposal("T-a", "ADMIN001");
        a.setToolName("create_customer"); a.setStatus("EXPIRED");
        AgentActionProposal b = pendingProposal("T-b", "ADMIN001");
        b.setToolName("create_lead"); b.setStatus("EXPIRED");
        when(tokenService.expireStaleForConversation("conv-2")).thenReturn(List.of(a, b));

        int n = actionService.expireStaleForConversationAndAnnotate("conv-2");

        assertEquals(2, n);
        org.mockito.ArgumentCaptor<String> noteCap = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(conversationService).appendSystemNote(eq("conv-2"), noteCap.capture());
        String note = noteCap.getValue();
        assertTrue(note.contains("create_customer"));
        assertTrue(note.contains("create_lead"));
        assertTrue(note.contains("2 prior proposals"), "note should pluralize");
    }

    @Test
    void reject_marksProposalAndAuditsRejected() {
        when(userContext.current()).thenReturn(adminSnap);
        AgentActionProposal p = pendingProposal("T-5", "ADMIN001");
        p.setStatus("REJECTED");
        when(tokenService.markRejected("T-5", "ADMIN001")).thenReturn(p);
        when(registry.find("fake")).thenReturn(Optional.of(handler));

        ExecutionResult r = actionService.reject("T-5");
        assertEquals("REJECTED", r.getStatus());
        verify(auditService).recordRejected(eq("T-5"), eq(adminSnap), eq("fake"), eq("A"));
    }

    private AgentActionProposal pendingProposal(String token, String user) {
        return AgentActionProposal.builder()
                .token(token)
                .userId(user)
                .dealerCode("DLR01")
                .toolName("fake")
                .tier("A")
                .payloadJson("{}")
                .payloadHash(ConfirmationTokenService.hash("{}"))
                .previewJson("{}")
                .status("PENDING")
                .expiresAt(LocalDateTime.now().plusMinutes(5))
                .createdTs(LocalDateTime.now())
                .build();
    }

    static class FakeHandler implements ActionHandler {
        final String name; final Tier tier; final Set<UserRole> roles; final boolean reversible;
        FakeHandler(String name, Tier tier, Set<UserRole> roles, boolean reversible) {
            this.name = name; this.tier = tier; this.roles = roles; this.reversible = reversible;
        }
        @Override public String toolName() { return name; }
        @Override public Tier tier() { return tier; }
        @Override public Set<UserRole> allowedRoles() { return roles; }
        @Override public String endpointDescriptor() { return "POST /fake"; }
        @Override public boolean reversible() { return reversible; }
        @Override public ImpactPreview dryRun(Map<String, Object> p, CurrentUserContext.Snapshot u) {
            return ImpactPreview.builder().summary("ok").build();
        }
        @Override public Object execute(Map<String, Object> p, CurrentUserContext.Snapshot u) {
            return Map.of("result", "ok");
        }
    }
}
