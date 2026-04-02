package com.autosales.modules.customer.service;

import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.customer.dto.LeadRequest;
import com.autosales.modules.customer.dto.LeadResponse;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.entity.CustomerLead;
import com.autosales.modules.customer.repository.CustomerLeadRepository;
import com.autosales.modules.customer.repository.CustomerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomerLeadServiceTest {

    @Mock
    private CustomerLeadRepository leadRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private CustomerLeadService customerLeadService;

    private Customer sampleCustomer;

    @BeforeEach
    void setUp() {
        sampleCustomer = Customer.builder()
                .customerId(1)
                .firstName("John")
                .lastName("Doe")
                .dealerCode("DLR01")
                .build();
    }

    @Test
    @DisplayName("create sets initial status to NW and contactCount to 0")
    void testCreate_success() {
        LeadRequest request = LeadRequest.builder()
                .customerId(1)
                .dealerCode("DLR01")
                .leadSource("WEB")
                .interestModel("CAMRY")
                .interestYear((short) 2026)
                .assignedSales("SMITH01")
                .followUpDate(LocalDate.of(2026, 4, 5))
                .notes("Interested in sedan")
                .build();

        when(customerRepository.findById(1)).thenReturn(Optional.of(sampleCustomer));

        ArgumentCaptor<CustomerLead> captor = ArgumentCaptor.forClass(CustomerLead.class);
        when(leadRepository.save(captor.capture())).thenAnswer(invocation -> {
            CustomerLead lead = invocation.getArgument(0);
            lead.setLeadId(100);
            return lead;
        });

        LeadResponse response = customerLeadService.create(request);

        CustomerLead saved = captor.getValue();
        assertThat(saved.getLeadStatus()).isEqualTo("NW");
        assertThat(saved.getContactCount()).isEqualTo((short) 0);
        assertThat(saved.getCreatedTs()).isNotNull();
        assertThat(saved.getUpdatedTs()).isNotNull();
        assertThat(saved.getCustomer()).isEqualTo(sampleCustomer);
        assertThat(saved.getDealerCode()).isEqualTo("DLR01");
        assertThat(saved.getLeadSource()).isEqualTo("WEB");

        assertThat(response).isNotNull();
        assertThat(response.getLeadId()).isEqualTo(100);
        assertThat(response.getLeadStatus()).isEqualTo("NW");
        assertThat(response.getCustomerName()).isEqualTo("Doe, John");
        verify(leadRepository).save(any(CustomerLead.class));
    }

    @Test
    @DisplayName("updateStatus increments contactCount and sets lastContactDt")
    void testUpdateStatus_success() {
        CustomerLead existingLead = CustomerLead.builder()
                .leadId(100)
                .customer(sampleCustomer)
                .dealerCode("DLR01")
                .leadSource("WEB")
                .interestModel("CAMRY")
                .interestYear((short) 2026)
                .leadStatus("NW")
                .assignedSales("SMITH01")
                .contactCount((short) 2)
                .createdTs(LocalDateTime.of(2026, 3, 1, 10, 0))
                .updatedTs(LocalDateTime.of(2026, 3, 1, 10, 0))
                .build();

        when(leadRepository.findById(100)).thenReturn(Optional.of(existingLead));

        ArgumentCaptor<CustomerLead> captor = ArgumentCaptor.forClass(CustomerLead.class);
        when(leadRepository.save(captor.capture())).thenAnswer(invocation -> invocation.getArgument(0));

        LocalDateTime beforeUpdate = LocalDateTime.now();
        LeadResponse response = customerLeadService.updateStatus(100, "CT");

        CustomerLead saved = captor.getValue();
        assertThat(saved.getLeadStatus()).isEqualTo("CT");
        assertThat(saved.getContactCount()).isEqualTo((short) 3);
        assertThat(saved.getLastContactDt()).isEqualTo(LocalDate.now());
        assertThat(saved.getUpdatedTs()).isAfterOrEqualTo(beforeUpdate);

        assertThat(response).isNotNull();
        assertThat(response.getLeadStatus()).isEqualTo("CT");
        verify(leadRepository).save(any(CustomerLead.class));
    }

    @Test
    @DisplayName("updateStatus throws IllegalStateException for closed lead statuses (WN, LS, DD)")
    void testUpdateStatus_closedLead() {
        for (String closedStatus : new String[]{"WN", "LS", "DD"}) {
            CustomerLead closedLead = CustomerLead.builder()
                    .leadId(200)
                    .customer(sampleCustomer)
                    .dealerCode("DLR01")
                    .leadSource("WEB")
                    .leadStatus(closedStatus)
                    .assignedSales("SMITH01")
                    .contactCount((short) 5)
                    .createdTs(LocalDateTime.of(2026, 3, 1, 10, 0))
                    .updatedTs(LocalDateTime.of(2026, 3, 15, 10, 0))
                    .build();

            when(leadRepository.findById(200)).thenReturn(Optional.of(closedLead));

            assertThatThrownBy(() -> customerLeadService.updateStatus(200, "CT"))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("closed status")
                    .hasMessageContaining(closedStatus);
        }

        verify(leadRepository, never()).save(any());
    }

    @Test
    @DisplayName("findById throws EntityNotFoundException when lead does not exist")
    void testFindById_notFound() {
        when(leadRepository.findById(999)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> customerLeadService.findById(999))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessageContaining("CustomerLead")
                .hasMessageContaining("999");
    }
}
