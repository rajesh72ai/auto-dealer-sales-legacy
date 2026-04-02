package com.autosales.modules.registration.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.common.util.SequenceGenerator;
import com.autosales.modules.registration.dto.*;
import com.autosales.modules.registration.entity.Registration;
import com.autosales.modules.registration.entity.TitleStatus;
import com.autosales.modules.registration.repository.RegistrationRepository;
import com.autosales.modules.registration.repository.TitleStatusRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Service for vehicle registration lifecycle management.
 * Port of REGGEN00, REGINQ00, REGVAL00, REGSUB00, REGSTS00.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class RegistrationService {

    private static final Map<String, String> REG_TYPE_NAMES = Map.of(
            "NW", "New", "TF", "Transfer", "RN", "Renewal", "DP", "Duplicate");

    private static final Map<String, String> REG_STATUS_NAMES = Map.of(
            "PR", "Preparing", "VL", "Validated", "SB", "Submitted",
            "PG", "Processing", "IS", "Issued", "RJ", "Rejected", "ER", "Error");

    private static final Map<String, Set<String>> VALID_TRANSITIONS = Map.of(
            "SB", Set.of("PG", "IS", "RJ", "ER"),
            "PG", Set.of("IS", "RJ", "ER"));

    private final RegistrationRepository registrationRepository;
    private final TitleStatusRepository titleStatusRepository;
    private final SequenceGenerator sequenceGenerator;
    private final FieldFormatter fieldFormatter;
    private final ResponseFormatter responseFormatter;

    public RegistrationService(RegistrationRepository registrationRepository,
                               TitleStatusRepository titleStatusRepository,
                               SequenceGenerator sequenceGenerator,
                               FieldFormatter fieldFormatter,
                               ResponseFormatter responseFormatter) {
        this.registrationRepository = registrationRepository;
        this.titleStatusRepository = titleStatusRepository;
        this.sequenceGenerator = sequenceGenerator;
        this.fieldFormatter = fieldFormatter;
        this.responseFormatter = responseFormatter;
    }

    /**
     * List registrations with optional status filter — REGINQ00.
     */
    public PaginatedResponse<RegistrationResponse> findAll(String status, Pageable pageable) {
        log.info("REGINQ00: Listing registrations — status={}", status);

        Page<Registration> page = (status != null)
                ? registrationRepository.findByRegStatus(status, pageable)
                : registrationRepository.findAll(pageable);

        List<RegistrationResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find registration by ID with full status history — REGINQ00.
     */
    public RegistrationResponse findById(String regId) {
        log.info("REGINQ00: Finding registration regId={}", regId);
        Registration reg = registrationRepository.findById(regId)
                .orElseThrow(() -> new EntityNotFoundException("Registration", regId));
        RegistrationResponse response = toResponse(reg);
        response.setStatusHistory(findStatusHistory(regId));
        return response;
    }

    /**
     * Find registrations by VIN — REGINQ00.
     */
    public List<RegistrationResponse> findByVin(String vin) {
        log.info("REGINQ00: Finding registrations by vin={}", vin);
        return registrationRepository.findByVin(vin).stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Find registrations by deal number — REGINQ00.
     */
    public RegistrationResponse findByDealNumber(String dealNumber) {
        log.info("REGINQ00: Finding registration by dealNumber={}", dealNumber);
        Registration reg = registrationRepository.findByDealNumber(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Registration", dealNumber));
        RegistrationResponse response = toResponse(reg);
        response.setStatusHistory(findStatusHistory(reg.getRegId()));
        return response;
    }

    /**
     * Create a new registration — REGGEN00.
     */
    @Transactional
    @Auditable(action = "INS", entity = "registration", keyExpression = "#request.dealNumber")
    public RegistrationResponse create(RegistrationRequest request) {
        log.info("REGGEN00: Creating registration for deal={}", request.getDealNumber());

        if (registrationRepository.existsByDealNumber(request.getDealNumber())) {
            throw new DuplicateEntityException("Registration", request.getDealNumber());
        }

        String regId = sequenceGenerator.generateRegistrationId();
        LocalDateTime now = LocalDateTime.now();

        Registration entity = Registration.builder()
                .regId(regId)
                .dealNumber(request.getDealNumber())
                .vin(request.getVin())
                .customerId(request.getCustomerId())
                .regState(request.getRegState())
                .regType(request.getRegType())
                .lienHolder(request.getLienHolder())
                .lienHolderAddr(request.getLienHolderAddr())
                .regStatus("PR")
                .regFeePaid(request.getRegFeePaid() != null ? request.getRegFeePaid() : BigDecimal.ZERO)
                .titleFeePaid(request.getTitleFeePaid() != null ? request.getTitleFeePaid() : BigDecimal.ZERO)
                .createdTs(now)
                .updatedTs(now)
                .build();

        Registration saved = registrationRepository.save(entity);
        log.info("REGGEN00: Created registration regId={} for deal={}", regId, request.getDealNumber());
        return toResponse(saved);
    }

    /**
     * Validate a registration before submission — REGVAL00.
     * Registration must be in PR (Preparing) status.
     * Checks: VIN length, customer data, state, type, fees.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "registration", keyExpression = "#regId")
    public RegistrationResponse validate(String regId) {
        log.info("REGVAL00: Validating registration regId={}", regId);

        Registration reg = registrationRepository.findById(regId)
                .orElseThrow(() -> new EntityNotFoundException("Registration", regId));

        if (!"PR".equals(reg.getRegStatus())) {
            throw new BusinessValidationException("Registration must be in Preparing status to validate");
        }

        // 5-step validation per REGVAL00
        StringBuilder errors = new StringBuilder();

        if (reg.getVin() == null || reg.getVin().length() != 17) {
            errors.append("VIN must be 17 characters. ");
        }
        if (reg.getCustomerId() == null) {
            errors.append("Customer ID is required. ");
        }
        if (reg.getRegState() == null || reg.getRegState().length() != 2) {
            errors.append("Valid registration state is required. ");
        }
        if (!REG_TYPE_NAMES.containsKey(reg.getRegType())) {
            errors.append("Invalid registration type. ");
        }
        if (reg.getRegFeePaid() == null || reg.getRegFeePaid().compareTo(BigDecimal.ZERO) <= 0
                || reg.getTitleFeePaid() == null || reg.getTitleFeePaid().compareTo(BigDecimal.ZERO) <= 0) {
            errors.append("Registration and title fees must be calculated. ");
        }

        if (!errors.isEmpty()) {
            throw new BusinessValidationException("Validation failed: " + errors.toString().trim());
        }

        reg.setRegStatus("VL");
        reg.setUpdatedTs(LocalDateTime.now());
        Registration saved = registrationRepository.save(reg);

        log.info("REGVAL00: Registration regId={} validated successfully", regId);
        return toResponse(saved);
    }

    /**
     * Submit a validated registration to state DMV — REGSUB00.
     * Registration must be in VL (Validated) status.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "registration", keyExpression = "#regId")
    public RegistrationResponse submit(String regId) {
        log.info("REGSUB00: Submitting registration regId={}", regId);

        Registration reg = registrationRepository.findById(regId)
                .orElseThrow(() -> new EntityNotFoundException("Registration", regId));

        if (!"VL".equals(reg.getRegStatus())) {
            throw new BusinessValidationException("Registration must be validated before submission");
        }

        reg.setRegStatus("SB");
        reg.setSubmissionDate(LocalDate.now());
        reg.setUpdatedTs(LocalDateTime.now());
        Registration saved = registrationRepository.save(reg);

        // Create title status history entry
        insertTitleStatus(regId, "SB", "Submitted to State DMV");

        log.info("REGSUB00: Registration regId={} submitted to state DMV", regId);
        return toResponse(saved);
    }

    /**
     * Update registration status with DMV response — REGSTS00.
     * Valid from SB or PG status only.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "registration", keyExpression = "#regId")
    public RegistrationResponse updateStatus(String regId, RegistrationStatusUpdateRequest request) {
        log.info("REGSTS00: Updating status for regId={} to {}", regId, request.getNewStatus());

        Registration reg = registrationRepository.findById(regId)
                .orElseThrow(() -> new EntityNotFoundException("Registration", regId));

        String currentStatus = reg.getRegStatus();
        String newStatus = request.getNewStatus();

        Set<String> allowed = VALID_TRANSITIONS.get(currentStatus);
        if (allowed == null || !allowed.contains(newStatus)) {
            throw new BusinessValidationException(
                    String.format("Cannot transition from %s to %s", currentStatus, newStatus));
        }

        // Status-specific handling per REGSTS00
        if ("IS".equals(newStatus)) {
            if (request.getPlateNumber() == null || request.getTitleNumber() == null) {
                throw new BusinessValidationException("Plate number and title number required for Issued status");
            }
            reg.setPlateNumber(request.getPlateNumber());
            reg.setTitleNumber(request.getTitleNumber());
            reg.setIssuedDate(LocalDate.now());
        }

        if ("RJ".equals(newStatus) && (request.getStatusDesc() == null || request.getStatusDesc().isBlank())) {
            throw new BusinessValidationException("Rejection reason is required");
        }

        reg.setRegStatus(newStatus);
        reg.setUpdatedTs(LocalDateTime.now());
        Registration saved = registrationRepository.save(reg);

        String desc = request.getStatusDesc() != null ? request.getStatusDesc()
                : REG_STATUS_NAMES.getOrDefault(newStatus, newStatus);
        insertTitleStatus(regId, newStatus, desc);

        log.info("REGSTS00: Registration regId={} status updated to {}", regId, newStatus);
        RegistrationResponse response = toResponse(saved);
        response.setStatusHistory(findStatusHistory(regId));
        return response;
    }

    private void insertTitleStatus(String regId, String statusCode, String statusDesc) {
        Short maxSeq = titleStatusRepository.findMaxStatusSeqByRegId(regId);
        short nextSeq = (short) (maxSeq + 1);

        TitleStatus status = TitleStatus.builder()
                .regId(regId)
                .statusSeq(nextSeq)
                .statusCode(statusCode)
                .statusDesc(statusDesc)
                .statusTs(LocalDateTime.now())
                .build();
        titleStatusRepository.save(status);
    }

    private List<TitleStatusResponse> findStatusHistory(String regId) {
        return titleStatusRepository.findByRegIdOrderByStatusSeqDesc(regId).stream()
                .map(ts -> TitleStatusResponse.builder()
                        .regId(ts.getRegId())
                        .statusSeq(ts.getStatusSeq())
                        .statusCode(ts.getStatusCode())
                        .statusDesc(ts.getStatusDesc())
                        .statusTs(ts.getStatusTs())
                        .statusName(REG_STATUS_NAMES.getOrDefault(ts.getStatusCode(), ts.getStatusCode()))
                        .build())
                .toList();
    }

    private RegistrationResponse toResponse(Registration entity) {
        return RegistrationResponse.builder()
                .regId(entity.getRegId())
                .dealNumber(entity.getDealNumber())
                .vin(entity.getVin())
                .customerId(entity.getCustomerId())
                .regState(entity.getRegState())
                .regType(entity.getRegType())
                .plateNumber(entity.getPlateNumber())
                .titleNumber(entity.getTitleNumber())
                .lienHolder(entity.getLienHolder())
                .lienHolderAddr(entity.getLienHolderAddr())
                .regStatus(entity.getRegStatus())
                .submissionDate(entity.getSubmissionDate())
                .issuedDate(entity.getIssuedDate())
                .regFeePaid(entity.getRegFeePaid())
                .titleFeePaid(entity.getTitleFeePaid())
                .createdTs(entity.getCreatedTs())
                .updatedTs(entity.getUpdatedTs())
                .regTypeName(REG_TYPE_NAMES.getOrDefault(entity.getRegType(), entity.getRegType()))
                .regStatusName(REG_STATUS_NAMES.getOrDefault(entity.getRegStatus(), entity.getRegStatus()))
                .formattedRegFee(fieldFormatter.formatCurrency(entity.getRegFeePaid()))
                .formattedTitleFee(fieldFormatter.formatCurrency(entity.getTitleFeePaid()))
                .build();
    }
}
