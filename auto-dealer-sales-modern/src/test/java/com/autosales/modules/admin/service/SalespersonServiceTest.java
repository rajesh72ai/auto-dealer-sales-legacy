package com.autosales.modules.admin.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.SalespersonRequest;
import com.autosales.modules.admin.dto.SalespersonResponse;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.entity.Salesperson;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.admin.repository.SalespersonRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SalespersonServiceTest {

    @Mock
    private SalespersonRepository repository;

    @Mock
    private DealerRepository dealerRepository;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private SalespersonService salespersonService;

    private Dealer buildDealer() {
        return Dealer.builder()
                .dealerCode("D0001")
                .dealerName("Test Motors")
                .addressLine1("123 Main St")
                .city("Denver")
                .stateCode("CO")
                .zipCode("80202")
                .phoneNumber("3035551234")
                .dealerPrincipal("John Doe")
                .regionCode("MTN")
                .zoneCode("W1")
                .oemDealerNum("OEM12345")
                .maxInventory((short) 200)
                .activeFlag("Y")
                .openedDate(LocalDate.of(2020, 1, 15))
                .createdTs(LocalDateTime.of(2020, 1, 15, 10, 0))
                .updatedTs(LocalDateTime.of(2020, 6, 1, 14, 30))
                .build();
    }

    private Salesperson buildSalesperson(Dealer dealer) {
        return Salesperson.builder()
                .salespersonId("SP00001")
                .salespersonName("Jane Smith")
                .dealer(dealer)
                .hireDate(LocalDate.of(2022, 3, 1))
                .terminationDate(null)
                .commissionPlan("ST")
                .activeFlag("Y")
                .createdTs(LocalDateTime.of(2022, 3, 1, 9, 0))
                .updatedTs(LocalDateTime.of(2022, 3, 1, 9, 0))
                .build();
    }

    private SalespersonRequest buildRequest() {
        return SalespersonRequest.builder()
                .salespersonId("SP00001")
                .salespersonName("Jane Smith")
                .dealerCode("D0001")
                .hireDate(LocalDate.of(2022, 3, 1))
                .terminationDate(null)
                .commissionPlan("ST")
                .activeFlag("Y")
                .build();
    }

    @Test
    void testCreate_success() {
        SalespersonRequest request = buildRequest();
        Dealer dealer = buildDealer();
        when(repository.existsById("SP00001")).thenReturn(false);
        when(dealerRepository.findById("D0001")).thenReturn(Optional.of(dealer));
        when(repository.save(any(Salesperson.class))).thenAnswer(inv -> inv.getArgument(0));

        SalespersonResponse response = salespersonService.create(request);

        assertNotNull(response);
        assertEquals("SP00001", response.getSalespersonId());
        assertEquals("D0001", response.getDealerCode());

        // Verify dealer existence was checked
        verify(dealerRepository).findById("D0001");

        ArgumentCaptor<Salesperson> captor = ArgumentCaptor.forClass(Salesperson.class);
        verify(repository).save(captor.capture());
        Salesperson saved = captor.getValue();
        assertNotNull(saved.getCreatedTs());
        assertNotNull(saved.getUpdatedTs());
        assertEquals(saved.getCreatedTs(), saved.getUpdatedTs());
    }

    @Test
    void testCreate_dealerNotFound() {
        SalespersonRequest request = buildRequest();
        request.setDealerCode("XXXXX");
        when(repository.existsById("SP00001")).thenReturn(false);
        when(dealerRepository.findById("XXXXX")).thenReturn(Optional.empty());

        // SalespersonService throws BusinessValidationException when dealer not found
        assertThrows(BusinessValidationException.class,
                () -> salespersonService.create(request));
        verify(repository, never()).save(any());
    }

    @Test
    void testFindById_success() {
        Dealer dealer = buildDealer();
        Salesperson entity = buildSalesperson(dealer);
        when(repository.findById("SP00001")).thenReturn(Optional.of(entity));

        SalespersonResponse response = salespersonService.findById("SP00001");

        assertNotNull(response);
        assertEquals("SP00001", response.getSalespersonId());
        assertEquals("Jane Smith", response.getSalespersonName());
        assertEquals("D0001", response.getDealerCode());
        assertEquals("Test Motors", response.getDealerName());
        verify(repository).findById("SP00001");
    }

    @Test
    void testUpdate_success() {
        Dealer dealer = buildDealer();
        Salesperson existing = buildSalesperson(dealer);
        when(repository.findById("SP00001")).thenReturn(Optional.of(existing));
        when(repository.save(any(Salesperson.class))).thenAnswer(inv -> inv.getArgument(0));

        SalespersonRequest request = buildRequest();
        request.setSalespersonName("Jane Doe");
        request.setCommissionPlan("SR");
        request.setActiveFlag("N");

        SalespersonResponse response = salespersonService.update("SP00001", request);

        assertNotNull(response);
        assertEquals("Jane Doe", response.getSalespersonName());
        assertEquals("SR", existing.getCommissionPlan());
        assertEquals("N", existing.getActiveFlag());
        assertNotNull(existing.getUpdatedTs());
        verify(repository).save(existing);
    }
}
