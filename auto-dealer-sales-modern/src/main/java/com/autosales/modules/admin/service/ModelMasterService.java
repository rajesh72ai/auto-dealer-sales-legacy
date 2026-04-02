package com.autosales.modules.admin.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.ModelMasterRequest;
import com.autosales.modules.admin.dto.ModelMasterResponse;
import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import com.autosales.modules.admin.repository.ModelMasterRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Service for vehicle model master data management.
 * Port of ADMMDL00.cbl — model master maintenance transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class ModelMasterService {

    private final ModelMasterRepository repository;
    private final ResponseFormatter responseFormatter;

    public ModelMasterService(ModelMasterRepository repository,
                              ResponseFormatter responseFormatter) {
        this.repository = repository;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all models with optional filtering by year and/or make.
     */
    public PaginatedResponse<ModelMasterResponse> findAll(Short year, String make, Pageable pageable) {
        log.debug("Finding models - year={}, make={}, page={}", year, make, pageable);

        Page<ModelMaster> page;
        if (year != null && make != null) {
            page = repository.findByModelYearAndMakeCode(year, make, pageable);
        } else if (year != null) {
            page = repository.findByModelYear(year, pageable);
        } else if (make != null) {
            page = repository.findByMakeCode(make, pageable);
        } else {
            page = repository.findAll(pageable);
        }

        List<ModelMasterResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a single model by its composite key (year, make, model).
     */
    public ModelMasterResponse findByKey(Short year, String make, String model) {
        log.debug("Finding model by key year={}, make={}, model={}", year, make, model);
        ModelMasterId id = new ModelMasterId(year, make, model);
        ModelMaster entity = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("ModelMaster",
                        year + "/" + make + "/" + model));
        return toResponse(entity);
    }

    /**
     * Create a new model master record.
     */
    @Transactional
    @Auditable(action = "INS", entity = "model_master", keyExpression = "#request.modelYear + '/' + #request.makeCode + '/' + #request.modelCode")
    public ModelMasterResponse create(ModelMasterRequest request) {
        log.info("Creating model year={}, make={}, model={}", request.getModelYear(), request.getMakeCode(), request.getModelCode());

        ModelMasterId id = new ModelMasterId(request.getModelYear(), request.getMakeCode(), request.getModelCode());
        if (repository.existsById(id)) {
            throw new DuplicateEntityException("ModelMaster",
                    request.getModelYear() + "/" + request.getMakeCode() + "/" + request.getModelCode());
        }

        ModelMaster entity = toEntity(request);
        entity.setCreatedTs(LocalDateTime.now());

        ModelMaster saved = repository.save(entity);
        log.info("Created model year={}, make={}, model={}", saved.getModelYear(), saved.getMakeCode(), saved.getModelCode());
        return toResponse(saved);
    }

    /**
     * Update an existing model master record.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "model_master", keyExpression = "#year + '/' + #make + '/' + #model")
    public ModelMasterResponse update(Short year, String make, String model, ModelMasterRequest request) {
        log.info("Updating model year={}, make={}, model={}", year, make, model);

        ModelMasterId id = new ModelMasterId(year, make, model);
        ModelMaster existing = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("ModelMaster",
                        year + "/" + make + "/" + model));

        // Update mutable fields (not composite key or createdTs)
        existing.setModelName(request.getModelName());
        existing.setBodyStyle(request.getBodyStyle());
        existing.setTrimLevel(request.getTrimLevel());
        existing.setEngineType(request.getEngineType());
        existing.setTransmission(request.getTransmission());
        existing.setDriveTrain(request.getDriveTrain());
        existing.setExteriorColors(request.getExteriorColors());
        existing.setInteriorColors(request.getInteriorColors());
        existing.setCurbWeight(request.getCurbWeight());
        existing.setFuelEconomyCity(request.getFuelEconomyCity());
        existing.setFuelEconomyHwy(request.getFuelEconomyHwy());
        existing.setActiveFlag(request.getActiveFlag());

        ModelMaster saved = repository.save(existing);
        log.info("Updated model year={}, make={}, model={}", saved.getModelYear(), saved.getMakeCode(), saved.getModelCode());
        return toResponse(saved);
    }

    private ModelMasterResponse toResponse(ModelMaster entity) {
        return ModelMasterResponse.builder()
                .modelYear(entity.getModelYear())
                .makeCode(entity.getMakeCode())
                .modelCode(entity.getModelCode())
                .modelName(entity.getModelName())
                .bodyStyle(entity.getBodyStyle())
                .trimLevel(entity.getTrimLevel())
                .engineType(entity.getEngineType())
                .transmission(entity.getTransmission())
                .driveTrain(entity.getDriveTrain())
                .exteriorColors(entity.getExteriorColors())
                .interiorColors(entity.getInteriorColors())
                .curbWeight(entity.getCurbWeight())
                .fuelEconomyCity(entity.getFuelEconomyCity())
                .fuelEconomyHwy(entity.getFuelEconomyHwy())
                .activeFlag(entity.getActiveFlag())
                .createdTs(entity.getCreatedTs())
                .build();
    }

    private ModelMaster toEntity(ModelMasterRequest request) {
        return ModelMaster.builder()
                .modelYear(request.getModelYear())
                .makeCode(request.getMakeCode())
                .modelCode(request.getModelCode())
                .modelName(request.getModelName())
                .bodyStyle(request.getBodyStyle())
                .trimLevel(request.getTrimLevel())
                .engineType(request.getEngineType())
                .transmission(request.getTransmission())
                .driveTrain(request.getDriveTrain())
                .exteriorColors(request.getExteriorColors())
                .interiorColors(request.getInteriorColors())
                .curbWeight(request.getCurbWeight())
                .fuelEconomyCity(request.getFuelEconomyCity())
                .fuelEconomyHwy(request.getFuelEconomyHwy())
                .activeFlag(request.getActiveFlag())
                .build();
    }
}
