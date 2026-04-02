package com.autosales.modules.sales.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.security.SystemUser;
import com.autosales.common.security.SystemUserRepository;
import com.autosales.common.util.*;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.entity.IncentiveProgram;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.entity.TaxRate;
import com.autosales.modules.admin.repository.*;
import com.autosales.modules.customer.entity.CreditCheck;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CreditCheckRepository;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.sales.dto.*;
import com.autosales.modules.sales.entity.IncentiveApplied;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.entity.SalesApproval;
import com.autosales.modules.sales.entity.TradeIn;
import com.autosales.modules.sales.repository.*;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for DealService — the deal lifecycle state machine.
 * Covers create, negotiate, validate, approve, trade-in, complete, and cancel flows.
 */
@ExtendWith(MockitoExtension.class)
class DealServiceTest {

    @Mock private SalesDealRepository dealRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private TradeInRepository tradeInRepository;
    @Mock private IncentiveAppliedRepository incentiveAppliedRepository;
    @Mock private IncentiveProgramRepository incentiveProgramRepository;
    @Mock private SalesApprovalRepository approvalRepository;
    @Mock private DealLineItemRepository lineItemRepository;
    @Mock private CreditCheckRepository creditCheckRepository;
    @Mock private SystemConfigRepository configRepository;
    @Mock private SystemUserRepository userRepository;
    @Mock private PriceMasterRepository priceMasterRepository;
    @Mock private TaxRateRepository taxRateRepository;
    @Mock private DealerRepository dealerRepository;
    @Mock private SequenceGenerator sequenceGenerator;
    @Mock private PricingEngine pricingEngine;
    @Mock private FieldFormatter fieldFormatter;
    @Mock private StockPositionService stockPositionService;
    @Mock private ResponseFormatter responseFormatter;

    @InjectMocks
    private DealService dealService;

    // Common test fixtures
    private Customer testCustomer;
    private Vehicle testVehicle;
    private Dealer testDealer;
    private PriceMaster testPriceMaster;
    private TaxRate testTaxRate;
    private SystemUser testSalesperson;
    private SystemUser testManager;
    private SystemUser testGM;

    @BeforeEach
    void setUp() {
        testCustomer = Customer.builder()
                .customerId(1001)
                .firstName("John")
                .lastName("Doe")
                .addressLine1("123 Main St")
                .city("Dallas")
                .stateCode("TX")
                .zipCode("75201")
                .customerType("I")
                .dealerCode("DLR01")
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .modelYear((short) 2026)
                .makeCode("HON")
                .modelCode("ACCRD")
                .exteriorColor("Black")
                .interiorColor("Tan")
                .vehicleStatus("AV")
                .dealerCode("DLR01")
                .daysInStock((short) 30)
                .pdiComplete("Y")
                .damageFlag("N")
                .odometer(15)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testDealer = Dealer.builder()
                .dealerCode("DLR01")
                .dealerName("Test Motors")
                .addressLine1("456 Dealer Blvd")
                .city("Dallas")
                .stateCode("TX")
                .zipCode("75201")
                .phoneNumber("2145551234")
                .dealerPrincipal("Jane Smith")
                .regionCode("SW1")
                .zoneCode("S1")
                .oemDealerNum("OEM12345")
                .maxInventory((short) 200)
                .activeFlag("Y")
                .openedDate(LocalDate.of(2000, 1, 1))
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testPriceMaster = PriceMaster.builder()
                .modelYear((short) 2026)
                .makeCode("HON")
                .modelCode("ACCRD")
                .effectiveDate(LocalDate.of(2026, 1, 1))
                .msrp(new BigDecimal("35000.00"))
                .invoicePrice(new BigDecimal("31000.00"))
                .holdbackAmt(new BigDecimal("500.00"))
                .holdbackPct(new BigDecimal("2.000"))
                .destinationFee(new BigDecimal("1095.00"))
                .advertisingFee(new BigDecimal("250.00"))
                .createdTs(LocalDateTime.now())
                .build();

        testTaxRate = TaxRate.builder()
                .stateCode("TX")
                .countyCode("00000")
                .cityCode("00000")
                .effectiveDate(LocalDate.of(2026, 1, 1))
                .stateRate(new BigDecimal("6.2500"))
                .countyRate(new BigDecimal("0.0000"))
                .cityRate(new BigDecimal("0.0000"))
                .docFeeMax(new BigDecimal("150.00"))
                .titleFee(new BigDecimal("33.00"))
                .regFee(new BigDecimal("75.00"))
                .build();

        testSalesperson = SystemUser.builder()
                .userId("SALES01")
                .userName("Bob Sales")
                .userType("S")
                .dealerCode("DLR01")
                .activeFlag("Y")
                .build();

        testManager = SystemUser.builder()
                .userId("MGR01")
                .userName("Alice Manager")
                .userType("M")
                .dealerCode("DLR01")
                .activeFlag("Y")
                .build();

        testGM = SystemUser.builder()
                .userId("GM01")
                .userName("Carol GM")
                .userType("G")
                .dealerCode("DLR01")
                .activeFlag("Y")
                .build();
    }

    // ========================================================================
    // Helper to build a standard deal in a given status
    // ========================================================================

    private SalesDeal buildDeal(String status) {
        return SalesDeal.builder()
                .dealNumber("D000000001")
                .dealerCode("DLR01")
                .customerId(1001)
                .vin("1HGCM82633A004352")
                .salespersonId("SALES01")
                .dealType("R")
                .dealStatus(status)
                .vehiclePrice(new BigDecimal("35000.00"))
                .totalOptions(BigDecimal.ZERO)
                .destinationFee(new BigDecimal("1095.00"))
                .subtotal(new BigDecimal("36095.00"))
                .tradeAllow(BigDecimal.ZERO)
                .tradePayoff(BigDecimal.ZERO)
                .netTrade(BigDecimal.ZERO)
                .rebatesApplied(BigDecimal.ZERO)
                .discountAmt(BigDecimal.ZERO)
                .docFee(new BigDecimal("150.00"))
                .stateTax(new BigDecimal("2255.94"))
                .countyTax(BigDecimal.ZERO)
                .cityTax(BigDecimal.ZERO)
                .titleFee(new BigDecimal("33.00"))
                .regFee(new BigDecimal("75.00"))
                .totalPrice(new BigDecimal("38608.94"))
                .downPayment(new BigDecimal("5000.00"))
                .amountFinanced(new BigDecimal("33608.94"))
                .frontGross(new BigDecimal("4000.00"))
                .backGross(new BigDecimal("500.00"))
                .totalGross(new BigDecimal("4500.00"))
                .dealDate(LocalDate.now())
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    /**
     * Stub recalculateDeal dependencies — tax rate and price master lookups
     * that happen inside the private recalculateDeal method.
     */
    private void stubRecalculateDeps() {
        lenient().when(taxRateRepository.findCurrentEffective(
                eq("TX"), eq("00000"), eq("00000"), any(LocalDate.class)))
                .thenReturn(Optional.of(testTaxRate));
        lenient().when(vehicleRepository.findById("1HGCM82633A004352"))
                .thenReturn(Optional.of(testVehicle));
        lenient().when(priceMasterRepository.findCurrentEffective(
                eq((short) 2026), eq("HON"), eq("ACCRD"), any(LocalDate.class)))
                .thenReturn(Optional.of(testPriceMaster));
    }

    // ========================================================================
    // 1. CREATE DEAL
    // ========================================================================

    @Test
    @DisplayName("createDeal: success - deal number generated, status=WS, vehicle price set from PriceMaster")
    void testCreateDeal_success() {
        CreateDealRequest request = CreateDealRequest.builder()
                .customerId(1001)
                .vin("1HGCM82633A004352")
                .salespersonId("SALES01")
                .dealType("R")
                .dealerCode("DLR01")
                .downPayment(new BigDecimal("5000.00"))
                .build();

        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(dealerRepository.findById("DLR01")).thenReturn(Optional.of(testDealer));
        when(sequenceGenerator.generateDealNumber()).thenReturn("D000000001");
        when(priceMasterRepository.findCurrentEffective(
                eq((short) 2026), eq("HON"), eq("ACCRD"), any(LocalDate.class)))
                .thenReturn(Optional.of(testPriceMaster));
        when(taxRateRepository.findCurrentEffective(
                eq("TX"), eq("00000"), eq("00000"), any(LocalDate.class)))
                .thenReturn(Optional.of(testTaxRate));

        // dealRepository.save returns whatever is passed in
        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));

        // fieldFormatter stubs for toResponse
        when(fieldFormatter.formatCurrency(any())).thenReturn("$0.00");
        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(userRepository.findByUserId("SALES01")).thenReturn(Optional.of(testSalesperson));

        DealResponse response = dealService.createDeal(request);

        assertNotNull(response);
        assertEquals("D000000001", response.getDealNumber());
        assertEquals("WS", response.getDealStatus());
        // Vehicle price should come from PriceMaster MSRP
        assertEquals(0, new BigDecimal("35000.00").compareTo(response.getVehiclePrice()));

        // Verify deal was saved
        ArgumentCaptor<SalesDeal> captor = ArgumentCaptor.forClass(SalesDeal.class);
        verify(dealRepository).save(captor.capture());
        SalesDeal saved = captor.getValue();
        assertEquals("WS", saved.getDealStatus());
        assertEquals(0, new BigDecimal("35000.00").compareTo(saved.getVehiclePrice()));
        assertEquals(0, new BigDecimal("1095.00").compareTo(saved.getDestinationFee()));
    }

    @Test
    @DisplayName("createDeal: vehicle not available (status=SD) throws BusinessValidationException")
    void testCreateDeal_vehicleNotAvailable() {
        testVehicle.setVehicleStatus("SD"); // Sold

        CreateDealRequest request = CreateDealRequest.builder()
                .customerId(1001)
                .vin("1HGCM82633A004352")
                .salespersonId("SALES01")
                .dealType("R")
                .dealerCode("DLR01")
                .build();

        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> dealService.createDeal(request));

        assertTrue(ex.getMessage().contains("not available for sale"));
        assertTrue(ex.getMessage().contains("SD"));
        verify(dealRepository, never()).save(any());
    }

    // ========================================================================
    // 2. NEGOTIATE
    // ========================================================================

    @Test
    @DisplayName("negotiate: counter offer sets new price, status -> NE, recalculation occurs")
    void testNegotiate_counterOffer() {
        SalesDeal deal = buildDeal("WS");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(dealerRepository.findById("DLR01")).thenReturn(Optional.of(testDealer));
        stubRecalculateDeps();
        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));

        NegotiationRequest request = NegotiationRequest.builder()
                .dealNumber("D000000001")
                .action("CO")
                .amount(new BigDecimal("33000.00"))
                .deskNotes("Customer counter at 33K")
                .build();

        NegotiationResponse response = dealService.negotiate("D000000001", request);

        assertNotNull(response);
        assertEquals("D000000001", response.getDealNumber());
        // Verify price was changed to counter offer amount
        assertEquals(0, new BigDecimal("33000.00").compareTo(response.getCurrentOffer()));
        // Verify status changed to NE
        assertEquals("NE", deal.getDealStatus());

        verify(dealRepository).save(any(SalesDeal.class));
    }

    @Test
    @DisplayName("negotiate: discount applied, front gross reduced")
    void testNegotiate_discount() {
        SalesDeal deal = buildDeal("WS");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(dealerRepository.findById("DLR01")).thenReturn(Optional.of(testDealer));
        stubRecalculateDeps();
        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));

        // 10% discount on $35,000 = $3,500
        NegotiationRequest request = NegotiationRequest.builder()
                .dealNumber("D000000001")
                .action("DS")
                .discountPct(new BigDecimal("10.00"))
                .build();

        NegotiationResponse response = dealService.negotiate("D000000001", request);

        assertNotNull(response);
        // Verify discount was applied
        assertEquals(0, new BigDecimal("3500.00").compareTo(deal.getDiscountAmt()));
        // Status should be NE
        assertEquals("NE", deal.getDealStatus());
        // Front gross should be reduced: vehiclePrice(35000) - discount(3500) - invoice(31000) = 500
        assertEquals(0, new BigDecimal("500.00").compareTo(deal.getFrontGross()));
    }

    // ========================================================================
    // 3. VALIDATE
    // ========================================================================

    @Test
    @DisplayName("validate: all 10 checks pass -> status PA, valid=true")
    void testValidate_allPass() {
        SalesDeal deal = buildDeal("NE");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(userRepository.findByUserId("SALES01")).thenReturn(Optional.of(testSalesperson));
        when(tradeInRepository.findBySalesDeal_DealNumber("D000000001")).thenReturn(Collections.emptyList());

        // Credit check required for retail deal type "R"
        CreditCheck creditCheck = CreditCheck.builder()
                .creditId(1)
                .customer(testCustomer)
                .status("AP")
                .expiryDate(LocalDate.now().plusDays(30))
                .build();
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1001), eq("AP"), any(LocalDate.class)))
                .thenReturn(Optional.of(creditCheck));

        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));

        ValidationResponse response = dealService.validate("D000000001");

        assertTrue(response.isValid());
        assertEquals("DEAL VALID", response.getResult());
        assertEquals("PA", response.getNewStatus());
        assertTrue(response.getErrors().isEmpty());
        // Verify deal was saved with PA status
        assertEquals("PA", deal.getDealStatus());
        verify(dealRepository).save(deal);
    }

    @Test
    @DisplayName("validate: missing credit check -> valid=false, errors populated")
    void testValidate_fails() {
        SalesDeal deal = buildDeal("NE");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(userRepository.findByUserId("SALES01")).thenReturn(Optional.of(testSalesperson));
        when(tradeInRepository.findBySalesDeal_DealNumber("D000000001")).thenReturn(Collections.emptyList());

        // No credit check found
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1001), eq("AP"), any(LocalDate.class)))
                .thenReturn(Optional.empty());

        ValidationResponse response = dealService.validate("D000000001");

        assertFalse(response.isValid());
        assertEquals("VALIDATION FAILED", response.getResult());
        assertFalse(response.getErrors().isEmpty());
        assertTrue(response.getErrors().stream()
                .anyMatch(e -> e.contains("credit check")));
        // Deal should NOT be saved when validation fails
        verify(dealRepository, never()).save(any());
    }

    // ========================================================================
    // 4. APPROVE
    // ========================================================================

    @Test
    @DisplayName("approve: manager approves -> status AP, SalesApproval record created")
    void testApprove_success() {
        SalesDeal deal = buildDeal("PA");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(userRepository.findByUserId("MGR01")).thenReturn(Optional.of(testManager));
        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(approvalRepository.save(any(SalesApproval.class))).thenAnswer(inv -> inv.getArgument(0));

        ApprovalRequest request = ApprovalRequest.builder()
                .approverId("MGR01")
                .action("AP")
                .approvalType("MG")
                .comments("Good deal")
                .build();

        ApprovalResponse response = dealService.approve("D000000001", request);

        assertEquals("D000000001", response.getDealNumber());
        assertEquals("AP", response.getNewStatus());
        assertEquals("AP", deal.getDealStatus());
        assertEquals("MGR01", deal.getSalesManagerId());

        // Verify SalesApproval record was created
        ArgumentCaptor<SalesApproval> approvalCaptor = ArgumentCaptor.forClass(SalesApproval.class);
        verify(approvalRepository).save(approvalCaptor.capture());
        SalesApproval savedApproval = approvalCaptor.getValue();
        assertEquals("D000000001", savedApproval.getDealNumber());
        assertEquals("A", savedApproval.getApprovalStatus());
        assertEquals("MGR01", savedApproval.getApproverId());
    }

    @Test
    @DisplayName("approve: salesperson (type S) tries to approve -> BusinessValidationException")
    void testApprove_insufficientAuthority() {
        SalesDeal deal = buildDeal("PA");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(userRepository.findByUserId("SALES01")).thenReturn(Optional.of(testSalesperson));

        ApprovalRequest request = ApprovalRequest.builder()
                .approverId("SALES01")
                .action("AP")
                .approvalType("MG")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> dealService.approve("D000000001", request));

        assertTrue(ex.getMessage().contains("does not have approval authority"));
        verify(dealRepository, never()).save(any());
        verify(approvalRepository, never()).save(any());
    }

    @Test
    @DisplayName("approve: negative front gross deal - regular manager fails, GM succeeds")
    void testApprove_loserDealNeedsGM() {
        // Build a deal with negative front gross (loser deal)
        SalesDeal deal = buildDeal("PA");
        deal.setFrontGross(new BigDecimal("-1500.00"));

        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));

        // First: regular manager tries -> should fail
        when(userRepository.findByUserId("MGR01")).thenReturn(Optional.of(testManager));
        when(fieldFormatter.formatCurrency(any())).thenReturn("-$1,500.00");

        ApprovalRequest mgrRequest = ApprovalRequest.builder()
                .approverId("MGR01")
                .action("AP")
                .approvalType("MG")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> dealService.approve("D000000001", mgrRequest));
        assertTrue(ex.getMessage().contains("Negative front gross"));
        assertTrue(ex.getMessage().contains("General Manager"));

        // Second: GM tries -> should succeed
        when(userRepository.findByUserId("GM01")).thenReturn(Optional.of(testGM));
        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(approvalRepository.save(any(SalesApproval.class))).thenAnswer(inv -> inv.getArgument(0));

        ApprovalRequest gmRequest = ApprovalRequest.builder()
                .approverId("GM01")
                .action("AP")
                .approvalType("GM")
                .comments("GM override for loser deal")
                .build();

        ApprovalResponse response = dealService.approve("D000000001", gmRequest);

        assertEquals("AP", response.getNewStatus());
        assertNotNull(response.getThresholdMessage());
        assertTrue(response.getThresholdMessage().contains("GM override"));
    }

    // ========================================================================
    // 5. ADD TRADE-IN
    // ========================================================================

    @Test
    @DisplayName("addTradeIn: ACV calculated by condition, net trade updated on deal")
    void testAddTradeIn_success() {
        SalesDeal deal = buildDeal("WS");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(dealerRepository.findById("DLR01")).thenReturn(Optional.of(testDealer));
        stubRecalculateDeps();
        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));

        // tradeInRepository.save returns what's passed, with an ID set
        when(tradeInRepository.save(any(TradeIn.class))).thenAnswer(inv -> {
            TradeIn t = inv.getArgument(0);
            t.setTradeId(100);
            return t;
        });
        when(fieldFormatter.formatCurrency(any())).thenReturn("$0.00");

        // Trade-in: 2020 Honda Civic, 60K miles, Good condition
        TradeInRequest request = TradeInRequest.builder()
                .tradeYear((short) 2020)
                .tradeMake("Honda")
                .tradeModel("Civic")
                .tradeColor("Silver")
                .odometer(60000)
                .conditionCode("G")
                .overAllow(new BigDecimal("500.00"))
                .payoffAmt(new BigDecimal("8000.00"))
                .payoffBank("Chase")
                .payoffAcct("ACC123")
                .appraisedBy("SALES01")
                .build();

        TradeInResponse response = dealService.addTradeIn("D000000001", request);

        assertNotNull(response);
        assertEquals(100, response.getTradeId());
        assertEquals("D000000001", response.getDealNumber());

        // ACV should be calculated: base * 0.85 (Good condition)
        // The acvAmount should be positive
        assertTrue(response.getAcvAmount().signum() > 0);

        // Allowance = ACV + overAllow(500)
        assertEquals(0, response.getAllowanceAmt().compareTo(
                response.getAcvAmount().add(new BigDecimal("500.00"))));

        // Net trade = allowance - payoff(8000)
        assertEquals(0, response.getNetTrade().compareTo(
                response.getAllowanceAmt().subtract(new BigDecimal("8000.00"))));

        // Verify deal was updated with trade values
        assertEquals(0, deal.getTradeAllow().compareTo(response.getAllowanceAmt()));
        assertEquals(0, deal.getTradePayoff().compareTo(new BigDecimal("8000.00")));
        assertEquals(0, deal.getNetTrade().compareTo(response.getNetTrade()));

        verify(tradeInRepository).save(any(TradeIn.class));
        verify(dealRepository).save(deal);
    }

    // ========================================================================
    // 6. COMPLETE DEAL
    // ========================================================================

    @Test
    @DisplayName("completeDeal: checklist passes, status -> DL, stockPositionService.processSold called")
    void testCompleteDeal_success() {
        SalesDeal deal = buildDeal("AP");
        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));
        when(tradeInRepository.findBySalesDeal_DealNumber("D000000001")).thenReturn(Collections.emptyList());

        // Credit check required for retail deal
        CreditCheck creditCheck = CreditCheck.builder()
                .creditId(1)
                .customer(testCustomer)
                .status("AP")
                .expiryDate(LocalDate.now().plusDays(30))
                .build();
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1001), eq("AP"), any(LocalDate.class)))
                .thenReturn(Optional.of(creditCheck));

        when(stockPositionService.processSold(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(new StockUpdateResult("1HGCM82633A004352", "AV", "SD", "DLR01", true, "Sold"));
        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));

        // Stubs for toResponse
        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(userRepository.findByUserId("SALES01")).thenReturn(Optional.of(testSalesperson));
        when(fieldFormatter.formatCurrency(any())).thenReturn("$0.00");

        CompletionRequest request = CompletionRequest.builder()
                .insuranceVerified(true)
                .tradeTitleReceived(true)
                .deliveryDate(LocalDate.now())
                .build();

        DealResponse response = dealService.completeDeal("D000000001", request);

        assertEquals("DL", response.getDealStatus());
        assertNotNull(deal.getDeliveryDate());

        // Verify stockPositionService.processSold was called
        verify(stockPositionService).processSold(
                eq("1HGCM82633A004352"), eq("DLR01"), eq("SALES01"), contains("D000000001"));
    }

    // ========================================================================
    // 7. CANCEL DEAL
    // ========================================================================

    @Test
    @DisplayName("cancelDeal: cancel delivered deal -> UW status, vehicle -> AV, incentives reversed")
    void testCancelDeal_reversal() {
        SalesDeal deal = buildDeal("DL");
        deal.setRebatesApplied(new BigDecimal("1500.00"));

        when(dealRepository.findById("D000000001")).thenReturn(Optional.of(deal));

        // One incentive was applied
        IncentiveApplied appliedIncentive = IncentiveApplied.builder()
                .dealNumber("D000000001")
                .incentiveId("INC001")
                .amountApplied(new BigDecimal("1500.00"))
                .appliedTs(LocalDateTime.now())
                .build();
        when(incentiveAppliedRepository.findByDealNumber("D000000001"))
                .thenReturn(List.of(appliedIncentive));

        IncentiveProgram program = IncentiveProgram.builder()
                .incentiveId("INC001")
                .unitsUsed(5)
                .build();
        when(incentiveProgramRepository.findById("INC001")).thenReturn(Optional.of(program));
        when(incentiveProgramRepository.save(any(IncentiveProgram.class))).thenAnswer(inv -> inv.getArgument(0));

        when(stockPositionService.processReceive(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(new StockUpdateResult("1HGCM82633A004352", "SD", "AV", "DLR01", true, "Received"));

        when(dealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));

        // Stubs for toResponse
        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(userRepository.findByUserId("SALES01")).thenReturn(Optional.of(testSalesperson));
        when(fieldFormatter.formatCurrency(any())).thenReturn("$0.00");

        CancellationRequest request = CancellationRequest.builder()
                .reason("Customer changed mind")
                .build();

        DealResponse response = dealService.cancelDeal("D000000001", request);

        // Delivered deal -> UW (Unwound), not CA
        assertEquals("UW", response.getDealStatus());

        // Verify vehicle was returned to available
        verify(stockPositionService).processReceive(
                eq("1HGCM82633A004352"), eq("DLR01"), eq("SALES01"), contains("unwound"));

        // Verify incentive was reversed: unitsUsed decremented from 5 to 4
        assertEquals(4, program.getUnitsUsed());
        verify(incentiveAppliedRepository).delete(appliedIncentive);
        verify(incentiveProgramRepository).save(program);

        // Verify rebates zeroed out
        assertEquals(0, deal.getRebatesApplied().compareTo(BigDecimal.ZERO));
    }
}
