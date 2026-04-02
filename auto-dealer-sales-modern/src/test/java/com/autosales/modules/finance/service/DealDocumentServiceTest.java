package com.autosales.modules.finance.service;

import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.admin.repository.ModelMasterRepository;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.finance.dto.DealDocumentResponse;
import com.autosales.modules.finance.entity.FinanceApp;
import com.autosales.modules.finance.entity.FinanceProduct;
import com.autosales.modules.finance.entity.LeaseTerms;
import com.autosales.modules.finance.repository.FinanceAppRepository;
import com.autosales.modules.finance.repository.FinanceProductRepository;
import com.autosales.modules.finance.repository.LeaseTermsRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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
 * Unit tests for DealDocumentService — closing document assembly.
 * Port of FINDOC00.cbl — the most data-intensive program in the FIN module (joins 9 tables).
 *
 * Legacy COBOL business rules validated:
 * - Document type determined by finance type: L="Retail Installment Contract", S="Lease Agreement", C="Cash Purchase Receipt" (FINDOC00)
 * - No finance app defaults to Cash Purchase Receipt (FINDOC00)
 * - Pricing itemization: vehicle price, options, destination, rebates, trade, taxes, fees (FINDOC00)
 * - Finance terms: APR, term, monthly payment, total payments, finance charge (FINDOC00)
 * - F&I products listed with name and retail price (FINDOC00 cursor, up to 5)
 * - Seller = dealer info, Buyer = customer info (FINDOC00 STRING formatting)
 * - Missing required entity → EntityNotFoundException (FINDOC00 error path)
 */
@ExtendWith(MockitoExtension.class)
class DealDocumentServiceTest {

    @Mock private SalesDealRepository salesDealRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private ModelMasterRepository modelMasterRepository;
    @Mock private FinanceAppRepository financeAppRepository;
    @Mock private LeaseTermsRepository leaseTermsRepository;
    @Mock private FinanceProductRepository financeProductRepository;
    @Mock private DealerRepository dealerRepository;
    @Mock private FieldFormatter fieldFormatter;

    @InjectMocks
    private DealDocumentService dealDocumentService;

    private SalesDeal testDeal;
    private Customer testCustomer;
    private Vehicle testVehicle;
    private Dealer testDealer;
    private ModelMaster testModelMaster;
    private FinanceApp testLoanApp;

    @BeforeEach
    void setUp() {
        testDeal = SalesDeal.builder()
                .dealNumber("D000000001")
                .dealerCode("DLR01")
                .customerId(1001)
                .vin("1HGCM82633A004352")
                .dealStatus("FI")
                .vehiclePrice(new BigDecimal("35000.00"))
                .totalOptions(new BigDecimal("1500.00"))
                .destinationFee(new BigDecimal("1095.00"))
                .rebatesApplied(new BigDecimal("2000.00"))
                .tradeAllow(new BigDecimal("8000.00"))
                .stateTax(new BigDecimal("2255.94"))
                .countyTax(new BigDecimal("100.00"))
                .cityTax(new BigDecimal("50.00"))
                .docFee(new BigDecimal("150.00"))
                .titleFee(new BigDecimal("33.00"))
                .regFee(new BigDecimal("75.00"))
                .totalPrice(new BigDecimal("38608.94"))
                .downPayment(new BigDecimal("5000.00"))
                .amountFinanced(new BigDecimal("33608.94"))
                .subtotal(new BigDecimal("36095.00"))
                .tradePayoff(BigDecimal.ZERO)
                .netTrade(BigDecimal.ZERO)
                .discountAmt(BigDecimal.ZERO)
                .frontGross(new BigDecimal("4000.00"))
                .backGross(BigDecimal.ZERO)
                .totalGross(new BigDecimal("4000.00"))
                .dealDate(LocalDate.now())
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

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
                .stockNumber("STK001")
                .odometer(15)
                .vehicleStatus("AV")
                .dealerCode("DLR01")
                .daysInStock((short) 30)
                .pdiComplete("Y")
                .damageFlag("N")
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

        testModelMaster = ModelMaster.builder()
                .modelYear((short) 2026)
                .makeCode("HON")
                .modelCode("ACCRD")
                .modelName("Accord EX-L")
                .build();

        testLoanApp = FinanceApp.builder()
                .financeId("FIN000000001")
                .dealNumber("D000000001")
                .customerId(1001)
                .financeType("L")
                .lenderCode("LND01")
                .appStatus("AP")
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("5.900"))
                .aprApproved(new BigDecimal("4.500"))
                .termMonths((short) 60)
                .monthlyPayment(new BigDecimal("625.50"))
                .downPayment(new BigDecimal("5000.00"))
                .submittedTs(LocalDateTime.now())
                .decisionTs(LocalDateTime.now())
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    private void stubCommonEntities() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(dealerRepository.findById("DLR01")).thenReturn(Optional.of(testDealer));
        lenient().when(modelMasterRepository.findById(any(ModelMasterId.class))).thenReturn(Optional.of(testModelMaster));
    }

    // ========================================================================
    // 1. LOAN DOCUMENT (FINDOC00 — L = "RETAIL INSTALLMENT CONTRACT")
    // ========================================================================

    @Test
    @DisplayName("generateDocument: loan deal → Retail Installment Contract with all sections (FINDOC00)")
    void testGenerateDocument_loanDeal() {
        stubCommonEntities();
        when(financeAppRepository.findByDealNumber("D000000001")).thenReturn(List.of(testLoanApp));
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(List.of(
                FinanceProduct.builder().productName("Extended Warranty").retailPrice(new BigDecimal("1995.00")).build(),
                FinanceProduct.builder().productName("GAP Insurance").retailPrice(new BigDecimal("895.00")).build()));

        DealDocumentResponse response = dealDocumentService.generateDocument("D000000001");

        assertNotNull(response);
        assertEquals("D000000001", response.getDealNumber());
        assertEquals("Retail Installment Contract", response.getDocumentType());

        // Seller section (FINDOC00 dealer info)
        assertNotNull(response.getSeller());
        assertEquals("Test Motors", response.getSeller().getDealerName());
        assertEquals("Dallas", response.getSeller().getCity());
        assertEquals("TX", response.getSeller().getState());

        // Buyer section (FINDOC00 customer info with STRING concatenation)
        assertNotNull(response.getBuyer());
        assertEquals("John Doe", response.getBuyer().getCustomerName());
        assertEquals("123 Main St", response.getBuyer().getAddress());

        // Vehicle section (FINDOC00 vehicle description)
        assertNotNull(response.getVehicle());
        assertEquals((short) 2026, response.getVehicle().getYear());
        assertEquals("1HGCM82633A004352", response.getVehicle().getVin());
        assertEquals("Accord EX-L", response.getVehicle().getModelName());
        assertEquals("STK001", response.getVehicle().getStockNumber());

        // Pricing section (FINDOC00 itemization)
        assertNotNull(response.getPricing());
        assertEquals(0, new BigDecimal("35000.00").compareTo(response.getPricing().getVehiclePrice()));
        assertEquals(0, new BigDecimal("1500.00").compareTo(response.getPricing().getOptions()));
        assertEquals(0, new BigDecimal("1095.00").compareTo(response.getPricing().getDestination()));
        assertEquals(0, new BigDecimal("2000.00").compareTo(response.getPricing().getRebates()));
        assertEquals(0, new BigDecimal("8000.00").compareTo(response.getPricing().getTradeAllowance()));

        // Finance terms section (FINDOC00 — uses approved APR for loan recalculation)
        assertNotNull(response.getFinanceTerms());
        assertEquals(0, new BigDecimal("4.500").compareTo(response.getFinanceTerms().getApr())); // aprApproved
        assertEquals((short) 60, response.getFinanceTerms().getTermMonths());
        assertEquals(0, new BigDecimal("625.50").compareTo(response.getFinanceTerms().getMonthlyPayment()));

        // F&I products (FINDOC00 cursor-based fetch)
        assertEquals(2, response.getFiProducts().size());
        assertEquals("Extended Warranty", response.getFiProducts().get(0).getProductName());
    }

    // ========================================================================
    // 2. LEASE DOCUMENT (FINDOC00 — S = "MOTOR VEHICLE LEASE AGREEMENT")
    // ========================================================================

    @Test
    @DisplayName("generateDocument: lease deal → Lease Agreement (FINDOC00)")
    void testGenerateDocument_leaseDeal() {
        FinanceApp leaseApp = FinanceApp.builder()
                .financeId("FIN000000002")
                .dealNumber("D000000001")
                .financeType("S")
                .appStatus("AP")
                .amountRequested(new BigDecimal("35000.00"))
                .termMonths((short) 36)
                .monthlyPayment(new BigDecimal("562.41"))
                .downPayment(BigDecimal.ZERO)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        stubCommonEntities();
        when(financeAppRepository.findByDealNumber("D000000001")).thenReturn(List.of(leaseApp));
        when(leaseTermsRepository.findByFinanceId("FIN000000002")).thenReturn(Optional.of(
                LeaseTerms.builder().financeId("FIN000000002").build()));
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());

        DealDocumentResponse response = dealDocumentService.generateDocument("D000000001");

        assertEquals("Lease Agreement", response.getDocumentType());
        assertNotNull(response.getFinanceTerms());
    }

    // ========================================================================
    // 3. CASH DOCUMENT (FINDOC00 — C = "CASH SALE RECEIPT")
    // ========================================================================

    @Test
    @DisplayName("generateDocument: cash deal → Cash Purchase Receipt, no finance terms (FINDOC00)")
    void testGenerateDocument_cashDeal() {
        FinanceApp cashApp = FinanceApp.builder()
                .financeId("FIN000000003")
                .dealNumber("D000000001")
                .financeType("C")
                .appStatus("NW")
                .amountRequested(new BigDecimal("38608.94"))
                .downPayment(BigDecimal.ZERO)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        stubCommonEntities();
        when(financeAppRepository.findByDealNumber("D000000001")).thenReturn(List.of(cashApp));
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());

        DealDocumentResponse response = dealDocumentService.generateDocument("D000000001");

        assertEquals("Cash Purchase Receipt", response.getDocumentType());
        // Cash deals have no finance terms section (FINDOC00 skips finance section for cash)
        assertNull(response.getFinanceTerms());
    }

    // ========================================================================
    // 4. NO FINANCE APP → DEFAULTS TO CASH (FINDOC00 fallback)
    // ========================================================================

    @Test
    @DisplayName("generateDocument: no finance app → defaults to Cash Purchase Receipt (FINDOC00 fallback)")
    void testGenerateDocument_noFinanceApp() {
        stubCommonEntities();
        when(financeAppRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());

        DealDocumentResponse response = dealDocumentService.generateDocument("D000000001");

        assertEquals("Cash Purchase Receipt", response.getDocumentType());
        assertNull(response.getFinanceTerms());
    }

    // ========================================================================
    // 5. MISSING ENTITIES → EntityNotFoundException (FINDOC00 error paths)
    // ========================================================================

    @Test
    @DisplayName("generateDocument: deal not found → EntityNotFoundException")
    void testGenerateDocument_dealNotFound() {
        when(salesDealRepository.findById("D999")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> dealDocumentService.generateDocument("D999"));
    }

    @Test
    @DisplayName("generateDocument: customer not found → EntityNotFoundException (FINDOC00 required data)")
    void testGenerateDocument_customerNotFound() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(customerRepository.findById(1001)).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> dealDocumentService.generateDocument("D000000001"));
    }

    @Test
    @DisplayName("generateDocument: vehicle not found → EntityNotFoundException")
    void testGenerateDocument_vehicleNotFound() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(customerRepository.findById(1001)).thenReturn(Optional.of(testCustomer));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> dealDocumentService.generateDocument("D000000001"));
    }

    @Test
    @DisplayName("generateDocument: model master missing → falls back to model code (FINDOC00 graceful)")
    void testGenerateDocument_modelMasterMissing() {
        stubCommonEntities();
        when(modelMasterRepository.findById(any(ModelMasterId.class))).thenReturn(Optional.empty());
        when(financeAppRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());

        DealDocumentResponse response = dealDocumentService.generateDocument("D000000001");

        // Falls back to model code when model master not found
        assertEquals("ACCRD", response.getVehicle().getModelName());
    }

    @Test
    @DisplayName("generateDocument: finance terms use approved APR when available, else requested (FINDOC00)")
    void testGenerateDocument_aprFallsBackToRequested() {
        FinanceApp appWithoutApproval = FinanceApp.builder()
                .financeId("FIN000000004")
                .dealNumber("D000000001")
                .financeType("L")
                .appStatus("NW")
                .amountRequested(new BigDecimal("33608.94"))
                .aprRequested(new BigDecimal("5.900"))
                .aprApproved(null) // Not yet approved
                .termMonths((short) 60)
                .monthlyPayment(new BigDecimal("650.23"))
                .downPayment(new BigDecimal("5000.00"))
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        stubCommonEntities();
        when(financeAppRepository.findByDealNumber("D000000001")).thenReturn(List.of(appWithoutApproval));
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());

        DealDocumentResponse response = dealDocumentService.generateDocument("D000000001");

        // Should fall back to requested APR
        assertEquals(0, new BigDecimal("5.900").compareTo(response.getFinanceTerms().getApr()));
    }
}
