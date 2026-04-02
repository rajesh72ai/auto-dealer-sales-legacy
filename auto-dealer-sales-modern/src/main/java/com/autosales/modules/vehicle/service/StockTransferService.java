package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.StockPositionService;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.vehicle.dto.TransferApprovalRequest;
import com.autosales.modules.vehicle.dto.TransferRequest;
import com.autosales.modules.vehicle.dto.TransferResponse;
import com.autosales.modules.vehicle.entity.StockTransfer;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.StockTransferRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Service for dealer-to-dealer stock transfer lifecycle management.
 * Port of VEHTRN00.cbl / STKTRN00.cbl — vehicle transfer request/approve/complete.
 *
 * <p>Transfer lifecycle: RQ (Requested) → AP (Approved) → CM (Completed)
 * or RQ → RJ (Rejected) or RQ/AP → CN (Cancelled).</p>
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class StockTransferService {

    private static final Map<String, String> STATUS_NAMES = Map.of(
            "RQ", "Requested",
            "AP", "Approved",
            "CM", "Completed",
            "RJ", "Rejected",
            "CN", "Cancelled"
    );

    private final StockTransferRepository stockTransferRepository;
    private final VehicleRepository vehicleRepository;
    private final DealerRepository dealerRepository;
    private final StockPositionService stockPositionService;

    /**
     * Request a new stock transfer. Vehicle must be AV at fromDealer;
     * cannot transfer to same dealer; destination dealer must exist.
     */
    @Transactional
    public TransferResponse requestTransfer(TransferRequest request) {
        log.info("TRANSFER REQUEST: vin={}, from={}, to={}", request.getVin(), request.getFromDealer(), request.getToDealer());

        // Validate source and destination are different
        if (request.getFromDealer().equals(request.getToDealer())) {
            throw new BusinessValidationException("Cannot transfer vehicle to the same dealer");
        }

        // Validate vehicle exists and is AV at fromDealer
        Vehicle vehicle = vehicleRepository.findById(request.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", request.getVin()));

        if (!"AV".equals(vehicle.getVehicleStatus())) {
            throw new BusinessValidationException(
                    "Vehicle " + request.getVin() + " is not available (status: " + vehicle.getVehicleStatus() + ")");
        }
        if (!request.getFromDealer().equals(vehicle.getDealerCode())) {
            throw new BusinessValidationException(
                    "Vehicle " + request.getVin() + " is not at dealer " + request.getFromDealer());
        }

        // Validate destination dealer exists
        if (!dealerRepository.existsById(request.getToDealer())) {
            throw new EntityNotFoundException("Dealer", request.getToDealer());
        }

        StockTransfer transfer = StockTransfer.builder()
                .fromDealer(request.getFromDealer())
                .toDealer(request.getToDealer())
                .vin(request.getVin())
                .transferStatus("RQ")
                .requestedBy(request.getRequestedBy())
                .requestedTs(LocalDateTime.now())
                .build();

        StockTransfer saved = stockTransferRepository.save(transfer);
        log.info("Transfer created: id={}, vin={}, from={} to={}", saved.getTransferId(),
                saved.getVin(), saved.getFromDealer(), saved.getToDealer());

        return toResponse(saved, vehicle);
    }

    /**
     * List transfers involving a dealer, optionally filtered by status.
     */
    public PaginatedResponse<TransferResponse> listTransfers(String dealerCode, String status, int page, int size) {
        log.debug("Listing transfers for dealer={}, status={}, page={}, size={}", dealerCode, status, page, size);

        Page<StockTransfer> transfers = stockTransferRepository.findByDealerAndStatus(
                dealerCode, status, PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "requestedTs")));

        var content = transfers.getContent().stream()
                .map(t -> toResponse(t, vehicleRepository.findById(t.getVin()).orElse(null)))
                .toList();

        return new PaginatedResponse<>("success", null, content,
                transfers.getNumber(), transfers.getTotalPages(), transfers.getTotalElements(),
                LocalDateTime.now());
    }

    /**
     * Get a single transfer by ID.
     */
    public TransferResponse getTransfer(int id) {
        log.debug("Getting transfer id={}", id);
        StockTransfer transfer = findTransferOrThrow(id);
        Vehicle vehicle = vehicleRepository.findById(transfer.getVin()).orElse(null);
        return toResponse(transfer, vehicle);
    }

    /**
     * Approve a transfer. Must be in RQ status.
     * Triggers transfer-out from source dealer stock position.
     */
    @Transactional
    public TransferResponse approveTransfer(int id, TransferApprovalRequest request) {
        log.info("TRANSFER APPROVE: id={}, approvedBy={}", id, request.getApprovedBy());

        StockTransfer transfer = findTransferOrThrow(id);
        if (!"RQ".equals(transfer.getTransferStatus())) {
            throw new BusinessValidationException(
                    "Transfer " + id + " cannot be approved (current status: " + transfer.getTransferStatus() + ")");
        }

        transfer.setTransferStatus("AP");
        transfer.setApprovedBy(request.getApprovedBy());
        transfer.setApprovedTs(LocalDateTime.now());
        stockTransferRepository.save(transfer);

        // Process transfer-out at source dealer
        stockPositionService.processTransferOut(transfer.getVin(), transfer.getFromDealer(),
                request.getApprovedBy(), "Transfer approved: #" + id);

        Vehicle vehicle = vehicleRepository.findById(transfer.getVin()).orElse(null);
        log.info("Transfer approved: id={}", id);
        return toResponse(transfer, vehicle);
    }

    /**
     * Complete a transfer. Must be in AP status.
     * Triggers transfer-in at destination dealer and updates vehicle dealerCode.
     */
    @Transactional
    public TransferResponse completeTransfer(int id) {
        log.info("TRANSFER COMPLETE: id={}", id);

        StockTransfer transfer = findTransferOrThrow(id);
        if (!"AP".equals(transfer.getTransferStatus())) {
            throw new BusinessValidationException(
                    "Transfer " + id + " cannot be completed (current status: " + transfer.getTransferStatus() + ")");
        }

        transfer.setTransferStatus("CM");
        transfer.setCompletedTs(LocalDateTime.now());
        stockTransferRepository.save(transfer);

        // Process transfer-in at destination dealer
        stockPositionService.processTransferIn(transfer.getVin(), transfer.getToDealer(),
                "SYSTEM", "Transfer completed: #" + id);

        // Update vehicle dealerCode to destination
        Vehicle vehicle = vehicleRepository.findById(transfer.getVin()).orElse(null);
        if (vehicle != null) {
            vehicle.setDealerCode(transfer.getToDealer());
            vehicle.setUpdatedTs(LocalDateTime.now());
            vehicleRepository.save(vehicle);
        }

        log.info("Transfer completed: id={}", id);
        return toResponse(transfer, vehicle);
    }

    /**
     * Cancel a transfer. Must be in RQ or AP status.
     * If was AP, reverses the transfer-out.
     */
    @Transactional
    public TransferResponse cancelTransfer(int id) {
        log.info("TRANSFER CANCEL: id={}", id);

        StockTransfer transfer = findTransferOrThrow(id);
        String currentStatus = transfer.getTransferStatus();

        if (!"RQ".equals(currentStatus) && !"AP".equals(currentStatus)) {
            throw new BusinessValidationException(
                    "Transfer " + id + " cannot be cancelled (current status: " + currentStatus + ")");
        }

        transfer.setTransferStatus("CN");
        transfer.setCompletedTs(LocalDateTime.now());
        stockTransferRepository.save(transfer);

        // If was approved, reverse the transfer-out (return vehicle to source dealer stock)
        if ("AP".equals(currentStatus)) {
            stockPositionService.processReceive(transfer.getVin(), transfer.getFromDealer(),
                    "SYSTEM", "Transfer cancelled: #" + id + " — reversing transfer-out");
        }

        Vehicle vehicle = vehicleRepository.findById(transfer.getVin()).orElse(null);
        log.info("Transfer cancelled: id={}", id);
        return toResponse(transfer, vehicle);
    }

    // ── Private helpers ──────────────────────────────────────────────────

    private StockTransfer findTransferOrThrow(int id) {
        return stockTransferRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("StockTransfer", String.valueOf(id)));
    }

    private String buildVehicleDesc(Vehicle vehicle) {
        if (vehicle == null) return "Unknown";
        return vehicle.getModelYear() + " " + vehicle.getMakeCode() + " " + vehicle.getModelCode();
    }

    private TransferResponse toResponse(StockTransfer transfer, Vehicle vehicle) {
        return TransferResponse.builder()
                .transferId(transfer.getTransferId())
                .fromDealer(transfer.getFromDealer())
                .toDealer(transfer.getToDealer())
                .vin(transfer.getVin())
                .vehicleDesc(buildVehicleDesc(vehicle))
                .transferStatus(transfer.getTransferStatus())
                .statusName(STATUS_NAMES.getOrDefault(transfer.getTransferStatus(), transfer.getTransferStatus()))
                .requestedBy(transfer.getRequestedBy())
                .approvedBy(transfer.getApprovedBy())
                .requestedTs(transfer.getRequestedTs())
                .approvedTs(transfer.getApprovedTs())
                .completedTs(transfer.getCompletedTs())
                .build();
    }
}
