package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.InboundProcessingResponse;
import com.autosales.modules.batch.dto.InboundVehicleRequest;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import com.autosales.modules.admin.repository.ModelMasterRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for InboundBatchService — port of BATINB00.cbl.
 * Validates the COBOL validation rules:
 *   - Record type must be VH or AL
 *   - VIN must not be blank
 *   - Make must not be blank
 *   - Model year must be 2000-2030
 *   - Dealer code required
 *   - Invoice amount > 0
 *   - Duplicate VIN rejected with DUP-VIN
 *   - Auto-creation of MODEL_MASTER for new model codes
 */
@ExtendWith(MockitoExtension.class)
class InboundBatchServiceTest {

    @Mock private BatchControlRepository batchControlRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private ModelMasterRepository modelMasterRepository;

    @InjectMocks
    private InboundBatchService inboundBatchService;

    private InboundVehicleRequest validRequest;

    @BeforeEach
    void setUp() {
        validRequest = InboundVehicleRequest.builder()
                .recordType("VH")
                .vin("1HGCM82633A004352")
                .makeCode("HON")
                .modelCode("ACCORD")
                .modelYear((short) 2026)
                .exteriorColor("White")
                .interiorColor("Black")
                .dealerCode("D0001")
                .invoiceAmount(new BigDecimal("28500.00"))
                .build();
    }

    // ── Validation Rules (ported from BATINB00 VALIDATE-RECORD) ───────

    @Test
    @DisplayName("BATINB00: Valid VH record passes validation")
    void validateRecord_validVhRecord_passes() {
        assertNull(inboundBatchService.validateRecord(validRequest));
    }

    @Test
    @DisplayName("BATINB00: Valid AL record passes validation")
    void validateRecord_validAlRecord_passes() {
        validRequest.setRecordType("AL");
        assertNull(inboundBatchService.validateRecord(validRequest));
    }

    @Test
    @DisplayName("BATINB00: Invalid record type rejected with INV-TYPE")
    void validateRecord_invalidType_rejected() {
        validRequest.setRecordType("XX");
        assertEquals("INV-TYPE", inboundBatchService.validateRecord(validRequest),
                "BATINB00: Record type must be VH or AL per COBOL validation");
    }

    @Test
    @DisplayName("BATINB00: Blank VIN rejected with INV-VIN")
    void validateRecord_blankVin_rejected() {
        validRequest.setVin("   ");
        assertEquals("INV-VIN", inboundBatchService.validateRecord(validRequest));
    }

    @Test
    @DisplayName("BATINB00: Blank make rejected with INV-MAKE")
    void validateRecord_blankMake_rejected() {
        validRequest.setMakeCode("");
        assertEquals("INV-MAKE", inboundBatchService.validateRecord(validRequest));
    }

    @Test
    @DisplayName("BATINB00: Model year 1999 rejected (below 2000-2030 range)")
    void validateRecord_yearTooLow_rejected() {
        validRequest.setModelYear((short) 1999);
        assertEquals("INV-YEAR", inboundBatchService.validateRecord(validRequest),
                "BATINB00: Model year must be 2000-2030");
    }

    @Test
    @DisplayName("BATINB00: Model year 2031 rejected (above 2000-2030 range)")
    void validateRecord_yearTooHigh_rejected() {
        validRequest.setModelYear((short) 2031);
        assertEquals("INV-YEAR", inboundBatchService.validateRecord(validRequest));
    }

    @Test
    @DisplayName("BATINB00: Missing dealer code rejected with INV-DLR")
    void validateRecord_blankDealer_rejected() {
        validRequest.setDealerCode("");
        assertEquals("INV-DLR", inboundBatchService.validateRecord(validRequest));
    }

    @Test
    @DisplayName("BATINB00: Zero invoice amount rejected with INV-AMT")
    void validateRecord_zeroAmount_rejected() {
        validRequest.setInvoiceAmount(BigDecimal.ZERO);
        assertEquals("INV-AMT", inboundBatchService.validateRecord(validRequest),
                "BATINB00: Invoice amount must be > 0");
    }

    @Test
    @DisplayName("BATINB00: Negative invoice amount rejected with INV-AMT")
    void validateRecord_negativeAmount_rejected() {
        validRequest.setInvoiceAmount(new BigDecimal("-100.00"));
        assertEquals("INV-AMT", inboundBatchService.validateRecord(validRequest));
    }

    // ── Duplicate VIN Check ───────────────────────────────────────────

    @Test
    @DisplayName("BATINB00: Duplicate VIN rejected with DUP-VIN reason code")
    void processInboundFeed_duplicateVin_rejected() {
        when(vehicleRepository.findById("1HGCM82633A004352"))
                .thenReturn(Optional.of(Vehicle.builder().vin("1HGCM82633A004352").build()));
        when(batchControlRepository.findById(any())).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        InboundProcessingResponse result = inboundBatchService.processInboundFeed(List.of(validRequest));

        assertEquals(0, result.getAccepted());
        assertEquals(1, result.getRejected());
        assertEquals("DUP-VIN", result.getRejections().get(0).getReasonCode(),
                "BATINB00: Duplicate VIN must be rejected with DUP-VIN code");
    }

    // ── Successful Insert ─────────────────────────────────────────────

    @Test
    @DisplayName("BATINB00: Valid new vehicle inserted with status AV")
    void processInboundFeed_newVehicle_insertedAsAvailable() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.empty());
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(i -> i.getArgument(0));
        when(modelMasterRepository.findById(any())).thenReturn(Optional.of(
                ModelMaster.builder().build()));
        when(batchControlRepository.findById(any())).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        InboundProcessingResponse result = inboundBatchService.processInboundFeed(List.of(validRequest));

        assertEquals(1, result.getAccepted());
        assertEquals(0, result.getRejected());

        ArgumentCaptor<Vehicle> captor = ArgumentCaptor.forClass(Vehicle.class);
        verify(vehicleRepository).save(captor.capture());
        Vehicle saved = captor.getValue();
        assertEquals("AV", saved.getVehicleStatus(),
                "BATINB00: New vehicle initial status must be AV (Available)");
        assertEquals("N", saved.getPdiComplete());
        assertEquals("N", saved.getDamageFlag());
        assertEquals((short) 0, saved.getDaysInStock());
    }

    // ── Model Master Auto-Creation ────────────────────────────────────

    @Test
    @DisplayName("BATINB00: New model code auto-creates MODEL_MASTER entry")
    void ensureModelMasterExists_newModel_created() {
        when(modelMasterRepository.findById(any(ModelMasterId.class))).thenReturn(Optional.empty());
        when(modelMasterRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        inboundBatchService.ensureModelMasterExists(validRequest);

        ArgumentCaptor<ModelMaster> captor = ArgumentCaptor.forClass(ModelMaster.class);
        verify(modelMasterRepository).save(captor.capture());
        ModelMaster saved = captor.getValue();
        assertEquals((short) 2026, saved.getModelYear());
        assertEquals("HON", saved.getMakeCode());
        assertEquals("ACCORD", saved.getModelCode());
        assertEquals("Y", saved.getActiveFlag());
    }

    @Test
    @DisplayName("BATINB00: Existing model code does not create duplicate")
    void ensureModelMasterExists_existingModel_notCreated() {
        when(modelMasterRepository.findById(any(ModelMasterId.class)))
                .thenReturn(Optional.of(ModelMaster.builder().build()));

        inboundBatchService.ensureModelMasterExists(validRequest);

        verify(modelMasterRepository, never()).save(any());
    }

    // ── Mixed Batch Processing ────────────────────────────────────────

    @Test
    @DisplayName("BATINB00: Mixed batch with valid and invalid records processes correctly")
    void processInboundFeed_mixedBatch_partialAcceptance() {
        InboundVehicleRequest invalidRecord = InboundVehicleRequest.builder()
                .recordType("XX") // Invalid type
                .vin("BAD")
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.empty());
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(i -> i.getArgument(0));
        when(modelMasterRepository.findById(any())).thenReturn(Optional.of(ModelMaster.builder().build()));
        when(batchControlRepository.findById(any())).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        InboundProcessingResponse result = inboundBatchService.processInboundFeed(
                List.of(validRequest, invalidRecord));

        assertEquals(2, result.getTotalRecords());
        assertEquals(1, result.getAccepted());
        assertEquals(1, result.getRejected());
    }
}
