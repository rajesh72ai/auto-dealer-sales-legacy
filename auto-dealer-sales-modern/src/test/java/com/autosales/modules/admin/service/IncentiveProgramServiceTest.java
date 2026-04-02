package com.autosales.modules.admin.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.IncentiveProgramRequest;
import com.autosales.modules.admin.dto.IncentiveProgramResponse;
import com.autosales.modules.admin.entity.IncentiveProgram;
import com.autosales.modules.admin.repository.IncentiveProgramRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IncentiveProgramServiceTest {

    @Mock
    private IncentiveProgramRepository repository;

    @Mock
    private FieldFormatter fieldFormatter;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private IncentiveProgramService incentiveProgramService;

    private IncentiveProgramRequest buildRequest(LocalDate startDate, LocalDate endDate) {
        return IncentiveProgramRequest.builder()
                .incentiveId("INC001")
                .incentiveName("Summer Cash Back")
                .incentiveType("CR")
                .modelYear((short) 2025)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .regionCode("MTN")
                .amount(new BigDecimal("2500.00"))
                .rateOverride(null)
                .startDate(startDate)
                .endDate(endDate)
                .maxUnits(500)
                .stackableFlag("N")
                .activeFlag("Y")
                .build();
    }

    private IncentiveProgram buildEntity() {
        return IncentiveProgram.builder()
                .incentiveId("INC001")
                .incentiveName("Summer Cash Back")
                .incentiveType("CR")
                .modelYear((short) 2025)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .regionCode("MTN")
                .amount(new BigDecimal("2500.00"))
                .rateOverride(null)
                .startDate(LocalDate.of(2025, 6, 1))
                .endDate(LocalDate.of(2025, 9, 30))
                .maxUnits(500)
                .unitsUsed(0)
                .stackableFlag("N")
                .activeFlag("Y")
                .createdTs(LocalDateTime.of(2025, 5, 1, 10, 0))
                .build();
    }

    @Test
    void testCreate_success() {
        IncentiveProgramRequest request = buildRequest(
                LocalDate.of(2025, 6, 1), LocalDate.of(2025, 9, 30));
        when(repository.save(any(IncentiveProgram.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$2,500.00");

        IncentiveProgramResponse response = incentiveProgramService.create(request);

        assertNotNull(response);
        assertEquals("INC001", response.getIncentiveId());

        ArgumentCaptor<IncentiveProgram> captor = ArgumentCaptor.forClass(IncentiveProgram.class);
        verify(repository).save(captor.capture());
        IncentiveProgram saved = captor.getValue();
        assertEquals(0, saved.getUnitsUsed());
        assertNotNull(saved.getCreatedTs());
    }

    @Test
    void testCreate_endBeforeStart() {
        // End date is before start date
        IncentiveProgramRequest request = buildRequest(
                LocalDate.of(2025, 9, 30), LocalDate.of(2025, 6, 1));

        assertThrows(BusinessValidationException.class,
                () -> incentiveProgramService.create(request));
        verify(repository, never()).save(any());
    }

    @Test
    void testActivate_success() {
        IncentiveProgram entity = buildEntity();
        entity.setActiveFlag("N");
        when(repository.findById("INC001")).thenReturn(Optional.of(entity));
        when(repository.save(any(IncentiveProgram.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$2,500.00");

        IncentiveProgramResponse response = incentiveProgramService.activate("INC001");

        assertNotNull(response);
        assertEquals("Y", entity.getActiveFlag());
        verify(repository).save(entity);
    }

    @Test
    void testDeactivate_success() {
        IncentiveProgram entity = buildEntity();
        entity.setActiveFlag("Y");
        when(repository.findById("INC001")).thenReturn(Optional.of(entity));
        when(repository.save(any(IncentiveProgram.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fieldFormatter.formatCurrency(any(BigDecimal.class))).thenReturn("$2,500.00");

        IncentiveProgramResponse response = incentiveProgramService.deactivate("INC001");

        assertNotNull(response);
        assertEquals("N", entity.getActiveFlag());
        verify(repository).save(entity);
    }

    @Test
    void testFindById_notFound() {
        when(repository.findById("NOTEXIST")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> incentiveProgramService.findById("NOTEXIST"));
        verify(repository).findById("NOTEXIST");
    }
}
