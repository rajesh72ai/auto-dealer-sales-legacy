package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.CrmExtractResponse;
import com.autosales.modules.batch.dto.DataLakeExtractResponse;
import com.autosales.modules.batch.dto.DmsExtractResponse;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for IntegrationBatchService — ports of:
 *   BATCRM00.cbl — CRM feed extract with purchase history aggregation
 *   BATDLAKE.cbl — Data lake CDC extract from audit log
 *   BATDMS00.cbl — DMS interface extract with dealer-nested structure
 */
@ExtendWith(MockitoExtension.class)
class IntegrationBatchServiceTest {

    @Mock private BatchControlRepository batchControlRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private SalesDealRepository salesDealRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private DealerRepository dealerRepository;
    @Mock private VehicleRepository vehicleRepository;

    @InjectMocks
    private IntegrationBatchService integrationBatchService;

    private Customer testCustomer;
    private SalesDeal testDeal;
    private Dealer testDealer;
    private Vehicle testVehicle;

    @BeforeEach
    void setUp() {
        testCustomer = Customer.builder()
                .customerId(100)
                .firstName("Jane")
                .lastName("Doe")
                .email("jane@example.com")
                .cellPhone("3035551234")
                .dealerCode("D0001")
                .updatedTs(LocalDateTime.now())
                .build();

        testDeal = SalesDeal.builder()
                .dealNumber("DL-CRM1")
                .customerId(100)
                .dealerCode("D0001")
                .dealStatus("DL")
                .totalPrice(new BigDecimal("45000.00"))
                .dealDate(LocalDate.of(2026, 2, 15))
                .build();

        testDealer = Dealer.builder()
                .dealerCode("D0001")
                .dealerName("Test Motors")
                .activeFlag("Y")
                .build();

        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .makeCode("HON")
                .modelCode("ACCORD")
                .modelYear((short) 2026)
                .exteriorColor("White")
                .vehicleStatus("AV")
                .dealerCode("D0001")
                .daysInStock((short) 15)
                .build();
    }

    // ── BATCRM00: CRM Extract ─────────────────────────────────────────

    @Test
    @DisplayName("BATCRM00: Extracts changed customers with purchase history aggregation")
    void runCrmExtract_aggregatesPurchaseHistory() {
        when(batchControlRepository.findById("BATCRM00")).thenReturn(Optional.of(
                BatchControl.builder().programId("BATCRM00").lastRunDate(LocalDate.of(1900, 1, 1))
                        .recordsProcessed(0).runStatus("OK")
                        .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now()).build()));
        when(customerRepository.findAll()).thenReturn(List.of(testCustomer));
        when(salesDealRepository.findByCustomerId(100)).thenReturn(List.of(testDeal));
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        CrmExtractResponse result = integrationBatchService.runCrmExtract();

        assertEquals(1, result.getCustomersExtracted());
        assertEquals(1, result.getRecords().get(0).getTotalDeals(),
                "BATCRM00: COUNT(*) of delivered deals for customer");
        assertEquals(new BigDecimal("45000.00"), result.getRecords().get(0).getTotalSpent(),
                "BATCRM00: SUM(TOTAL_PRICE) for delivered deals");
        assertEquals(LocalDate.of(2026, 2, 15), result.getRecords().get(0).getLastDealDate(),
                "BATCRM00: MAX(DEAL_DATE) for delivered deals");
    }

    @Test
    @DisplayName("BATCRM00: Customers updated before last run date are excluded")
    void runCrmExtract_respectsLastRunDate() {
        Customer oldCustomer = Customer.builder()
                .customerId(200)
                .firstName("Old")
                .lastName("Customer")
                .updatedTs(LocalDateTime.of(2025, 1, 1, 0, 0))
                .build();
        when(batchControlRepository.findById("BATCRM00")).thenReturn(Optional.of(
                BatchControl.builder().programId("BATCRM00").lastRunDate(LocalDate.of(2026, 3, 1))
                        .recordsProcessed(0).runStatus("OK")
                        .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now()).build()));
        when(customerRepository.findAll()).thenReturn(List.of(oldCustomer));
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        CrmExtractResponse result = integrationBatchService.runCrmExtract();

        assertEquals(0, result.getCustomersExtracted(),
                "BATCRM00: Only customers with LAST_UPDATED > last_run_date are extracted");
    }

    // ── BATDLAKE: Data Lake Extract ───────────────────────────────────

    @Test
    @DisplayName("BATDLAKE: Reads today's audit log and extracts source records")
    void runDataLakeExtract_extractsTodayChanges() {
        AuditLog auditEntry = new AuditLog();
        auditEntry.setAuditId(1);
        auditEntry.setTableName("VEHICLE");
        auditEntry.setKeyValue("1HGCM82633A004352");
        auditEntry.setActionType("UPDATE");
        auditEntry.setAuditTs(LocalDateTime.now());

        when(auditLogRepository.findAll()).thenReturn(List.of(auditEntry));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(batchControlRepository.findById("BATDLAKE")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        DataLakeExtractResponse result = integrationBatchService.runDataLakeExtract();

        assertEquals(1, result.getTotalRecords());
        assertEquals(0, result.getErrorCount());
        assertEquals("VEHICLE", result.getRecords().get(0).getTableName());
        assertNotNull(result.getRecords().get(0).getPayload(),
                "BATDLAKE: Payload must contain extracted source record data");
    }

    @Test
    @DisplayName("BATDLAKE: Unknown table name increments error count")
    void runDataLakeExtract_unknownTable_incrementsError() {
        AuditLog unknownEntry = new AuditLog();
        unknownEntry.setAuditId(2);
        unknownEntry.setTableName("UNKNOWN_TABLE");
        unknownEntry.setKeyValue("KEY1");
        unknownEntry.setActionType("INSERT");
        unknownEntry.setAuditTs(LocalDateTime.now());

        when(auditLogRepository.findAll()).thenReturn(List.of(unknownEntry));
        when(batchControlRepository.findById("BATDLAKE")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        DataLakeExtractResponse result = integrationBatchService.runDataLakeExtract();

        assertEquals(0, result.getTotalRecords());
        assertEquals(1, result.getErrorCount(),
                "BATDLAKE: Unknown tables increment error count (non-fatal per COBOL logic)");
    }

    // ── BATDMS00: DMS Extract ─────────────────────────────────────────

    @Test
    @DisplayName("BATDMS00: Extracts inventory (AV/HD/TR) and recent deals per dealer")
    void runDmsExtract_dealerNestedStructure() {
        when(batchControlRepository.findById("BATDMS00")).thenReturn(Optional.of(
                BatchControl.builder().programId("BATDMS00").lastSyncDate(LocalDate.of(1900, 1, 1))
                        .recordsProcessed(0).runStatus("OK")
                        .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now()).build()));
        when(dealerRepository.findByActiveFlagOrderByDealerName("Y")).thenReturn(List.of(testDealer));
        when(vehicleRepository.findAll()).thenReturn(List.of(testVehicle));
        when(salesDealRepository.findAll()).thenReturn(List.of(testDeal));
        when(customerRepository.findById(100)).thenReturn(Optional.of(testCustomer));
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        DmsExtractResponse result = integrationBatchService.runDmsExtract();

        assertEquals(1, result.getDealersProcessed());
        assertEquals(1, result.getInventoryRecords(),
                "BATDMS00: Only AV/HD/TR vehicles included in DMS inventory extract");
        assertEquals(1, result.getDealRecords());
        assertEquals("Test Motors", result.getDealers().get(0).getDealerName());
    }

    @Test
    @DisplayName("BATDMS00: Sold vehicles excluded from DMS inventory")
    void runDmsExtract_soldVehiclesExcluded() {
        Vehicle soldVehicle = Vehicle.builder()
                .vin("SOLD000000000001")
                .vehicleStatus("SD")
                .dealerCode("D0001")
                .build();
        when(batchControlRepository.findById("BATDMS00")).thenReturn(Optional.of(
                BatchControl.builder().programId("BATDMS00").lastSyncDate(LocalDate.of(1900, 1, 1))
                        .recordsProcessed(0).runStatus("OK")
                        .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now()).build()));
        when(dealerRepository.findByActiveFlagOrderByDealerName("Y")).thenReturn(List.of(testDealer));
        when(vehicleRepository.findAll()).thenReturn(List.of(soldVehicle));
        when(salesDealRepository.findAll()).thenReturn(List.of());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        DmsExtractResponse result = integrationBatchService.runDmsExtract();

        assertEquals(0, result.getInventoryRecords(),
                "BATDMS00: Sold vehicles (SD) not included in DMS inventory per COBOL cursor");
    }
}
