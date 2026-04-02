package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.CommissionResponse;
import com.autosales.modules.batch.entity.Commission;
import com.autosales.modules.batch.repository.CommissionAuditRepository;
import com.autosales.modules.batch.repository.CommissionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for CommissionService.
 * Validates commission query operations and DTO mapping.
 */
@ExtendWith(MockitoExtension.class)
class CommissionServiceTest {

    @Mock private CommissionRepository commissionRepository;
    @Mock private CommissionAuditRepository commissionAuditRepository;

    @InjectMocks
    private CommissionService commissionService;

    private Commission testCommission;

    @BeforeEach
    void setUp() {
        testCommission = Commission.builder()
                .commissionId(1)
                .dealerCode("D0001")
                .salespersonId("SP001")
                .dealNumber("DL-001")
                .commType("FR")
                .grossAmount(new BigDecimal("3500.00"))
                .commRate(new BigDecimal("0.2500"))
                .commAmount(new BigDecimal("875.00"))
                .payPeriod("202603")
                .paidFlag("N")
                .calcTs(LocalDateTime.now())
                .build();
    }

    @Test
    @DisplayName("Commission query by dealer and period returns correct DTOs")
    void getCommissionsByDealerAndPeriod_mapsCorrectly() {
        when(commissionRepository.findByDealerCodeAndPayPeriodOrderBySalespersonId("D0001", "202603"))
                .thenReturn(List.of(testCommission));

        List<CommissionResponse> result = commissionService
                .getCommissionsByDealerAndPeriod("D0001", "202603");

        assertEquals(1, result.size());
        assertEquals("SP001", result.get(0).getSalespersonId());
        assertEquals(new BigDecimal("875.00"), result.get(0).getCommAmount());
        assertEquals("N", result.get(0).getPaidFlag());
    }

    @Test
    @DisplayName("Unpaid commissions filtered correctly")
    void getUnpaidCommissions_filtersUnpaid() {
        when(commissionRepository.findByDealerCodeAndPaidFlag("D0001", "N"))
                .thenReturn(List.of(testCommission));

        List<CommissionResponse> result = commissionService.getUnpaidCommissions("D0001");

        assertEquals(1, result.size());
        assertEquals("N", result.get(0).getPaidFlag());
    }

    @Test
    @DisplayName("Total commissions sum returns correct aggregate")
    void getTotalCommissions_sumsCorrectly() {
        when(commissionRepository.sumCommAmountByDealerCodeAndPayPeriod("D0001", "202603"))
                .thenReturn(new BigDecimal("3500.00"));

        BigDecimal total = commissionService.getTotalCommissions("D0001", "202603");

        assertEquals(new BigDecimal("3500.00"), total);
    }

    @Test
    @DisplayName("Total commissions returns zero when null")
    void getTotalCommissions_nullReturnsZero() {
        when(commissionRepository.sumCommAmountByDealerCodeAndPayPeriod("D0001", "202603"))
                .thenReturn(null);

        BigDecimal total = commissionService.getTotalCommissions("D0001", "202603");

        assertEquals(BigDecimal.ZERO, total);
    }
}
