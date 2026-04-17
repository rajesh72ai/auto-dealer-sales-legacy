package com.autosales.modules.agent.action;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.dto.ExecutionResult;
import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.autosales.modules.agent.action.repository.AgentToolCallAuditRepository;
import com.autosales.modules.customer.dto.LeadResponse;
import com.autosales.modules.customer.service.CustomerLeadService;
import com.autosales.modules.sales.dto.CancellationRequest;
import com.autosales.modules.sales.dto.DealResponse;
import com.autosales.modules.sales.service.DealService;
import com.autosales.modules.vehicle.dto.TransferResponse;
import com.autosales.modules.vehicle.service.StockTransferService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UndoServiceTest {

    @Mock private AgentToolCallAuditRepository auditRepo;
    @Mock private DealService dealService;
    @Mock private StockTransferService transferService;
    @Mock private CustomerLeadService leadService;
    @Spy private ObjectMapper mapper = new ObjectMapper();

    @InjectMocks private UndoService undoService;

    private CurrentUserContext.Snapshot user;

    @BeforeEach
    void setUp() {
        user = new CurrentUserContext.Snapshot("SALES001", UserRole.SALESPERSON, "DLR01");
    }

    private AgentToolCallAudit baseAudit() {
        return AgentToolCallAudit.builder()
                .auditId(42L)
                .userId("SALES001")
                .toolName("create_deal")
                .status("EXECUTED")
                .reversible(true)
                .undone(false)
                .undoExpiresAt(LocalDateTime.now().plusSeconds(60))
                .compensationJson("{\"action\":\"cancel_deal\",\"dealNumber\":\"DL01000001\",\"reason\":\"agent_undo\"}")
                .build();
    }

    @Test
    void execute_cancelDeal_happyPath() {
        AgentToolCallAudit audit = baseAudit();
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));
        DealResponse cancelled = DealResponse.builder().dealNumber("DL01000001").dealStatus("CA").build();
        when(dealService.cancelDeal(eq("DL01000001"), any(CancellationRequest.class))).thenReturn(cancelled);

        ExecutionResult result = undoService.execute(42L, user);

        assertEquals("UNDONE", result.getStatus());
        assertEquals(42L, result.getAuditId());
        assertEquals("undo:create_deal", result.getToolName());
        assertSame(cancelled, result.getResult());

        ArgumentCaptor<AgentToolCallAudit> savedCap = ArgumentCaptor.forClass(AgentToolCallAudit.class);
        verify(auditRepo).save(savedCap.capture());
        assertTrue(savedCap.getValue().getUndone());
        assertNotNull(savedCap.getValue().getUndoneAt());
    }

    @Test
    void execute_cancelTransfer_happyPath() {
        AgentToolCallAudit audit = baseAudit();
        audit.setToolName("transfer_stock");
        audit.setCompensationJson("{\"action\":\"cancel_transfer\",\"transferId\":17}");
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));
        TransferResponse cancelled = TransferResponse.builder().transferId(17).transferStatus("CN").build();
        when(transferService.cancelTransfer(17)).thenReturn(cancelled);

        ExecutionResult result = undoService.execute(42L, user);

        assertEquals("UNDONE", result.getStatus());
        assertSame(cancelled, result.getResult());
        verify(transferService).cancelTransfer(17);
    }

    @Test
    void execute_closeLead_happyPath() {
        AgentToolCallAudit audit = baseAudit();
        audit.setToolName("create_lead");
        audit.setCompensationJson("{\"action\":\"close_lead\",\"leadId\":101,\"leadStatus\":\"DD\"}");
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));
        LeadResponse closed = LeadResponse.builder().leadId(101).leadStatus("DD").build();
        when(leadService.updateStatus(101, "DD")).thenReturn(closed);

        ExecutionResult result = undoService.execute(42L, user);

        assertEquals("UNDONE", result.getStatus());
        assertSame(closed, result.getResult());
    }

    @Test
    void execute_rejectsDifferentUser() {
        AgentToolCallAudit audit = baseAudit();
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));
        CurrentUserContext.Snapshot otherUser =
                new CurrentUserContext.Snapshot("OTHER01", UserRole.SALESPERSON, "DLR01");

        SecurityException ex = assertThrows(SecurityException.class,
                () -> undoService.execute(42L, otherUser));
        assertTrue(ex.getMessage().contains("different user"));
        verify(dealService, never()).cancelDeal(anyString(), any());
    }

    @Test
    void execute_rejectsExpiredWindow() {
        AgentToolCallAudit audit = baseAudit();
        audit.setUndoExpiresAt(LocalDateTime.now().minusSeconds(1));
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));

        IllegalStateException ex = assertThrows(IllegalStateException.class,
                () -> undoService.execute(42L, user));
        assertTrue(ex.getMessage().contains("expired"));
    }

    @Test
    void execute_rejectsAlreadyUndone() {
        AgentToolCallAudit audit = baseAudit();
        audit.setUndone(true);
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));

        IllegalStateException ex = assertThrows(IllegalStateException.class,
                () -> undoService.execute(42L, user));
        assertTrue(ex.getMessage().contains("already been undone"));
    }

    @Test
    void execute_rejectsNonReversible() {
        AgentToolCallAudit audit = baseAudit();
        audit.setReversible(false);
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));

        IllegalStateException ex = assertThrows(IllegalStateException.class,
                () -> undoService.execute(42L, user));
        assertTrue(ex.getMessage().contains("not reversible"));
    }

    @Test
    void execute_rejectsWrongStatus() {
        AgentToolCallAudit audit = baseAudit();
        audit.setStatus("PROPOSED");
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));

        IllegalStateException ex = assertThrows(IllegalStateException.class,
                () -> undoService.execute(42L, user));
        assertTrue(ex.getMessage().contains("PROPOSED"));
    }

    @Test
    void execute_rejectsMissingCompensation() {
        AgentToolCallAudit audit = baseAudit();
        audit.setCompensationJson(null);
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));

        IllegalStateException ex = assertThrows(IllegalStateException.class,
                () -> undoService.execute(42L, user));
        assertTrue(ex.getMessage().contains("No compensation"));
    }

    @Test
    void execute_unknownAction_returnsCleanError() {
        AgentToolCallAudit audit = baseAudit();
        audit.setCompensationJson("{\"action\":\"remove_trade_in\",\"tradeId\":5001}");
        when(auditRepo.findById(42L)).thenReturn(Optional.of(audit));

        UnsupportedOperationException ex = assertThrows(UnsupportedOperationException.class,
                () -> undoService.execute(42L, user));
        assertTrue(ex.getMessage().contains("remove_trade_in"));
        assertTrue(ex.getMessage().contains("not yet activated"));
        // Audit row must not be marked undone if the dispatch fails
        verify(auditRepo, never()).save(any());
    }

    @Test
    void execute_unknownAuditId_throws() {
        when(auditRepo.findById(99L)).thenReturn(Optional.empty());

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> undoService.execute(99L, user));
        assertTrue(ex.getMessage().contains("not found"));
    }

    @Test
    void activated_returnsTrue() {
        assertTrue(undoService.activated(),
                "UndoService should report activated=true now that v1 is shipped");
    }
}
