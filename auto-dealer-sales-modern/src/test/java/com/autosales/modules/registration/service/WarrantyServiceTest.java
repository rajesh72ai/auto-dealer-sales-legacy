package com.autosales.modules.registration.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.modules.registration.dto.WarrantyResponse;
import com.autosales.modules.registration.entity.Warranty;
import com.autosales.modules.registration.repository.WarrantyRepository;
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
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for WarrantyService.
 * Validates business logic ported from WRCWAR00 (warranty registration) and WRCINQ00 (warranty inquiry).
 */
@ExtendWith(MockitoExtension.class)
class WarrantyServiceTest {

    @Mock private WarrantyRepository warrantyRepository;
    @Mock private FieldFormatter fieldFormatter;

    @InjectMocks
    private WarrantyService service;

    private Warranty buildWarranty(String type, int years, int mileageLimit, BigDecimal deductible) {
        LocalDate startDate = LocalDate.of(2025, 6, 15);
        return Warranty.builder()
                .warrantyId(1)
                .vin("1HGCM82633A004352")
                .dealNumber("D-0000000001")
                .warrantyType(type)
                .startDate(startDate)
                .expiryDate(startDate.plusYears(years))
                .mileageLimit(mileageLimit)
                .deductible(deductible)
                .activeFlag("Y")
                .registeredTs(LocalDateTime.of(2025, 6, 15, 10, 0))
                .build();
    }

    // ─── WRCWAR00: Warranty Registration ────────────────────────────────

    @Test
    @DisplayName("WRCWAR00: Register warranties creates exactly 4 standard coverages")
    void testRegisterWarranties_creates4StandardTypes() {
        when(warrantyRepository.existsByVinAndDealNumber(anyString(), anyString())).thenReturn(false);
        when(warrantyRepository.saveAll(anyList())).thenAnswer(inv -> {
            List<Warranty> list = inv.getArgument(0);
            for (int i = 0; i < list.size(); i++) {
                list.get(i).setWarrantyId(i + 1);
            }
            return list;
        });
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$0.00");

        LocalDate saleDate = LocalDate.of(2025, 6, 15);
        List<WarrantyResponse> results = service.registerWarranties(
                "1HGCM82633A004352", "D-0000000001", saleDate);

        assertEquals(4, results.size());

        // Verify the 4 types per WRCWAR00 hard-coded parameters
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Warranty>> captor = ArgumentCaptor.forClass(List.class);
        verify(warrantyRepository).saveAll(captor.capture());
        List<Warranty> saved = captor.getValue();

        assertEquals("BT", saved.get(0).getWarrantyType());
        assertEquals("PT", saved.get(1).getWarrantyType());
        assertEquals("CR", saved.get(2).getWarrantyType());
        assertEquals("EM", saved.get(3).getWarrantyType());
    }

    @Test
    @DisplayName("WRCWAR00: Basic warranty — 3 years, 36000 miles, $0 deductible")
    void testRegisterWarranties_basicCoverage() {
        when(warrantyRepository.existsByVinAndDealNumber(anyString(), anyString())).thenReturn(false);
        when(warrantyRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$0.00");

        LocalDate saleDate = LocalDate.of(2025, 6, 15);
        service.registerWarranties("1HGCM82633A004352", "D-0000000001", saleDate);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Warranty>> captor = ArgumentCaptor.forClass(List.class);
        verify(warrantyRepository).saveAll(captor.capture());
        Warranty basic = captor.getValue().get(0);

        assertEquals("BT", basic.getWarrantyType());
        assertEquals(saleDate, basic.getStartDate());
        assertEquals(saleDate.plusYears(3), basic.getExpiryDate());
        assertEquals(36000, basic.getMileageLimit());
        assertEquals(BigDecimal.ZERO, basic.getDeductible());
        assertEquals("Y", basic.getActiveFlag());
    }

    @Test
    @DisplayName("WRCWAR00: Powertrain warranty — 5 years, 60000 miles, $100 deductible")
    void testRegisterWarranties_powertrainCoverage() {
        when(warrantyRepository.existsByVinAndDealNumber(anyString(), anyString())).thenReturn(false);
        when(warrantyRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$100.00");

        LocalDate saleDate = LocalDate.of(2025, 6, 15);
        service.registerWarranties("1HGCM82633A004352", "D-0000000001", saleDate);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Warranty>> captor = ArgumentCaptor.forClass(List.class);
        verify(warrantyRepository).saveAll(captor.capture());
        Warranty powertrain = captor.getValue().get(1);

        assertEquals("PT", powertrain.getWarrantyType());
        assertEquals(saleDate.plusYears(5), powertrain.getExpiryDate());
        assertEquals(60000, powertrain.getMileageLimit());
        assertEquals(new BigDecimal("100.00"), powertrain.getDeductible());
    }

    @Test
    @DisplayName("WRCWAR00: Corrosion warranty — 5 years, unlimited miles (999999)")
    void testRegisterWarranties_corrosionCoverage() {
        when(warrantyRepository.existsByVinAndDealNumber(anyString(), anyString())).thenReturn(false);
        when(warrantyRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$0.00");

        LocalDate saleDate = LocalDate.of(2025, 6, 15);
        service.registerWarranties("1HGCM82633A004352", "D-0000000001", saleDate);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Warranty>> captor = ArgumentCaptor.forClass(List.class);
        verify(warrantyRepository).saveAll(captor.capture());
        Warranty corrosion = captor.getValue().get(2);

        assertEquals("CR", corrosion.getWarrantyType());
        assertEquals(999999, corrosion.getMileageLimit());
    }

    @Test
    @DisplayName("WRCWAR00: Emission warranty — 8 years, 80000 miles, $0 deductible")
    void testRegisterWarranties_emissionCoverage() {
        when(warrantyRepository.existsByVinAndDealNumber(anyString(), anyString())).thenReturn(false);
        when(warrantyRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$0.00");

        LocalDate saleDate = LocalDate.of(2025, 6, 15);
        service.registerWarranties("1HGCM82633A004352", "D-0000000001", saleDate);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Warranty>> captor = ArgumentCaptor.forClass(List.class);
        verify(warrantyRepository).saveAll(captor.capture());
        Warranty emission = captor.getValue().get(3);

        assertEquals("EM", emission.getWarrantyType());
        assertEquals(saleDate.plusYears(8), emission.getExpiryDate());
        assertEquals(80000, emission.getMileageLimit());
        assertEquals(BigDecimal.ZERO, emission.getDeductible());
    }

    @Test
    @DisplayName("WRCWAR00: Reject duplicate warranty registration for same VIN/deal")
    void testRegisterWarranties_rejectsDuplicate() {
        when(warrantyRepository.existsByVinAndDealNumber("1HGCM82633A004352", "D-0000000001")).thenReturn(true);

        assertThrows(DuplicateEntityException.class, () ->
                service.registerWarranties("1HGCM82633A004352", "D-0000000001", LocalDate.now()));
        verify(warrantyRepository, never()).saveAll(anyList());
    }

    @Test
    @DisplayName("WRCWAR00: Missing VIN throws validation error")
    void testRegisterWarranties_missingVin() {
        assertThrows(BusinessValidationException.class, () ->
                service.registerWarranties("", "D-0000000001", LocalDate.now()));
    }

    @Test
    @DisplayName("WRCWAR00: Missing sale date throws validation error")
    void testRegisterWarranties_missingSaleDate() {
        assertThrows(BusinessValidationException.class, () ->
                service.registerWarranties("1HGCM82633A004352", "D-0000000001", null));
    }

    @Test
    @DisplayName("WRCWAR00: All warranties use deal date as start date (not current date)")
    void testRegisterWarranties_startDateIsSaleDate() {
        when(warrantyRepository.existsByVinAndDealNumber(anyString(), anyString())).thenReturn(false);
        when(warrantyRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$0.00");

        LocalDate saleDate = LocalDate.of(2024, 1, 10); // Past date
        service.registerWarranties("1HGCM82633A004352", "D-0000000001", saleDate);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Warranty>> captor = ArgumentCaptor.forClass(List.class);
        verify(warrantyRepository).saveAll(captor.capture());

        for (Warranty w : captor.getValue()) {
            assertEquals(saleDate, w.getStartDate(),
                    "All warranties should start on sale date, not current date");
        }
    }

    // ─── WRCINQ00: Warranty Coverage Inquiry ────────────────────────────

    @Test
    @DisplayName("WRCINQ00: Active warranty shows status=Active with remaining days > 0")
    void testFindByVin_activeWarrantyShowsStatus() {
        Warranty warranty = buildWarranty("BT", 3, 36000, BigDecimal.ZERO);
        when(warrantyRepository.findByVin("1HGCM82633A004352")).thenReturn(List.of(warranty));

        List<WarrantyResponse> results = service.findByVin("1HGCM82633A004352");

        assertEquals(1, results.size());
        WarrantyResponse resp = results.get(0);
        assertEquals("Active", resp.getStatus());
        assertTrue(resp.getRemainingDays() > 0);
        assertEquals("Basic (Bumper-to-Bumper)", resp.getWarrantyTypeName());
    }

    @Test
    @DisplayName("WRCINQ00: Expired warranty shows status=Expired with remainingDays=0")
    void testFindByVin_expiredWarrantyShowsStatus() {
        Warranty warranty = Warranty.builder()
                .warrantyId(1)
                .vin("1HGCM82633A004352")
                .dealNumber("D-0000000001")
                .warrantyType("BT")
                .startDate(LocalDate.of(2020, 1, 1))
                .expiryDate(LocalDate.of(2023, 1, 1))
                .mileageLimit(36000)
                .deductible(BigDecimal.ZERO)
                .activeFlag("Y")
                .registeredTs(LocalDateTime.of(2020, 1, 1, 10, 0))
                .build();
        when(warrantyRepository.findByVin("1HGCM82633A004352")).thenReturn(List.of(warranty));

        List<WarrantyResponse> results = service.findByVin("1HGCM82633A004352");

        assertEquals("Expired", results.get(0).getStatus());
        assertEquals(0L, results.get(0).getRemainingDays());
    }

    @Test
    @DisplayName("WRCINQ00: Deductible $0 displays as 'None', non-zero shows currency")
    void testFindByVin_deductibleFormatting() {
        Warranty basic = buildWarranty("BT", 3, 36000, BigDecimal.ZERO);
        Warranty powertrain = buildWarranty("PT", 5, 60000, new BigDecimal("100.00"));
        powertrain.setWarrantyId(2);
        when(warrantyRepository.findByVin("1HGCM82633A004352")).thenReturn(List.of(basic, powertrain));
        when(fieldFormatter.formatCurrency(new BigDecimal("100.00"))).thenReturn("$100.00");

        List<WarrantyResponse> results = service.findByVin("1HGCM82633A004352");

        assertEquals("None", results.get(0).getFormattedDeductible());
        assertEquals("$100.00", results.get(1).getFormattedDeductible());
    }

    @Test
    @DisplayName("WRCINQ00: Warranty type codes map correctly — BT, PT, CR, EM")
    void testFindByVin_warrantyTypeNames() {
        Warranty bt = buildWarranty("BT", 3, 36000, BigDecimal.ZERO);
        Warranty pt = buildWarranty("PT", 5, 60000, new BigDecimal("100.00"));
        pt.setWarrantyId(2);
        Warranty cr = buildWarranty("CR", 5, 999999, BigDecimal.ZERO);
        cr.setWarrantyId(3);
        Warranty em = buildWarranty("EM", 8, 80000, BigDecimal.ZERO);
        em.setWarrantyId(4);
        when(warrantyRepository.findByVin(anyString())).thenReturn(List.of(bt, pt, cr, em));
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$0.00");

        List<WarrantyResponse> results = service.findByVin("1HGCM82633A004352");

        assertEquals("Basic (Bumper-to-Bumper)", results.get(0).getWarrantyTypeName());
        assertEquals("Powertrain", results.get(1).getWarrantyTypeName());
        assertEquals("Corrosion", results.get(2).getWarrantyTypeName());
        assertEquals("Emission", results.get(3).getWarrantyTypeName());
    }
}
