package com.autosales.modules.admin.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.PriceMasterRequest;
import com.autosales.modules.admin.dto.PriceMasterResponse;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.entity.PriceMasterId;
import com.autosales.modules.admin.repository.PriceMasterRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Service for vehicle price master data management.
 * Port of ADMPRC00.cbl — price master maintenance transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class PriceMasterService {

    private final PriceMasterRepository repository;
    private final FieldFormatter fieldFormatter;
    private final ResponseFormatter responseFormatter;

    public PriceMasterService(PriceMasterRepository repository,
                              FieldFormatter fieldFormatter,
                              ResponseFormatter responseFormatter) {
        this.repository = repository;
        this.fieldFormatter = fieldFormatter;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all price records with optional filtering by year and/or make.
     */
    public PaginatedResponse<PriceMasterResponse> findAll(Short year, String make, Pageable pageable) {
        log.debug("Finding prices - year={}, make={}, page={}", year, make, pageable);

        Page<PriceMaster> page;
        if (year != null && make != null) {
            page = repository.findByModelYearAndMakeCode(year, make, pageable);
        } else {
            page = repository.findAll(pageable);
        }

        List<PriceMasterResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find the currently effective price for a specific model.
     */
    public PriceMasterResponse findCurrentEffective(Short year, String make, String model) {
        log.debug("Finding current effective price for year={}, make={}, model={}", year, make, model);
        PriceMaster entity = repository.findCurrentEffective(year, make, model, LocalDate.now())
                .orElseThrow(() -> new EntityNotFoundException("PriceMaster",
                        year + "/" + make + "/" + model + " (effective)"));
        return toResponse(entity);
    }

    /**
     * Find price history for a specific model (last 5 records).
     */
    public List<PriceMasterResponse> findHistory(Short year, String make, String model) {
        log.debug("Finding price history for year={}, make={}, model={}", year, make, model);
        return repository.findTop5ByModelYearAndMakeCodeAndModelCodeOrderByEffectiveDateDesc(year, make, model)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Create a new price master record.
     */
    @Transactional
    @Auditable(action = "INS", entity = "price_master", keyExpression = "#request.modelYear + '/' + #request.makeCode + '/' + #request.modelCode")
    public PriceMasterResponse create(PriceMasterRequest request) {
        log.info("Creating price record year={}, make={}, model={}, effective={}",
                request.getModelYear(), request.getMakeCode(), request.getModelCode(), request.getEffectiveDate());

        validatePricing(request);

        PriceMaster entity = toEntity(request);
        entity.setCreatedTs(LocalDateTime.now());

        PriceMaster saved = repository.save(entity);
        log.info("Created price record for {}/{}/{} effective {}",
                saved.getModelYear(), saved.getMakeCode(), saved.getModelCode(), saved.getEffectiveDate());
        return toResponse(saved);
    }

    /**
     * Update an existing price master record.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "price_master", keyExpression = "#year + '/' + #make + '/' + #model")
    public PriceMasterResponse update(Short year, String make, String model, LocalDate date, PriceMasterRequest request) {
        log.info("Updating price record year={}, make={}, model={}, effective={}", year, make, model, date);

        validatePricing(request);

        PriceMasterId id = new PriceMasterId(year, make, model, date);
        PriceMaster existing = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("PriceMaster",
                        year + "/" + make + "/" + model + "/" + date));

        // Update mutable fields (not composite key or createdTs)
        existing.setMsrp(request.getMsrp());
        existing.setInvoicePrice(request.getInvoicePrice());
        existing.setHoldbackAmt(request.getHoldbackAmt());
        existing.setHoldbackPct(request.getHoldbackPct());
        existing.setDestinationFee(request.getDestinationFee());
        existing.setAdvertisingFee(request.getAdvertisingFee());
        existing.setExpiryDate(request.getExpiryDate());

        PriceMaster saved = repository.save(existing);
        log.info("Updated price record for {}/{}/{} effective {}",
                saved.getModelYear(), saved.getMakeCode(), saved.getModelCode(), saved.getEffectiveDate());
        return toResponse(saved);
    }

    private void validatePricing(PriceMasterRequest request) {
        if (request.getMsrp().compareTo(request.getInvoicePrice()) <= 0) {
            throw new BusinessValidationException(
                    "MSRP (" + request.getMsrp() + ") must be greater than invoice price (" + request.getInvoicePrice() + ")");
        }
    }

    private PriceMasterResponse toResponse(PriceMaster entity) {
        return PriceMasterResponse.builder()
                .modelYear(entity.getModelYear())
                .makeCode(entity.getMakeCode())
                .modelCode(entity.getModelCode())
                .msrp(entity.getMsrp())
                .invoicePrice(entity.getInvoicePrice())
                .holdbackAmt(entity.getHoldbackAmt())
                .holdbackPct(entity.getHoldbackPct())
                .destinationFee(entity.getDestinationFee())
                .advertisingFee(entity.getAdvertisingFee())
                .effectiveDate(entity.getEffectiveDate())
                .expiryDate(entity.getExpiryDate())
                .createdTs(entity.getCreatedTs())
                .dealerMargin(entity.getMsrp().subtract(entity.getInvoicePrice()))
                .formattedMsrp(fieldFormatter.formatCurrency(entity.getMsrp()))
                .formattedInvoice(fieldFormatter.formatCurrency(entity.getInvoicePrice()))
                .build();
    }

    private PriceMaster toEntity(PriceMasterRequest request) {
        return PriceMaster.builder()
                .modelYear(request.getModelYear())
                .makeCode(request.getMakeCode())
                .modelCode(request.getModelCode())
                .effectiveDate(request.getEffectiveDate())
                .msrp(request.getMsrp())
                .invoicePrice(request.getInvoicePrice())
                .holdbackAmt(request.getHoldbackAmt())
                .holdbackPct(request.getHoldbackPct())
                .destinationFee(request.getDestinationFee())
                .advertisingFee(request.getAdvertisingFee())
                .expiryDate(request.getExpiryDate())
                .build();
    }
}
