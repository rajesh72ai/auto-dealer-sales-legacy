package com.autosales.modules.admin.service;

import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.DealerRequest;
import com.autosales.modules.admin.dto.DealerResponse;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.repository.DealerRepository;
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
class DealerServiceTest {

    @Mock
    private DealerRepository repository;

    @Mock
    private FieldFormatter fieldFormatter;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private DealerService dealerService;

    private Dealer buildDealer() {
        return Dealer.builder()
                .dealerCode("D0001")
                .dealerName("Test Motors")
                .addressLine1("123 Main St")
                .addressLine2("Suite 100")
                .city("Denver")
                .stateCode("CO")
                .zipCode("80202")
                .phoneNumber("3035551234")
                .faxNumber("3035555678")
                .dealerPrincipal("John Doe")
                .regionCode("MTN")
                .zoneCode("W1")
                .oemDealerNum("OEM12345")
                .floorPlanLenderId("FPL01")
                .maxInventory((short) 200)
                .activeFlag("Y")
                .openedDate(LocalDate.of(2020, 1, 15))
                .createdTs(LocalDateTime.of(2020, 1, 15, 10, 0))
                .updatedTs(LocalDateTime.of(2020, 6, 1, 14, 30))
                .build();
    }

    private DealerRequest buildDealerRequest() {
        return DealerRequest.builder()
                .dealerCode("D0001")
                .dealerName("Test Motors")
                .addressLine1("123 Main St")
                .addressLine2("Suite 100")
                .city("Denver")
                .stateCode("CO")
                .zipCode("80202")
                .phoneNumber("3035551234")
                .faxNumber("3035555678")
                .dealerPrincipal("John Doe")
                .regionCode("MTN")
                .zoneCode("W1")
                .oemDealerNum("OEM12345")
                .floorPlanLenderId("FPL01")
                .maxInventory((short) 200)
                .activeFlag("Y")
                .openedDate(LocalDate.of(2020, 1, 15))
                .build();
    }

    @Test
    void testFindByCode_success() {
        Dealer dealer = buildDealer();
        when(repository.findById("D0001")).thenReturn(Optional.of(dealer));
        when(fieldFormatter.formatPhone("3035551234")).thenReturn("303-555-1234");
        when(fieldFormatter.formatPhone("3035555678")).thenReturn("303-555-5678");

        DealerResponse response = dealerService.findByCode("D0001");

        assertNotNull(response);
        assertEquals("D0001", response.getDealerCode());
        assertEquals("Test Motors", response.getDealerName());
        assertEquals("Denver", response.getCity());
        assertEquals("CO", response.getStateCode());
        assertEquals("303-555-1234", response.getFormattedPhone());
        assertEquals("303-555-5678", response.getFormattedFax());
        verify(repository).findById("D0001");
    }

    @Test
    void testFindByCode_notFound() {
        when(repository.findById("XXXXX")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> dealerService.findByCode("XXXXX"));
        verify(repository).findById("XXXXX");
    }

    @Test
    void testCreate_success() {
        DealerRequest request = buildDealerRequest();
        when(repository.existsById("D0001")).thenReturn(false);
        when(repository.save(any(Dealer.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fieldFormatter.formatPhone(anyString())).thenReturn("303-555-1234");

        DealerResponse response = dealerService.create(request);

        assertNotNull(response);
        assertEquals("D0001", response.getDealerCode());

        ArgumentCaptor<Dealer> captor = ArgumentCaptor.forClass(Dealer.class);
        verify(repository).save(captor.capture());
        Dealer saved = captor.getValue();
        assertNotNull(saved.getCreatedTs());
        assertNotNull(saved.getUpdatedTs());
        assertEquals(saved.getCreatedTs(), saved.getUpdatedTs());
    }

    @Test
    void testCreate_duplicate() {
        DealerRequest request = buildDealerRequest();
        when(repository.existsById("D0001")).thenReturn(true);

        assertThrows(DuplicateEntityException.class,
                () -> dealerService.create(request));
        verify(repository, never()).save(any());
    }

    @Test
    void testUpdate_success() {
        Dealer existing = buildDealer();
        LocalDateTime originalCreatedTs = existing.getCreatedTs();
        when(repository.findById("D0001")).thenReturn(Optional.of(existing));
        when(repository.save(any(Dealer.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fieldFormatter.formatPhone(anyString())).thenReturn("303-555-1234");

        DealerRequest request = buildDealerRequest();
        request.setDealerName("Updated Motors");
        request.setCity("Boulder");
        request.setMaxInventory((short) 300);

        DealerResponse response = dealerService.update("D0001", request);

        assertNotNull(response);
        assertEquals("Updated Motors", response.getDealerName());
        assertEquals("Boulder", response.getCity());
        assertEquals((short) 300, response.getMaxInventory());
        // createdTs should not change
        assertEquals(originalCreatedTs, existing.getCreatedTs());
        // updatedTs should be refreshed
        assertNotNull(existing.getUpdatedTs());
        verify(repository).save(existing);
    }
}
