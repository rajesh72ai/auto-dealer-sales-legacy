package com.autosales.modules.finance.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.*;
import com.autosales.modules.finance.dto.*;
import com.autosales.modules.finance.entity.FinanceApp;
import com.autosales.modules.finance.entity.LeaseTerms;
import com.autosales.modules.finance.repository.FinanceAppRepository;
import com.autosales.modules.finance.repository.LeaseTermsRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for FinanceAppService — finance application lifecycle.
 * Covers FINAPP00 (create), FINAPV00 (approve/decline), FINCAL00 (loan calc), FINLSE00 (lease calc).
 *
 * Legacy COBOL business rules validated:
 * - Deal must be AP to enter F&I (FINAPP00)
 * - Loan/Lease require lender code; Cash does not (FINAPP00)
 * - APR 0-30%, term 12-84 months (FINAPP00)
 * - Principal = amountRequested - downPayment >= $500 for loan calc (COMLONL0)
 * - Only NW/CD apps can be decided; AP is terminal (FINAPV00)
 * - Approve recalculates payment with approved terms (FINAPV00)
 * - Conditional requires stipulations <= 200 chars (FINAPV00)
 * - Loan calc: pure stateless, 4 term comparisons, 12-month amortization (FINCAL00)
 * - Lease calc: defaults (residual 55%, MF 0.00125, term 36, tax 7%, acqFee $695) (FINLSE00)
 * - Lease terms persisted when dealNumber provided (FINLSE00)
 * - Lease terms insert is optional — calculator still returns results (FINLSE00)
 */
@ExtendWith(MockitoExtension.class)
class FinanceAppServiceTest {

    @Mock private FinanceAppRepository financeAppRepository;
    @Mock private LeaseTermsRepository leaseTermsRepository;
    @Mock private SalesDealRepository salesDealRepository;
    @Mock private LoanCalculator loanCalculator;
    @Mock private LeaseCalculator leaseCalculator;
    @Mock private FieldFormatter fieldFormatter;

    @InjectMocks
    private FinanceAppService financeAppService;

    // Common fixtures
    private SalesDeal testDeal;
    private FinanceApp testFinanceApp;

    @BeforeEach
    void setUp() {
        testDeal = SalesDeal.builder()
                .dealNumber("D000000001")
                .dealerCode("DLR01")
                .customerId(1001)
                .vin("1HGCM82633A004352")
                .dealStatus("AP")
                .vehiclePrice(new BigDecimal("35000.00"))
                .totalPrice(new BigDecimal("38608.94"))
                .downPayment(new BigDecimal("5000.00"))
                .amountFinanced(new BigDecimal("33608.94"))
                .frontGross(new BigDecimal("4000.00"))
                .backGross(BigDecimal.ZERO)
                .totalGross(new BigDecimal("4000.00"))
                .stateTax(new BigDecimal("2255.94"))
                .countyTax(BigDecimal.ZERO)
                .cityTax(BigDecimal.ZERO)
                .docFee(new BigDecimal("150.00"))
                .titleFee(new BigDecimal("33.00"))
                .regFee(new BigDecimal("75.00"))
                .subtotal(new BigDecimal("36095.00"))
                .totalOptions(BigDecimal.ZERO)
                .destinationFee(new BigDecimal("1095.00"))
                .tradeAllow(BigDecimal.ZERO)
                .tradePayoff(BigDecimal.ZERO)
                .netTrade(BigDecimal.ZERO)
                .rebatesApplied(BigDecimal.ZERO)
                .discountAmt(BigDecimal.ZERO)
                .dealDate(LocalDate.now())
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testFinanceApp = FinanceApp.builder()
                .financeId("FIN000000001")
                .dealNumber("D000000001")
                .customerId(1001)
                .financeType("L")
                .lenderCode("LND01")
                .appStatus("NW")
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("5.900"))
                .termMonths((short) 60)
                .monthlyPayment(new BigDecimal("650.23"))
                .downPayment(new BigDecimal("5000.00"))
                .submittedTs(LocalDateTime.now())
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    // ========================================================================
    // 1. CREATE APPLICATION (FINAPP00)
    // ========================================================================

    @Test
    @DisplayName("createApplication: loan type success — deal transitions AP→FI, payment calculated via COMLONL0")
    void testCreateApplication_loanSuccess() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("L")
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("5.900"))
                .termMonths((short) 60)
                .downPayment(new BigDecimal("5000.00"))
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        // COMLONL0 equivalent — loan calculation
        LoanCalculationResult calcResult = new LoanCalculationResult(
                new BigDecimal("650.23"), new BigDecimal("5405.86"),
                new BigDecimal("34014.80"), List.of());
        when(loanCalculator.calculate(any(BigDecimal.class), any(BigDecimal.class), eq((int) (short) 60)))
                .thenReturn(calcResult);

        FinanceAppResponse response = financeAppService.createApplication(request);

        assertNotNull(response);
        assertEquals("D000000001", response.getDealNumber());
        assertEquals("NW", response.getAppStatus());
        assertEquals("Loan", response.getFinanceTypeName());
        assertEquals("New", response.getStatusName());

        // Verify deal status transitioned AP → FI (per FINAPP00 business rule)
        assertEquals("FI", testDeal.getDealStatus());
        verify(salesDealRepository).save(testDeal);

        // Verify finance app was saved with calculated payment
        ArgumentCaptor<FinanceApp> captor = ArgumentCaptor.forClass(FinanceApp.class);
        verify(financeAppRepository).save(captor.capture());
        FinanceApp saved = captor.getValue();
        assertTrue(saved.getFinanceId().startsWith("FIN"));
        assertEquals("NW", saved.getAppStatus());
        assertEquals(1001, saved.getCustomerId());
        assertNotNull(saved.getMonthlyPayment());
    }

    @Test
    @DisplayName("createApplication: cash type — no lender required, no payment calc (FINAPP00 minimal path)")
    void testCreateApplication_cashType() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("C")
                .amountRequested(new BigDecimal("38608.94"))
                .downPayment(BigDecimal.ZERO)
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        FinanceAppResponse response = financeAppService.createApplication(request);

        assertNotNull(response);
        assertEquals("Cash", response.getFinanceTypeName());
        // No loan calculation should have been called for cash
        verify(loanCalculator, never()).calculate(any(), any(), anyInt());
        // Deal still moves to FI
        assertEquals("FI", testDeal.getDealStatus());
    }

    @Test
    @DisplayName("createApplication: lease type — no payment calc in FINAPP00, deferred to FINLSE00")
    void testCreateApplication_leaseType() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("S")
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("35000.00"))
                .downPayment(BigDecimal.ZERO)
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        FinanceAppResponse response = financeAppService.createApplication(request);

        assertNotNull(response);
        assertEquals("Lease", response.getFinanceTypeName());
        // Lease payment deferred to FINLSE00 — no loan calc
        verify(loanCalculator, never()).calculate(any(), any(), anyInt());
    }

    @Test
    @DisplayName("createApplication: deal NOT in AP status → rejection (FINAPP00 gate check)")
    void testCreateApplication_dealNotApproved() {
        testDeal.setDealStatus("WS"); // Worksheet, not Approved
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("L")
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("5.900"))
                .termMonths((short) 60)
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.createApplication(request));

        assertTrue(ex.getMessage().contains("Approved (AP) status"));
        assertTrue(ex.getMessage().contains("WS"));
        verify(financeAppRepository, never()).save(any());
    }

    @Test
    @DisplayName("createApplication: loan without lender code → rejection (FINAPP00 non-cash requires lender)")
    void testCreateApplication_loanMissingLender() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("L")
                .lenderCode(null) // Missing!
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("5.900"))
                .termMonths((short) 60)
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.createApplication(request));

        assertTrue(ex.getMessage().contains("Lender code is required"));
        verify(financeAppRepository, never()).save(any());
    }

    @Test
    @DisplayName("createApplication: APR > 30% → rejection (FINAPP00 range check)")
    void testCreateApplication_aprOutOfRange() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("L")
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("31.000")) // Over 30%
                .termMonths((short) 60)
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.createApplication(request));

        assertTrue(ex.getMessage().contains("APR must be between 0 and 30"));
        verify(financeAppRepository, never()).save(any());
    }

    @Test
    @DisplayName("createApplication: term outside 12-84 → rejection (FINAPP00 range check)")
    void testCreateApplication_termOutOfRange() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("L")
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("5.900"))
                .termMonths((short) 96) // Over 84
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.createApplication(request));

        assertTrue(ex.getMessage().contains("Term must be between 12 and 84"));
    }

    @Test
    @DisplayName("createApplication: invalid finance type → rejection")
    void testCreateApplication_invalidFinanceType() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("X") // Invalid
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("33608.94"))
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.createApplication(request));

        assertTrue(ex.getMessage().contains("Finance type must be L"));
    }

    @Test
    @DisplayName("createApplication: principal < $500 after down payment → no payment calc (COMLONL0 threshold)")
    void testCreateApplication_principalBelowMinimum() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D000000001")
                .financeType("L")
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("600.00"))
                .aprRequested(new BigDecimal("5.000"))
                .termMonths((short) 12)
                .downPayment(new BigDecimal("200.00")) // net = $400, below $500
                .build();

        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        FinanceAppResponse response = financeAppService.createApplication(request);

        // App created but no loan calculation because principal < $500
        assertNotNull(response);
        verify(loanCalculator, never()).calculate(any(), any(), anyInt());
    }

    @Test
    @DisplayName("createApplication: deal not found → EntityNotFoundException")
    void testCreateApplication_dealNotFound() {
        FinanceAppRequest request = FinanceAppRequest.builder()
                .dealNumber("D999999999")
                .financeType("L")
                .lenderCode("LND01")
                .amountRequested(new BigDecimal("33608.94"))
                .build();

        when(salesDealRepository.findById("D999999999")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> financeAppService.createApplication(request));
    }

    // ========================================================================
    // 2. APPROVE / DECLINE (FINAPV00)
    // ========================================================================

    @Test
    @DisplayName("approveOrDecline: approve loan — recalculates payment with approved terms (FINAPV00)")
    void testApprove_loanRecalculates() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        // Recalculation with approved terms (COMLONL0 CALC with approved amount/APR)
        LoanCalculationResult calcResult = new LoanCalculationResult(
                new BigDecimal("620.15"), new BigDecimal("4600.06"),
                new BigDecimal("32009.00"), List.of());
        BigDecimal netAmount = new BigDecimal("30000.00").subtract(new BigDecimal("5000.00")); // 25000
        when(loanCalculator.calculate(eq(netAmount), eq(new BigDecimal("4.900")), eq((int) (short) 60)))
                .thenReturn(calcResult);

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("AP")
                .amountApproved(new BigDecimal("30000.00"))
                .aprApproved(new BigDecimal("4.900"))
                .build();

        FinanceApprovalResponse response = financeAppService.approveOrDecline(request);

        assertEquals("FIN000000001", response.getFinanceId());
        assertEquals("AP", response.getNewStatus());
        assertEquals("Approved", response.getActionName());
        assertNotNull(response.getDecisionTs());
        // Side-by-side comparison: original vs approved (per FINAPV00 display layout)
        assertEquals(new BigDecimal("33608.94"), response.getOriginalAmount());
        assertEquals(new BigDecimal("30000.00"), response.getApprovedAmount());
        assertEquals(new BigDecimal("5.900"), response.getOriginalApr());
        assertEquals(new BigDecimal("4.900"), response.getApprovedApr());
    }

    @Test
    @DisplayName("approveOrDecline: conditional — stipulations recorded (FINAPV00 CD path)")
    void testApprove_conditional() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("CD")
                .stipulations("Proof of income required, 2 recent pay stubs")
                .build();

        FinanceApprovalResponse response = financeAppService.approveOrDecline(request);

        assertEquals("CD", response.getNewStatus());
        assertEquals("Conditional", response.getActionName());
        assertEquals("Proof of income required, 2 recent pay stubs", response.getStipulations());
    }

    @Test
    @DisplayName("approveOrDecline: decline — allows resubmit to different lender (FINAPV00 DN path)")
    void testApprove_decline() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("DN")
                .build();

        FinanceApprovalResponse response = financeAppService.approveOrDecline(request);

        assertEquals("DN", response.getNewStatus());
        assertEquals("Declined", response.getActionName());
    }

    @Test
    @DisplayName("approveOrDecline: already-approved app → cannot re-decide (FINAPV00 terminal state)")
    void testApprove_alreadyApproved() {
        testFinanceApp.setAppStatus("AP"); // Already approved
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("AP")
                .amountApproved(new BigDecimal("30000.00"))
                .aprApproved(new BigDecimal("4.900"))
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.approveOrDecline(request));

        assertTrue(ex.getMessage().contains("Cannot change decision"));
        assertTrue(ex.getMessage().contains("AP"));
        verify(financeAppRepository, never()).save(any());
    }

    @Test
    @DisplayName("approveOrDecline: conditional app can be re-decided (FINAPV00 CD → AP transition)")
    void testApprove_conditionalToApproved() {
        testFinanceApp.setAppStatus("CD"); // Conditional — can still be decided
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        LoanCalculationResult calcResult = new LoanCalculationResult(
                new BigDecimal("620.15"), new BigDecimal("4600.06"),
                new BigDecimal("32009.00"), List.of());
        when(loanCalculator.calculate(any(), any(), anyInt())).thenReturn(calcResult);

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("AP")
                .amountApproved(new BigDecimal("30000.00"))
                .aprApproved(new BigDecimal("4.900"))
                .build();

        FinanceApprovalResponse response = financeAppService.approveOrDecline(request);

        assertEquals("AP", response.getNewStatus());
    }

    @Test
    @DisplayName("approveOrDecline: approve missing amount → rejection")
    void testApprove_missingAmount() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("AP")
                .amountApproved(null) // Missing!
                .aprApproved(new BigDecimal("4.900"))
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.approveOrDecline(request));

        assertTrue(ex.getMessage().contains("Approved amount is required"));
    }

    @Test
    @DisplayName("approveOrDecline: conditional missing stipulations → rejection (FINAPV00 validation)")
    void testApprove_conditionalMissingStipulations() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("CD")
                .stipulations(null) // Missing!
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.approveOrDecline(request));

        assertTrue(ex.getMessage().contains("Stipulations are required"));
    }

    @Test
    @DisplayName("approveOrDecline: stipulations > 200 chars → rejection (FINAPV00 VARCHAR 200 limit)")
    void testApprove_stipulationsTooLong() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("CD")
                .stipulations("A".repeat(201)) // 201 chars
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.approveOrDecline(request));

        assertTrue(ex.getMessage().contains("200 characters"));
    }

    @Test
    @DisplayName("approveOrDecline: invalid action → rejection")
    void testApprove_invalidAction() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));

        FinanceApprovalRequest request = FinanceApprovalRequest.builder()
                .financeId("FIN000000001")
                .action("XX") // Invalid
                .build();

        assertThrows(BusinessValidationException.class,
                () -> financeAppService.approveOrDecline(request));
    }

    // ========================================================================
    // 3. LOAN CALCULATOR (FINCAL00)
    // ========================================================================

    @Test
    @DisplayName("calculateLoan: success — primary calc + 4 term comparisons + amortization (FINCAL00)")
    void testCalculateLoan_success() {
        LoanCalculatorRequest request = LoanCalculatorRequest.builder()
                .principal(new BigDecimal("30000.00"))
                .apr(new BigDecimal("5.900"))
                .termMonths(60)
                .downPayment(new BigDecimal("5000.00"))
                .build();

        // Primary: 60-month calc
        LoanCalculationResult primary = new LoanCalculationResult(
                new BigDecimal("482.63"), new BigDecimal("3957.80"),
                new BigDecimal("28957.80"),
                List.of(new AmortizationEntry(
                        1, new BigDecimal("482.63"), new BigDecimal("359.63"),
                        new BigDecimal("123.00"), new BigDecimal("123.00"),
                        new BigDecimal("24640.37"))));
        when(loanCalculator.calculate(eq(new BigDecimal("25000.00")), eq(new BigDecimal("5.900")), eq(60)))
                .thenReturn(primary);

        // 4 comparison terms (36, 48, 60, 72) per FINCAL00 WS-COMP-TERMS table
        for (int term : new int[]{36, 48, 72}) {
            when(loanCalculator.calculate(eq(new BigDecimal("25000.00")), eq(new BigDecimal("5.900")), eq(term)))
                    .thenReturn(new LoanCalculationResult(
                            new BigDecimal("700.00"), new BigDecimal("2000.00"),
                            new BigDecimal("27000.00"), List.of()));
        }

        LoanCalculatorResponse response = financeAppService.calculateLoan(request);

        assertNotNull(response);
        assertEquals(new BigDecimal("30000.00"), response.getPrincipal());
        assertEquals(new BigDecimal("5000.00"), response.getDownPayment());
        assertEquals(0, new BigDecimal("25000.00").compareTo(response.getNetPrincipal()));
        assertEquals(new BigDecimal("482.63"), response.getMonthlyPayment());
        // 4 comparison terms (FINCAL00 side-by-side: 36/48/60/72)
        assertEquals(4, response.getComparisons().size());
        // Amortization schedule present
        assertFalse(response.getAmortizationSchedule().isEmpty());
    }

    @Test
    @DisplayName("calculateLoan: principal below $500 → rejection (FINCAL00 net principal >= $500)")
    void testCalculateLoan_principalTooLow() {
        LoanCalculatorRequest request = LoanCalculatorRequest.builder()
                .principal(new BigDecimal("400.00"))
                .apr(new BigDecimal("5.900"))
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> financeAppService.calculateLoan(request));

        assertTrue(ex.getMessage().contains("$500"));
    }

    @Test
    @DisplayName("calculateLoan: APR out of range → rejection")
    void testCalculateLoan_aprOutOfRange() {
        LoanCalculatorRequest request = LoanCalculatorRequest.builder()
                .principal(new BigDecimal("30000.00"))
                .apr(new BigDecimal("35.000"))
                .build();

        assertThrows(BusinessValidationException.class,
                () -> financeAppService.calculateLoan(request));
    }

    @Test
    @DisplayName("calculateLoan: default term 60 months when not specified (FINCAL00 default)")
    void testCalculateLoan_defaultTerm() {
        LoanCalculatorRequest request = LoanCalculatorRequest.builder()
                .principal(new BigDecimal("25000.00"))
                .apr(new BigDecimal("5.000"))
                .termMonths(null)
                .downPayment(BigDecimal.ZERO)
                .build();

        LoanCalculationResult result = new LoanCalculationResult(
                new BigDecimal("471.78"), new BigDecimal("3306.80"),
                new BigDecimal("28306.80"), List.of());
        when(loanCalculator.calculate(any(), any(), eq(60))).thenReturn(result);
        // Stub comparison terms
        for (int term : new int[]{36, 48, 72}) {
            when(loanCalculator.calculate(any(), any(), eq(term))).thenReturn(result);
        }

        LoanCalculatorResponse response = financeAppService.calculateLoan(request);

        assertEquals(60, response.getTermMonths());
    }

    // ========================================================================
    // 4. LEASE CALCULATOR (FINLSE00)
    // ========================================================================

    @Test
    @DisplayName("calculateLease: success with defaults — residual 55%, MF 0.00125, 36mo (FINLSE00 defaults)")
    void testCalculateLease_withDefaults() {
        LeaseCalculatorRequest request = LeaseCalculatorRequest.builder()
                .capitalizedCost(new BigDecimal("35000.00"))
                .build();

        LeaseCalculationResult calcResult = new LeaseCalculationResult(
                new BigDecimal("19250.00"),  // residualAmount (55% of 35000)
                new BigDecimal("35695.00"),  // adjustedCapCost (35000 + 695 acqFee)
                new BigDecimal("456.94"),    // monthlyDepreciation
                new BigDecimal("68.68"),     // monthlyFinanceCharge
                new BigDecimal("36.79"),     // monthlyTax
                new BigDecimal("562.41"),    // totalMonthlyPayment
                new BigDecimal("1257.41"),   // driveOffAmount
                new BigDecimal("20246.76"),  // totalCost
                new BigDecimal("3.00"));     // equivalentApr (MF * 2400)

        when(leaseCalculator.calculate(
                eq(new BigDecimal("35000.00")), eq(BigDecimal.ZERO),
                eq(new BigDecimal("55.00")), eq(new BigDecimal("0.00125")),
                eq(36), eq(new BigDecimal("7.0")),
                eq(new BigDecimal("695")), eq(BigDecimal.ZERO)))
                .thenReturn(calcResult);

        LeaseCalculatorResponse response = financeAppService.calculateLease(request);

        assertNotNull(response);
        // Verify defaults were applied (per FINLSE00)
        assertEquals(0, new BigDecimal("55.00").compareTo(response.getResidualPct()));
        assertEquals(0, new BigDecimal("0.00125").compareTo(response.getMoneyFactor()));
        assertEquals(36, response.getTermMonths());
        assertEquals(0, new BigDecimal("7.0").compareTo(response.getTaxRate()));
        assertEquals(0, new BigDecimal("695").compareTo(response.getAcqFee()));
        // Verify equivalent APR = MF * 2400 (industry standard, per FINLSE00)
        assertEquals(0, new BigDecimal("3.00").compareTo(response.getEquivalentApr()));
    }

    @Test
    @DisplayName("calculateLease: with dealNumber — persists lease terms (FINLSE00 INSERT LEASE_TERMS)")
    void testCalculateLease_persistsLeaseTerms() {
        LeaseCalculatorRequest request = LeaseCalculatorRequest.builder()
                .capitalizedCost(new BigDecimal("35000.00"))
                .dealNumber("D000000001")
                .build();

        FinanceApp leaseApp = FinanceApp.builder()
                .financeId("FIN000000002")
                .dealNumber("D000000001")
                .financeType("S")
                .appStatus("NW")
                .amountRequested(new BigDecimal("35000.00"))
                .downPayment(BigDecimal.ZERO)
                .build();

        when(financeAppRepository.findByDealNumberAndFinanceType("D000000001", "S"))
                .thenReturn(Optional.of(leaseApp));
        when(leaseTermsRepository.findByFinanceId("FIN000000002"))
                .thenReturn(Optional.empty()); // New terms

        LeaseCalculationResult calcResult = new LeaseCalculationResult(
                new BigDecimal("19250.00"), new BigDecimal("35695.00"),
                new BigDecimal("456.94"), new BigDecimal("68.68"),
                new BigDecimal("36.79"), new BigDecimal("562.41"),
                new BigDecimal("1257.41"), new BigDecimal("20246.76"),
                new BigDecimal("3.00"));
        when(leaseCalculator.calculate(any(), any(), any(), any(), anyInt(), any(), any(), any()))
                .thenReturn(calcResult);
        when(leaseTermsRepository.save(any(LeaseTerms.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeAppRepository.save(any(FinanceApp.class))).thenAnswer(inv -> inv.getArgument(0));

        LeaseCalculatorResponse response = financeAppService.calculateLease(request);

        assertNotNull(response);

        // Verify lease terms were persisted (per FINLSE00 INSERT LEASE_TERMS)
        ArgumentCaptor<LeaseTerms> termsCaptor = ArgumentCaptor.forClass(LeaseTerms.class);
        verify(leaseTermsRepository).save(termsCaptor.capture());
        LeaseTerms savedTerms = termsCaptor.getValue();
        assertEquals("FIN000000002", savedTerms.getFinanceId());
        assertEquals(12000, savedTerms.getMilesPerYear());
        assertEquals(0, new BigDecimal("0.25").compareTo(savedTerms.getExcessMileChg()));
        assertEquals(0, new BigDecimal("395.00").compareTo(savedTerms.getDispositionFee()));

        // Verify finance app monthly payment updated
        verify(financeAppRepository).save(any(FinanceApp.class));
    }

    @Test
    @DisplayName("calculateLease: without dealNumber — pure calculation, no DB writes (FINLSE00 calculator-only mode)")
    void testCalculateLease_noDealNumber() {
        LeaseCalculatorRequest request = LeaseCalculatorRequest.builder()
                .capitalizedCost(new BigDecimal("35000.00"))
                .build();

        LeaseCalculationResult calcResult = new LeaseCalculationResult(
                new BigDecimal("19250.00"), new BigDecimal("35695.00"),
                new BigDecimal("456.94"), new BigDecimal("68.68"),
                new BigDecimal("36.79"), new BigDecimal("562.41"),
                new BigDecimal("1257.41"), new BigDecimal("20246.76"),
                new BigDecimal("3.00"));
        when(leaseCalculator.calculate(any(), any(), any(), any(), anyInt(), any(), any(), any()))
                .thenReturn(calcResult);

        financeAppService.calculateLease(request);

        // No DB operations for calculator-only mode
        verify(leaseTermsRepository, never()).save(any());
        verify(financeAppRepository, never()).save(any());
    }

    // ========================================================================
    // 5. GET / LIST
    // ========================================================================

    @Test
    @DisplayName("getApplication: found → response with calculated totals")
    void testGetApplication_success() {
        when(financeAppRepository.findByFinanceId("FIN000000001")).thenReturn(Optional.of(testFinanceApp));

        FinanceAppResponse response = financeAppService.getApplication("FIN000000001");

        assertNotNull(response);
        assertEquals("FIN000000001", response.getFinanceId());
        assertEquals("Loan", response.getFinanceTypeName());
        assertEquals("New", response.getStatusName());
        assertNotNull(response.getTotalOfPayments()); // monthlyPayment * term
        assertNotNull(response.getTotalInterest());
    }

    @Test
    @DisplayName("getApplication: not found → EntityNotFoundException")
    void testGetApplication_notFound() {
        when(financeAppRepository.findByFinanceId("FIN999")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> financeAppService.getApplication("FIN999"));
    }

    @Test
    @DisplayName("listApplications: filter by dealNumber")
    void testListApplications_byDealNumber() {
        Page<FinanceApp> page = new PageImpl<>(List.of(testFinanceApp));
        when(financeAppRepository.findByDealNumber(eq("D000000001"), any(Pageable.class))).thenReturn(page);

        PaginatedResponse<FinanceAppResponse> response =
                financeAppService.listApplications("D000000001", null, null, 0, 20);

        assertEquals(1, response.content().size());
        assertEquals("D000000001", response.content().get(0).getDealNumber());
    }
}
