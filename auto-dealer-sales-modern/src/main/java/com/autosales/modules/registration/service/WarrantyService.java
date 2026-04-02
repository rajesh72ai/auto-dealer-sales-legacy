package com.autosales.modules.registration.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.modules.registration.dto.WarrantyResponse;
import com.autosales.modules.registration.entity.Warranty;
import com.autosales.modules.registration.repository.WarrantyRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

/**
 * Service for warranty registration and coverage inquiry.
 * Port of WRCWAR00 (warranty registration) and WRCINQ00 (warranty inquiry).
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class WarrantyService {

    private static final Map<String, String> WARRANTY_TYPE_NAMES = Map.of(
            "BT", "Basic (Bumper-to-Bumper)",
            "PT", "Powertrain",
            "CR", "Corrosion",
            "EM", "Emission");

    /** Standard warranty definitions per WRCWAR00 hard-coded parameters */
    private static final List<WarrantyDef> STANDARD_WARRANTIES = List.of(
            new WarrantyDef("BT", 3, 36000, BigDecimal.ZERO),
            new WarrantyDef("PT", 5, 60000, new BigDecimal("100.00")),
            new WarrantyDef("CR", 5, 999999, BigDecimal.ZERO),
            new WarrantyDef("EM", 8, 80000, BigDecimal.ZERO));

    private final WarrantyRepository warrantyRepository;
    private final FieldFormatter fieldFormatter;

    public WarrantyService(WarrantyRepository warrantyRepository,
                           FieldFormatter fieldFormatter) {
        this.warrantyRepository = warrantyRepository;
        this.fieldFormatter = fieldFormatter;
    }

    /**
     * Get all warranty coverages for a VIN — WRCINQ00.
     */
    public List<WarrantyResponse> findByVin(String vin) {
        log.info("WRCINQ00: Warranty inquiry for vin={}", vin);
        return warrantyRepository.findByVin(vin).stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Get warranties by deal number.
     */
    public List<WarrantyResponse> findByDealNumber(String dealNumber) {
        log.info("WRCINQ00: Warranty inquiry for dealNumber={}", dealNumber);
        return warrantyRepository.findByDealNumber(dealNumber).stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Register standard warranty coverages for a sold vehicle — WRCWAR00.
     * Creates 4 standard warranties: Basic, Powertrain, Corrosion, Emission.
     *
     * @param vin        the vehicle VIN
     * @param dealNumber the deal number
     * @param saleDate   the sale/deal date (warranty start date)
     * @return list of created warranty responses
     */
    @Transactional
    @Auditable(action = "INS", entity = "warranty", keyExpression = "#vin")
    public List<WarrantyResponse> registerWarranties(String vin, String dealNumber, LocalDate saleDate) {
        log.info("WRCWAR00: Registering warranties for vin={} deal={}", vin, dealNumber);

        if (vin == null || vin.isBlank() || dealNumber == null || dealNumber.isBlank()) {
            throw new BusinessValidationException("VIN and deal number are required");
        }
        if (saleDate == null) {
            throw new BusinessValidationException("Sale date is required for warranty registration");
        }

        if (warrantyRepository.existsByVinAndDealNumber(vin, dealNumber)) {
            throw new DuplicateEntityException("Warranty", vin + "/" + dealNumber);
        }

        LocalDateTime now = LocalDateTime.now();
        List<Warranty> warranties = STANDARD_WARRANTIES.stream()
                .map(def -> Warranty.builder()
                        .vin(vin)
                        .dealNumber(dealNumber)
                        .warrantyType(def.type())
                        .startDate(saleDate)
                        .expiryDate(saleDate.plusYears(def.years()))
                        .mileageLimit(def.mileageLimit())
                        .deductible(def.deductible())
                        .activeFlag("Y")
                        .registeredTs(now)
                        .build())
                .toList();

        List<Warranty> saved = warrantyRepository.saveAll(warranties);
        log.info("WRCWAR00: Registered {} warranties for vin={}", saved.size(), vin);

        return saved.stream().map(this::toResponse).toList();
    }

    private WarrantyResponse toResponse(Warranty entity) {
        long remainingDays = ChronoUnit.DAYS.between(LocalDate.now(), entity.getExpiryDate());
        boolean active = "Y".equals(entity.getActiveFlag()) && remainingDays > 0;

        return WarrantyResponse.builder()
                .warrantyId(entity.getWarrantyId())
                .vin(entity.getVin())
                .dealNumber(entity.getDealNumber())
                .warrantyType(entity.getWarrantyType())
                .startDate(entity.getStartDate())
                .expiryDate(entity.getExpiryDate())
                .mileageLimit(entity.getMileageLimit())
                .deductible(entity.getDeductible())
                .activeFlag(entity.getActiveFlag())
                .registeredTs(entity.getRegisteredTs())
                .warrantyTypeName(WARRANTY_TYPE_NAMES.getOrDefault(entity.getWarrantyType(), entity.getWarrantyType()))
                .formattedDeductible(entity.getDeductible().compareTo(BigDecimal.ZERO) == 0
                        ? "None" : fieldFormatter.formatCurrency(entity.getDeductible()))
                .status(active ? "Active" : "Expired")
                .remainingDays(Math.max(remainingDays, 0))
                .build();
    }

    private record WarrantyDef(String type, int years, int mileageLimit, BigDecimal deductible) {}
}
