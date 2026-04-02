package com.autosales.modules.registration.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.registration.dto.WarrantyClaimRequest;
import com.autosales.modules.registration.dto.WarrantyClaimResponse;
import com.autosales.modules.registration.dto.WarrantyClaimSummaryResponse;
import com.autosales.modules.registration.entity.WarrantyClaim;
import com.autosales.modules.registration.repository.WarrantyClaimRepository;
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
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for WarrantyClaimService.
 * Validates business logic ported from WRCRPT00 (warranty claims summary report).
 */
@ExtendWith(MockitoExtension.class)
class WarrantyClaimServiceTest {

    @Mock private WarrantyClaimRepository claimRepository;
    @Mock private FieldFormatter fieldFormatter;
    @Mock private ResponseFormatter responseFormatter;

    @InjectMocks
    private WarrantyClaimService service;

    @BeforeEach
    void setUp() {
        lenient().when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$0.00");
        lenient().when(responseFormatter.paginated(anyList(), anyInt(), anyInt(), anyLong()))
                .thenAnswer(inv -> new PaginatedResponse<>("success", null,
                        inv.getArgument(0), inv.getArgument(1), inv.getArgument(2), inv.getArgument(3),
                        LocalDateTime.now()));
    }

    private WarrantyClaim buildClaim(String type, String status, BigDecimal labor, BigDecimal parts) {
        return WarrantyClaim.builder()
                .claimNumber("WC000001")
                .vin("1HGCM82633A004352")
                .dealerCode("D0001")
                .claimType(type)
                .claimDate(LocalDate.of(2025, 8, 15))
                .repairDate(LocalDate.of(2025, 8, 16))
                .laborAmt(labor)
                .partsAmt(parts)
                .totalClaim(labor.add(parts))
                .claimStatus(status)
                .technicianId("TECH001")
                .repairOrderNum("RO-001")
                .notes("Test claim")
                .createdTs(LocalDateTime.of(2025, 8, 15, 10, 0))
                .updatedTs(LocalDateTime.of(2025, 8, 15, 10, 0))
                .build();
    }

    private WarrantyClaimRequest buildRequest() {
        return WarrantyClaimRequest.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("D0001")
                .claimType("BA")
                .claimDate(LocalDate.of(2025, 8, 15))
                .laborAmt(new BigDecimal("250.00"))
                .partsAmt(new BigDecimal("150.00"))
                .technicianId("TECH001")
                .repairOrderNum("RO-001")
                .notes("Engine noise under warranty")
                .build();
    }

    // ─── Claim CRUD ─────────────────────────────────────────────────────

    @Test
    @DisplayName("Create warranty claim calculates total from labor + parts")
    void testCreate_calculatesTotal() {
        WarrantyClaimRequest request = buildRequest();
        when(claimRepository.save(any(WarrantyClaim.class))).thenAnswer(inv -> inv.getArgument(0));

        WarrantyClaimResponse response = service.create(request);

        assertNotNull(response);
        ArgumentCaptor<WarrantyClaim> captor = ArgumentCaptor.forClass(WarrantyClaim.class);
        verify(claimRepository).save(captor.capture());
        assertEquals(new BigDecimal("400.00"), captor.getValue().getTotalClaim());
    }

    @Test
    @DisplayName("Create warranty claim defaults status to NW (New)")
    void testCreate_defaultsStatusToNew() {
        WarrantyClaimRequest request = buildRequest();
        when(claimRepository.save(any(WarrantyClaim.class))).thenAnswer(inv -> inv.getArgument(0));

        service.create(request);

        ArgumentCaptor<WarrantyClaim> captor = ArgumentCaptor.forClass(WarrantyClaim.class);
        verify(claimRepository).save(captor.capture());
        assertEquals("NW", captor.getValue().getClaimStatus());
    }

    @Test
    @DisplayName("Cannot update a closed claim")
    void testUpdate_rejectsClosedClaim() {
        WarrantyClaim existing = buildClaim("BA", "CL", new BigDecimal("250.00"), new BigDecimal("150.00"));
        when(claimRepository.findById("WC000001")).thenReturn(Optional.of(existing));

        WarrantyClaimRequest request = buildRequest();
        assertThrows(BusinessValidationException.class, () -> service.update("WC000001", request));
    }

    @Test
    @DisplayName("Update warranty claim recalculates total")
    void testUpdate_recalculatesTotal() {
        WarrantyClaim existing = buildClaim("BA", "NW", new BigDecimal("250.00"), new BigDecimal("150.00"));
        when(claimRepository.findById("WC000001")).thenReturn(Optional.of(existing));
        when(claimRepository.save(any(WarrantyClaim.class))).thenAnswer(inv -> inv.getArgument(0));

        WarrantyClaimRequest request = buildRequest();
        request.setLaborAmt(new BigDecimal("300.00"));
        request.setPartsAmt(new BigDecimal("200.00"));

        service.update("WC000001", request);

        ArgumentCaptor<WarrantyClaim> captor = ArgumentCaptor.forClass(WarrantyClaim.class);
        verify(claimRepository).save(captor.capture());
        assertEquals(new BigDecimal("500.00"), captor.getValue().getTotalClaim());
    }

    @Test
    @DisplayName("Find claim by number returns not found for invalid claim")
    void testFindByClaimNumber_notFound() {
        when(claimRepository.findById("WC999999")).thenReturn(Optional.empty());
        assertThrows(EntityNotFoundException.class, () -> service.findByClaimNumber("WC999999"));
    }

    // ─── WRCRPT00: Warranty Claims Summary Report ───────────────────────

    @Test
    @DisplayName("WRCRPT00: Report groups claims by type with correct totals")
    void testReport_groupsByTypeWithTotals() {
        List<WarrantyClaim> claims = List.of(
                buildClaim("BA", "AP", new BigDecimal("200.00"), new BigDecimal("100.00")),
                buildClaim("BA", "DN", new BigDecimal("150.00"), new BigDecimal("50.00")),
                buildClaim("PT", "AP", new BigDecimal("300.00"), new BigDecimal("200.00")));

        // Set unique claim numbers
        claims.get(0).setClaimNumber("WC000001");
        claims.get(1).setClaimNumber("WC000002");
        claims.get(2).setClaimNumber("WC000003");

        when(claimRepository.findClaimsForReport(eq("D0001"), isNull(), isNull())).thenReturn(claims);

        WarrantyClaimSummaryResponse report = service.generateReport("D0001", null, null);

        assertEquals("D0001", report.getDealerCode());
        assertEquals(2, report.getByType().size());
        assertEquals(3, report.getGrandTotalClaims());

        // BA group
        var baGroup = report.getByType().stream().filter(g -> "BA".equals(g.getClaimType())).findFirst().orElseThrow();
        assertEquals(2, baGroup.getTotalClaims());
        assertEquals(new BigDecimal("350.00"), baGroup.getLaborTotal());
        assertEquals(new BigDecimal("150.00"), baGroup.getPartsTotal());
        assertEquals(new BigDecimal("500.00"), baGroup.getClaimTotal());
        assertEquals(1, baGroup.getApprovedCount());
        assertEquals(1, baGroup.getDeniedCount());

        // PT group
        var ptGroup = report.getByType().stream().filter(g -> "PT".equals(g.getClaimType())).findFirst().orElseThrow();
        assertEquals(1, ptGroup.getTotalClaims());
        assertEquals(new BigDecimal("500.00"), ptGroup.getClaimTotal());
    }

    @Test
    @DisplayName("WRCRPT00: Grand total and average calculation")
    void testReport_grandTotalAndAverage() {
        List<WarrantyClaim> claims = List.of(
                buildClaim("BA", "AP", new BigDecimal("200.00"), new BigDecimal("100.00")),
                buildClaim("PT", "AP", new BigDecimal("300.00"), new BigDecimal("200.00")));
        claims.get(0).setClaimNumber("WC000001");
        claims.get(1).setClaimNumber("WC000002");

        when(claimRepository.findClaimsForReport(eq("D0001"), isNull(), isNull())).thenReturn(claims);

        WarrantyClaimSummaryResponse report = service.generateReport("D0001", null, null);

        assertEquals(new BigDecimal("500.00"), report.getGrandTotalLabor());
        assertEquals(new BigDecimal("300.00"), report.getGrandTotalParts());
        assertEquals(new BigDecimal("800.00"), report.getGrandTotal());
        assertEquals(new BigDecimal("400.00"), report.getAverageClaimAmount());
    }

    @Test
    @DisplayName("WRCRPT00: Approved status includes AP, PA, PD — denied is DN only")
    void testReport_approvedDeniedCounting() {
        List<WarrantyClaim> claims = List.of(
                buildClaim("BA", "AP", new BigDecimal("100.00"), new BigDecimal("50.00")),
                buildClaim("BA", "PA", new BigDecimal("100.00"), new BigDecimal("50.00")),
                buildClaim("BA", "PD", new BigDecimal("100.00"), new BigDecimal("50.00")),
                buildClaim("BA", "DN", new BigDecimal("100.00"), new BigDecimal("50.00")),
                buildClaim("BA", "NW", new BigDecimal("100.00"), new BigDecimal("50.00")));
        for (int i = 0; i < claims.size(); i++) claims.get(i).setClaimNumber("WC00000" + i);

        when(claimRepository.findClaimsForReport(eq("D0001"), isNull(), isNull())).thenReturn(claims);

        WarrantyClaimSummaryResponse report = service.generateReport("D0001", null, null);

        assertEquals(3, report.getTotalApproved()); // AP + PA + PD
        assertEquals(1, report.getTotalDenied());   // DN only
    }

    @Test
    @DisplayName("WRCRPT00: Invalid date range FROM > TO throws validation error")
    void testReport_invalidDateRange() {
        assertThrows(BusinessValidationException.class, () ->
                service.generateReport("D0001", LocalDate.of(2025, 12, 1), LocalDate.of(2025, 1, 1)));
    }

    @Test
    @DisplayName("WRCRPT00: No claims found returns empty report with zeros")
    void testReport_emptyReport() {
        when(claimRepository.findClaimsForReport(eq("D0001"), isNull(), isNull())).thenReturn(List.of());

        WarrantyClaimSummaryResponse report = service.generateReport("D0001", null, null);

        assertEquals(0, report.getGrandTotalClaims());
        assertEquals(BigDecimal.ZERO, report.getGrandTotal());
        assertEquals(BigDecimal.ZERO, report.getAverageClaimAmount());
        assertTrue(report.getByType().isEmpty());
    }

    @Test
    @DisplayName("WRCRPT00: Claim type names map correctly — BA, PT, EX, GW, RC, CM, PD")
    void testReport_claimTypeNames() {
        WarrantyClaim claim = buildClaim("GW", "AP", new BigDecimal("100.00"), new BigDecimal("50.00"));
        when(claimRepository.findClaimsForReport(eq("D0001"), isNull(), isNull())).thenReturn(List.of(claim));

        WarrantyClaimSummaryResponse report = service.generateReport("D0001", null, null);

        assertEquals("Goodwill", report.getByType().get(0).getClaimTypeName());
    }

    @Test
    @DisplayName("List claims for dealer with status filter")
    void testFindByDealer_withStatusFilter() {
        WarrantyClaim claim = buildClaim("BA", "NW", new BigDecimal("250.00"), new BigDecimal("150.00"));
        Page<WarrantyClaim> page = new PageImpl<>(List.of(claim), PageRequest.of(0, 20), 1);
        when(claimRepository.findByDealerCodeAndClaimStatus("D0001", "NW", PageRequest.of(0, 20))).thenReturn(page);

        PaginatedResponse<WarrantyClaimResponse> result = service.findByDealer("D0001", "NW", PageRequest.of(0, 20));

        assertNotNull(result);
        assertEquals(1, result.content().size());
    }
}
