package com.autosales.modules.admin.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.IncentiveProgramRequest;
import com.autosales.modules.admin.dto.IncentiveProgramResponse;
import com.autosales.modules.admin.entity.IncentiveProgram;
import com.autosales.modules.admin.repository.IncentiveProgramRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Service for incentive program management.
 * Port of ADMINC00.cbl — incentive program maintenance transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class IncentiveProgramService {

    private final IncentiveProgramRepository repository;
    private final FieldFormatter fieldFormatter;
    private final ResponseFormatter responseFormatter;

    public IncentiveProgramService(IncentiveProgramRepository repository,
                                   FieldFormatter fieldFormatter,
                                   ResponseFormatter responseFormatter) {
        this.repository = repository;
        this.fieldFormatter = fieldFormatter;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all incentive programs with optional filtering by type and/or active flag.
     */
    public PaginatedResponse<IncentiveProgramResponse> findAll(String type, String activeFlag, Pageable pageable) {
        log.debug("Finding incentive programs - type={}, activeFlag={}, page={}", type, activeFlag, pageable);

        Page<IncentiveProgram> page;
        if (type != null && activeFlag != null) {
            page = repository.findByIncentiveTypeAndActiveFlag(type, activeFlag, pageable);
        } else if (type != null) {
            page = repository.findByIncentiveType(type, pageable);
        } else if (activeFlag != null) {
            page = repository.findByActiveFlag(activeFlag, pageable);
        } else {
            page = repository.findAll(pageable);
        }

        List<IncentiveProgramResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a single incentive program by ID.
     */
    public IncentiveProgramResponse findById(String id) {
        log.debug("Finding incentive program by id={}", id);
        IncentiveProgram entity = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("IncentiveProgram", id));
        return toResponse(entity);
    }

    /**
     * Create a new incentive program.
     */
    @Transactional
    @Auditable(action = "INS", entity = "incentive_program", keyExpression = "#request.incentiveId")
    public IncentiveProgramResponse create(IncentiveProgramRequest request) {
        log.info("Creating incentive program id={}", request.getIncentiveId());

        validateDateRange(request);

        IncentiveProgram entity = toEntity(request);
        entity.setUnitsUsed(0);
        entity.setCreatedTs(LocalDateTime.now());

        IncentiveProgram saved = repository.save(entity);
        log.info("Created incentive program id={}", saved.getIncentiveId());
        return toResponse(saved);
    }

    /**
     * Update an existing incentive program.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "incentive_program", keyExpression = "#id")
    public IncentiveProgramResponse update(String id, IncentiveProgramRequest request) {
        log.info("Updating incentive program id={}", id);

        validateDateRange(request);

        IncentiveProgram existing = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("IncentiveProgram", id));

        // Update mutable fields (not incentiveId, unitsUsed, createdTs)
        existing.setIncentiveName(request.getIncentiveName());
        existing.setIncentiveType(request.getIncentiveType());
        existing.setModelYear(request.getModelYear());
        existing.setMakeCode(request.getMakeCode());
        existing.setModelCode(request.getModelCode());
        existing.setRegionCode(request.getRegionCode());
        existing.setAmount(request.getAmount());
        existing.setRateOverride(request.getRateOverride());
        existing.setStartDate(request.getStartDate());
        existing.setEndDate(request.getEndDate());
        existing.setMaxUnits(request.getMaxUnits());
        existing.setStackableFlag(request.getStackableFlag());
        existing.setActiveFlag(request.getActiveFlag());

        IncentiveProgram saved = repository.save(existing);
        log.info("Updated incentive program id={}", saved.getIncentiveId());
        return toResponse(saved);
    }

    /**
     * Activate an incentive program.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "incentive_program", keyExpression = "#id")
    public IncentiveProgramResponse activate(String id) {
        log.info("Activating incentive program id={}", id);
        IncentiveProgram entity = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("IncentiveProgram", id));
        entity.setActiveFlag("Y");
        IncentiveProgram saved = repository.save(entity);
        log.info("Activated incentive program id={}", saved.getIncentiveId());
        return toResponse(saved);
    }

    /**
     * Deactivate an incentive program.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "incentive_program", keyExpression = "#id")
    public IncentiveProgramResponse deactivate(String id) {
        log.info("Deactivating incentive program id={}", id);
        IncentiveProgram entity = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("IncentiveProgram", id));
        entity.setActiveFlag("N");
        IncentiveProgram saved = repository.save(entity);
        log.info("Deactivated incentive program id={}", saved.getIncentiveId());
        return toResponse(saved);
    }

    private void validateDateRange(IncentiveProgramRequest request) {
        if (!request.getEndDate().isAfter(request.getStartDate())) {
            throw new BusinessValidationException(
                    "End date (" + request.getEndDate() + ") must be after start date (" + request.getStartDate() + ")");
        }
    }

    private IncentiveProgramResponse toResponse(IncentiveProgram entity) {
        Integer unitsRemaining = entity.getMaxUnits() != null
                ? entity.getMaxUnits() - entity.getUnitsUsed()
                : null;

        return IncentiveProgramResponse.builder()
                .incentiveId(entity.getIncentiveId())
                .incentiveName(entity.getIncentiveName())
                .incentiveType(entity.getIncentiveType())
                .modelYear(entity.getModelYear())
                .makeCode(entity.getMakeCode())
                .modelCode(entity.getModelCode())
                .regionCode(entity.getRegionCode())
                .amount(entity.getAmount())
                .rateOverride(entity.getRateOverride())
                .startDate(entity.getStartDate())
                .endDate(entity.getEndDate())
                .maxUnits(entity.getMaxUnits())
                .stackableFlag(entity.getStackableFlag())
                .activeFlag(entity.getActiveFlag())
                .createdTs(entity.getCreatedTs())
                .unitsRemaining(unitsRemaining)
                .isExpired(entity.getEndDate().isBefore(LocalDate.now()))
                .formattedAmount(fieldFormatter.formatCurrency(entity.getAmount()))
                .build();
    }

    private IncentiveProgram toEntity(IncentiveProgramRequest request) {
        return IncentiveProgram.builder()
                .incentiveId(request.getIncentiveId())
                .incentiveName(request.getIncentiveName())
                .incentiveType(request.getIncentiveType())
                .modelYear(request.getModelYear())
                .makeCode(request.getMakeCode())
                .modelCode(request.getModelCode())
                .regionCode(request.getRegionCode())
                .amount(request.getAmount())
                .rateOverride(request.getRateOverride())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .maxUnits(request.getMaxUnits())
                .stackableFlag(request.getStackableFlag())
                .activeFlag(request.getActiveFlag())
                .build();
    }
}
