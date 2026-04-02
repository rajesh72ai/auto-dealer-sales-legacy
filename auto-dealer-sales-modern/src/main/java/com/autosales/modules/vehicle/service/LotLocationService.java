package com.autosales.modules.vehicle.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.modules.vehicle.dto.LotLocationRequest;
import com.autosales.modules.vehicle.dto.LotLocationResponse;
import com.autosales.modules.vehicle.entity.LotLocation;
import com.autosales.modules.vehicle.entity.LotLocationId;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.LotLocationRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Set;

/**
 * Service for lot location management with capacity tracking.
 * Port of VEHLOC00.cbl — vehicle lot location maintenance transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class LotLocationService {

    private static final Set<String> VALID_LOCATION_TYPES = Set.of("L", "S", "V", "O");

    private final LotLocationRepository lotLocationRepository;
    private final VehicleRepository vehicleRepository;

    /**
     * List all lot locations for a dealer with calculated availability metrics.
     */
    public List<LotLocationResponse> listLocations(String dealerCode) {
        log.debug("Listing lot locations for dealerCode={}", dealerCode);
        return lotLocationRepository.findByDealerCode(dealerCode).stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Get a single lot location by dealer code and location code.
     */
    public LotLocationResponse getLocation(String dealerCode, String locationCode) {
        log.debug("Getting lot location dealerCode={}, locationCode={}", dealerCode, locationCode);
        LotLocation location = findLocationOrThrow(dealerCode, locationCode);
        return toResponse(location);
    }

    /**
     * Create a new lot location with validation.
     */
    @Transactional
    @Auditable(action = "INS", entity = "lot_location", keyExpression = "#request.dealerCode + '-' + #request.locationCode")
    public LotLocationResponse createLocation(LotLocationRequest request) {
        log.info("Creating lot location dealerCode={}, locationCode={}", request.getDealerCode(), request.getLocationCode());

        validateLocationType(request.getLocationType());
        validateCapacity(request.getMaxCapacity());

        LotLocationId id = new LotLocationId(request.getDealerCode(), request.getLocationCode());
        if (lotLocationRepository.existsById(id)) {
            throw new BusinessValidationException(
                    "Lot location already exists: " + request.getDealerCode() + "/" + request.getLocationCode());
        }

        LotLocation entity = LotLocation.builder()
                .dealerCode(request.getDealerCode())
                .locationCode(request.getLocationCode())
                .locationDesc(request.getLocationDesc())
                .locationType(request.getLocationType())
                .maxCapacity(request.getMaxCapacity())
                .currentCount((short) 0)
                .activeFlag("Y")
                .build();

        LotLocation saved = lotLocationRepository.save(entity);
        log.info("Created lot location dealerCode={}, locationCode={}", saved.getDealerCode(), saved.getLocationCode());
        return toResponse(saved);
    }

    /**
     * Update an existing lot location (partial update of mutable fields).
     */
    @Transactional
    @Auditable(action = "UPD", entity = "lot_location", keyExpression = "#dealerCode + '-' + #locationCode")
    public LotLocationResponse updateLocation(String dealerCode, String locationCode, LotLocationRequest request) {
        log.info("Updating lot location dealerCode={}, locationCode={}", dealerCode, locationCode);

        LotLocation existing = findLocationOrThrow(dealerCode, locationCode);

        if (request.getLocationDesc() != null) {
            existing.setLocationDesc(request.getLocationDesc());
        }
        if (request.getLocationType() != null) {
            validateLocationType(request.getLocationType());
            existing.setLocationType(request.getLocationType());
        }
        if (request.getMaxCapacity() != null) {
            validateCapacity(request.getMaxCapacity());
            if (request.getMaxCapacity() < existing.getCurrentCount()) {
                throw new BusinessValidationException(
                        "New capacity (" + request.getMaxCapacity() + ") cannot be less than current count ("
                                + existing.getCurrentCount() + ")");
            }
            existing.setMaxCapacity(request.getMaxCapacity());
        }
        if (request.getActiveFlag() != null) {
            existing.setActiveFlag(request.getActiveFlag());
        }

        LotLocation saved = lotLocationRepository.save(existing);
        log.info("Updated lot location dealerCode={}, locationCode={}", saved.getDealerCode(), saved.getLocationCode());
        return toResponse(saved);
    }

    /**
     * Soft-deactivate a lot location by setting activeFlag to 'N'.
     */
    @Transactional
    @Auditable(action = "DEL", entity = "lot_location", keyExpression = "#dealerCode + '-' + #locationCode")
    public LotLocationResponse deactivateLocation(String dealerCode, String locationCode) {
        log.info("Deactivating lot location dealerCode={}, locationCode={}", dealerCode, locationCode);

        LotLocation existing = findLocationOrThrow(dealerCode, locationCode);

        if ("N".equals(existing.getActiveFlag())) {
            throw new BusinessValidationException(
                    "Lot location is already inactive: " + dealerCode + "/" + locationCode);
        }

        existing.setActiveFlag("N");

        LotLocation saved = lotLocationRepository.save(existing);
        log.info("Deactivated lot location dealerCode={}, locationCode={}", saved.getDealerCode(), saved.getLocationCode());
        return toResponse(saved);
    }

    /**
     * Assign a vehicle to a lot location, adjusting capacity counts at old and new locations.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "lot_location", keyExpression = "#vin + '->' + #dealerCode + '/' + #locationCode")
    public void assignVehicleToLocation(String vin, String dealerCode, String locationCode) {
        log.info("Assigning vehicle vin={} to lot location dealerCode={}, locationCode={}", vin, dealerCode, locationCode);

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        LotLocation newLocation = findLocationOrThrow(dealerCode, locationCode);

        if ("N".equals(newLocation.getActiveFlag())) {
            throw new BusinessValidationException(
                    "Cannot assign vehicle to inactive location: " + dealerCode + "/" + locationCode);
        }

        if (newLocation.getCurrentCount() >= newLocation.getMaxCapacity()) {
            throw new BusinessValidationException(
                    "Location " + dealerCode + "/" + locationCode + " is at full capacity ("
                            + newLocation.getMaxCapacity() + ")");
        }

        // Decrement count at old location if vehicle was previously assigned
        String oldLocationCode = vehicle.getLotLocation();
        if (oldLocationCode != null && !oldLocationCode.isBlank()) {
            LotLocationId oldId = new LotLocationId(vehicle.getDealerCode(), oldLocationCode);
            lotLocationRepository.findById(oldId).ifPresent(oldLocation -> {
                if (oldLocation.getCurrentCount() > 0) {
                    oldLocation.setCurrentCount((short) (oldLocation.getCurrentCount() - 1));
                    lotLocationRepository.save(oldLocation);
                    log.debug("Decremented count at old location dealerCode={}, locationCode={}",
                            oldLocation.getDealerCode(), oldLocation.getLocationCode());
                }
            });
        }

        // Increment count at new location
        newLocation.setCurrentCount((short) (newLocation.getCurrentCount() + 1));
        lotLocationRepository.save(newLocation);

        // Update vehicle's lot location
        vehicle.setLotLocation(locationCode);
        vehicleRepository.save(vehicle);

        log.info("Assigned vehicle vin={} to location dealerCode={}, locationCode={}", vin, dealerCode, locationCode);
    }

    // ── Private helpers ──────────────────────────────────────────────────

    private LotLocation findLocationOrThrow(String dealerCode, String locationCode) {
        LotLocationId id = new LotLocationId(dealerCode, locationCode);
        return lotLocationRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("LotLocation", dealerCode + "/" + locationCode));
    }

    private void validateLocationType(String locationType) {
        if (locationType == null || !VALID_LOCATION_TYPES.contains(locationType)) {
            throw new BusinessValidationException(
                    "Invalid location type '" + locationType + "'. Must be one of: L (Lot), S (Showroom), V (Service), O (Offsite)");
        }
    }

    private void validateCapacity(Short maxCapacity) {
        if (maxCapacity == null || maxCapacity <= 0) {
            throw new BusinessValidationException("Max capacity must be greater than 0");
        }
    }

    private LotLocationResponse toResponse(LotLocation entity) {
        int available = entity.getMaxCapacity() - entity.getCurrentCount();
        BigDecimal utilization = entity.getMaxCapacity() > 0
                ? BigDecimal.valueOf(entity.getCurrentCount())
                        .multiply(BigDecimal.valueOf(100))
                        .divide(BigDecimal.valueOf(entity.getMaxCapacity()), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return LotLocationResponse.builder()
                .dealerCode(entity.getDealerCode())
                .locationCode(entity.getLocationCode())
                .locationDesc(entity.getLocationDesc())
                .locationType(entity.getLocationType())
                .maxCapacity(entity.getMaxCapacity())
                .currentCount(entity.getCurrentCount())
                .activeFlag(entity.getActiveFlag())
                .availableSpots(available)
                .utilizationPct(utilization)
                .build();
    }
}
