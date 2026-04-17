package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.sales.dto.CreateDealRequest;
import com.autosales.modules.sales.dto.DealResponse;
import com.autosales.modules.sales.service.DealService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Validation;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CreateDealHandlerTest {

    @Mock private DealService dealService;
    @Spy  private PayloadValidator payloadValidator = new PayloadValidator(
            new ObjectMapper(),
            Validation.buildDefaultValidatorFactory().getValidator());
    @InjectMocks private CreateDealHandler handler;

    private CurrentUserContext.Snapshot salesUser;

    @BeforeEach
    void setUp() {
        salesUser = new CurrentUserContext.Snapshot("SALES001", UserRole.SALESPERSON, "DLR01");
    }

    @Test
    void metadata_reportsToolAndTierCorrectly() {
        assertEquals("create_deal", handler.toolName());
        assertEquals(Tier.A, handler.tier());
        assertTrue(handler.reversible());
        assertTrue(handler.allowedRoles().contains(UserRole.SALESPERSON));
        assertTrue(handler.allowedRoles().contains(UserRole.MANAGER));
        assertEquals("POST /api/deals", handler.endpointDescriptor());
    }

    @Test
    void dryRun_throwsRollbackWithPopulatedPreview() {
        DealResponse returned = sampleDeal();
        when(dealService.createDeal(any())).thenReturn(returned);

        Map<String, Object> payload = Map.of(
            "customerId", 7,
            "vin", "1HGCM82633A123456",
            "dealType", "R"
        );

        DryRunRollback rollback = assertThrows(DryRunRollback.class,
                () -> handler.dryRun(payload, salesUser));
        ImpactPreview preview = rollback.getPreview();
        assertNotNull(preview);
        assertEquals("create_deal", preview.getToolName());
        assertTrue(preview.isReversible());
        assertTrue(preview.getSummary().contains("John Doe"));
        assertFalse(preview.getChanges().isEmpty());
        assertTrue(preview.getChanges().stream().anyMatch(c -> c.contains("SalesDeal")));
    }

    @Test
    void dryRun_defaultsDealerCodeAndSalespersonFromUser() {
        ArgumentCaptor<CreateDealRequest> cap = ArgumentCaptor.forClass(CreateDealRequest.class);
        when(dealService.createDeal(cap.capture())).thenReturn(sampleDeal());

        Map<String, Object> payload = Map.of(
            "customerId", 7,
            "vin", "1HGCM82633A123456"
        );

        assertThrows(DryRunRollback.class, () -> handler.dryRun(payload, salesUser));
        CreateDealRequest req = cap.getValue();
        assertEquals("DLR01", req.getDealerCode());
        assertEquals("SALES001", req.getSalespersonId());
        assertEquals("R", req.getDealType());
    }

    @Test
    void execute_callsDealServiceAndReturnsResponse() {
        DealResponse returned = sampleDeal();
        when(dealService.createDeal(any())).thenReturn(returned);

        Object result = handler.execute(
                Map.of("customerId", 7, "vin", "1HGCM82633A123456", "dealType", "R"),
                salesUser);

        assertSame(returned, result);
    }

    @Test
    void compensation_includesDealNumberAndCancelAction() {
        DealResponse deal = sampleDeal();
        Map<String, Object> comp = handler.compensation(Map.of(), deal);
        assertNotNull(comp);
        assertEquals("cancel_deal", comp.get("action"));
        assertEquals("DL01000042", comp.get("dealNumber"));
    }

    @Test
    void compensation_nullForUnexpectedResult() {
        assertNull(handler.compensation(Map.of(), "not a deal"));
    }

    @Test
    void dryRun_warnsWhenVehiclePriceMissing() {
        DealResponse deal = sampleDeal();
        deal.setVehiclePrice(BigDecimal.ZERO);
        when(dealService.createDeal(any())).thenReturn(deal);

        DryRunRollback rollback = assertThrows(DryRunRollback.class,
                () -> handler.dryRun(
                        Map.of("customerId", 1, "vin", "X", "dealType", "R"),
                        salesUser));
        assertTrue(rollback.getPreview().getWarnings().stream()
                .anyMatch(w -> w.contains("PriceMaster")));
    }

    private DealResponse sampleDeal() {
        return DealResponse.builder()
                .dealNumber("DL01000042")
                .dealerCode("DLR01")
                .customerId(7)
                .vin("1HGCM82633A123456")
                .salespersonId("SALES001")
                .dealType("R")
                .dealStatus("WS")
                .vehiclePrice(new BigDecimal("28500.00"))
                .subtotal(new BigDecimal("28500.00"))
                .totalPrice(new BigDecimal("30075.00"))
                .downPayment(new BigDecimal("5000.00"))
                .amountFinanced(new BigDecimal("25075.00"))
                .customerName("John Doe")
                .vehicleDesc("2024 HON ACCORD")
                .salespersonName("Jane Sales")
                .statusDescription("Worksheet")
                .build();
    }
}
