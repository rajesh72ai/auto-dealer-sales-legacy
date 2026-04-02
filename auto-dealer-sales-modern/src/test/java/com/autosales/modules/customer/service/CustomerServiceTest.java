package com.autosales.modules.customer.service;

import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.security.SystemUser;
import com.autosales.common.security.SystemUserRepository;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.customer.dto.CustomerRequest;
import com.autosales.modules.customer.dto.CustomerResponse;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private DealerRepository dealerRepository;

    @Mock
    private SalesDealRepository salesDealRepository;

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private SystemUserRepository systemUserRepository;

    @Mock
    private FieldFormatter fieldFormatter;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private CustomerService customerService;

    private Customer sampleCustomer;

    @BeforeEach
    void setUp() {
        sampleCustomer = Customer.builder()
                .customerId(1)
                .firstName("John")
                .lastName("Doe")
                .middleInit("A")
                .dateOfBirth(LocalDate.of(1985, 3, 15))
                .ssnLast4("1234")
                .driversLicense("D1234567")
                .dlState("TX")
                .addressLine1("123 Main St")
                .city("Dallas")
                .stateCode("TX")
                .zipCode("75201")
                .homePhone("2145551234")
                .cellPhone("2145559876")
                .email("john.doe@example.com")
                .employerName("Acme Corp")
                .annualIncome(new BigDecimal("75000.00"))
                .customerType("I")
                .sourceCode("WEB")
                .dealerCode("DLR01")
                .assignedSales("SMITH01")
                .createdTs(LocalDateTime.of(2026, 1, 15, 10, 0))
                .updatedTs(LocalDateTime.of(2026, 1, 15, 10, 0))
                .build();
    }

    @Test
    @DisplayName("findById returns customer response when customer exists")
    void testFindById_success() {
        when(customerRepository.findById(1)).thenReturn(Optional.of(sampleCustomer));
        when(fieldFormatter.formatPhone("2145551234")).thenReturn("214-555-1234");
        when(fieldFormatter.formatPhone("2145559876")).thenReturn("214-555-9876");

        CustomerResponse response = customerService.findById(1);

        assertThat(response).isNotNull();
        assertThat(response.getCustomerId()).isEqualTo(1);
        assertThat(response.getFirstName()).isEqualTo("John");
        assertThat(response.getLastName()).isEqualTo("Doe");
        assertThat(response.getFullName()).isEqualTo("Doe, John");
        assertThat(response.getDealerCode()).isEqualTo("DLR01");
        assertThat(response.getFormattedPhone()).isEqualTo("214-555-1234");
        assertThat(response.getFormattedCellPhone()).isEqualTo("214-555-9876");
        verify(customerRepository).findById(1);
    }

    @Test
    @DisplayName("findById throws EntityNotFoundException when customer does not exist")
    void testFindById_notFound() {
        when(customerRepository.findById(999)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> customerService.findById(999))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessageContaining("Customer")
                .hasMessageContaining("999");
    }

    @Test
    @DisplayName("create sets timestamps, assigns salesperson, and saves customer")
    void testCreate_success() {
        CustomerRequest request = CustomerRequest.builder()
                .firstName("Jane")
                .lastName("Smith")
                .addressLine1("456 Oak Ave")
                .city("Austin")
                .stateCode("TX")
                .zipCode("73301")
                .cellPhone("5125551111")
                .customerType("I")
                .dealerCode("DLR01")
                .annualIncome(new BigDecimal("60000.00"))
                .build();

        // Dealer exists
        when(dealerRepository.existsById("DLR01")).thenReturn(true);

        // No duplicate
        when(customerRepository.findByLastNameAndCellPhoneAndDealerCode("Smith", "5125551111", "DLR01"))
                .thenReturn(Optional.empty());

        // Salesperson auto-assignment: request has no assignedSales
        SystemUser salesperson = SystemUser.builder()
                .userId("JONES01")
                .dealerCode("DLR01")
                .userType("S")
                .activeFlag("Y")
                .build();
        when(systemUserRepository.findAll()).thenReturn(List.of(salesperson));

        // Capture the saved entity
        ArgumentCaptor<Customer> captor = ArgumentCaptor.forClass(Customer.class);
        when(customerRepository.save(captor.capture())).thenAnswer(invocation -> {
            Customer c = invocation.getArgument(0);
            c.setCustomerId(2);
            return c;
        });

        when(fieldFormatter.formatPhone(any())).thenReturn("");

        CustomerResponse response = customerService.create(request);

        Customer saved = captor.getValue();
        assertThat(saved.getCreatedTs()).isNotNull();
        assertThat(saved.getUpdatedTs()).isNotNull();
        assertThat(saved.getAssignedSales()).isEqualTo("JONES01");
        assertThat(response.getCustomerId()).isEqualTo(2);
        assertThat(response.getFirstName()).isEqualTo("Jane");
        verify(customerRepository).save(any(Customer.class));
    }

    @Test
    @DisplayName("create throws DuplicateEntityException when duplicate customer found")
    void testCreate_duplicate() {
        CustomerRequest request = CustomerRequest.builder()
                .firstName("John")
                .lastName("Doe")
                .cellPhone("2145559876")
                .customerType("I")
                .dealerCode("DLR01")
                .build();

        when(dealerRepository.existsById("DLR01")).thenReturn(true);
        when(customerRepository.findByLastNameAndCellPhoneAndDealerCode("Doe", "2145559876", "DLR01"))
                .thenReturn(Optional.of(sampleCustomer));

        assertThatThrownBy(() -> customerService.create(request))
                .isInstanceOf(DuplicateEntityException.class)
                .hasMessageContaining("Customer")
                .hasMessageContaining("Doe/2145559876");

        verify(customerRepository, never()).save(any());
    }

    @Test
    @DisplayName("update modifies mutable fields and sets updatedTs")
    void testUpdate_success() {
        when(customerRepository.findById(1)).thenReturn(Optional.of(sampleCustomer));

        CustomerRequest request = CustomerRequest.builder()
                .firstName("Jonathan")
                .lastName("Doe")
                .middleInit("B")
                .addressLine1("789 Elm St")
                .city("Houston")
                .stateCode("TX")
                .zipCode("77001")
                .homePhone("7135551111")
                .cellPhone("7135552222")
                .email("jonathan.doe@example.com")
                .employerName("New Corp")
                .annualIncome(new BigDecimal("90000.00"))
                .customerType("I")
                .sourceCode("REF")
                .dealerCode("DLR01")
                .assignedSales("SMITH01")
                .build();

        ArgumentCaptor<Customer> captor = ArgumentCaptor.forClass(Customer.class);
        when(customerRepository.save(captor.capture())).thenAnswer(invocation -> invocation.getArgument(0));
        when(fieldFormatter.formatPhone(any())).thenReturn("");

        LocalDateTime beforeUpdate = LocalDateTime.now();
        CustomerResponse response = customerService.update(1, request);

        Customer saved = captor.getValue();
        assertThat(saved.getFirstName()).isEqualTo("Jonathan");
        assertThat(saved.getMiddleInit()).isEqualTo("B");
        assertThat(saved.getCity()).isEqualTo("Houston");
        assertThat(saved.getEmail()).isEqualTo("jonathan.doe@example.com");
        assertThat(saved.getAnnualIncome().compareTo(new BigDecimal("90000.00"))).isZero();
        assertThat(saved.getUpdatedTs()).isAfterOrEqualTo(beforeUpdate);
        // createdTs should remain unchanged
        assertThat(saved.getCreatedTs()).isEqualTo(sampleCustomer.getCreatedTs());
        assertThat(response).isNotNull();
        verify(customerRepository).save(any(Customer.class));
    }
}
