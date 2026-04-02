package com.autosales.modules.registration.service;

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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for RecallService.
 * Validates business logic ported from WRCRCL00 (recall management), WRCRCLB0 (batch feed), WRCNOTF0 (notifications).
 */
@ExtendWith(MockitoExtension.class)
class RecallServiceTest {

    @Mock private RecallCampaignRepository campaignRepository;
    @Mock private RecallVehicleRepository vehicleRepository;
    @Mock private RecallNotificationRepository notificationRepository;
    @Mock private ResponseFormatter responseFormatter;

    @InjectMocks
    private RecallService service;

    @BeforeEach
    void setUp() {
        lenient().when(responseFormatter.paginated(anyList(), anyInt(), anyInt(), anyLong()))
                .thenAnswer(inv -> new PaginatedResponse<>("success", null,
                        inv.getArgument(0), inv.getArgument(1), inv.getArgument(2), inv.getArgument(3),
                        LocalDateTime.now()));
    }

    private RecallCampaign buildCampaign() {
        return RecallCampaign.builder()
                .recallId("RCL2025001")
                .nhtsaNum("25V-001")
                .recallDesc("Airbag inflator may rupture during deployment")
                .severity("C")
                .affectedYears("2020-2023")
                .affectedModels("F-150, Bronco")
                .remedyDesc("Replace airbag inflator assembly")
                .remedyAvailDt(LocalDate.of(2025, 9, 1))
                .announcedDate(LocalDate.of(2025, 6, 1))
                .totalAffected(5)
                .totalCompleted(2)
                .campaignStatus("A")
                .createdTs(LocalDateTime.of(2025, 6, 1, 10, 0))
                .build();
    }

    private RecallVehicle buildRecallVehicle(String status) {
        return RecallVehicle.builder()
                .recallId("RCL2025001")
                .vin("1HGCM82633A004352")
                .dealerCode("D0001")
                .recallStatus(status)
                .partsOrdered("N")
                .partsAvail("N")
                .build();
    }

    // ─── WRCRCL00 INQ: Campaign Inquiry ─────────────────────────────────

    @Test
    @DisplayName("WRCRCL00 INQ: Campaign detail shows severity name and completion percentage")
    void testFindCampaignById_showsSeverityAndCompletion() {
        RecallCampaign campaign = buildCampaign();
        when(campaignRepository.findById("RCL2025001")).thenReturn(Optional.of(campaign));

        RecallCampaignResponse response = service.findCampaignById("RCL2025001");

        assertEquals("RCL2025001", response.getRecallId());
        assertEquals("Critical", response.getSeverityName());
        assertEquals("Active", response.getCampaignStatusName());
        assertEquals(40.0, response.getCompletionPercentage()); // 2/5 = 40%
    }

    @Test
    @DisplayName("WRCRCL00 INQ: Campaign not found throws EntityNotFoundException")
    void testFindCampaignById_notFound() {
        when(campaignRepository.findById("XXXX")).thenReturn(Optional.empty());
        assertThrows(EntityNotFoundException.class, () -> service.findCampaignById("XXXX"));
    }

    @Test
    @DisplayName("WRCRCL00 INQ: Completion percentage is 0 when totalAffected is 0")
    void testFindCampaignById_zeroAffected() {
        RecallCampaign campaign = buildCampaign();
        campaign.setTotalAffected(0);
        campaign.setTotalCompleted(0);
        when(campaignRepository.findById("RCL2025001")).thenReturn(Optional.of(campaign));

        RecallCampaignResponse response = service.findCampaignById("RCL2025001");
        assertEquals(0.0, response.getCompletionPercentage());
    }

    // ─── WRCRCLB0: Batch Campaign + Vehicle Ingestion ───────────────────

    @Test
    @DisplayName("WRCRCLB0: Create campaign sets status Active and counters to zero")
    void testCreateCampaign_setsStatusAndCounters() {
        RecallCampaignRequest request = RecallCampaignRequest.builder()
                .recallId("RCL2025004")
                .nhtsaNum("25V-004")
                .recallDesc("Brake line corrosion")
                .severity("H")
                .affectedYears("2021-2022")
                .affectedModels("Camry")
                .remedyDesc("Replace brake lines")
                .announcedDate(LocalDate.of(2025, 8, 1))
                .build();

        when(campaignRepository.existsById("RCL2025004")).thenReturn(false);
        when(campaignRepository.save(any(RecallCampaign.class))).thenAnswer(inv -> inv.getArgument(0));

        RecallCampaignResponse response = service.createCampaign(request);

        ArgumentCaptor<RecallCampaign> captor = ArgumentCaptor.forClass(RecallCampaign.class);
        verify(campaignRepository).save(captor.capture());
        assertEquals("A", captor.getValue().getCampaignStatus());
        assertEquals(0, captor.getValue().getTotalAffected());
        assertEquals(0, captor.getValue().getTotalCompleted());
    }

    @Test
    @DisplayName("WRCRCLB0: Reject duplicate campaign ID")
    void testCreateCampaign_rejectsDuplicate() {
        RecallCampaignRequest request = RecallCampaignRequest.builder()
                .recallId("RCL2025001").recallDesc("Test").severity("M")
                .affectedYears("2020").affectedModels("F-150").remedyDesc("Fix")
                .announcedDate(LocalDate.now()).build();

        when(campaignRepository.existsById("RCL2025001")).thenReturn(true);
        assertThrows(DuplicateEntityException.class, () -> service.createCampaign(request));
    }

    @Test
    @DisplayName("WRCRCLB0: Add vehicle to campaign sets status OP and increments totalAffected")
    void testAddVehicle_setsStatusAndIncrementsTotalAffected() {
        RecallCampaign campaign = buildCampaign();
        int originalAffected = campaign.getTotalAffected();
        when(campaignRepository.findById("RCL2025001")).thenReturn(Optional.of(campaign));
        when(vehicleRepository.existsById(any(RecallVehicleId.class))).thenReturn(false);
        when(vehicleRepository.save(any(RecallVehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(campaignRepository.save(any(RecallCampaign.class))).thenAnswer(inv -> inv.getArgument(0));

        RecallVehicleResponse response = service.addVehicle("RCL2025001", "1HGCM82633A004352", "D0001");

        assertEquals("OP", response.getRecallStatus());
        assertEquals("Open", response.getRecallStatusName());

        ArgumentCaptor<RecallCampaign> captor = ArgumentCaptor.forClass(RecallCampaign.class);
        verify(campaignRepository).save(captor.capture());
        assertEquals(originalAffected + 1, captor.getValue().getTotalAffected());
    }

    @Test
    @DisplayName("WRCRCLB0: Reject duplicate vehicle in same campaign")
    void testAddVehicle_rejectsDuplicate() {
        when(campaignRepository.findById("RCL2025001")).thenReturn(Optional.of(buildCampaign()));
        when(vehicleRepository.existsById(any(RecallVehicleId.class))).thenReturn(true);

        assertThrows(DuplicateEntityException.class, () ->
                service.addVehicle("RCL2025001", "1HGCM82633A004352", "D0001"));
    }

    // ─── WRCRCL00 UPD: Vehicle Status Updates ───────────────────────────

    @Test
    @DisplayName("WRCRCL00 UPD: OP→SC sets scheduled date")
    void testUpdateVehicleStatus_openToScheduled() {
        RecallVehicle vehicle = buildRecallVehicle("OP");
        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.save(any(RecallVehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        RecallVehicleStatusRequest request = RecallVehicleStatusRequest.builder()
                .newStatus("SC")
                .scheduledDate(LocalDate.of(2025, 9, 15))
                .technicianId("TECH001")
                .build();

        RecallVehicleResponse response = service.updateVehicleStatus("RCL2025001", "1HGCM82633A004352", request);

        assertEquals("SC", response.getRecallStatus());
        assertEquals("Scheduled", response.getRecallStatusName());
        assertEquals(LocalDate.of(2025, 9, 15), response.getScheduledDate());
        assertEquals("TECH001", response.getTechnicianId());
    }

    @Test
    @DisplayName("WRCRCL00 UPD: IP→CM sets completed date and increments campaign totalCompleted")
    void testUpdateVehicleStatus_completionIncrementsCounter() {
        RecallVehicle vehicle = buildRecallVehicle("IP");
        RecallCampaign campaign = buildCampaign();
        int originalCompleted = campaign.getTotalCompleted();

        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.save(any(RecallVehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(campaignRepository.findById("RCL2025001")).thenReturn(Optional.of(campaign));
        when(campaignRepository.save(any(RecallCampaign.class))).thenAnswer(inv -> inv.getArgument(0));

        RecallVehicleStatusRequest request = RecallVehicleStatusRequest.builder()
                .newStatus("CM")
                .technicianId("TECH001")
                .build();

        RecallVehicleResponse response = service.updateVehicleStatus("RCL2025001", "1HGCM82633A004352", request);

        assertEquals("CM", response.getRecallStatus());
        assertEquals(LocalDate.now(), response.getCompletedDate());

        ArgumentCaptor<RecallCampaign> captor = ArgumentCaptor.forClass(RecallCampaign.class);
        verify(campaignRepository).save(captor.capture());
        assertEquals(originalCompleted + 1, captor.getValue().getTotalCompleted());
    }

    @Test
    @DisplayName("WRCRCL00 UPD: OP→NA marks vehicle not applicable")
    void testUpdateVehicleStatus_notApplicable() {
        RecallVehicle vehicle = buildRecallVehicle("OP");
        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.save(any(RecallVehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        RecallVehicleStatusRequest request = RecallVehicleStatusRequest.builder()
                .newStatus("NA").build();

        RecallVehicleResponse response = service.updateVehicleStatus("RCL2025001", "1HGCM82633A004352", request);

        assertEquals("NA", response.getRecallStatus());
        assertEquals("Not Applicable", response.getRecallStatusName());
    }

    @Test
    @DisplayName("WRCRCL00 UPD: Invalid transition OP→CM is rejected")
    void testUpdateVehicleStatus_invalidTransition_openToComplete() {
        RecallVehicle vehicle = buildRecallVehicle("OP");
        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.of(vehicle));

        RecallVehicleStatusRequest request = RecallVehicleStatusRequest.builder()
                .newStatus("CM").build();

        assertThrows(BusinessValidationException.class, () ->
                service.updateVehicleStatus("RCL2025001", "1HGCM82633A004352", request));
    }

    @Test
    @DisplayName("WRCRCL00 UPD: Invalid transition SC→NA is rejected")
    void testUpdateVehicleStatus_invalidTransition_scheduledToNA() {
        RecallVehicle vehicle = buildRecallVehicle("SC");
        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.of(vehicle));

        RecallVehicleStatusRequest request = RecallVehicleStatusRequest.builder()
                .newStatus("NA").build();

        assertThrows(BusinessValidationException.class, () ->
                service.updateVehicleStatus("RCL2025001", "1HGCM82633A004352", request));
    }

    @Test
    @DisplayName("WRCRCL00 UPD: Vehicle not found in campaign throws EntityNotFoundException")
    void testUpdateVehicleStatus_vehicleNotFound() {
        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.empty());

        RecallVehicleStatusRequest request = RecallVehicleStatusRequest.builder()
                .newStatus("SC").build();

        assertThrows(EntityNotFoundException.class, () ->
                service.updateVehicleStatus("RCL2025001", "XXXX", request));
    }

    // ─── WRCNOTF0: Recall Notification Generator ────────────────────────

    @Test
    @DisplayName("WRCNOTF0: Create notification defaults to Mail type and response=N")
    void testCreateNotification_defaultsToMail() {
        when(campaignRepository.existsById("RCL2025001")).thenReturn(true);
        when(notificationRepository.existsByRecallIdAndVin("RCL2025001", "1HGCM82633A004352")).thenReturn(false);
        when(notificationRepository.save(any(RecallNotification.class))).thenAnswer(inv -> {
            RecallNotification n = inv.getArgument(0);
            n.setNotifId(1);
            return n;
        });
        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.empty());

        RecallNotificationResponse response = service.createNotification(
                "RCL2025001", "1HGCM82633A004352", 1001, null);

        assertEquals("M", response.getNotifType());
        assertEquals("Mail", response.getNotifTypeName());
        assertEquals("N", response.getResponseFlag());
        assertEquals(LocalDate.now(), response.getNotifDate());
    }

    @Test
    @DisplayName("WRCNOTF0: Reject duplicate notification for same recall/VIN")
    void testCreateNotification_rejectsDuplicate() {
        when(campaignRepository.existsById("RCL2025001")).thenReturn(true);
        when(notificationRepository.existsByRecallIdAndVin("RCL2025001", "1HGCM82633A004352")).thenReturn(true);

        assertThrows(DuplicateEntityException.class, () ->
                service.createNotification("RCL2025001", "1HGCM82633A004352", 1001, "M"));
    }

    @Test
    @DisplayName("WRCNOTF0: Notification updates recall vehicle's notified date")
    void testCreateNotification_updatesVehicleNotifiedDate() {
        when(campaignRepository.existsById("RCL2025001")).thenReturn(true);
        when(notificationRepository.existsByRecallIdAndVin(anyString(), anyString())).thenReturn(false);
        when(notificationRepository.save(any(RecallNotification.class))).thenAnswer(inv -> {
            RecallNotification n = inv.getArgument(0);
            n.setNotifId(1);
            return n;
        });

        RecallVehicle vehicle = buildRecallVehicle("OP");
        when(vehicleRepository.findById(any(RecallVehicleId.class))).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.save(any(RecallVehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        service.createNotification("RCL2025001", "1HGCM82633A004352", 1001, "E");

        ArgumentCaptor<RecallVehicle> captor = ArgumentCaptor.forClass(RecallVehicle.class);
        verify(vehicleRepository).save(captor.capture());
        assertEquals(LocalDate.now(), captor.getValue().getNotifiedDate());
    }

    @Test
    @DisplayName("WRCNOTF0: Campaign not found throws EntityNotFoundException")
    void testCreateNotification_campaignNotFound() {
        when(campaignRepository.existsById("XXXX")).thenReturn(false);

        assertThrows(EntityNotFoundException.class, () ->
                service.createNotification("XXXX", "1HGCM82633A004352", 1001, "M"));
    }

    // ─── WRCRCL00 VEH: Vehicle Listing ──────────────────────────────────

    @Test
    @DisplayName("WRCRCL00 VEH: List vehicles for campaign with status filter")
    void testFindVehiclesByRecall_withStatusFilter() {
        RecallVehicle vehicle = buildRecallVehicle("OP");
        Page<RecallVehicle> page = new PageImpl<>(List.of(vehicle), PageRequest.of(0, 20), 1);
        when(campaignRepository.existsById("RCL2025001")).thenReturn(true);
        when(vehicleRepository.findByRecallIdAndRecallStatus("RCL2025001", "OP", PageRequest.of(0, 20))).thenReturn(page);

        PaginatedResponse<RecallVehicleResponse> result = service.findVehiclesByRecall("RCL2025001", "OP", PageRequest.of(0, 20));

        assertNotNull(result);
        assertEquals(1, result.content().size());
        assertEquals("Open", result.content().get(0).getRecallStatusName());
    }

    @Test
    @DisplayName("WRCRCL00 VEH: Campaign not found throws error before listing vehicles")
    void testFindVehiclesByRecall_campaignNotFound() {
        when(campaignRepository.existsById("XXXX")).thenReturn(false);

        assertThrows(EntityNotFoundException.class, () ->
                service.findVehiclesByRecall("XXXX", null, PageRequest.of(0, 20)));
    }

    // ─── Severity Name Mappings ─────────────────────────────────────────

    @Test
    @DisplayName("WRCRCL00: Severity codes map correctly — C=Critical, H=High, M=Medium, L=Low")
    void testSeverityNameMapping() {
        for (var entry : java.util.Map.of("C", "Critical", "H", "High", "M", "Medium", "L", "Low").entrySet()) {
            RecallCampaign campaign = buildCampaign();
            campaign.setSeverity(entry.getKey());
            when(campaignRepository.findById("RCL2025001")).thenReturn(Optional.of(campaign));

            RecallCampaignResponse response = service.findCampaignById("RCL2025001");
            assertEquals(entry.getValue(), response.getSeverityName(),
                    "Severity " + entry.getKey() + " should map to " + entry.getValue());
        }
    }
}
