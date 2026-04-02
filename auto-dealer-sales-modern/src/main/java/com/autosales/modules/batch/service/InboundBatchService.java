package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.InboundProcessingResponse;
import com.autosales.modules.batch.dto.InboundProcessingResponse.RejectedRecord;
import com.autosales.modules.batch.dto.InboundVehicleRequest;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import com.autosales.modules.admin.repository.ModelMasterRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Inbound data feed processing service.
 * Port of BATINB00.cbl — processes manufacturer vehicle allocation feeds:
 * - Validates each record (type, VIN, make, model year, dealer, invoice)
 * - Inserts new vehicles into VEHICLE table
 * - Auto-creates MODEL_MASTER entries for new model codes
 * - Tracks rejected records with reason codes
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class InboundBatchService {

    private static final String PROGRAM_ID = "BATINB00";

    private final BatchControlRepository batchControlRepository;
    private final VehicleRepository vehicleRepository;
    private final ModelMasterRepository modelMasterRepository;

    // ── BATINB00: Process Inbound Feed ────────────────────────────────

    @Transactional
    public InboundProcessingResponse processInboundFeed(List<InboundVehicleRequest> records) {
        log.info("BATINB00: Processing {} inbound allocation records", records.size());

        List<RejectedRecord> rejections = new ArrayList<>();
        int accepted = 0;

        for (InboundVehicleRequest record : records) {
            String rejectReason = validateRecord(record);
            if (rejectReason != null) {
                rejections.add(RejectedRecord.builder()
                        .vin(record.getVin())
                        .reasonCode(rejectReason)
                        .description(getRejectDescription(rejectReason))
                        .build());
                continue;
            }

            // Check for duplicate VIN (legacy: COUNT(*) on VEHICLE by VIN)
            if (vehicleRepository.findById(record.getVin()).isPresent()) {
                rejections.add(RejectedRecord.builder()
                        .vin(record.getVin())
                        .reasonCode("DUP-VIN")
                        .description("Duplicate VIN already exists in inventory")
                        .build());
                continue;
            }

            // Insert vehicle with initial status AV (Available)
            Vehicle vehicle = Vehicle.builder()
                    .vin(record.getVin())
                    .makeCode(record.getMakeCode())
                    .modelCode(record.getModelCode())
                    .modelYear(record.getModelYear())
                    .exteriorColor(record.getExteriorColor())
                    .interiorColor(record.getInteriorColor())
                    .vehicleStatus("AV")
                    .dealerCode(record.getDealerCode())
                    .daysInStock((short) 0)
                    .pdiComplete("N")
                    .damageFlag("N")
                    .odometer(0)
                    .receiveDate(LocalDate.now())
                    .createdTs(LocalDateTime.now())
                    .updatedTs(LocalDateTime.now())
                    .build();
            vehicleRepository.save(vehicle);

            // Auto-create model master if not exists (legacy: CHECK + INSERT)
            ensureModelMasterExists(record);

            accepted++;
            log.debug("BATINB00: VIN {} accepted", record.getVin());
        }

        updateBatchControl(accepted);

        log.info("BATINB00: Completed — {} accepted, {} rejected", accepted, rejections.size());
        return InboundProcessingResponse.builder()
                .processedAt(LocalDateTime.now())
                .totalRecords(records.size())
                .accepted(accepted)
                .rejected(rejections.size())
                .rejections(rejections)
                .build();
    }

    /**
     * Validate inbound record per BATINB00 validation rules:
     * - Record type must be VH or AL
     * - VIN must not be blank
     * - Make must not be blank
     * - Model year must be 2000-2030
     * - Dealer code required
     * - Invoice amount must be > 0
     */
    String validateRecord(InboundVehicleRequest record) {
        if (record.getRecordType() == null
                || (!"VH".equals(record.getRecordType()) && !"AL".equals(record.getRecordType()))) {
            return "INV-TYPE";
        }
        if (record.getVin() == null || record.getVin().isBlank()) {
            return "INV-VIN";
        }
        if (record.getMakeCode() == null || record.getMakeCode().isBlank()) {
            return "INV-MAKE";
        }
        if (record.getModelYear() == null || record.getModelYear() < 2000 || record.getModelYear() > 2030) {
            return "INV-YEAR";
        }
        if (record.getDealerCode() == null || record.getDealerCode().isBlank()) {
            return "INV-DLR";
        }
        if (record.getInvoiceAmount() == null || record.getInvoiceAmount().compareTo(BigDecimal.ZERO) <= 0) {
            return "INV-AMT";
        }
        return null; // valid
    }

    /**
     * Auto-create MODEL_MASTER entry if model code + year combination doesn't exist.
     * Ported from BATINB00 CHECK-MODEL-MASTER paragraph.
     */
    void ensureModelMasterExists(InboundVehicleRequest record) {
        ModelMasterId id = new ModelMasterId(record.getModelYear(), record.getMakeCode(), record.getModelCode());
        if (modelMasterRepository.findById(id).isEmpty()) {
            ModelMaster newModel = ModelMaster.builder()
                    .modelYear(record.getModelYear())
                    .makeCode(record.getMakeCode())
                    .modelCode(record.getModelCode())
                    .modelName(record.getModelCode()) // Default name from code
                    .bodyStyle("SD") // Default sedan
                    .trimLevel("BAS") // Default base
                    .engineType("GAS") // Default gas
                    .transmission("A") // Default automatic
                    .driveTrain("FWD") // Default front-wheel drive
                    .activeFlag("Y")
                    .createdTs(LocalDateTime.now())
                    .build();
            modelMasterRepository.save(newModel);
            log.debug("BATINB00: Created model master for {}/{}/{}",
                    record.getModelYear(), record.getMakeCode(), record.getModelCode());
        }
    }

    private String getRejectDescription(String reasonCode) {
        return switch (reasonCode) {
            case "INV-TYPE" -> "Invalid record type (must be VH or AL)";
            case "INV-VIN" -> "VIN is blank or missing";
            case "INV-MAKE" -> "Make code is blank or missing";
            case "INV-YEAR" -> "Model year out of range (2000-2030)";
            case "INV-DLR" -> "Dealer code is blank or missing";
            case "INV-AMT" -> "Invoice amount must be greater than zero";
            case "DUP-VIN" -> "Duplicate VIN already exists in inventory";
            default -> "Unknown rejection reason";
        };
    }

    private void updateBatchControl(int recordsProcessed) {
        LocalDateTime now = LocalDateTime.now();
        BatchControl control = batchControlRepository.findById(PROGRAM_ID)
                .orElse(BatchControl.builder()
                        .programId(PROGRAM_ID)
                        .recordsProcessed(0)
                        .runStatus("OK")
                        .createdTs(now)
                        .updatedTs(now)
                        .build());
        control.setLastRunDate(LocalDate.now());
        control.setRecordsProcessed(recordsProcessed);
        control.setRunStatus("OK");
        control.setUpdatedTs(now);
        batchControlRepository.save(control);
    }
}
