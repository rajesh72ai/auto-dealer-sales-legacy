package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.*;
import com.autosales.modules.batch.dto.CrmExtractResponse.CrmCustomerRecord;
import com.autosales.modules.batch.dto.DataLakeExtractResponse.DataLakeRecord;
import com.autosales.modules.batch.dto.DmsExtractResponse.*;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.common.audit.AuditLog;
import com.autosales.common.audit.AuditLogRepository;
import com.autosales.modules.admin.entity.Dealer;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Integration batch service covering three legacy extract programs:
 *
 * BATCRM00.cbl — CRM feed extract (changed customers + purchase history)
 * BATDLAKE.cbl — Data lake extract (audit-log-driven CDC)
 * BATDMS00.cbl — DMS interface extract (dealer inventory + deal sync)
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class IntegrationBatchService {

    private final BatchControlRepository batchControlRepository;
    private final CustomerRepository customerRepository;
    private final SalesDealRepository salesDealRepository;
    private final AuditLogRepository auditLogRepository;
    private final DealerRepository dealerRepository;
    private final VehicleRepository vehicleRepository;

    // ── BATCRM00: CRM Feed Extract ────────────────────────────────────

    /**
     * Port of BATCRM00.cbl — extracts changed customers since last run date,
     * with purchase history summaries (COUNT, SUM, MAX from SALES_DEAL).
     */
    @Transactional
    public CrmExtractResponse runCrmExtract() {
        log.info("BATCRM00: Starting CRM feed extraction");
        String programId = "BATCRM00";

        // Get last run date from batch_control (legacy: defaults to 1900-01-01)
        LocalDate lastRunDate = batchControlRepository.findById(programId)
                .map(BatchControl::getLastRunDate)
                .orElse(LocalDate.of(1900, 1, 1));

        // Select customers updated since last run
        List<Customer> changedCustomers = customerRepository.findAll().stream()
                .filter(c -> c.getUpdatedTs() != null
                        && c.getUpdatedTs().toLocalDate().isAfter(lastRunDate))
                .toList();

        List<CrmCustomerRecord> records = new ArrayList<>();
        for (Customer cust : changedCustomers) {
            // Aggregate purchase history — COUNT(*), SUM(TOTAL_PRICE), MAX(DEAL_DATE)
            List<SalesDeal> custDeals = salesDealRepository.findByCustomerId(cust.getCustomerId())
                    .stream()
                    .filter(d -> "DL".equals(d.getDealStatus()) || "SD".equals(d.getDealStatus()))
                    .toList();

            int totalDeals = custDeals.size();
            BigDecimal totalSpent = custDeals.stream()
                    .map(SalesDeal::getTotalPrice)
                    .filter(p -> p != null)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            LocalDate lastDealDate = custDeals.stream()
                    .map(SalesDeal::getDealDate)
                    .filter(d -> d != null)
                    .max(LocalDate::compareTo)
                    .orElse(null);

            records.add(CrmCustomerRecord.builder()
                    .customerId(cust.getCustomerId())
                    .firstName(cust.getFirstName())
                    .lastName(cust.getLastName())
                    .email(cust.getEmail())
                    .cellPhone(cust.getCellPhone())
                    .dealerCode(cust.getDealerCode())
                    .totalDeals(totalDeals)
                    .totalSpent(totalSpent)
                    .lastDealDate(lastDealDate)
                    .extractDate(LocalDate.now())
                    .build());
        }

        // Update batch control
        updateBatchControl(programId, records.size());

        log.info("BATCRM00: Extracted {} customer records", records.size());
        return CrmExtractResponse.builder()
                .extractedAt(LocalDateTime.now())
                .customersExtracted(records.size())
                .records(records)
                .build();
    }

    // ── BATDLAKE: Data Lake Extract ───────────────────────────────────

    /**
     * Port of BATDLAKE.cbl — reads today's AUDIT_LOG entries, extracts
     * full current row from the changed source table, produces JSON-like output.
     */
    public DataLakeExtractResponse runDataLakeExtract() {
        log.info("BATDLAKE: Starting data lake extraction");
        LocalDate today = LocalDate.now();

        List<AuditLog> todayLogs = auditLogRepository.findAll().stream()
                .filter(a -> a.getAuditTs() != null
                        && a.getAuditTs().toLocalDate().equals(today))
                .toList();

        List<DataLakeRecord> records = new ArrayList<>();
        int errorCount = 0;

        for (AuditLog al : todayLogs) {
            String payload = extractPayload(al.getTableName(), al.getKeyValue());
            if (payload != null) {
                records.add(DataLakeRecord.builder()
                        .tableName(al.getTableName())
                        .keyValue(al.getKeyValue())
                        .actionType(al.getActionType())
                        .auditTs(al.getAuditTs())
                        .payload(payload)
                        .build());
            } else {
                errorCount++;
            }
        }

        updateBatchControl("BATDLAKE", records.size());

        log.info("BATDLAKE: Extracted {} records, {} errors", records.size(), errorCount);
        return DataLakeExtractResponse.builder()
                .extractedAt(LocalDateTime.now())
                .totalRecords(records.size())
                .errorCount(errorCount)
                .records(records)
                .build();
    }

    // ── BATDMS00: DMS Interface Extract ───────────────────────────────

    /**
     * Port of BATDMS00.cbl — iterates active dealers, extracts inventory
     * (status AV/HD/TR) and recent deals per dealer for DMS sync.
     */
    @Transactional
    public DmsExtractResponse runDmsExtract() {
        log.info("BATDMS00: Starting DMS interface extraction");
        String programId = "BATDMS00";

        LocalDate lastSyncDate = batchControlRepository.findById(programId)
                .map(BatchControl::getLastSyncDate)
                .orElse(LocalDate.of(1900, 1, 1));

        List<Dealer> activeDealers = dealerRepository.findByActiveFlagOrderByDealerName("Y");
        List<DmsDealerBlock> dealerBlocks = new ArrayList<>();
        int totalInventory = 0;
        int totalDeals = 0;

        for (Dealer dealer : activeDealers) {
            String dc = dealer.getDealerCode();

            // Inventory: vehicles in status AV/HD/TR
            List<DmsInventoryRecord> inventory = vehicleRepository.findAll().stream()
                    .filter(v -> dc.equals(v.getDealerCode()))
                    .filter(v -> List.of("AV", "HD", "TR").contains(v.getVehicleStatus()))
                    .map(v -> DmsInventoryRecord.builder()
                            .vin(v.getVin())
                            .makeCode(v.getMakeCode())
                            .modelCode(v.getModelCode())
                            .modelYear(v.getModelYear())
                            .exteriorColor(v.getExteriorColor())
                            .vehicleStatus(v.getVehicleStatus())
                            .daysInStock(v.getDaysInStock())
                            .msrp(BigDecimal.ZERO) // MSRP from price master, simplified
                            .build())
                    .toList();

            // Deals since last sync
            List<DmsDealRecord> deals = salesDealRepository.findAll().stream()
                    .filter(d -> dc.equals(d.getDealerCode()))
                    .filter(d -> d.getDealDate() != null && d.getDealDate().isAfter(lastSyncDate))
                    .map(d -> {
                        String custName = getCustomerName(d.getCustomerId());
                        return DmsDealRecord.builder()
                                .dealNumber(d.getDealNumber())
                                .customerName(custName)
                                .vin(d.getVin())
                                .dealType(d.getDealType())
                                .dealStatus(d.getDealStatus())
                                .totalPrice(d.getTotalPrice())
                                .dealDate(d.getDealDate())
                                .build();
                    })
                    .toList();

            if (!inventory.isEmpty() || !deals.isEmpty()) {
                dealerBlocks.add(DmsDealerBlock.builder()
                        .dealerCode(dc)
                        .dealerName(dealer.getDealerName())
                        .inventory(inventory)
                        .deals(deals)
                        .build());
                totalInventory += inventory.size();
                totalDeals += deals.size();
            }
        }

        // Update sync date
        updateBatchControlWithSync(programId, totalInventory + totalDeals);

        log.info("BATDMS00: Extracted {} dealers, {} inventory, {} deals",
                dealerBlocks.size(), totalInventory, totalDeals);
        return DmsExtractResponse.builder()
                .extractedAt(LocalDateTime.now())
                .dealersProcessed(dealerBlocks.size())
                .inventoryRecords(totalInventory)
                .dealRecords(totalDeals)
                .dealers(dealerBlocks)
                .build();
    }

    /**
     * Table dispatch for data lake extraction.
     * Ported from BATDLAKE EVALUATE TABLE_NAME logic.
     */
    private String extractPayload(String tableName, String keyValue) {
        if (tableName == null || keyValue == null) return null;

        return switch (tableName.toUpperCase()) {
            case "SALES_DEAL" -> salesDealRepository.findById(keyValue)
                    .map(d -> String.format("{\"dealNumber\":\"%s\",\"status\":\"%s\",\"total\":%s}",
                            d.getDealNumber(), d.getDealStatus(), d.getTotalPrice()))
                    .orElse(null);
            case "VEHICLE" -> vehicleRepository.findById(keyValue)
                    .map(v -> String.format("{\"vin\":\"%s\",\"status\":\"%s\",\"dealer\":\"%s\"}",
                            v.getVin(), v.getVehicleStatus(), v.getDealerCode()))
                    .orElse(null);
            case "CUSTOMER" -> {
                try {
                    int custId = Integer.parseInt(keyValue);
                    yield customerRepository.findById(custId)
                            .map(c -> String.format("{\"customerId\":%d,\"name\":\"%s %s\",\"dealer\":\"%s\"}",
                                    c.getCustomerId(), c.getFirstName(), c.getLastName(), c.getDealerCode()))
                            .orElse(null);
                } catch (NumberFormatException e) {
                    yield null;
                }
            }
            default -> null;
        };
    }

    private String getCustomerName(Integer customerId) {
        if (customerId == null) return "";
        return customerRepository.findById(customerId)
                .map(c -> c.getLastName() + ", " + c.getFirstName())
                .orElse("");
    }

    private void updateBatchControl(String programId, int recordsProcessed) {
        LocalDateTime now = LocalDateTime.now();
        BatchControl control = batchControlRepository.findById(programId)
                .orElse(BatchControl.builder()
                        .programId(programId)
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

    private void updateBatchControlWithSync(String programId, int recordsProcessed) {
        LocalDateTime now = LocalDateTime.now();
        BatchControl control = batchControlRepository.findById(programId)
                .orElse(BatchControl.builder()
                        .programId(programId)
                        .recordsProcessed(0)
                        .runStatus("OK")
                        .createdTs(now)
                        .updatedTs(now)
                        .build());
        control.setLastRunDate(LocalDate.now());
        control.setLastSyncDate(LocalDate.now());
        control.setRecordsProcessed(recordsProcessed);
        control.setRunStatus("OK");
        control.setUpdatedTs(now);
        batchControlRepository.save(control);
    }
}
