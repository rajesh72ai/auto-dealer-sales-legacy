package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.GlPostingResponse;
import com.autosales.modules.batch.dto.GlPostingResponse.GlEntry;
import com.autosales.modules.batch.repository.BatchControlRepository;
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
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for GlPostingService — port of BATGLINT.cbl.
 * Validates balanced double-entry journal entries:
 *   Revenue: Debit A/R (1200), Credit Vehicle Revenue (4010) = TOTAL - TAX - F&I
 *   COGS:    Debit COGS (5010), Credit Inventory (1400) = invoice price
 *   F&I:     Debit A/R (1200), Credit F&I Income (4020) = back gross
 *   Tax:     Debit A/R (1200), Credit Tax Collected (2300) = state+county+city
 */
@ExtendWith(MockitoExtension.class)
class GlPostingServiceTest {

    @Mock private BatchControlRepository batchControlRepository;
    @Mock private SalesDealRepository salesDealRepository;
    @Mock private VehicleRepository vehicleRepository;

    @InjectMocks
    private GlPostingService glPostingService;

    private SalesDeal testDeal;

    @BeforeEach
    void setUp() {
        testDeal = SalesDeal.builder()
                .dealNumber("DL-GL01")
                .dealerCode("D0001")
                .vin("1HGCM82633A004352")
                .dealStatus("DL")
                .totalPrice(new BigDecimal("42000.00"))
                .stateTax(new BigDecimal("2100.00"))
                .countyTax(new BigDecimal("420.00"))
                .cityTax(new BigDecimal("210.00"))
                .backGross(new BigDecimal("1500.00"))
                .frontGross(new BigDecimal("2500.00"))
                .totalGross(new BigDecimal("4000.00"))
                .dealDate(LocalDate.now())
                .build();
    }

    // ── GL Account Codes ──────────────────────────────────────────────

    @Test
    @DisplayName("BATGLINT: GL account codes match legacy WS-GL-ACCOUNTS working storage")
    void glAccountCodes_matchLegacy() {
        assertEquals("4010-00-00", GlPostingService.ACCT_VEHICLE_REVENUE);
        assertEquals("5010-00-00", GlPostingService.ACCT_COGS);
        assertEquals("4020-00-00", GlPostingService.ACCT_FI_INCOME);
        assertEquals("2300-00-00", GlPostingService.ACCT_TAX_COLLECTED);
        assertEquals("1200-00-00", GlPostingService.ACCT_ACCOUNTS_RECV);
        assertEquals("1400-00-00", GlPostingService.ACCT_INVENTORY);
    }

    // ── Revenue Entry ─────────────────────────────────────────────────

    @Test
    @DisplayName("BATGLINT: Revenue = TOTAL_PRICE - TAX - F&I, balanced debit/credit")
    void generateGlEntries_revenueEntry_balanced() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(
                Vehicle.builder().vin("1HGCM82633A004352").build()));

        GlPostingResponse result = glPostingService.generateGlEntries(List.of(testDeal), false);

        // Revenue = 42000.00 - (2100+420+210) - 1500 = 42000 - 2730 - 1500 = 37770
        BigDecimal expectedRevenue = new BigDecimal("37770.00");
        assertEquals(expectedRevenue, result.getTotalRevenue(),
                "BATGLINT: Vehicle revenue = TOTAL_PRICE - total_tax - F&I (back_gross)");

        // Find revenue entries
        List<GlEntry> revenueDebits = result.getEntries().stream()
                .filter(e -> "4010-00-00".equals(e.getAccountCode()) ||
                        ("1200-00-00".equals(e.getAccountCode()) && "DR".equals(e.getEntryType())
                         && e.getAmount().equals(expectedRevenue)))
                .toList();
        assertFalse(revenueDebits.isEmpty(), "BATGLINT: A/R debit entry must exist for revenue");
    }

    // ── F&I Entry ─────────────────────────────────────────────────────

    @Test
    @DisplayName("BATGLINT: F&I entry only generated when back_gross > 0")
    void generateGlEntries_fiEntry_generatedWhenPositive() {
        when(vehicleRepository.findById(any())).thenReturn(Optional.of(
                Vehicle.builder().vin("1HGCM82633A004352").build()));

        GlPostingResponse result = glPostingService.generateGlEntries(List.of(testDeal), false);

        assertEquals(new BigDecimal("1500.00"), result.getTotalFiIncome());

        List<GlEntry> fiCredits = result.getEntries().stream()
                .filter(e -> "4020-00-00".equals(e.getAccountCode()) && "CR".equals(e.getEntryType()))
                .toList();
        assertEquals(1, fiCredits.size());
        assertEquals(new BigDecimal("1500.00"), fiCredits.get(0).getAmount(),
                "BATGLINT: F&I Income credit = back_gross amount");
    }

    @Test
    @DisplayName("BATGLINT: No F&I entry when back_gross is zero")
    void generateGlEntries_noFiEntry_whenZero() {
        SalesDeal noFiDeal = SalesDeal.builder()
                .dealNumber("DL-NOFI")
                .dealStatus("DL")
                .vin("1HGCM82633A004352")
                .totalPrice(new BigDecimal("35000.00"))
                .stateTax(BigDecimal.ZERO)
                .countyTax(BigDecimal.ZERO)
                .cityTax(BigDecimal.ZERO)
                .backGross(BigDecimal.ZERO)
                .build();
        when(vehicleRepository.findById(any())).thenReturn(Optional.of(
                Vehicle.builder().vin("1HGCM82633A004352").build()));

        GlPostingResponse result = glPostingService.generateGlEntries(List.of(noFiDeal), false);

        List<GlEntry> fiEntries = result.getEntries().stream()
                .filter(e -> "4020-00-00".equals(e.getAccountCode()))
                .toList();
        assertEquals(0, fiEntries.size(),
                "BATGLINT: F&I entry only when amount > 0 (per COBOL IF clause)");
    }

    // ── Tax Entry ─────────────────────────────────────────────────────

    @Test
    @DisplayName("BATGLINT: Tax = state + county + city, credit to 2300")
    void generateGlEntries_taxEntry_sumsAllTaxes() {
        when(vehicleRepository.findById(any())).thenReturn(Optional.of(
                Vehicle.builder().vin("1HGCM82633A004352").build()));

        GlPostingResponse result = glPostingService.generateGlEntries(List.of(testDeal), false);

        // Total tax = 2100 + 420 + 210 = 2730
        assertEquals(new BigDecimal("2730.00"), result.getTotalTax(),
                "BATGLINT: Total tax = STATE_TAX + COUNTY_TAX + CITY_TAX");

        List<GlEntry> taxCredits = result.getEntries().stream()
                .filter(e -> "2300-00-00".equals(e.getAccountCode()) && "CR".equals(e.getEntryType()))
                .toList();
        assertEquals(1, taxCredits.size());
    }

    // ── Balanced Entries ──────────────────────────────────────────────

    @Test
    @DisplayName("BATGLINT: Total debits equal total credits (balanced journal)")
    void generateGlEntries_balancedDebitsAndCredits() {
        when(vehicleRepository.findById(any())).thenReturn(Optional.of(
                Vehicle.builder().vin("1HGCM82633A004352").build()));

        GlPostingResponse result = glPostingService.generateGlEntries(List.of(testDeal), false);

        BigDecimal totalDebits = result.getEntries().stream()
                .filter(e -> "DR".equals(e.getEntryType()))
                .map(GlEntry::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalCredits = result.getEntries().stream()
                .filter(e -> "CR".equals(e.getEntryType()))
                .map(GlEntry::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        assertEquals(totalDebits, totalCredits,
                "BATGLINT: Double-entry accounting — total DR must equal total CR");
    }

    // ── Full Run ──────────────────────────────────────────────────────

    @Test
    @DisplayName("BATGLINT: Full GL posting run returns correct deal count")
    void runGlPosting_processesDeals() {
        when(salesDealRepository.findAll()).thenReturn(List.of(testDeal));
        when(vehicleRepository.findById(any())).thenReturn(Optional.of(
                Vehicle.builder().vin("1HGCM82633A004352").build()));
        when(batchControlRepository.findById("BATGLINT")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        BatchRunResult result = glPostingService.runGlPosting();

        assertEquals("BATGLINT", result.getProgramId());
        assertEquals("OK", result.getStatus());
        assertEquals(1, result.getRecordsProcessed());
    }
}
