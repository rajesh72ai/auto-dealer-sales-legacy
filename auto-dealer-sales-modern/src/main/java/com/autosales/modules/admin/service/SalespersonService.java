package com.autosales.modules.admin.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.SalespersonRequest;
import com.autosales.modules.admin.dto.SalespersonResponse;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.entity.Salesperson;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.admin.repository.SalespersonRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Service for salesperson management.
 * Port of ADMSLP00.cbl — salesperson maintenance transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class SalespersonService {

    private final SalespersonRepository repository;
    private final DealerRepository dealerRepository;
    private final ResponseFormatter responseFormatter;

    public SalespersonService(SalespersonRepository repository,
                              DealerRepository dealerRepository,
                              ResponseFormatter responseFormatter) {
        this.repository = repository;
        this.dealerRepository = dealerRepository;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all salespersons for a given dealer (dealer code is required).
     */
    public PaginatedResponse<SalespersonResponse> findAll(String dealerCode, Pageable pageable) {
        log.debug("Finding salespersons - dealerCode={}, page={}", dealerCode, pageable);

        if (dealerCode == null || dealerCode.isBlank()) {
            throw new BusinessValidationException("Dealer code is required to list salespersons");
        }

        Page<Salesperson> page = repository.findByDealer_DealerCode(dealerCode, pageable);

        List<SalespersonResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a single salesperson by ID.
     */
    public SalespersonResponse findById(String id) {
        log.debug("Finding salesperson by id={}", id);
        Salesperson entity = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Salesperson", id));
        return toResponse(entity);
    }

    /**
     * Create a new salesperson record.
     */
    @Transactional
    @Auditable(action = "INS", entity = "salesperson", keyExpression = "#request.salespersonId")
    public SalespersonResponse create(SalespersonRequest request) {
        log.info("Creating salesperson id={}, dealer={}", request.getSalespersonId(), request.getDealerCode());

        if (repository.existsById(request.getSalespersonId())) {
            throw new DuplicateEntityException("Salesperson", request.getSalespersonId());
        }

        // Validate dealer exists
        Dealer dealer = dealerRepository.findById(request.getDealerCode())
                .orElseThrow(() -> new BusinessValidationException(
                        "Dealer not found with code: " + request.getDealerCode()));

        Salesperson entity = toEntity(request, dealer);
        LocalDateTime now = LocalDateTime.now();
        entity.setCreatedTs(now);
        entity.setUpdatedTs(now);

        Salesperson saved = repository.save(entity);
        log.info("Created salesperson id={}", saved.getSalespersonId());
        return toResponse(saved);
    }

    /**
     * Update an existing salesperson record.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "salesperson", keyExpression = "#id")
    public SalespersonResponse update(String id, SalespersonRequest request) {
        log.info("Updating salesperson id={}", id);

        Salesperson existing = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Salesperson", id));

        // If dealer code is changing, validate the new dealer exists
        if (!existing.getDealer().getDealerCode().equals(request.getDealerCode())) {
            Dealer newDealer = dealerRepository.findById(request.getDealerCode())
                    .orElseThrow(() -> new BusinessValidationException(
                            "Dealer not found with code: " + request.getDealerCode()));
            existing.setDealer(newDealer);
        }

        // Update mutable fields (not salespersonId, createdTs)
        existing.setSalespersonName(request.getSalespersonName());
        existing.setHireDate(request.getHireDate());
        existing.setTerminationDate(request.getTerminationDate());
        existing.setCommissionPlan(request.getCommissionPlan());
        existing.setActiveFlag(request.getActiveFlag());
        existing.setUpdatedTs(LocalDateTime.now());

        Salesperson saved = repository.save(existing);
        log.info("Updated salesperson id={}", saved.getSalespersonId());
        return toResponse(saved);
    }

    private SalespersonResponse toResponse(Salesperson entity) {
        return SalespersonResponse.builder()
                .salespersonId(entity.getSalespersonId())
                .salespersonName(entity.getSalespersonName())
                .dealerCode(entity.getDealer().getDealerCode())
                .hireDate(entity.getHireDate())
                .terminationDate(entity.getTerminationDate())
                .commissionPlan(entity.getCommissionPlan())
                .activeFlag(entity.getActiveFlag())
                .createdTs(entity.getCreatedTs())
                .updatedTs(entity.getUpdatedTs())
                .dealerName(entity.getDealer().getDealerName())
                .build();
    }

    private Salesperson toEntity(SalespersonRequest request, Dealer dealer) {
        return Salesperson.builder()
                .salespersonId(request.getSalespersonId())
                .salespersonName(request.getSalespersonName())
                .dealer(dealer)
                .hireDate(request.getHireDate())
                .terminationDate(request.getTerminationDate())
                .commissionPlan(request.getCommissionPlan())
                .activeFlag(request.getActiveFlag())
                .build();
    }
}
