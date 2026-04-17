package com.autosales.modules.registration.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.common.util.SequenceGenerator;
import com.autosales.modules.registration.dto.RegistrationRequest;
import com.autosales.modules.registration.dto.RegistrationResponse;
import com.autosales.modules.registration.dto.RegistrationStatusUpdateRequest;
import com.autosales.modules.registration.entity.Registration;
import com.autosales.modules.registration.entity.TitleStatus;
import com.autosales.modules.registration.repository.RegistrationRepository;
import com.autosales.modules.registration.repository.TitleStatusRepository;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for RegistrationService.
 * Validates business logic ported from REGGEN00, REGINQ00, REGVAL00, REGSUB00, REGSTS00.
 */
@ExtendWith(MockitoExtension.class)
class RegistrationServiceTest {

    @Mock private RegistrationRepository registrationRepository;
    @Mock private TitleStatusRepository titleStatusRepository;
    @Mock private SequenceGenerator sequenceGenerator;
    @Mock private FieldFormatter fieldFormatter;
    @Mock private ResponseFormatter responseFormatter;

    @InjectMocks
    private RegistrationService service;

    private Registration buildRegistration(String status) {
        return Registration.builder()
                .regId("R-000000000001")
                .dealNumber("D-0000000001")
                .vin("1HGCM82633A004352")
                .customerId(1001)
                .regState("CO")
                .regType("NW")
                .regStatus(status)
                .regFeePaid(new BigDecimal("85.00"))
                .titleFeePaid(new BigDecimal("7.20"))
                .createdTs(LocalDateTime.of(2025, 6, 1, 10, 0))
                .updatedTs(LocalDateTime.of(2025, 6, 1, 10, 0))
                .build();
    }

    private RegistrationRequest buildRequest() {
        return RegistrationRequest.builder()
                .dealNumber("D-0000000001")
                .vin("1HGCM82633A004352")
                .customerId(1001)
                .regState("CO")
                .regType("NW")
                .regFeePaid(new BigDecimal("85.00"))
                .titleFeePaid(new BigDecimal("7.20"))
                .lienHolder("Chase Auto Finance")
                .lienHolderAddr("123 Finance Blvd, New York, NY 10001")
                .build();
    }

    @BeforeEach
    void setUp() {
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$85.00");
        lenient().when(responseFormatter.paginated(anyList(), anyInt(), anyInt(), anyLong()))
                .thenAnswer(inv -> new PaginatedResponse<>("success", null,
                        inv.getArgument(0), inv.getArgument(1), inv.getArgument(2), inv.getArgument(3),
                        LocalDateTime.now()));
    }

    // ─── REGGEN00: Registration Document Generation ─────────────────────

    @Test
    @DisplayName("REGGEN00: Create registration generates unique ID and sets status PR")
    void testCreate_generatesIdAndSetsPreparingStatus() {
        RegistrationRequest request = buildRequest();
        when(registrationRepository.existsByDealNumber("D-0000000001")).thenReturn(false);
        when(sequenceGenerator.generateRegistrationId()).thenReturn("R-0000000016");
        when(registrationRepository.save(any(Registration.class))).thenAnswer(inv -> inv.getArgument(0));

        RegistrationResponse response = service.create(request);

        assertNotNull(response);
        assertEquals("R-0000000016", response.getRegId());
        assertEquals("PR", response.getRegStatus());
        assertEquals("Preparing", response.getRegStatusName());
        assertEquals("NW", response.getRegType());
        assertEquals("New", response.getRegTypeName());

        ArgumentCaptor<Registration> captor = ArgumentCaptor.forClass(Registration.class);
        verify(registrationRepository).save(captor.capture());
        Registration saved = captor.getValue();
        assertEquals("PR", saved.getRegStatus());
        assertNotNull(saved.getCreatedTs());
        assertEquals(saved.getCreatedTs(), saved.getUpdatedTs());
    }

    @Test
    @DisplayName("REGGEN00: Reject duplicate registration for same deal number")
    void testCreate_rejectsDuplicate() {
        RegistrationRequest request = buildRequest();
        when(registrationRepository.existsByDealNumber("D-0000000001")).thenReturn(true);

        assertThrows(DuplicateEntityException.class, () -> service.create(request));
        verify(registrationRepository, never()).save(any());
    }

    @Test
    @DisplayName("REGGEN00: Default fees to zero when not provided")
    void testCreate_defaultsFeesToZero() {
        RegistrationRequest request = buildRequest();
        request.setRegFeePaid(null);
        request.setTitleFeePaid(null);
        when(registrationRepository.existsByDealNumber(anyString())).thenReturn(false);
        when(sequenceGenerator.generateRegistrationId()).thenReturn("R-0000000017");
        when(registrationRepository.save(any(Registration.class))).thenAnswer(inv -> inv.getArgument(0));

        service.create(request);

        ArgumentCaptor<Registration> captor = ArgumentCaptor.forClass(Registration.class);
        verify(registrationRepository).save(captor.capture());
        assertEquals(BigDecimal.ZERO, captor.getValue().getRegFeePaid());
        assertEquals(BigDecimal.ZERO, captor.getValue().getTitleFeePaid());
    }

    @Test
    @DisplayName("REGGEN00: Stores lien holder info from finance application")
    void testCreate_storesLienHolderInfo() {
        RegistrationRequest request = buildRequest();
        when(registrationRepository.existsByDealNumber(anyString())).thenReturn(false);
        when(sequenceGenerator.generateRegistrationId()).thenReturn("R-0000000018");
        when(registrationRepository.save(any(Registration.class))).thenAnswer(inv -> inv.getArgument(0));

        service.create(request);

        ArgumentCaptor<Registration> captor = ArgumentCaptor.forClass(Registration.class);
        verify(registrationRepository).save(captor.capture());
        assertEquals("Chase Auto Finance", captor.getValue().getLienHolder());
        assertEquals("123 Finance Blvd, New York, NY 10001", captor.getValue().getLienHolderAddr());
    }

    // ─── REGINQ00: Registration Inquiry ─────────────────────────────────

    @Test
    @DisplayName("REGINQ00: Find registration by ID returns full details")
    void testFindById_returnsFullDetails() {
        Registration reg = buildRegistration("IS");
        reg.setPlateNumber("ABC-1234");
        reg.setTitleNumber("T2025-00001");
        reg.setIssuedDate(LocalDate.of(2025, 7, 15));
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));
        when(titleStatusRepository.findByRegIdOrderByStatusSeqDesc("R-000000000001")).thenReturn(List.of());

        RegistrationResponse response = service.findById("R-000000000001");

        assertNotNull(response);
        assertEquals("R-000000000001", response.getRegId());
        assertEquals("IS", response.getRegStatus());
        assertEquals("Issued", response.getRegStatusName());
        assertEquals("ABC-1234", response.getPlateNumber());
        assertEquals("T2025-00001", response.getTitleNumber());
    }

    @Test
    @DisplayName("REGINQ00: Inquiry for non-existent registration throws EntityNotFoundException")
    void testFindById_notFound() {
        when(registrationRepository.findById("XXXX")).thenReturn(Optional.empty());
        assertThrows(EntityNotFoundException.class, () -> service.findById("XXXX"));
    }

    @Test
    @DisplayName("REGINQ00: List registrations with status filter uses cursor pagination")
    void testFindAll_withStatusFilter() {
        Registration reg = buildRegistration("SB");
        Page<Registration> page = new PageImpl<>(List.of(reg), PageRequest.of(0, 20), 1);
        when(registrationRepository.findByRegStatus("SB", PageRequest.of(0, 20))).thenReturn(page);

        PaginatedResponse<RegistrationResponse> result = service.findAll("SB", PageRequest.of(0, 20));

        assertNotNull(result);
        assertEquals(1, result.content().size());
        assertEquals("SB", result.content().get(0).getRegStatus());
    }

    @Test
    @DisplayName("REGINQ00: Search by VIN returns matching registrations")
    void testFindByVin_returnsMatches() {
        Registration reg = buildRegistration("PR");
        when(registrationRepository.findByVin("1HGCM82633A004352")).thenReturn(List.of(reg));

        List<RegistrationResponse> results = service.findByVin("1HGCM82633A004352");

        assertEquals(1, results.size());
        assertEquals("1HGCM82633A004352", results.get(0).getVin());
    }

    // ─── REGVAL00: Registration Validation ──────────────────────────────

    @Test
    @DisplayName("REGVAL00: Validate registration with all checks passing sets status VL")
    void testValidate_allChecksPassing() {
        Registration reg = buildRegistration("PR");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));
        when(registrationRepository.save(any(Registration.class))).thenAnswer(inv -> inv.getArgument(0));

        RegistrationResponse response = service.validate("R-000000000001");

        assertEquals("VL", response.getRegStatus());
        assertEquals("Validated", response.getRegStatusName());
    }

    @Test
    @DisplayName("REGVAL00: Reject validation when registration not in Preparing status")
    void testValidate_rejectsNonPreparingStatus() {
        Registration reg = buildRegistration("SB");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> service.validate("R-000000000001"));
        assertTrue(ex.getMessage().contains("Preparing status"));
    }

    @Test
    @DisplayName("REGVAL00: Collect all validation failures — VIN, fees (does not short-circuit)")
    void testValidate_collectsAllFailures() {
        Registration reg = buildRegistration("PR");
        reg.setVin("SHORT");
        reg.setRegFeePaid(BigDecimal.ZERO);
        reg.setTitleFeePaid(BigDecimal.ZERO);
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> service.validate("R-000000000001"));
        // Should report both VIN and fees failures (not short-circuit)
        assertTrue(ex.getMessage().contains("VIN"));
        assertTrue(ex.getMessage().contains("fees"));
    }

    @Test
    @DisplayName("REGVAL00: Invalid registration type fails validation")
    void testValidate_invalidRegType() {
        Registration reg = buildRegistration("PR");
        reg.setRegType("XX");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> service.validate("R-000000000001"));
        assertTrue(ex.getMessage().contains("registration type"));
    }

    // ─── REGSUB00: Registration Submission ──────────────────────────────

    @Test
    @DisplayName("REGSUB00: Submit validated registration sets status SB with submission date")
    void testSubmit_setsStatusAndDate() {
        Registration reg = buildRegistration("VL");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));
        when(registrationRepository.save(any(Registration.class))).thenAnswer(inv -> inv.getArgument(0));
        when(titleStatusRepository.findMaxStatusSeqByRegId("R-000000000001")).thenReturn((short) 0);
        when(titleStatusRepository.save(any(TitleStatus.class))).thenAnswer(inv -> inv.getArgument(0));

        RegistrationResponse response = service.submit("R-000000000001");

        assertEquals("SB", response.getRegStatus());
        assertEquals(LocalDate.now(), response.getSubmissionDate());

        // Verify title status history entry created
        ArgumentCaptor<TitleStatus> tsCaptor = ArgumentCaptor.forClass(TitleStatus.class);
        verify(titleStatusRepository).save(tsCaptor.capture());
        assertEquals("SB", tsCaptor.getValue().getStatusCode());
        assertEquals("Submitted to State DMV", tsCaptor.getValue().getStatusDesc());
        assertEquals((short) 1, tsCaptor.getValue().getStatusSeq());
    }

    @Test
    @DisplayName("REGSUB00: Reject submission when registration not validated")
    void testSubmit_rejectsNonValidatedStatus() {
        Registration reg = buildRegistration("PR");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> service.submit("R-000000000001"));
        assertTrue(ex.getMessage().contains("validated"));
    }

    // ─── REGSTS00: Registration Status Update ───────────────────────────

    @Test
    @DisplayName("REGSTS00: Update SB→IS requires plate and title number, sets issued date")
    void testUpdateStatus_issuedRequiresPlateAndTitle() {
        Registration reg = buildRegistration("SB");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));
        when(registrationRepository.save(any(Registration.class))).thenAnswer(inv -> inv.getArgument(0));
        when(titleStatusRepository.findMaxStatusSeqByRegId("R-000000000001")).thenReturn((short) 1);
        when(titleStatusRepository.save(any(TitleStatus.class))).thenAnswer(inv -> inv.getArgument(0));
        when(titleStatusRepository.findByRegIdOrderByStatusSeqDesc("R-000000000001")).thenReturn(List.of());

        RegistrationStatusUpdateRequest request = RegistrationStatusUpdateRequest.builder()
                .newStatus("IS")
                .plateNumber("ABC-1234")
                .titleNumber("T2025-00001")
                .build();

        RegistrationResponse response = service.updateStatus("R-000000000001", request);

        assertEquals("IS", response.getRegStatus());
        assertEquals("ABC-1234", response.getPlateNumber());
        assertEquals("T2025-00001", response.getTitleNumber());
        assertNotNull(response.getIssuedDate());
    }

    @Test
    @DisplayName("REGSTS00: Update SB→IS fails without plate number")
    void testUpdateStatus_issuedFailsWithoutPlate() {
        Registration reg = buildRegistration("SB");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        RegistrationStatusUpdateRequest request = RegistrationStatusUpdateRequest.builder()
                .newStatus("IS")
                .titleNumber("T2025-00001")
                .build();

        assertThrows(BusinessValidationException.class,
                () -> service.updateStatus("R-000000000001", request));
    }

    @Test
    @DisplayName("REGSTS00: Update SB→RJ requires rejection reason")
    void testUpdateStatus_rejectionRequiresReason() {
        Registration reg = buildRegistration("SB");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        RegistrationStatusUpdateRequest request = RegistrationStatusUpdateRequest.builder()
                .newStatus("RJ")
                .build();

        assertThrows(BusinessValidationException.class,
                () -> service.updateStatus("R-000000000001", request));
    }

    @Test
    @DisplayName("REGSTS00: Invalid status transition PG→PG is rejected")
    void testUpdateStatus_invalidTransition() {
        Registration reg = buildRegistration("PG");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        RegistrationStatusUpdateRequest request = RegistrationStatusUpdateRequest.builder()
                .newStatus("PG")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> service.updateStatus("R-000000000001", request));
        assertTrue(ex.getMessage().contains("Cannot transition"));
    }

    @Test
    @DisplayName("REGSTS00: Cannot update status from Preparing (only SB/PG allowed)")
    void testUpdateStatus_cannotUpdateFromPreparing() {
        Registration reg = buildRegistration("PR");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));

        RegistrationStatusUpdateRequest request = RegistrationStatusUpdateRequest.builder()
                .newStatus("IS")
                .plateNumber("ABC-1234")
                .titleNumber("T2025-00001")
                .build();

        assertThrows(BusinessValidationException.class,
                () -> service.updateStatus("R-000000000001", request));
    }

    @Test
    @DisplayName("REGSTS00: SB→PG transition creates status history entry")
    void testUpdateStatus_processingCreatesHistory() {
        Registration reg = buildRegistration("SB");
        when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));
        when(registrationRepository.save(any(Registration.class))).thenAnswer(inv -> inv.getArgument(0));
        when(titleStatusRepository.findMaxStatusSeqByRegId("R-000000000001")).thenReturn((short) 1);
        when(titleStatusRepository.save(any(TitleStatus.class))).thenAnswer(inv -> inv.getArgument(0));
        when(titleStatusRepository.findByRegIdOrderByStatusSeqDesc("R-000000000001")).thenReturn(List.of());

        RegistrationStatusUpdateRequest request = RegistrationStatusUpdateRequest.builder()
                .newStatus("PG")
                .statusDesc("Processing at state DMV")
                .build();

        service.updateStatus("R-000000000001", request);

        ArgumentCaptor<TitleStatus> captor = ArgumentCaptor.forClass(TitleStatus.class);
        verify(titleStatusRepository).save(captor.capture());
        assertEquals("PG", captor.getValue().getStatusCode());
        assertEquals("Processing at state DMV", captor.getValue().getStatusDesc());
        assertEquals((short) 2, captor.getValue().getStatusSeq());
    }

    // ─── Registration Type Descriptions (from REGINQ00 screen map) ─────

    @Test
    @DisplayName("REGINQ00: Registration type codes map to correct descriptions")
    void testRegTypeDescriptions() {
        for (var entry : java.util.Map.of(
                "NW", "New", "TF", "Transfer", "RN", "Renewal", "DP", "Duplicate").entrySet()) {
            Registration reg = buildRegistration("PR");
            reg.setRegType(entry.getKey());
            when(registrationRepository.findById("R-000000000001")).thenReturn(Optional.of(reg));
            when(titleStatusRepository.findByRegIdOrderByStatusSeqDesc("R-000000000001")).thenReturn(List.of());

            RegistrationResponse response = service.findById("R-000000000001");
            assertEquals(entry.getValue(), response.getRegTypeName(),
                    "Type " + entry.getKey() + " should map to " + entry.getValue());
        }
    }
}
