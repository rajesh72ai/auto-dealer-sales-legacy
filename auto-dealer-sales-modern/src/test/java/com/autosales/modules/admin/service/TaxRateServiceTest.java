package com.autosales.modules.admin.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.common.util.TaxCalculationResult;
import com.autosales.modules.admin.dto.TaxCalculationRequest;
import com.autosales.modules.admin.dto.TaxRateRequest;
import com.autosales.modules.admin.dto.TaxRateResponse;
import com.autosales.modules.admin.entity.TaxRate;
import com.autosales.modules.admin.repository.TaxRateRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TaxRateServiceTest {

    @Mock
    private TaxRateRepository repository;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private TaxRateService taxRateService;

    private TaxRateRequest buildRequest(BigDecimal stateRate, BigDecimal countyRate, BigDecimal cityRate) {
        return TaxRateRequest.builder()
                .stateCode("CO")
                .countyCode("DNV01")
                .cityCode("DEN01")
                .stateRate(stateRate)
                .countyRate(countyRate)
                .cityRate(cityRate)
                .docFeeMax(new BigDecimal("599.00"))
                .titleFee(new BigDecimal("7.20"))
                .regFee(new BigDecimal("50.00"))
                .effectiveDate(LocalDate.of(2025, 1, 1))
                .expiryDate(LocalDate.of(2025, 12, 31))
                .build();
    }

    private TaxRate buildTaxRate() {
        return TaxRate.builder()
                .stateCode("CO")
                .countyCode("DNV01")
                .cityCode("DEN01")
                .effectiveDate(LocalDate.of(2025, 1, 1))
                .stateRate(new BigDecimal("0.0290"))
                .countyRate(new BigDecimal("0.0100"))
                .cityRate(new BigDecimal("0.0435"))
                .docFeeMax(new BigDecimal("599.00"))
                .titleFee(new BigDecimal("7.20"))
                .regFee(new BigDecimal("50.00"))
                .expiryDate(LocalDate.of(2025, 12, 31))
                .build();
    }

    @Test
    void testCreate_success() {
        TaxRateRequest request = buildRequest(
                new BigDecimal("0.0290"),
                new BigDecimal("0.0100"),
                new BigDecimal("0.0435"));
        when(repository.save(any(TaxRate.class))).thenAnswer(inv -> inv.getArgument(0));

        TaxRateResponse response = taxRateService.create(request);

        assertNotNull(response);
        assertEquals("CO", response.getStateCode());
        assertEquals("DNV01", response.getCountyCode());
        assertEquals("DEN01", response.getCityCode());
        verify(repository).save(any(TaxRate.class));
    }

    @Test
    void testCreate_combinedRateExceeds15() {
        // Combined rate = 0.08 + 0.05 + 0.03 = 0.16, exceeds 0.15 max
        TaxRateRequest request = buildRequest(
                new BigDecimal("0.0800"),
                new BigDecimal("0.0500"),
                new BigDecimal("0.0300"));

        assertThrows(BusinessValidationException.class,
                () -> taxRateService.create(request));
        verify(repository, never()).save(any());
    }

    @Test
    void testCalculateTax_success() {
        TaxRate rate = buildTaxRate();
        when(repository.findCurrentEffective(eq("CO"), eq("DNV01"), eq("DEN01"), any(LocalDate.class)))
                .thenReturn(Optional.of(rate));

        TaxCalculationRequest request = TaxCalculationRequest.builder()
                .taxableAmount(new BigDecimal("30000.00"))
                .tradeAllowance(BigDecimal.ZERO)
                .stateCode("CO")
                .countyCode("DNV01")
                .cityCode("DEN01")
                .build();

        TaxCalculationResult result = taxRateService.calculateTax(request);

        assertNotNull(result);
        // stateTax = 30000 * 0.0290 = 870.00
        assertTrue(result.stateTax().compareTo(new BigDecimal("870.00")) == 0);
        // countyTax = 30000 * 0.0100 = 300.00
        assertTrue(result.countyTax().compareTo(new BigDecimal("300.00")) == 0);
        // cityTax = 30000 * 0.0435 = 1305.00
        assertTrue(result.cityTax().compareTo(new BigDecimal("1305.00")) == 0);
        // totalTax = 870 + 300 + 1305 = 2475.00
        assertTrue(result.totalTax().compareTo(new BigDecimal("2475.00")) == 0);
        // totalFees = 599 + 7.20 + 50 = 656.20
        assertTrue(result.totalFees().compareTo(new BigDecimal("656.20")) == 0);
        // grandTotal = 2475 + 656.20 = 3131.20
        assertTrue(result.grandTotal().compareTo(new BigDecimal("3131.20")) == 0);
    }

    @Test
    void testFindCurrentEffective_notFound() {
        when(repository.findCurrentEffective(eq("XX"), eq("NONE1"), eq("NONE2"), any(LocalDate.class)))
                .thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> taxRateService.findCurrentEffective("XX", "NONE1", "NONE2"));
    }
}
