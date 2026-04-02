package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.StockPositionService;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.vehicle.dto.TransferApprovalRequest;
import com.autosales.modules.vehicle.dto.TransferRequest;
import com.autosales.modules.vehicle.dto.TransferResponse;
import com.autosales.modules.vehicle.entity.StockTransfer;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.StockTransferRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for StockTransferService — dealer-to-dealer stock transfer lifecycle.
 * Port of VEHTRN00.cbl / STKTRN00.cbl — transfer request/approve/complete/cancel.
 */
@ExtendWith(MockitoExtension.class)
class StockTransferServiceTest {

    @Mock private StockTransferRepository stockTransferRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private DealerRepository dealerRepository;
    @Mock private StockPositionService stockPositionService;

    @InjectMocks
    private StockTransferService stockTransferService;

    // Common test fixtures
    private Vehicle testVehicle;
    private StockTransfer testTransfer;

    @BeforeEach
    void setUp() {
        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .modelYear((short) 2025)
                .makeCode("HONDA")
                .modelCode("ACCORD")
                .exteriorColor("White")
                .interiorColor("Black")
                .vehicleStatus("AV")
                .dealerCode("D0001")
                .daysInStock((short) 15)
                .pdiComplete("Y")
                .damageFlag("N")
                .odometer(25)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testTransfer = StockTransfer.builder()
                .transferId(100)
                .fromDealer("D0001")
                .toDealer("D0002")
                .vin("1HGCM82633A004352")
                .transferStatus("RQ")
                .requestedBy("MGR01")
                .requestedTs(LocalDateTime.now())
                .build();
    }

    // ── VEHTRN00: requestTransfer ───────────────────────────────────────

    @Test
    @DisplayName("VEHTRN00: requestTransfer success — vehicle AV, different dealers, status=RQ")
    void requestTransfer_success() {
        TransferRequest request = TransferRequest.builder()
                .fromDealer("D0001").toDealer("D0002")
                .vin("1HGCM82633A004352").requestedBy("MGR01")
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(dealerRepository.existsById("D0002")).thenReturn(true);
        when(stockTransferRepository.save(any(StockTransfer.class))).thenAnswer(inv -> {
            StockTransfer t = inv.getArgument(0);
            t.setTransferId(100);
            return t;
        });

        TransferResponse result = stockTransferService.requestTransfer(request);

        assertEquals(100, result.getTransferId());
        assertEquals("RQ", result.getTransferStatus());
        assertEquals("Requested", result.getStatusName());
        assertEquals("D0001", result.getFromDealer());
        assertEquals("D0002", result.getToDealer());

        ArgumentCaptor<StockTransfer> captor = ArgumentCaptor.forClass(StockTransfer.class);
        verify(stockTransferRepository).save(captor.capture());
        assertEquals("RQ", captor.getValue().getTransferStatus());
    }

    @Test
    @DisplayName("VEHTRN00: requestTransfer same dealer rejects")
    void requestTransfer_sameDealer_throwsException() {
        TransferRequest request = TransferRequest.builder()
                .fromDealer("D0001").toDealer("D0001")
                .vin("1HGCM82633A004352").requestedBy("MGR01")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> stockTransferService.requestTransfer(request));
        assertTrue(ex.getMessage().contains("same dealer"));
    }

    @Test
    @DisplayName("VEHTRN00: requestTransfer vehicle not AV rejects")
    void requestTransfer_vehicleNotAV_throwsException() {
        testVehicle.setVehicleStatus("HD");
        TransferRequest request = TransferRequest.builder()
                .fromDealer("D0001").toDealer("D0002")
                .vin("1HGCM82633A004352").requestedBy("MGR01")
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> stockTransferService.requestTransfer(request));
        assertTrue(ex.getMessage().contains("not available"));
    }

    // ── STKTRN00: approveTransfer ───────────────────────────────────────

    @Test
    @DisplayName("STKTRN00: approveTransfer RQ->AP, processTransferOut called")
    void approveTransfer_success() {
        when(stockTransferRepository.findById(100)).thenReturn(Optional.of(testTransfer));
        when(stockTransferRepository.save(any(StockTransfer.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        TransferApprovalRequest request = TransferApprovalRequest.builder()
                .approvedBy("DIR01")
                .build();

        TransferResponse result = stockTransferService.approveTransfer(100, request);

        assertEquals("AP", result.getTransferStatus());
        assertEquals("DIR01", result.getApprovedBy());
        verify(stockPositionService).processTransferOut("1HGCM82633A004352", "D0001",
                "DIR01", "Transfer approved: #100");
    }

    // ── STKTRN00: completeTransfer ──────────────────────────────────────

    @Test
    @DisplayName("STKTRN00: completeTransfer AP->CM, processTransferIn called, vehicle.dealerCode updated")
    void completeTransfer_success() {
        testTransfer.setTransferStatus("AP");
        when(stockTransferRepository.findById(100)).thenReturn(Optional.of(testTransfer));
        when(stockTransferRepository.save(any(StockTransfer.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        TransferResponse result = stockTransferService.completeTransfer(100);

        assertEquals("CM", result.getTransferStatus());
        verify(stockPositionService).processTransferIn("1HGCM82633A004352", "D0002",
                "SYSTEM", "Transfer completed: #100");
        verify(vehicleRepository).save(argThat(v -> "D0002".equals(v.getDealerCode())));
    }

    // ── STKTRN00: cancelTransfer ────────────────────────────────────────

    @Test
    @DisplayName("STKTRN00: cancelTransfer RQ->CN without reversal")
    void cancelTransfer_fromRQ_noReversal() {
        testTransfer.setTransferStatus("RQ");
        when(stockTransferRepository.findById(100)).thenReturn(Optional.of(testTransfer));
        when(stockTransferRepository.save(any(StockTransfer.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        TransferResponse result = stockTransferService.cancelTransfer(100);

        assertEquals("CN", result.getTransferStatus());
        // No reversal for RQ status
        verify(stockPositionService, never()).processReceive(any(), any(), any(), any());
    }

    @Test
    @DisplayName("STKTRN00: cancelTransfer AP->CN with transfer-out reversal")
    void cancelTransfer_fromAP_reversesTransferOut() {
        testTransfer.setTransferStatus("AP");
        when(stockTransferRepository.findById(100)).thenReturn(Optional.of(testTransfer));
        when(stockTransferRepository.save(any(StockTransfer.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        TransferResponse result = stockTransferService.cancelTransfer(100);

        assertEquals("CN", result.getTransferStatus());
        // Reversal: processReceive called to restore vehicle at source dealer
        verify(stockPositionService).processReceive(eq("1HGCM82633A004352"), eq("D0001"),
                eq("SYSTEM"), contains("reversing transfer-out"));
    }

    // ── getTransfer: not found ──────────────────────────────────────────

    @Test
    @DisplayName("STKTRN00: getTransfer not found throws EntityNotFoundException")
    void getTransfer_notFound_throwsException() {
        when(stockTransferRepository.findById(999)).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class, () -> stockTransferService.getTransfer(999));
    }
}
