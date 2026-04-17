package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.finance.dto.FinanceAppRequest;
import com.autosales.modules.finance.dto.FinanceAppResponse;
import com.autosales.modules.finance.service.FinanceAppService;
import com.autosales.modules.sales.dto.ApplyIncentivesRequest;
import com.autosales.modules.sales.dto.DealResponse;
import com.autosales.modules.sales.dto.TradeInRequest;
import com.autosales.modules.sales.dto.TradeInResponse;
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
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TierAHandlersTest {

    @Mock private DealService dealService;
    @Mock private FinanceAppService financeAppService;
    @Spy  private PayloadValidator payloadValidator = new PayloadValidator(
            new ObjectMapper(),
            Validation.buildDefaultValidatorFactory().getValidator());

    @InjectMocks private AddTradeInHandler addTradeInHandler;
    @InjectMocks private SubmitFinanceAppHandler submitFinanceAppHandler;
    @InjectMocks private ApplyIncentiveHandler applyIncentiveHandler;

    private CurrentUserContext.Snapshot salesUser;

    @BeforeEach
    void setUp() {
        salesUser = new CurrentUserContext.Snapshot("SALES001", UserRole.SALESPERSON, "DLR01");
    }

    // ---- add_trade_in ----

    @Test
    void addTradeIn_dryRunBuildsPreviewAndRollsBack() {
        TradeInResponse t = TradeInResponse.builder()
                .tradeId(5001)
                .dealNumber("DL01000001")
                .tradeYear((short) 2019)
                .tradeMake("HON")
                .tradeModel("CIVIC")
                .conditionCode("G")
                .odometer(45000)
                .acvAmount(new BigDecimal("11000.00"))
                .overAllow(new BigDecimal("1000.00"))
                .allowanceAmt(new BigDecimal("12000.00"))
                .payoffAmt(new BigDecimal("4000.00"))
                .netTrade(new BigDecimal("8000.00"))
                .build();
        when(dealService.addTradeIn(eq("DL01000001"), any())).thenReturn(t);

        Map<String, Object> payload = Map.of(
            "dealNumber", "DL01000001",
            "tradeYear", 2019,
            "tradeMake", "HON",
            "tradeModel", "CIVIC",
            "odometer", 45000,
            "conditionCode", "G",
            "overAllow", 1000.00
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> addTradeInHandler.dryRun(payload, salesUser));
        assertTrue(rb.getPreview().getSummary().contains("2019"));
        assertTrue(rb.getPreview().getChanges().stream().anyMatch(c -> c.contains("ACV")));
    }

    @Test
    void addTradeIn_requiresDealNumber() {
        Map<String, Object> payload = Map.of("tradeYear", 2019);
        assertThrows(IllegalArgumentException.class,
                () -> addTradeInHandler.dryRun(payload, salesUser));
    }

    @Test
    void addTradeIn_defaultsAppraisedByFromUser() {
        TradeInResponse stub = TradeInResponse.builder().tradeId(1).dealNumber("D1").build();
        ArgumentCaptor<TradeInRequest> cap = ArgumentCaptor.forClass(TradeInRequest.class);
        when(dealService.addTradeIn(eq("D1"), cap.capture())).thenReturn(stub);

        Map<String, Object> payload = Map.of(
            "dealNumber", "D1",
            "tradeYear", 2020,
            "tradeMake", "TOY",
            "tradeModel", "CAMRY",
            "odometer", 30000,
            "conditionCode", "E"
        );
        assertThrows(DryRunRollback.class,
                () -> addTradeInHandler.dryRun(payload, salesUser));
        assertEquals("SALES001", cap.getValue().getAppraisedBy());
    }

    // ---- submit_finance_app ----

    @Test
    void submitFinanceApp_dryRunBuildsPreview() {
        FinanceAppResponse app = FinanceAppResponse.builder()
                .financeId("FA0001")
                .dealNumber("DL01000001")
                .financeType("L")
                .financeTypeName("Loan")
                .amountRequested(new BigDecimal("25000.00"))
                .aprRequested(new BigDecimal("6.9"))
                .termMonths((short) 60)
                .monthlyPayment(new BigDecimal("493.75"))
                .build();
        when(financeAppService.createApplication(any())).thenReturn(app);

        Map<String, Object> payload = Map.of(
            "dealNumber", "DL01000001",
            "financeType", "L",
            "lenderCode", "ALLY",
            "amountRequested", 25000.00,
            "aprRequested", 6.9,
            "termMonths", 60
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> submitFinanceAppHandler.dryRun(payload, salesUser));
        assertTrue(rb.getPreview().getSummary().contains("60"));
        assertTrue(rb.getPreview().getChanges().stream().anyMatch(c -> c.contains("monthly payment")));
    }

    @Test
    void submitFinanceApp_warnsOnHighApr() {
        FinanceAppResponse app = FinanceAppResponse.builder()
                .financeId("FA2")
                .dealNumber("D2")
                .financeType("L")
                .amountRequested(new BigDecimal("10000"))
                .termMonths((short) 48)
                .build();
        when(financeAppService.createApplication(any())).thenReturn(app);

        Map<String, Object> payload = Map.of(
            "dealNumber", "D2",
            "financeType", "L",
            "amountRequested", 10000,
            "aprRequested", 18.5,
            "termMonths", 48
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> submitFinanceAppHandler.dryRun(payload, salesUser));
        assertTrue(rb.getPreview().getWarnings().stream().anyMatch(w -> w.contains("APR")));
    }

    @Test
    void submitFinanceApp_isReversibleWithCompensation() {
        FinanceAppResponse app = FinanceAppResponse.builder()
                .financeId("FA9")
                .dealNumber("D9")
                .build();
        Map<String, Object> comp = submitFinanceAppHandler.compensation(Map.of(), app);
        assertNotNull(comp);
        assertEquals("withdraw_finance_app", comp.get("action"));
        assertEquals("FA9", comp.get("financeId"));
    }

    // ---- apply_incentive ----

    @Test
    void applyIncentive_dryRunListsIncentivesInPreview() {
        DealResponse deal = DealResponse.builder()
                .dealNumber("DL01000001")
                .rebatesApplied(new BigDecimal("1500.00"))
                .totalPrice(new BigDecimal("27000.00"))
                .build();
        when(dealService.applyIncentives(eq("DL01000001"), any())).thenReturn(deal);

        Map<String, Object> payload = Map.of(
            "dealNumber", "DL01000001",
            "incentiveIds", List.of("LOYALTY-MAR", "CASHBACK-500")
        );
        DryRunRollback rb = assertThrows(DryRunRollback.class,
                () -> applyIncentiveHandler.dryRun(payload, salesUser));
        assertTrue(rb.getPreview().getChanges().stream()
                .anyMatch(c -> c.contains("LOYALTY-MAR")));
        assertTrue(rb.getPreview().getChanges().stream()
                .anyMatch(c -> c.contains("CASHBACK-500")));
    }

    @Test
    void applyIncentive_compensationIncludesIncentiveIds() {
        DealResponse deal = DealResponse.builder().dealNumber("D1").build();
        Map<String, Object> comp = applyIncentiveHandler.compensation(
                Map.of("dealNumber", "D1", "incentiveIds", List.of("A", "B")), deal);
        assertNotNull(comp);
        assertEquals("remove_incentive", comp.get("action"));
        assertEquals(List.of("A", "B"), comp.get("incentiveIds"));
    }

    @Test
    void applyIncentive_requiresDealNumber() {
        ApplyIncentivesRequest payloadNoDeal = new ApplyIncentivesRequest();
        Map<String, Object> payload = Map.of("incentiveIds", List.of("A"));
        assertThrows(IllegalArgumentException.class,
                () -> applyIncentiveHandler.dryRun(payload, salesUser));
    }
}
