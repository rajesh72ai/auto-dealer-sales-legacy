package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.CommissionResponse;
import com.autosales.modules.batch.entity.Commission;
import com.autosales.modules.batch.entity.CommissionAudit;
import com.autosales.modules.batch.repository.CommissionAuditRepository;
import com.autosales.modules.batch.repository.CommissionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * Commission management service.
 * Supports the commission and commission_audit tables used by batch processing.
 * Commission calculation is driven by deal gross amounts and commission rates.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class CommissionService {

    private final CommissionRepository commissionRepository;
    private final CommissionAuditRepository commissionAuditRepository;

    public List<CommissionResponse> getCommissionsByDealerAndPeriod(String dealerCode, String payPeriod) {
        return commissionRepository
                .findByDealerCodeAndPayPeriodOrderBySalespersonId(dealerCode, payPeriod)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<CommissionResponse> getCommissionsBySalesperson(String salespersonId, String payPeriod) {
        return commissionRepository.findBySalespersonIdAndPayPeriod(salespersonId, payPeriod)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<CommissionResponse> getCommissionsByDeal(String dealNumber) {
        return commissionRepository.findByDealNumber(dealNumber)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<CommissionResponse> getUnpaidCommissions(String dealerCode) {
        return commissionRepository.findByDealerCodeAndPaidFlag(dealerCode, "N")
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public BigDecimal getTotalCommissions(String dealerCode, String payPeriod) {
        BigDecimal total = commissionRepository
                .sumCommAmountByDealerCodeAndPayPeriod(dealerCode, payPeriod);
        return total != null ? total : BigDecimal.ZERO;
    }

    private CommissionResponse toResponse(Commission entity) {
        return CommissionResponse.builder()
                .commissionId(entity.getCommissionId())
                .dealerCode(entity.getDealerCode())
                .salespersonId(entity.getSalespersonId())
                .dealNumber(entity.getDealNumber())
                .commType(entity.getCommType())
                .grossAmount(entity.getGrossAmount())
                .commRate(entity.getCommRate())
                .commAmount(entity.getCommAmount())
                .payPeriod(entity.getPayPeriod())
                .paidFlag(entity.getPaidFlag())
                .calcTs(entity.getCalcTs())
                .build();
    }
}
