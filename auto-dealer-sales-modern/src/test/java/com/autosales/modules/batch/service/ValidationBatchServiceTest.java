package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.ValidationReportResponse;
import com.autosales.modules.batch.dto.ValidationReportResponse.ValidationException;
import com.autosales.modules.batch.repository.BatchControlRepository;
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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for ValidationBatchService — port of BATVAL00.cbl.
 * Validates all four COBOL validation phases:
 *   Phase 1: Orphaned deals (NOT EXISTS on CUSTOMER)
 *   Phase 2: Orphaned vehicles (NOT EXISTS on DEALER)
 *   Phase 3: VIN checksum validation (COMVINL0 'VALD')
 *   Phase 4: Duplicate customer detection (self-join on name+DOB+dealer)
 */
@ExtendWith(MockitoExtension.class)
class ValidationBatchServiceTest {

    @Mock private BatchControlRepository batchControlRepository;
    @Mock private SalesDealRepository salesDealRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private DealerRepository dealerRepository;

    @InjectMocks
    private ValidationBatchService validationBatchService;

    private Customer customer1;
    private Customer customer2;
    private Dealer dealer1;

    @BeforeEach
    void setUp() {
        customer1 = Customer.builder()
                .customerId(100)
                .firstName("John")
                .lastName("Smith")
                .dateOfBirth(LocalDate.of(1985, 6, 15))
                .dealerCode("D0001")
                .build();

        customer2 = Customer.builder()
                .customerId(101)
                .firstName("John")
                .lastName("Smith")
                .dateOfBirth(LocalDate.of(1985, 6, 15))
                .dealerCode("D0001")
                .build();

        dealer1 = Dealer.builder()
                .dealerCode("D0001")
                .dealerName("Test Motors")
                .activeFlag("Y")
                .build();
    }

    // ── Phase 1: Orphaned Deals ───────────────────────────────────────

    @Test
    @DisplayName("BATVAL00 Phase 1: Deal with non-existent customer flagged as orphan")
    void findOrphanedDeals_detectsOrphan() {
        SalesDeal orphanDeal = SalesDeal.builder()
                .dealNumber("DL-ORF")
                .customerId(999) // Non-existent customer
                .dealStatus("WS")
                .build();
        when(customerRepository.findAll()).thenReturn(List.of(customer1));
        when(salesDealRepository.findAll()).thenReturn(List.of(orphanDeal));

        List<ValidationException> result = validationBatchService.findOrphanedDeals();

        assertEquals(1, result.size());
        assertEquals("SALES_DEAL", result.get(0).getEntityType());
        assertEquals("DL-ORF", result.get(0).getEntityId());
        assertEquals("HIGH", result.get(0).getSeverity());
    }

    @Test
    @DisplayName("BATVAL00 Phase 1: Cancelled deals excluded from orphan check")
    void findOrphanedDeals_cancelledExcluded() {
        SalesDeal cancelledDeal = SalesDeal.builder()
                .dealNumber("DL-CA1")
                .customerId(999)
                .dealStatus("CA") // Cancelled — excluded per COBOL logic
                .build();
        when(customerRepository.findAll()).thenReturn(List.of(customer1));
        when(salesDealRepository.findAll()).thenReturn(List.of(cancelledDeal));

        List<ValidationException> result = validationBatchService.findOrphanedDeals();

        assertEquals(0, result.size(), "BATVAL00: Cancelled/Unwound deals excluded from orphan check");
    }

    // ── Phase 2: Orphaned Vehicles ────────────────────────────────────

    @Test
    @DisplayName("BATVAL00 Phase 2: Vehicle with non-existent dealer flagged as orphan")
    void findOrphanedVehicles_detectsOrphan() {
        Vehicle orphanVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("XXXXX") // Non-existent dealer
                .build();
        when(dealerRepository.findAll()).thenReturn(List.of(dealer1));
        when(vehicleRepository.findAll()).thenReturn(List.of(orphanVehicle));

        List<ValidationException> result = validationBatchService.findOrphanedVehicles();

        assertEquals(1, result.size());
        assertEquals("VEHICLE", result.get(0).getEntityType());
    }

    // ── Phase 3: VIN Checksum Validation ──────────────────────────────

    @Test
    @DisplayName("COMVINL0 VALD: Valid VIN passes checksum (11XXXXXXXXXXXXXXX pattern)")
    void isValidVinChecksum_validVin_returnsTrue() {
        // Known valid VIN: 11111111111111111 → checksum digit is '1' at pos 9
        assertTrue(ValidationBatchService.isValidVinChecksum("11111111111111111"),
                "COMVINL0: VIN with all 1s should pass (check digit = 1)");
    }

    @Test
    @DisplayName("COMVINL0 VALD: VIN with incorrect check digit fails")
    void isValidVinChecksum_wrongCheckDigit_returnsFalse() {
        // Modify position 9 to wrong digit
        assertFalse(ValidationBatchService.isValidVinChecksum("11111111211111111"),
                "COMVINL0: VIN with wrong check digit at position 9 should fail");
    }

    @Test
    @DisplayName("COMVINL0 VALD: VIN shorter than 17 characters fails")
    void isValidVinChecksum_shortVin_returnsFalse() {
        assertFalse(ValidationBatchService.isValidVinChecksum("1234567890"),
                "COMVINL0: VIN must be exactly 17 characters");
    }

    @Test
    @DisplayName("COMVINL0 VALD: Null VIN fails")
    void isValidVinChecksum_nullVin_returnsFalse() {
        assertFalse(ValidationBatchService.isValidVinChecksum(null));
    }

    @Test
    @DisplayName("COMVINL0 VALD: VIN with I, O, Q characters fails (not in VIN alphabet)")
    void isValidVinChecksum_invalidCharacters_returnsFalse() {
        assertFalse(ValidationBatchService.isValidVinChecksum("1HGCM826I3A004352"),
                "COMVINL0: I, O, Q are invalid VIN characters per ISO 3779");
    }

    @Test
    @DisplayName("BATVAL00 Phase 3: Invalid VINs flagged on vehicles")
    void validateVinChecksums_detectsInvalidVin() {
        Vehicle badVinVehicle = Vehicle.builder()
                .vin("ABCDEFGHIJKLMNOPQ") // Invalid VIN
                .dealerCode("D0001")
                .build();
        when(vehicleRepository.findAll()).thenReturn(List.of(badVinVehicle));

        List<ValidationException> result = validationBatchService.validateVinChecksums();

        assertEquals(1, result.size());
        assertEquals("MEDIUM", result.get(0).getSeverity());
    }

    // ── Phase 4: Duplicate Customers ──────────────────────────────────

    @Test
    @DisplayName("BATVAL00 Phase 4: Customers with same name+DOB+dealer detected as duplicate")
    void findDuplicateCustomers_detectsDuplicate() {
        when(customerRepository.findAll()).thenReturn(List.of(customer1, customer2));

        List<ValidationException> result = validationBatchService.findDuplicateCustomers();

        assertEquals(1, result.size());
        assertEquals("CUSTOMER", result.get(0).getEntityType());
        assertTrue(result.get(0).getEntityId().contains("100"));
        assertTrue(result.get(0).getEntityId().contains("101"));
        assertEquals("LOW", result.get(0).getSeverity());
    }

    @Test
    @DisplayName("BATVAL00 Phase 4: Customers with different DOB not flagged as duplicate")
    void findDuplicateCustomers_differentDob_notDuplicate() {
        Customer differentDob = Customer.builder()
                .customerId(102)
                .firstName("John")
                .lastName("Smith")
                .dateOfBirth(LocalDate.of(1990, 1, 1)) // Different DOB
                .dealerCode("D0001")
                .build();
        when(customerRepository.findAll()).thenReturn(List.of(customer1, differentDob));

        List<ValidationException> result = validationBatchService.findDuplicateCustomers();

        assertEquals(0, result.size(),
                "BATVAL00: Self-join on LAST_NAME+FIRST_NAME+DOB+DEALER must match all fields");
    }

    // ── Flag Invalid VINs ─────────────────────────────────────────────

    @Test
    @DisplayName("BATVAL00 Phase 3: Vehicle damage flag set to Y with VIN CHECKSUM FAILED desc")
    void flagInvalidVins_setsDamageFlag() {
        Vehicle vehicle = Vehicle.builder()
                .vin("BADVIN12345678901")
                .damageFlag("N")
                .updatedTs(LocalDateTime.now())
                .build();
        when(vehicleRepository.findById("BADVIN12345678901")).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        ValidationException ve = ValidationException.builder()
                .entityId("BADVIN12345678901").build();
        int count = validationBatchService.flagInvalidVins(List.of(ve));

        assertEquals(1, count);
        assertEquals("Y", vehicle.getDamageFlag());
        assertEquals("VIN CHECKSUM FAILED", vehicle.getDamageDesc(),
                "BATVAL00: Must set DAMAGE_DESC = 'VIN CHECKSUM FAILED' per COBOL logic");
    }

    // ── Full Run ──────────────────────────────────────────────────────

    @Test
    @DisplayName("BATVAL00: Full validation returns report with four phases")
    void runValidation_fourPhases() {
        when(customerRepository.findAll()).thenReturn(List.of());
        when(salesDealRepository.findAll()).thenReturn(List.of());
        when(vehicleRepository.findAll()).thenReturn(List.of());
        when(dealerRepository.findAll()).thenReturn(List.of());
        when(batchControlRepository.findById("BATVAL00")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        BatchRunResult result = validationBatchService.runValidation();

        assertEquals("BATVAL00", result.getProgramId());
        assertEquals(4, result.getPhases().size());
    }
}
