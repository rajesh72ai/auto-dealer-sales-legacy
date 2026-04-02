package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.ValidationReportResponse;
import com.autosales.modules.batch.dto.ValidationReportResponse.ValidationException;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Data validation/integrity batch service.
 * Port of BATVAL00.cbl — four-phase weekly validation:
 * Phase 1: Orphaned deals (deals without valid customers)
 * Phase 2: Orphaned vehicles (vehicles without valid dealers)
 * Phase 3: VIN checksum validation
 * Phase 4: Duplicate customer detection
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class ValidationBatchService {

    private static final String PROGRAM_ID = "BATVAL00";

    private final BatchControlRepository batchControlRepository;
    private final SalesDealRepository salesDealRepository;
    private final CustomerRepository customerRepository;
    private final VehicleRepository vehicleRepository;
    private final DealerRepository dealerRepository;

    // ── Read-only report generation ───────────────────────────────────

    public ValidationReportResponse generateValidationReport() {
        log.info("BATVAL00: Generating validation report");

        List<ValidationException> orphanedDeals = findOrphanedDeals();
        List<ValidationException> orphanedVehicles = findOrphanedVehicles();
        List<ValidationException> invalidVins = validateVinChecksums();
        List<ValidationException> duplicateCustomers = findDuplicateCustomers();

        int total = orphanedDeals.size() + orphanedVehicles.size()
                + invalidVins.size() + duplicateCustomers.size();

        return ValidationReportResponse.builder()
                .generatedAt(LocalDateTime.now())
                .totalExceptions(total)
                .orphanedDeals(orphanedDeals)
                .orphanedVehicles(orphanedVehicles)
                .invalidVins(invalidVins)
                .duplicateCustomers(duplicateCustomers)
                .build();
    }

    // ── BATVAL00: Run Full Validation ─────────────────────────────────

    @Transactional
    public BatchRunResult runValidation() {
        log.info("BATVAL00: Starting data validation batch");
        LocalDateTime startedAt = LocalDateTime.now();
        List<String> phases = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        ValidationReportResponse report = generateValidationReport();

        phases.add("Phase 1: Orphaned deals — " + report.getOrphanedDeals().size() + " found");
        phases.add("Phase 2: Orphaned vehicles — " + report.getOrphanedVehicles().size() + " found");
        phases.add("Phase 3: Invalid VINs — " + report.getInvalidVins().size() + " found");
        phases.add("Phase 4: Duplicate customers — " + report.getDuplicateCustomers().size() + " found");

        // Flag invalid VINs (BATVAL00 sets DAMAGE_FLAG='Y', DAMAGE_DESC='VIN CHECKSUM FAILED')
        int flagged = flagInvalidVins(report.getInvalidVins());
        if (flagged > 0) {
            warnings.add(flagged + " vehicles flagged with invalid VIN checksums");
        }

        updateBatchControl(report.getTotalExceptions());

        return BatchRunResult.builder()
                .programId(PROGRAM_ID)
                .status("OK")
                .recordsProcessed(report.getTotalExceptions())
                .recordsError(0)
                .startedAt(startedAt)
                .completedAt(LocalDateTime.now())
                .phases(phases)
                .warnings(warnings)
                .build();
    }

    /**
     * Phase 1: Find deals where CUSTOMER_ID has no matching CUSTOMER row.
     * Ported from BATVAL00 CHECK-ORPHAN-DEALS — NOT EXISTS subquery.
     */
    List<ValidationException> findOrphanedDeals() {
        Set<Integer> validCustomerIds = customerRepository.findAll().stream()
                .map(Customer::getCustomerId)
                .collect(Collectors.toSet());

        return salesDealRepository.findAll().stream()
                .filter(d -> !"CA".equals(d.getDealStatus()) && !"UW".equals(d.getDealStatus()))
                .filter(d -> d.getCustomerId() != null && !validCustomerIds.contains(d.getCustomerId()))
                .map(d -> ValidationException.builder()
                        .entityType("SALES_DEAL")
                        .entityId(d.getDealNumber())
                        .description("Deal references non-existent customer ID " + d.getCustomerId())
                        .severity("HIGH")
                        .build())
                .toList();
    }

    /**
     * Phase 2: Find vehicles where DEALER_CODE has no matching DEALER row.
     * Ported from BATVAL00 CHECK-ORPHAN-VEHICLES.
     */
    List<ValidationException> findOrphanedVehicles() {
        Set<String> validDealerCodes = dealerRepository.findAll().stream()
                .map(d -> d.getDealerCode())
                .collect(Collectors.toSet());

        return vehicleRepository.findAll().stream()
                .filter(v -> v.getDealerCode() != null && !validDealerCodes.contains(v.getDealerCode()))
                .map(v -> ValidationException.builder()
                        .entityType("VEHICLE")
                        .entityId(v.getVin())
                        .description("Vehicle references non-existent dealer " + v.getDealerCode())
                        .severity("HIGH")
                        .build())
                .toList();
    }

    /**
     * Phase 3: Validate VIN checksums using ISO 3779 algorithm.
     * Ported from BATVAL00 VALIDATE-VIN-CHECKSUMS which calls COMVINL0 'VALD'.
     * Standard VIN checksum: position 9 is the check digit.
     */
    List<ValidationException> validateVinChecksums() {
        return vehicleRepository.findAll().stream()
                .filter(v -> v.getVin() != null && !isValidVinChecksum(v.getVin()))
                .map(v -> ValidationException.builder()
                        .entityType("VEHICLE")
                        .entityId(v.getVin())
                        .description("VIN checksum validation failed")
                        .severity("MEDIUM")
                        .build())
                .toList();
    }

    /**
     * Phase 4: Find duplicate customers by LAST_NAME + FIRST_NAME + DOB + DEALER_CODE.
     * Ported from BATVAL00 CHECK-DUPLICATE-CUSTOMERS self-join.
     */
    List<ValidationException> findDuplicateCustomers() {
        List<Customer> allCustomers = customerRepository.findAll();
        List<ValidationException> dupes = new ArrayList<>();

        // Group by (lastName, firstName, DOB, dealerCode) — same logic as COBOL self-join
        var grouped = allCustomers.stream()
                .filter(c -> c.getLastName() != null && c.getFirstName() != null)
                .collect(Collectors.groupingBy(c ->
                        c.getLastName().trim().toUpperCase() + "|" +
                        c.getFirstName().trim().toUpperCase() + "|" +
                        (c.getDateOfBirth() != null ? c.getDateOfBirth().toString() : "") + "|" +
                        (c.getDealerCode() != null ? c.getDealerCode() : "")));

        grouped.forEach((key, customers) -> {
            if (customers.size() > 1) {
                // Report all pairs (C1.ID < C2.ID, matching COBOL logic)
                for (int i = 0; i < customers.size() - 1; i++) {
                    for (int j = i + 1; j < customers.size(); j++) {
                        dupes.add(ValidationException.builder()
                                .entityType("CUSTOMER")
                                .entityId(customers.get(i).getCustomerId() + "/" + customers.get(j).getCustomerId())
                                .description("Potential duplicate: " + customers.get(i).getLastName()
                                        + ", " + customers.get(i).getFirstName())
                                .severity("LOW")
                                .build());
                    }
                }
            }
        });
        return dupes;
    }

    /**
     * Flag vehicles with invalid VIN checksums.
     * Legacy: Sets DAMAGE_FLAG = 'Y' and DAMAGE_DESC = 'VIN CHECKSUM FAILED'.
     */
    @Transactional
    int flagInvalidVins(List<ValidationException> invalidVins) {
        int count = 0;
        for (ValidationException ve : invalidVins) {
            Optional<Vehicle> vOpt = vehicleRepository.findById(ve.getEntityId());
            if (vOpt.isPresent()) {
                Vehicle v = vOpt.get();
                v.setDamageFlag("Y");
                v.setDamageDesc("VIN CHECKSUM FAILED");
                v.setUpdatedTs(LocalDateTime.now());
                vehicleRepository.save(v);
                count++;
            }
        }
        return count;
    }

    /**
     * ISO 3779 VIN checksum validation.
     * Port of COMVINL0 'VALD' function from the legacy codebase.
     * The check digit is at position 9 (index 8).
     */
    static boolean isValidVinChecksum(String vin) {
        if (vin == null || vin.length() != 17) {
            return false;
        }

        String transliteration = "0123456789.ABCDEFGH..JKLMN.P.R..STUVWXYZ";
        int[] weights = {8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2};

        int sum = 0;
        for (int i = 0; i < 17; i++) {
            char c = vin.charAt(i);
            int value;
            int idx = transliteration.indexOf(c);
            if (idx < 0) {
                return false; // Invalid character
            }
            value = idx % 10;
            sum += value * weights[i];
        }

        int remainder = sum % 11;
        char checkDigit = remainder == 10 ? 'X' : (char) ('0' + remainder);
        return vin.charAt(8) == checkDigit;
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
