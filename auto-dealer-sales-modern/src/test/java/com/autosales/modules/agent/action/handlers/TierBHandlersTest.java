package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.registration.dto.WarrantyClaimRequest;
import com.autosales.modules.registration.dto.WarrantyClaimResponse;
import com.autosales.modules.registration.service.WarrantyClaimService;
import com.autosales.modules.sales.dto.ApprovalRequest;
import com.autosales.modules.sales.dto.ApprovalResponse;
import com.autosales.modules.sales.service.DealService;
import com.autosales.modules.vehicle.dto.ShipmentDeliverRequest;
import com.autosales.modules.vehicle.dto.ShipmentResponse;
import com.autosales.modules.vehicle.dto.TransferRequest;
import com.autosales.modules.vehicle.dto.TransferResponse;
import com.autosales.modules.vehicle.service.ProductionLogisticsService;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TierBHandlersTest {

    @Mock private DealService dealService;
    @Mock private StockTransferService transferService;
    @Mock private ProductionLogisticsService logisticsService;
    @Mock private WarrantyClaimService warrantyClaimService;
    // findAndRegisterModules() picks up JavaTimeModule so LocalDate fields in
    // WarrantyClaimRequest round-trip. Spring Boot registers this automatically
    // in production via jackson-datatype-jsr310 on the classpath.
    @Spy  private ObjectMapper mapper = new ObjectMapper().findAndRegisterModules();

    @InjectMocks private ApproveDealHandler approveDealHandler;
    @InjectMocks private TransferStockHandler transferStockHandler;
    @InjectMocks private MarkArrivedHandler markArrivedHandler;
    @InjectMocks private CloseWarrantyClaimHandler closeWarrantyClaimHandler;

    private CurrentUserContext.Snapshot managerUser;

    @BeforeEach
    void setUp() {
        managerUser = new CurrentUserContext.Snapshot("MGR001", UserRole.MANAGER, "DLR01");
    }

    // ---- metadata / tier assertions ----

    @Test
    void allFourHandlersAreTierB() {
        assertEquals(Tier.B, approveDealHandler.tier());
        assertEquals(Tier.B, transferStockHandler.tier());
        assertEquals(Tier.B, markArrivedHandler.tier());
        assertEquals(Tier.B, closeWarrantyClaimHandler.tier());
    }

    @Test
    void approveDealAndTransferStock_restrictedToManagerAdmin() {
        assertEquals(Set.of(UserRole.MANAGER, UserRole.ADMIN), approveDealHandler.allowedRoles());
        assertEquals(Set.of(UserRole.MANAGER, UserRole.ADMIN), transferStockHandler.allowedRoles());
    }

    @Test
    void markArrivedAllowsOperator() {
        assertTrue(markArrivedHandler.allowedRoles().contains(UserRole.OPERATOR));
    }

    @Test
    void closeWarrantyClaimAllowsFinance() {
        assertTrue(closeWarrantyClaimHandler.allowedRoles().contains(UserRole.FINANCE));
    }

    @Test
    void approveAndMarkArrivedAndCloseWarranty_areNotReversible() {
        assertFalse(approveDealHandler.reversible());
        assertFalse(markArrivedHandler.reversible());
        assertFalse(closeWarrantyClaimHandler.reversible());
    }

    @Test
    void transferStock_isReversibleBecausePendingUntilApproval() {
        assertTrue(transferStockHandler.reversible());
    }

    // ---- approve_deal ----

    @Test
    void approveDeal_dryRunBuildsStatusTransitionPreview() {
        ApprovalResponse resp = ApprovalResponse.builder()
                .dealNumber("DL01000001")
                .action("AP")
                .approvalType("MG")
                .approverId("MGR001")
                .approverName("Mary Manager")
                .oldStatus("PA")
                .newStatus("AP")
                .oldStatusDescription("Pending Approval")
                .newStatusDescription("Approved")
                .build();
        when(dealService.approve(eq("DL01000001"), any())).thenReturn(resp);

        Map<String, Object> payload = Map.of(
            "dealNumber", "DL01000001",
            "action", "AP",
            "approvalType", "MG",
            "comments", "Looks good"
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> approveDealHandler.dryRun(payload, managerUser));
        assertTrue(rb.getPreview().getSummary().contains("Pending Approval"));
        assertTrue(rb.getPreview().getChanges().stream()
                .anyMatch(c -> c.contains("PA") && c.contains("AP")));
    }

    @Test
    void approveDeal_defaultsApproverIdFromUser() {
        ApprovalResponse resp = ApprovalResponse.builder()
                .dealNumber("D1").action("AP").approvalType("MG")
                .oldStatus("PA").newStatus("AP")
                .oldStatusDescription("x").newStatusDescription("y")
                .build();
        ArgumentCaptor<ApprovalRequest> cap = ArgumentCaptor.forClass(ApprovalRequest.class);
        when(dealService.approve(eq("D1"), cap.capture())).thenReturn(resp);

        assertThrows(DryRunRollback.class, () -> approveDealHandler.dryRun(
                Map.of("dealNumber", "D1", "action", "AP", "approvalType", "MG"),
                managerUser));

        assertEquals("MGR001", cap.getValue().getApproverId());
    }

    // ---- transfer_stock ----

    @Test
    void transferStock_dryRunIncludesDealerPathAndPendingWarning() {
        TransferResponse resp = TransferResponse.builder()
                .transferId(7001)
                .fromDealer("DLR01")
                .toDealer("DLR03")
                .vin("1HGCM82633A123456")
                .vehicleDesc("2024 HON ACCORD")
                .transferStatus("RQ")
                .statusName("Requested")
                .build();
        when(transferService.requestTransfer(any())).thenReturn(resp);

        Map<String, Object> payload = Map.of(
            "fromDealer", "DLR01",
            "toDealer", "DLR03",
            "vin", "1HGCM82633A123456",
            "reason", "High demand at DLR03"
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> transferStockHandler.dryRun(payload, managerUser));
        assertTrue(rb.getPreview().getSummary().contains("DLR01"));
        assertTrue(rb.getPreview().getSummary().contains("DLR03"));
        assertTrue(rb.getPreview().getWarnings().stream()
                .anyMatch(w -> w.contains("pending")));
    }

    // ---- mark_arrived ----

    @Test
    void markArrived_dryRunWarnsAboutIrreversibility() {
        ShipmentResponse resp = ShipmentResponse.builder()
                .shipmentId("SH0001")
                .destDealer("DLR01")
                .shipmentStatus("IT")
                .statusName("In Transit")
                .vehicleCount((short) 3)
                .build();
        when(logisticsService.deliverShipment(eq("SH0001"), any())).thenReturn(resp);

        Map<String, Object> payload = Map.of(
            "shipmentId", "SH0001",
            "receivedBy", "OPS001",
            "notes", "All 3 inspected OK"
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> markArrivedHandler.dryRun(payload,
                        new CurrentUserContext.Snapshot("OPS001", UserRole.OPERATOR, "DLR01")));
        assertTrue(rb.getPreview().getWarnings().stream()
                .anyMatch(w -> w.contains("NOT reversible")));
    }

    @Test
    void markArrived_requiresShipmentId() {
        assertThrows(IllegalArgumentException.class,
                () -> markArrivedHandler.dryRun(Map.of("receivedBy", "x"), managerUser));
    }

    // ---- close_warranty_claim ----

    @Test
    void closeWarrantyClaim_defaultsStatusToCL() {
        WarrantyClaimResponse resp = WarrantyClaimResponse.builder()
                .claimNumber("WC2026-0042")
                .vin("1HGCM82633A123456")
                .claimStatus("CL")
                .claimStatusName("Closed")
                .laborAmt(new BigDecimal("450.00"))
                .partsAmt(new BigDecimal("400.00"))
                .totalClaim(new BigDecimal("850.00"))
                .build();
        ArgumentCaptor<WarrantyClaimRequest> cap = ArgumentCaptor.forClass(WarrantyClaimRequest.class);
        when(warrantyClaimService.update(eq("WC2026-0042"), cap.capture())).thenReturn(resp);

        Map<String, Object> payload = Map.of(
            "claimNumber", "WC2026-0042",
            "vin", "1HGCM82633A123456",
            "claimType", "WR",
            "claimDate", LocalDate.now().toString(),
            "laborAmt", 450.00,
            "partsAmt", 400.00,
            "notes", "Repair verified"
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> closeWarrantyClaimHandler.dryRun(payload, managerUser));
        assertEquals("CL", cap.getValue().getClaimStatus());
        assertTrue(rb.getPreview().getChanges().stream()
                .anyMatch(c -> c.contains("Closed")));
        assertTrue(rb.getPreview().getWarnings().stream()
                .anyMatch(w -> w.contains("cannot be reopened")));
    }
}
