package com.autosales.modules.registration.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.registration.dto.*;
import com.autosales.modules.registration.entity.RecallCampaign;
import com.autosales.modules.registration.entity.RecallNotification;
import com.autosales.modules.registration.entity.RecallVehicle;
import com.autosales.modules.registration.entity.RecallVehicleId;
import com.autosales.modules.registration.repository.RecallCampaignRepository;
import com.autosales.modules.registration.repository.RecallNotificationRepository;
import com.autosales.modules.registration.repository.RecallVehicleRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Service for recall campaign management, vehicle tracking, and notifications.
 * Port of WRCRCL00 (recall management), WRCRCLB0 (batch feed), WRCNOTF0 (notifications).
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class RecallService {

    private static final Map<String, String> SEVERITY_NAMES = Map.of(
            "C", "Critical", "H", "High", "M", "Medium", "L", "Low");

    private static final Map<String, String> CAMPAIGN_STATUS_NAMES = Map.of(
            "A", "Active", "P", "Pending", "C", "Closed");

    private static final Map<String, String> RECALL_STATUS_NAMES = Map.of(
            "OP", "Open", "SC", "Scheduled", "IP", "In Progress",
            "CM", "Completed", "NA", "Not Applicable");

    private static final Map<String, String> NOTIF_TYPE_NAMES = Map.of(
            "M", "Mail", "E", "Email", "P", "Phone", "S", "SMS");

    private static final Map<String, Set<String>> VALID_STATUS_TRANSITIONS = Map.of(
            "OP", Set.of("SC", "NA"),
            "SC", Set.of("IP"),
            "IP", Set.of("CM"));

    private final RecallCampaignRepository campaignRepository;
    private final RecallVehicleRepository vehicleRepository;
    private final RecallNotificationRepository notificationRepository;
    private final ResponseFormatter responseFormatter;

    public RecallService(RecallCampaignRepository campaignRepository,
                         RecallVehicleRepository vehicleRepository,
                         RecallNotificationRepository notificationRepository,
                         ResponseFormatter responseFormatter) {
        this.campaignRepository = campaignRepository;
        this.vehicleRepository = vehicleRepository;
        this.notificationRepository = notificationRepository;
        this.responseFormatter = responseFormatter;
    }

    // ─── Campaign Operations (WRCRCL00 INQ + WRCRCLB0) ─────────────────

    /**
     * List all recall campaigns with optional status filter — WRCRCL00 INQ.
     */
    public PaginatedResponse<RecallCampaignResponse> findAllCampaigns(String status, Pageable pageable) {
        log.info("WRCRCL00: Listing recall campaigns — status={}", status);

        Page<RecallCampaign> page = (status != null)
                ? campaignRepository.findByCampaignStatus(status, pageable)
                : campaignRepository.findAll(pageable);

        List<RecallCampaignResponse> content = page.getContent().stream()
                .map(this::toCampaignResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Get campaign detail by recall ID — WRCRCL00 INQ.
     */
    public RecallCampaignResponse findCampaignById(String recallId) {
        log.info("WRCRCL00: Campaign detail for recallId={}", recallId);
        RecallCampaign campaign = campaignRepository.findById(recallId)
                .orElseThrow(() -> new EntityNotFoundException("RecallCampaign", recallId));
        return toCampaignResponse(campaign);
    }

    /**
     * Create a new recall campaign — WRCRCLB0 (batch feed ingestion).
     */
    @Transactional
    @Auditable(action = "INS", entity = "recall_campaign", keyExpression = "#request.recallId")
    public RecallCampaignResponse createCampaign(RecallCampaignRequest request) {
        log.info("WRCRCLB0: Creating recall campaign recallId={}", request.getRecallId());

        if (campaignRepository.existsById(request.getRecallId())) {
            throw new DuplicateEntityException("RecallCampaign", request.getRecallId());
        }

        RecallCampaign entity = RecallCampaign.builder()
                .recallId(request.getRecallId())
                .nhtsaNum(request.getNhtsaNum())
                .recallDesc(request.getRecallDesc())
                .severity(request.getSeverity())
                .affectedYears(request.getAffectedYears())
                .affectedModels(request.getAffectedModels())
                .remedyDesc(request.getRemedyDesc())
                .remedyAvailDt(request.getRemedyAvailDt())
                .announcedDate(request.getAnnouncedDate())
                .totalAffected(0)
                .totalCompleted(0)
                .campaignStatus("A")
                .createdTs(LocalDateTime.now())
                .build();

        RecallCampaign saved = campaignRepository.save(entity);
        log.info("WRCRCLB0: Created recall campaign recallId={}", request.getRecallId());
        return toCampaignResponse(saved);
    }

    // ─── Vehicle Operations (WRCRCL00 VEH + UPD) ───────────────────────

    /**
     * List vehicles for a recall campaign with optional status filter — WRCRCL00 VEH.
     */
    public PaginatedResponse<RecallVehicleResponse> findVehiclesByRecall(String recallId, String status, Pageable pageable) {
        log.info("WRCRCL00: Listing vehicles for recallId={} status={}", recallId, status);

        if (!campaignRepository.existsById(recallId)) {
            throw new EntityNotFoundException("RecallCampaign", recallId);
        }

        Page<RecallVehicle> page = (status != null)
                ? vehicleRepository.findByRecallIdAndRecallStatus(recallId, status, pageable)
                : vehicleRepository.findByRecallId(recallId, pageable);

        List<RecallVehicleResponse> content = page.getContent().stream()
                .map(this::toVehicleResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Add a vehicle to a recall campaign — WRCRCLB0.
     */
    @Transactional
    @Auditable(action = "INS", entity = "recall_vehicle", keyExpression = "#recallId + '/' + #vin")
    public RecallVehicleResponse addVehicle(String recallId, String vin, String dealerCode) {
        log.info("WRCRCLB0: Adding vin={} to recall recallId={}", vin, recallId);

        RecallCampaign campaign = campaignRepository.findById(recallId)
                .orElseThrow(() -> new EntityNotFoundException("RecallCampaign", recallId));

        RecallVehicleId id = new RecallVehicleId(recallId, vin);
        if (vehicleRepository.existsById(id)) {
            throw new DuplicateEntityException("RecallVehicle", recallId + "/" + vin);
        }

        RecallVehicle entity = RecallVehicle.builder()
                .recallId(recallId)
                .vin(vin)
                .dealerCode(dealerCode)
                .recallStatus("OP")
                .partsOrdered("N")
                .partsAvail("N")
                .build();

        RecallVehicle saved = vehicleRepository.save(entity);

        // Increment total affected
        campaign.setTotalAffected(campaign.getTotalAffected() + 1);
        campaignRepository.save(campaign);

        log.info("WRCRCLB0: Added vin={} to recall recallId={}", vin, recallId);
        return toVehicleResponse(saved);
    }

    /**
     * Update recall status for a vehicle — WRCRCL00 UPD.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "recall_vehicle", keyExpression = "#recallId + '/' + #vin")
    public RecallVehicleResponse updateVehicleStatus(String recallId, String vin, RecallVehicleStatusRequest request) {
        log.info("WRCRCL00: Updating vehicle status recallId={} vin={} to {}", recallId, vin, request.getNewStatus());

        RecallVehicleId id = new RecallVehicleId(recallId, vin);
        RecallVehicle vehicle = vehicleRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("RecallVehicle", recallId + "/" + vin));

        String currentStatus = vehicle.getRecallStatus();
        String newStatus = request.getNewStatus();

        Set<String> allowed = VALID_STATUS_TRANSITIONS.get(currentStatus);
        if (allowed == null || !allowed.contains(newStatus)) {
            throw new BusinessValidationException(
                    String.format("Cannot transition recall status from %s to %s", currentStatus, newStatus));
        }

        vehicle.setRecallStatus(newStatus);

        switch (newStatus) {
            case "SC" -> {
                vehicle.setScheduledDate(request.getScheduledDate() != null ? request.getScheduledDate() : LocalDate.now());
                vehicle.setTechnicianId(request.getTechnicianId());
            }
            case "CM" -> {
                vehicle.setCompletedDate(LocalDate.now());
                vehicle.setTechnicianId(request.getTechnicianId());
                // Increment campaign completion counter
                RecallCampaign campaign = campaignRepository.findById(recallId)
                        .orElseThrow(() -> new EntityNotFoundException("RecallCampaign", recallId));
                campaign.setTotalCompleted(campaign.getTotalCompleted() + 1);
                campaignRepository.save(campaign);
            }
        }

        RecallVehicle saved = vehicleRepository.save(vehicle);
        log.info("WRCRCL00: Updated vehicle status recallId={} vin={} to {}", recallId, vin, newStatus);
        return toVehicleResponse(saved);
    }

    /**
     * Get all recalls affecting a specific VIN.
     */
    public List<RecallVehicleResponse> findRecallsByVin(String vin) {
        log.info("Finding recalls for vin={}", vin);
        return vehicleRepository.findByVin(vin).stream()
                .map(this::toVehicleResponse)
                .toList();
    }

    // ─── Notification Operations (WRCNOTF0) ────────────────────────────

    /**
     * List notifications for a recall campaign.
     */
    public List<RecallNotificationResponse> findNotificationsByRecall(String recallId) {
        log.info("WRCNOTF0: Listing notifications for recallId={}", recallId);
        return notificationRepository.findByRecallId(recallId).stream()
                .map(this::toNotificationResponse)
                .toList();
    }

    /**
     * Create a recall notification — WRCNOTF0.
     */
    @Transactional
    @Auditable(action = "INS", entity = "recall_notification", keyExpression = "#recallId + '/' + #vin")
    public RecallNotificationResponse createNotification(String recallId, String vin, Integer customerId, String notifType) {
        log.info("WRCNOTF0: Creating notification for recallId={} vin={}", recallId, vin);

        if (!campaignRepository.existsById(recallId)) {
            throw new EntityNotFoundException("RecallCampaign", recallId);
        }

        if (notificationRepository.existsByRecallIdAndVin(recallId, vin)) {
            throw new DuplicateEntityException("RecallNotification", recallId + "/" + vin);
        }

        RecallNotification entity = RecallNotification.builder()
                .recallId(recallId)
                .vin(vin)
                .customerId(customerId)
                .notifType(notifType != null ? notifType : "M")
                .notifDate(LocalDate.now())
                .responseFlag("N")
                .build();

        RecallNotification saved = notificationRepository.save(entity);

        // Update notified date on recall vehicle if exists
        RecallVehicleId rvId = new RecallVehicleId(recallId, vin);
        vehicleRepository.findById(rvId).ifPresent(rv -> {
            rv.setNotifiedDate(LocalDate.now());
            vehicleRepository.save(rv);
        });

        log.info("WRCNOTF0: Created notification for recallId={} vin={}", recallId, vin);
        return toNotificationResponse(saved);
    }

    // ─── Mapping ────────────────────────────────────────────────────────

    private RecallCampaignResponse toCampaignResponse(RecallCampaign entity) {
        double pct = entity.getTotalAffected() > 0
                ? (double) entity.getTotalCompleted() / entity.getTotalAffected() * 100.0
                : 0.0;

        return RecallCampaignResponse.builder()
                .recallId(entity.getRecallId())
                .nhtsaNum(entity.getNhtsaNum())
                .recallDesc(entity.getRecallDesc())
                .severity(entity.getSeverity())
                .affectedYears(entity.getAffectedYears())
                .affectedModels(entity.getAffectedModels())
                .remedyDesc(entity.getRemedyDesc())
                .remedyAvailDt(entity.getRemedyAvailDt())
                .announcedDate(entity.getAnnouncedDate())
                .totalAffected(entity.getTotalAffected())
                .totalCompleted(entity.getTotalCompleted())
                .campaignStatus(entity.getCampaignStatus())
                .createdTs(entity.getCreatedTs())
                .severityName(SEVERITY_NAMES.getOrDefault(entity.getSeverity(), entity.getSeverity()))
                .campaignStatusName(CAMPAIGN_STATUS_NAMES.getOrDefault(entity.getCampaignStatus(), entity.getCampaignStatus()))
                .completionPercentage(Math.round(pct * 10.0) / 10.0)
                .build();
    }

    private RecallVehicleResponse toVehicleResponse(RecallVehicle entity) {
        return RecallVehicleResponse.builder()
                .recallId(entity.getRecallId())
                .vin(entity.getVin())
                .dealerCode(entity.getDealerCode())
                .recallStatus(entity.getRecallStatus())
                .notifiedDate(entity.getNotifiedDate())
                .scheduledDate(entity.getScheduledDate())
                .completedDate(entity.getCompletedDate())
                .technicianId(entity.getTechnicianId())
                .partsOrdered(entity.getPartsOrdered())
                .partsAvail(entity.getPartsAvail())
                .recallStatusName(RECALL_STATUS_NAMES.getOrDefault(entity.getRecallStatus(), entity.getRecallStatus()))
                .build();
    }

    private RecallNotificationResponse toNotificationResponse(RecallNotification entity) {
        return RecallNotificationResponse.builder()
                .notifId(entity.getNotifId())
                .recallId(entity.getRecallId())
                .vin(entity.getVin())
                .customerId(entity.getCustomerId())
                .notifType(entity.getNotifType())
                .notifDate(entity.getNotifDate())
                .responseFlag(entity.getResponseFlag())
                .notifTypeName(NOTIF_TYPE_NAMES.getOrDefault(entity.getNotifType(), entity.getNotifType()))
                .build();
    }
}
