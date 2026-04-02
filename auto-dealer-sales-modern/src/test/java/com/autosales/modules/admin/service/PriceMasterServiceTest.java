package com.autosales.modules.admin.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.PriceMasterRequest;
import com.autosales.modules.admin.dto.PriceMasterResponse;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.repository.PriceMasterRepository;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PriceMasterServiceTest {

    @Mock
    private PriceMasterRepository repository;

    @Mock
    private FieldFormatter fieldFormatter;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private PriceMasterService priceMasterService;

    private PriceMaster buildPriceMaster() {
        return PriceMaster.builder()
                .modelYear((short) 2025)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .effectiveDate(LocalDate.of(2025, 1, 1))
                .msrp(new BigDecimal("35000.00"))
                .invoicePrice(new BigDecimal("30000.00"))
                .holdbackAmt(new BigDecimal("900.00"))
                .holdbackPct(new BigDecimal("3.000"))
                .destinationFee(new BigDecimal("1095.00"))
                .advertisingFee(new BigDecimal("500.00"))
                .expiryDate(LocalDate.of(2025, 12, 31))
                .createdTs(LocalDateTime.of(2025, 1, 1, 8, 0))
                .build();
    }

    private PriceMasterRequest buildRequest(BigDecimal msrp, BigDecimal invoice) {
        return PriceMasterRequest.builder()
                .modelYear((short) 2025)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .effectiveDate(LocalDate.of(2025, 1, 1))
                .msrp(msrp)
                .invoicePrice(invoice)
                .holdbackAmt(new BigDecimal("900.00"))
                .holdbackPct(new BigDecimal("3.000"))
                .destinationFee(new BigDecimal("1095.00"))
                .advertisingFee(new BigDecimal("500.00"))
                .expiryDate(LocalDate.of(2025, 12, 31))
                .build();
    }

    @Test
    void testFindCurrentEffective_success() {
        PriceMaster entity = buildPriceMaster();
        when(repository.findCurrentEffective(eq((short) 2025), eq("TOY"), eq("CAMRY"), any(LocalDate.class)))
                .thenReturn(Optional.of(entity));
        when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$35,000.00");

        PriceMasterResponse response = priceMasterService.findCurrentEffective((short) 2025, "TOY", "CAMRY");

        assertNotNull(response);
        assertEquals((short) 2025, response.getModelYear());
        assertEquals("TOY", response.getMakeCode());
        assertTrue(response.getDealerMargin().compareTo(new BigDecimal("5000.00")) == 0);
        verify(repository).findCurrentEffective(eq((short) 2025), eq("TOY"), eq("CAMRY"), any(LocalDate.class));
    }

    @Test
    void testCreate_success() {
        PriceMasterRequest request = buildRequest(new BigDecimal("35000.00"), new BigDecimal("30000.00"));
        when(repository.save(any(PriceMaster.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$35,000.00");

        PriceMasterResponse response = priceMasterService.create(request);

        assertNotNull(response);
        assertEquals("CAMRY", response.getModelCode());
        verify(repository).save(any(PriceMaster.class));
    }

    @Test
    void testCreate_msrpLessThanInvoice() {
        // MSRP <= invoice should throw BusinessValidationException
        PriceMasterRequest request = buildRequest(new BigDecimal("25000.00"), new BigDecimal("30000.00"));

        assertThrows(BusinessValidationException.class,
                () -> priceMasterService.create(request));
        verify(repository, never()).save(any());
    }

    @Test
    void testFindHistory() {
        PriceMaster p1 = buildPriceMaster();
        PriceMaster p2 = buildPriceMaster();
        p2.setEffectiveDate(LocalDate.of(2024, 7, 1));
        PriceMaster p3 = buildPriceMaster();
        p3.setEffectiveDate(LocalDate.of(2024, 1, 1));

        when(repository.findTop5ByModelYearAndMakeCodeAndModelCodeOrderByEffectiveDateDesc(
                (short) 2025, "TOY", "CAMRY"))
                .thenReturn(List.of(p1, p2, p3));
        when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$35,000.00");

        List<PriceMasterResponse> history = priceMasterService.findHistory((short) 2025, "TOY", "CAMRY");

        assertNotNull(history);
        assertEquals(3, history.size());
        assertTrue(history.size() <= 5);
        verify(repository).findTop5ByModelYearAndMakeCodeAndModelCodeOrderByEffectiveDateDesc(
                (short) 2025, "TOY", "CAMRY");
    }
}
