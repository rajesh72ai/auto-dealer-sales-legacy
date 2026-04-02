package com.autosales.modules.admin.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.DealerRequest;
import com.autosales.modules.admin.dto.DealerResponse;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.repository.DealerRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Service for dealer master data management.
 * Port of ADMDLR00.cbl — dealer maintenance transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class DealerService {

    private final DealerRepository repository;
    private final FieldFormatter fieldFormatter;
    private final ResponseFormatter responseFormatter;

    public DealerService(DealerRepository repository,
                         FieldFormatter fieldFormatter,
                         ResponseFormatter responseFormatter) {
        this.repository = repository;
        this.fieldFormatter = fieldFormatter;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all dealers with optional filtering by region and/or active flag.
     */
    public PaginatedResponse<DealerResponse> findAll(String region, String activeFlag, Pageable pageable) {
        log.debug("Finding dealers - region={}, activeFlag={}, page={}", region, activeFlag, pageable);

        Page<Dealer> page;
        if (region != null && activeFlag != null) {
            page = repository.findByRegionCodeAndActiveFlag(region, activeFlag, pageable);
        } else if (region != null) {
            page = repository.findByRegionCode(region, pageable);
        } else if (activeFlag != null) {
            page = repository.findByActiveFlag(activeFlag, pageable);
        } else {
            page = repository.findAll(pageable);
        }

        List<DealerResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a single dealer by dealer code.
     */
    public DealerResponse findByCode(String code) {
        log.debug("Finding dealer by code={}", code);
        Dealer dealer = repository.findById(code)
                .orElseThrow(() -> new EntityNotFoundException("Dealer", code));
        return toResponse(dealer);
    }

    /**
     * Create a new dealer record.
     */
    @Transactional
    @Auditable(action = "INS", entity = "dealer", keyExpression = "#request.dealerCode")
    public DealerResponse create(DealerRequest request) {
        log.info("Creating dealer code={}", request.getDealerCode());

        if (repository.existsById(request.getDealerCode())) {
            throw new DuplicateEntityException("Dealer", request.getDealerCode());
        }

        Dealer entity = toEntity(request);
        LocalDateTime now = LocalDateTime.now();
        entity.setCreatedTs(now);
        entity.setUpdatedTs(now);

        Dealer saved = repository.save(entity);
        log.info("Created dealer code={}", saved.getDealerCode());
        return toResponse(saved);
    }

    /**
     * Update an existing dealer record.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "dealer", keyExpression = "#code")
    public DealerResponse update(String code, DealerRequest request) {
        log.info("Updating dealer code={}", code);

        Dealer existing = repository.findById(code)
                .orElseThrow(() -> new EntityNotFoundException("Dealer", code));

        // Update mutable fields (not dealerCode, createdTs)
        existing.setDealerName(request.getDealerName());
        existing.setAddressLine1(request.getAddressLine1());
        existing.setAddressLine2(request.getAddressLine2());
        existing.setCity(request.getCity());
        existing.setStateCode(request.getStateCode());
        existing.setZipCode(request.getZipCode());
        existing.setPhoneNumber(request.getPhoneNumber());
        existing.setFaxNumber(request.getFaxNumber());
        existing.setDealerPrincipal(request.getDealerPrincipal());
        existing.setRegionCode(request.getRegionCode());
        existing.setZoneCode(request.getZoneCode());
        existing.setOemDealerNum(request.getOemDealerNum());
        existing.setFloorPlanLenderId(request.getFloorPlanLenderId());
        existing.setMaxInventory(request.getMaxInventory());
        existing.setActiveFlag(request.getActiveFlag());
        existing.setOpenedDate(request.getOpenedDate());
        existing.setUpdatedTs(LocalDateTime.now());

        Dealer saved = repository.save(existing);
        log.info("Updated dealer code={}", saved.getDealerCode());
        return toResponse(saved);
    }

    private DealerResponse toResponse(Dealer entity) {
        return DealerResponse.builder()
                .dealerCode(entity.getDealerCode())
                .dealerName(entity.getDealerName())
                .addressLine1(entity.getAddressLine1())
                .addressLine2(entity.getAddressLine2())
                .city(entity.getCity())
                .stateCode(entity.getStateCode())
                .zipCode(entity.getZipCode())
                .phoneNumber(entity.getPhoneNumber())
                .faxNumber(entity.getFaxNumber())
                .dealerPrincipal(entity.getDealerPrincipal())
                .regionCode(entity.getRegionCode())
                .zoneCode(entity.getZoneCode())
                .oemDealerNum(entity.getOemDealerNum())
                .floorPlanLenderId(entity.getFloorPlanLenderId())
                .maxInventory(entity.getMaxInventory())
                .activeFlag(entity.getActiveFlag())
                .openedDate(entity.getOpenedDate())
                .createdTs(entity.getCreatedTs())
                .updatedTs(entity.getUpdatedTs())
                .formattedPhone(fieldFormatter.formatPhone(entity.getPhoneNumber()))
                .formattedFax(entity.getFaxNumber() != null ? fieldFormatter.formatPhone(entity.getFaxNumber()) : null)
                .build();
    }

    private Dealer toEntity(DealerRequest request) {
        return Dealer.builder()
                .dealerCode(request.getDealerCode())
                .dealerName(request.getDealerName())
                .addressLine1(request.getAddressLine1())
                .addressLine2(request.getAddressLine2())
                .city(request.getCity())
                .stateCode(request.getStateCode())
                .zipCode(request.getZipCode())
                .phoneNumber(request.getPhoneNumber())
                .faxNumber(request.getFaxNumber())
                .dealerPrincipal(request.getDealerPrincipal())
                .regionCode(request.getRegionCode())
                .zoneCode(request.getZoneCode())
                .oemDealerNum(request.getOemDealerNum())
                .floorPlanLenderId(request.getFloorPlanLenderId())
                .maxInventory(request.getMaxInventory())
                .activeFlag(request.getActiveFlag())
                .openedDate(request.getOpenedDate())
                .build();
    }
}
