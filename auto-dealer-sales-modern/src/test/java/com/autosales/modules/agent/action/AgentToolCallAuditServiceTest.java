package com.autosales.modules.agent.action;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.autosales.modules.agent.action.repository.AgentToolCallAuditRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgentToolCallAuditServiceTest {

    @Mock private AgentToolCallAuditRepository repo;
    @Spy  private ObjectMapper mapper = new ObjectMapper();
    @Mock private ApplicationEventPublisher events;
    @InjectMocks private AgentToolCallAuditService service;

    private CurrentUserContext.Snapshot user;

    @BeforeEach
    void setUp() {
        user = new CurrentUserContext.Snapshot("ADMIN001", UserRole.ADMIN, "DLR01");
        when(repo.save(any(AgentToolCallAudit.class))).thenAnswer(inv -> {
            AgentToolCallAudit a = inv.getArgument(0);
            a.setAuditId(42L);
            return a;
        });
    }

    @Test
    void recordProposed_setsDryRunTrueAndStatusProposed() {
        ArgumentCaptor<AgentToolCallAudit> cap = ArgumentCaptor.forClass(AgentToolCallAudit.class);
        service.recordProposed(user, "conv-1", "tok-1", "create_deal", "A",
                "POST /api/deals", "POST",
                Map.of("vin", "x"), Map.of("summary", "y"), true);
        verify(repo).save(cap.capture());
        AgentToolCallAudit a = cap.getValue();
        assertEquals("PROPOSED", a.getStatus());
        assertTrue(a.getDryRun());
        assertTrue(a.getReversible());
        assertEquals("A", a.getTier());
        assertEquals("ADMIN001", a.getUserId());
        assertEquals("A", a.getUserRole());
        assertEquals("DLR01", a.getDealerCode());
    }

    @Test
    void recordExecuted_setsUndoExpiryWhenReversible() {
        ArgumentCaptor<AgentToolCallAudit> cap = ArgumentCaptor.forClass(AgentToolCallAudit.class);
        service.recordExecuted(user, "conv-1", "tok-1", "create_deal", "A",
                "POST /api/deals", "POST",
                Map.of("vin", "x"), Map.of("dealNumber", "DL01"), 200, 42,
                true, Map.of("inverse", "delete_deal"));
        verify(repo).save(cap.capture());
        AgentToolCallAudit a = cap.getValue();
        assertEquals("EXECUTED", a.getStatus());
        assertFalse(a.getDryRun());
        assertTrue(a.getReversible());
        assertNotNull(a.getUndoExpiresAt());
        assertNotNull(a.getCompensationJson());
        assertTrue(a.getCompensationJson().contains("delete_deal"));
        assertEquals(42, a.getElapsedMs());
    }

    @Test
    void recordExecuted_noUndoWhenNotReversible() {
        ArgumentCaptor<AgentToolCallAudit> cap = ArgumentCaptor.forClass(AgentToolCallAudit.class);
        service.recordExecuted(user, null, "tok-2", "approve_deal", "B",
                "POST /approve", "POST", Map.of(), Map.of(), 200, 10, false, null);
        verify(repo).save(cap.capture());
        AgentToolCallAudit a = cap.getValue();
        assertFalse(a.getReversible());
        assertNull(a.getUndoExpiresAt());
        assertNull(a.getCompensationJson());
    }

    @Test
    void recordFailed_capturesErrorMessageAndTruncates() {
        String longMsg = "x".repeat(1000);
        service.recordFailed(user, null, "tok-3", "t", "A", "/x", "POST",
                Map.of(), new RuntimeException(longMsg), 5);
        ArgumentCaptor<AgentToolCallAudit> cap = ArgumentCaptor.forClass(AgentToolCallAudit.class);
        verify(repo).save(cap.capture());
        AgentToolCallAudit a = cap.getValue();
        assertEquals("FAILED", a.getStatus());
        assertEquals(500, a.getErrorMessage().length());
    }

    @Test
    void recordRejected_writesRejectedRow() {
        service.recordRejected("tok-4", user, "t", "A");
        ArgumentCaptor<AgentToolCallAudit> cap = ArgumentCaptor.forClass(AgentToolCallAudit.class);
        verify(repo).save(cap.capture());
        AgentToolCallAudit a = cap.getValue();
        assertEquals("REJECTED", a.getStatus());
        assertEquals("tok-4", a.getProposalToken());
        assertTrue(a.getDryRun());
    }
}
