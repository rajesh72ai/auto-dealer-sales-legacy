package com.autosales.modules.registration.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.registration.dto.WarrantyClaimRequest;
import com.autosales.modules.registration.dto.WarrantyClaimResponse;
import com.autosales.modules.registration.dto.WarrantyClaimSummaryResponse;
import com.autosales.modules.registration.entity.WarrantyClaim;
import com.autosales.modules.registration.repository.WarrantyClaimRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for warranty claim management and reporting.
 * Port of WRCRPT00 (claims summary report) and claim CRUD.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class WarrantyClaimService {

    private static final Map<String, String> CLAIM_TYPE_NAMES = Map.of(
            "BA", "Basic", "PT", "Powertrain", "EX", "Extended",
            "GW", "Goodwill", "RC", "Recall", "CM", "Campaign", "PD", "Pre-Delivery");

    private static final Map<String, String> CLAIM_STATUS_NAMES = Map.of(
            "NW", "New", "IP", "In Progress", "AP", "Approved",
            "PA", "Partially Approved", "PD", "Paid",
            "DN", "Denied", "CL", "Closed");

    private static final Set<String> APPROVED_STATUSES = Set.of("AP", "PA", "PD");

    private final WarrantyClaimRepository claimRepository;
    private final FieldFormatter fieldFormatter;
    private final ResponseFormatter responseFormatter;

    public WarrantyClaimService(WarrantyClaimRepository claimRepository,
                                FieldFormatter fieldFormatter,
                                ResponseFormatter responseFormatter) {
        this.claimRepository = claimRepository;
        this.fieldFormatter = fieldFormatter;
        this.responseFormatter = responseFormatter;
    }

    /**
     * List warranty claims for a dealer with optional status filter.
     */
    public PaginatedResponse<WarrantyClaimResponse> findByDealer(String dealerCode, String status, Pageable pageable) {
        log.info("Listing warranty claims — dealer={}, status={}", dealerCode, status);

        Page<WarrantyClaim> page = (status != null)
                ? claimRepository.findByDealerCodeAndClaimStatus(dealerCode, status, pageable)
                : claimRepository.findByDealerCode(dealerCode, pageable);

        List<WarrantyClaimResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a claim by claim number.
     */
    public WarrantyClaimResponse findByClaimNumber(String claimNumber) {
        log.info("Finding warranty claim number={}", claimNumber);
        WarrantyClaim claim = claimRepository.findById(claimNumber)
                .orElseThrow(() -> new EntityNotFoundException("WarrantyClaim", claimNumber));
        return toResponse(claim);
    }

    /**
     * Find all claims for a VIN.
     */
    public List<WarrantyClaimResponse> findByVin(String vin) {
        log.info("Finding warranty claims for vin={}", vin);
        return claimRepository.findByVin(vin).stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Create a new warranty claim.
     */
    @Transactional
    @Auditable(action = "INS", entity = "warranty_claim", keyExpression = "#request.vin")
    public WarrantyClaimResponse create(WarrantyClaimRequest request) {
        log.info("Creating warranty claim for vin={} dealer={}", request.getVin(), request.getDealerCode());

        BigDecimal totalClaim = request.getLaborAmt().add(request.getPartsAmt());
        String claimNumber = generateClaimNumber();
        LocalDateTime now = LocalDateTime.now();

        WarrantyClaim entity = WarrantyClaim.builder()
                .claimNumber(claimNumber)
                .vin(request.getVin())
                .dealerCode(request.getDealerCode())
                .claimType(request.getClaimType())
                .claimDate(request.getClaimDate())
                .repairDate(request.getRepairDate())
                .laborAmt(request.getLaborAmt())
                .partsAmt(request.getPartsAmt())
                .totalClaim(totalClaim)
                .claimStatus(request.getClaimStatus() != null ? request.getClaimStatus() : "NW")
                .technicianId(request.getTechnicianId())
                .repairOrderNum(request.getRepairOrderNum())
                .notes(request.getNotes())
                .createdTs(now)
                .updatedTs(now)
                .build();

        WarrantyClaim saved = claimRepository.save(entity);
        log.info("Created warranty claim number={}", claimNumber);
        return toResponse(saved);
    }

    /**
     * Update a warranty claim.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "warranty_claim", keyExpression = "#claimNumber")
    public WarrantyClaimResponse update(String claimNumber, WarrantyClaimRequest request) {
        log.info("Updating warranty claim number={}", claimNumber);

        WarrantyClaim existing = claimRepository.findById(claimNumber)
                .orElseThrow(() -> new EntityNotFoundException("WarrantyClaim", claimNumber));

        if ("CL".equals(existing.getClaimStatus())) {
            throw new BusinessValidationException("Cannot update a closed claim");
        }

        existing.setClaimType(request.getClaimType());
        existing.setRepairDate(request.getRepairDate());
        existing.setLaborAmt(request.getLaborAmt());
        existing.setPartsAmt(request.getPartsAmt());
        existing.setTotalClaim(request.getLaborAmt().add(request.getPartsAmt()));
        existing.setClaimStatus(request.getClaimStatus() != null ? request.getClaimStatus() : existing.getClaimStatus());
        existing.setTechnicianId(request.getTechnicianId());
        existing.setRepairOrderNum(request.getRepairOrderNum());
        existing.setNotes(request.getNotes());
        existing.setUpdatedTs(LocalDateTime.now());

        WarrantyClaim saved = claimRepository.save(existing);
        log.info("Updated warranty claim number={}", claimNumber);
        return toResponse(saved);
    }

    /**
     * Generate warranty claims summary report for a dealer — WRCRPT00.
     */
    public WarrantyClaimSummaryResponse generateReport(String dealerCode, LocalDate fromDate, LocalDate toDate) {
        log.info("WRCRPT00: Generating claims report — dealer={} from={} to={}", dealerCode, fromDate, toDate);

        if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
            throw new BusinessValidationException("From date must be before to date");
        }

        List<WarrantyClaim> claims = claimRepository.findClaimsForReport(dealerCode, fromDate, toDate);

        if (claims.isEmpty()) {
            return WarrantyClaimSummaryResponse.builder()
                    .dealerCode(dealerCode)
                    .fromDate(fromDate != null ? fromDate.toString() : null)
                    .toDate(toDate != null ? toDate.toString() : null)
                    .byType(List.of())
                    .grandTotalClaims(0)
                    .grandTotalLabor(BigDecimal.ZERO)
                    .grandTotalParts(BigDecimal.ZERO)
                    .grandTotal(BigDecimal.ZERO)
                    .averageClaimAmount(BigDecimal.ZERO)
                    .totalApproved(0)
                    .totalDenied(0)
                    .build();
        }

        // Group by claim type
        Map<String, List<WarrantyClaim>> byType = claims.stream()
                .collect(Collectors.groupingBy(WarrantyClaim::getClaimType));

        List<WarrantyClaimSummaryResponse.ClaimTypeSummary> typeSummaries = byType.entrySet().stream()
                .map(entry -> {
                    String type = entry.getKey();
                    List<WarrantyClaim> typeClaims = entry.getValue();
                    BigDecimal laborTotal = typeClaims.stream()
                            .map(WarrantyClaim::getLaborAmt).reduce(BigDecimal.ZERO, BigDecimal::add);
                    BigDecimal partsTotal = typeClaims.stream()
                            .map(WarrantyClaim::getPartsAmt).reduce(BigDecimal.ZERO, BigDecimal::add);

                    return WarrantyClaimSummaryResponse.ClaimTypeSummary.builder()
                            .claimType(type)
                            .claimTypeName(CLAIM_TYPE_NAMES.getOrDefault(type, type))
                            .totalClaims(typeClaims.size())
                            .laborTotal(laborTotal)
                            .partsTotal(partsTotal)
                            .claimTotal(laborTotal.add(partsTotal))
                            .approvedCount((int) typeClaims.stream()
                                    .filter(c -> APPROVED_STATUSES.contains(c.getClaimStatus())).count())
                            .deniedCount((int) typeClaims.stream()
                                    .filter(c -> "DN".equals(c.getClaimStatus())).count())
                            .build();
                })
                .sorted(Comparator.comparing(WarrantyClaimSummaryResponse.ClaimTypeSummary::getClaimType))
                .toList();

        BigDecimal grandLabor = typeSummaries.stream()
                .map(WarrantyClaimSummaryResponse.ClaimTypeSummary::getLaborTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal grandParts = typeSummaries.stream()
                .map(WarrantyClaimSummaryResponse.ClaimTypeSummary::getPartsTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal grandTotal = grandLabor.add(grandParts);
        int grandCount = claims.size();

        return WarrantyClaimSummaryResponse.builder()
                .dealerCode(dealerCode)
                .fromDate(fromDate != null ? fromDate.toString() : null)
                .toDate(toDate != null ? toDate.toString() : null)
                .byType(typeSummaries)
                .grandTotalClaims(grandCount)
                .grandTotalLabor(grandLabor)
                .grandTotalParts(grandParts)
                .grandTotal(grandTotal)
                .averageClaimAmount(grandCount > 0
                        ? grandTotal.divide(BigDecimal.valueOf(grandCount), 2, RoundingMode.HALF_UP)
                        : BigDecimal.ZERO)
                .totalApproved((int) claims.stream()
                        .filter(c -> APPROVED_STATUSES.contains(c.getClaimStatus())).count())
                .totalDenied((int) claims.stream()
                        .filter(c -> "DN".equals(c.getClaimStatus())).count())
                .build();
    }

    private String generateClaimNumber() {
        return "WC" + String.format("%06d", System.nanoTime() % 1000000);
    }

    private WarrantyClaimResponse toResponse(WarrantyClaim entity) {
        return WarrantyClaimResponse.builder()
                .claimNumber(entity.getClaimNumber())
                .vin(entity.getVin())
                .dealerCode(entity.getDealerCode())
                .claimType(entity.getClaimType())
                .claimDate(entity.getClaimDate())
                .repairDate(entity.getRepairDate())
                .laborAmt(entity.getLaborAmt())
                .partsAmt(entity.getPartsAmt())
                .totalClaim(entity.getTotalClaim())
                .claimStatus(entity.getClaimStatus())
                .technicianId(entity.getTechnicianId())
                .repairOrderNum(entity.getRepairOrderNum())
                .notes(entity.getNotes())
                .createdTs(entity.getCreatedTs())
                .updatedTs(entity.getUpdatedTs())
                .claimTypeName(CLAIM_TYPE_NAMES.getOrDefault(entity.getClaimType(), entity.getClaimType()))
                .claimStatusName(CLAIM_STATUS_NAMES.getOrDefault(entity.getClaimStatus(), entity.getClaimStatus()))
                .formattedLabor(fieldFormatter.formatCurrency(entity.getLaborAmt()))
                .formattedParts(fieldFormatter.formatCurrency(entity.getPartsAmt()))
                .formattedTotal(fieldFormatter.formatCurrency(entity.getTotalClaim()))
                .build();
    }
}
