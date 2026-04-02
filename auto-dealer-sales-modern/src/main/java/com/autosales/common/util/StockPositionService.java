package com.autosales.common.util;

import com.autosales.modules.vehicle.entity.StockPosition;
import com.autosales.modules.vehicle.entity.StockPositionId;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.entity.VehicleStatusHist;
import com.autosales.modules.vehicle.entity.VehicleStatusHistId;
import com.autosales.modules.vehicle.repository.StockPositionRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import com.autosales.modules.vehicle.repository.VehicleStatusHistRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Single point of stock-position mutation for all vehicle inventory operations.
 * Port of COMSTCK0.cbl — stock position update module.
 *
 * <p>Manages vehicle status transitions and stock position count updates atomically.
 * Every status change is recorded in VEHICLE_STATUS_HIST for audit trail.</p>
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class StockPositionService {

    private final VehicleRepository vehicleRepository;
    private final StockPositionRepository stockPositionRepository;
    private final VehicleStatusHistRepository vehicleStatusHistRepository;

    /**
     * Receive a vehicle into dealer stock.
     * Sets status to AV (Available), increments on_hand count.
     */
    @Transactional
    public StockUpdateResult processReceive(String vin, String dealerCode, String userId, String reason) {
        log.info("STOCK RECEIVE: vin={}, dealer={}, user={}, reason={}", vin, dealerCode, userId, reason);

        Vehicle vehicle = vehicleRepository.findById(vin).orElse(null);
        if (vehicle == null) {
            return new StockUpdateResult(vin, "NONE", "NONE", dealerCode, false, "Vehicle not found");
        }

        String oldStatus = vehicle.getVehicleStatus();
        vehicle.setVehicleStatus("AV");
        vehicle.setDealerCode(dealerCode);
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        // Increment on_hand, decrement in_transit if was IT/AL
        updateStockCounts(dealerCode, vehicle, counts -> {
            counts.setOnHandCount((short) (counts.getOnHandCount() + 1));
            if ("IT".equals(oldStatus)) {
                counts.setInTransitCount((short) Math.max(0, counts.getInTransitCount() - 1));
            } else if ("AL".equals(oldStatus)) {
                counts.setAllocatedCount((short) Math.max(0, counts.getAllocatedCount() - 1));
            }
        });

        recordStatusHistory(vin, oldStatus, "AV", userId, reason);
        return new StockUpdateResult(vin, oldStatus, "AV", dealerCode, true, "Vehicle received into stock");
    }

    /**
     * Mark a vehicle as sold.
     * Sets status to SD (Sold), decrements on_hand, increments sold_mtd and sold_ytd.
     */
    @Transactional
    public StockUpdateResult processSold(String vin, String dealerCode, String userId, String reason) {
        log.info("STOCK SOLD: vin={}, dealer={}, user={}, reason={}", vin, dealerCode, userId, reason);

        Vehicle vehicle = vehicleRepository.findById(vin).orElse(null);
        if (vehicle == null) {
            return new StockUpdateResult(vin, "NONE", "NONE", dealerCode, false, "Vehicle not found");
        }

        String oldStatus = vehicle.getVehicleStatus();
        vehicle.setVehicleStatus("SD");
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        updateStockCounts(dealerCode, vehicle, counts -> {
            counts.setOnHandCount((short) Math.max(0, counts.getOnHandCount() - 1));
            counts.setSoldMtd((short) (counts.getSoldMtd() + 1));
            counts.setSoldYtd((short) (counts.getSoldYtd() + 1));
        });

        recordStatusHistory(vin, oldStatus, "SD", userId, reason);
        return new StockUpdateResult(vin, oldStatus, "SD", dealerCode, true, "Vehicle marked as sold");
    }

    /**
     * Place a vehicle on hold.
     * Sets status to HD (Hold), decrements on_hand, increments on_hold.
     */
    @Transactional
    public StockUpdateResult processHold(String vin, String dealerCode, String userId, String reason) {
        log.info("STOCK HOLD: vin={}, dealer={}, user={}, reason={}", vin, dealerCode, userId, reason);

        Vehicle vehicle = vehicleRepository.findById(vin).orElse(null);
        if (vehicle == null) {
            return new StockUpdateResult(vin, "NONE", "NONE", dealerCode, false, "Vehicle not found");
        }

        String oldStatus = vehicle.getVehicleStatus();
        vehicle.setVehicleStatus("HD");
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        updateStockCounts(dealerCode, vehicle, counts -> {
            counts.setOnHandCount((short) Math.max(0, counts.getOnHandCount() - 1));
            counts.setOnHoldCount((short) (counts.getOnHoldCount() + 1));
        });

        recordStatusHistory(vin, oldStatus, "HD", userId, reason);
        return new StockUpdateResult(vin, oldStatus, "HD", dealerCode, true, "Vehicle placed on hold");
    }

    /**
     * Release a vehicle from hold back to available.
     * Sets status to AV (Available), decrements on_hold, increments on_hand.
     */
    @Transactional
    public StockUpdateResult processRelease(String vin, String dealerCode, String userId, String reason) {
        log.info("STOCK RELEASE: vin={}, dealer={}, user={}, reason={}", vin, dealerCode, userId, reason);

        Vehicle vehicle = vehicleRepository.findById(vin).orElse(null);
        if (vehicle == null) {
            return new StockUpdateResult(vin, "NONE", "NONE", dealerCode, false, "Vehicle not found");
        }

        String oldStatus = vehicle.getVehicleStatus();
        vehicle.setVehicleStatus("AV");
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        updateStockCounts(dealerCode, vehicle, counts -> {
            counts.setOnHoldCount((short) Math.max(0, counts.getOnHoldCount() - 1));
            counts.setOnHandCount((short) (counts.getOnHandCount() + 1));
        });

        recordStatusHistory(vin, oldStatus, "AV", userId, reason);
        return new StockUpdateResult(vin, oldStatus, "AV", dealerCode, true, "Vehicle released from hold");
    }

    /**
     * Receive a vehicle via dealer-to-dealer transfer.
     * Sets status to AV at destination dealer, updates counts.
     */
    @Transactional
    public StockUpdateResult processTransferIn(String vin, String dealerCode, String userId, String reason) {
        log.info("STOCK TRANSFER-IN: vin={}, dealer={}, user={}, reason={}", vin, dealerCode, userId, reason);

        Vehicle vehicle = vehicleRepository.findById(vin).orElse(null);
        if (vehicle == null) {
            return new StockUpdateResult(vin, "NONE", "NONE", dealerCode, false, "Vehicle not found");
        }

        String oldStatus = vehicle.getVehicleStatus();
        vehicle.setVehicleStatus("AV");
        vehicle.setDealerCode(dealerCode);
        vehicle.setDaysInStock((short) 0);
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        // Increment on_hand at destination
        updateStockCounts(dealerCode, vehicle, counts -> {
            counts.setOnHandCount((short) (counts.getOnHandCount() + 1));
        });

        recordStatusHistory(vin, oldStatus, "AV", userId, reason);
        return new StockUpdateResult(vin, oldStatus, "AV", dealerCode, true, "Vehicle transfer received");
    }

    /**
     * Send a vehicle out via dealer-to-dealer transfer.
     * Sets status to TR (Transfer), decrements on_hand at source.
     */
    @Transactional
    public StockUpdateResult processTransferOut(String vin, String dealerCode, String userId, String reason) {
        log.info("STOCK TRANSFER-OUT: vin={}, dealer={}, user={}, reason={}", vin, dealerCode, userId, reason);

        Vehicle vehicle = vehicleRepository.findById(vin).orElse(null);
        if (vehicle == null) {
            return new StockUpdateResult(vin, "NONE", "NONE", dealerCode, false, "Vehicle not found");
        }

        String oldStatus = vehicle.getVehicleStatus();
        vehicle.setVehicleStatus("TR");
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        // Decrement on_hand at source
        updateStockCounts(dealerCode, vehicle, counts -> {
            counts.setOnHandCount((short) Math.max(0, counts.getOnHandCount() - 1));
        });

        recordStatusHistory(vin, oldStatus, "TR", userId, reason);
        return new StockUpdateResult(vin, oldStatus, "TR", dealerCode, true, "Vehicle transferred out");
    }

    /**
     * Allocate a vehicle (factory allocation to dealer).
     * Sets status to AL (Allocated), increments allocated count.
     */
    @Transactional
    public StockUpdateResult processAllocate(String vin, String dealerCode, String userId, String reason) {
        log.info("STOCK ALLOCATE: vin={}, dealer={}, user={}, reason={}", vin, dealerCode, userId, reason);

        Vehicle vehicle = vehicleRepository.findById(vin).orElse(null);
        if (vehicle == null) {
            return new StockUpdateResult(vin, "NONE", "NONE", dealerCode, false, "Vehicle not found");
        }

        String oldStatus = vehicle.getVehicleStatus();
        vehicle.setVehicleStatus("AL");
        vehicle.setDealerCode(dealerCode);
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        updateStockCounts(dealerCode, vehicle, counts -> {
            counts.setAllocatedCount((short) (counts.getAllocatedCount() + 1));
        });

        recordStatusHistory(vin, oldStatus, "AL", userId, reason);
        return new StockUpdateResult(vin, oldStatus, "AL", dealerCode, true, "Vehicle allocated to dealer");
    }

    // --- Private helpers ---

    @FunctionalInterface
    private interface StockCountUpdater {
        void update(StockPosition position);
    }

    private void updateStockCounts(String dealerCode, Vehicle vehicle, StockCountUpdater updater) {
        StockPositionId id = new StockPositionId(
                dealerCode, vehicle.getModelYear(), vehicle.getMakeCode(), vehicle.getModelCode());
        StockPosition position = stockPositionRepository.findById(id)
                .orElse(StockPosition.builder()
                        .dealerCode(dealerCode)
                        .modelYear(vehicle.getModelYear())
                        .makeCode(vehicle.getMakeCode())
                        .modelCode(vehicle.getModelCode())
                        .onHandCount((short) 0)
                        .inTransitCount((short) 0)
                        .allocatedCount((short) 0)
                        .onHoldCount((short) 0)
                        .soldMtd((short) 0)
                        .soldYtd((short) 0)
                        .reorderPoint((short) 3)
                        .build());

        updater.update(position);
        position.setUpdatedTs(LocalDateTime.now());
        stockPositionRepository.save(position);
    }

    private void recordStatusHistory(String vin, String oldStatus, String newStatus,
                                      String userId, String reason) {
        // Get next sequence number for this VIN
        int nextSeq = vehicleStatusHistRepository.findTopByVinOrderByStatusSeqDesc(vin)
                .map(h -> h.getStatusSeq() + 1)
                .orElse(1);

        VehicleStatusHist hist = VehicleStatusHist.builder()
                .vin(vin)
                .statusSeq(nextSeq)
                .oldStatus(oldStatus)
                .newStatus(newStatus)
                .changedBy(userId)
                .changeReason(reason)
                .changedTs(LocalDateTime.now())
                .build();
        vehicleStatusHistRepository.save(hist);
    }
}
