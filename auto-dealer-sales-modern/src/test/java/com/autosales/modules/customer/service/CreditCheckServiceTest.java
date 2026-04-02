package com.autosales.modules.customer.service;

import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.customer.dto.CreditCheckRequest;
import com.autosales.modules.customer.dto.CreditCheckResponse;
import com.autosales.modules.customer.entity.CreditCheck;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CreditCheckRepository;
import com.autosales.modules.customer.repository.CustomerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.math.RoundingMode;
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
class CreditCheckServiceTest {

    @Mock
    private CreditCheckRepository creditCheckRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private FieldFormatter fieldFormatter;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private CreditCheckService creditCheckService;

    private Customer highIncomeCustomer;
    private Customer lowIncomeCustomer;

    @BeforeEach
    void setUp() {
        highIncomeCustomer = Customer.builder()
                .customerId(1)
                .firstName("John")
                .lastName("Doe")
                .annualIncome(new BigDecimal("120000.00"))
                .dealerCode("DLR01")
                .build();

        lowIncomeCustomer = Customer.builder()
                .customerId(2)
                .firstName("Jane")
                .lastName("Smith")
                .annualIncome(new BigDecimal("30000.00"))
                .dealerCode("DLR01")
                .build();
    }

    @Test
    @DisplayName("checkCredit with high income (>100K) assigns tier A, score 800, max financing 5x")
    void testCheckCredit_highIncome() {
        CreditCheckRequest request = CreditCheckRequest.builder()
                .customerId(1)
                .monthlyDebt(new BigDecimal("500.00"))
                .bureauCode("EQ")
                .build();

        when(customerRepository.findById(1)).thenReturn(Optional.of(highIncomeCustomer));
        // No existing valid credit check
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1), eq("RC"), any(LocalDate.class))).thenReturn(Optional.empty());
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1), eq("AP"), any(LocalDate.class))).thenReturn(Optional.empty());

        ArgumentCaptor<CreditCheck> captor = ArgumentCaptor.forClass(CreditCheck.class);
        when(creditCheckRepository.save(captor.capture())).thenAnswer(invocation -> {
            CreditCheck cc = invocation.getArgument(0);
            cc.setCreditId(100);
            return cc;
        });

        CreditCheckResponse response = creditCheckService.checkCredit(request);

        CreditCheck saved = captor.getValue();
        assertThat(saved.getCreditTier()).isEqualTo("A");
        assertThat(saved.getCreditScore()).isEqualTo((short) 800);
        assertThat(saved.getStatus()).isEqualTo("AP");

        // Max financing = 120000 * 5 = 600000 (DTI is low, no reduction)
        BigDecimal expectedMax = new BigDecimal("120000.00").multiply(BigDecimal.valueOf(5));
        assertThat(response.getMaxFinancing().compareTo(expectedMax)).isZero();
        assertThat(response.getMessage()).contains("Tier A");
    }

    @Test
    @DisplayName("checkCredit with low income (<35K) assigns tier E, score 520")
    void testCheckCredit_lowIncome() {
        CreditCheckRequest request = CreditCheckRequest.builder()
                .customerId(2)
                .monthlyDebt(new BigDecimal("200.00"))
                .bureauCode("EQ")
                .build();

        when(customerRepository.findById(2)).thenReturn(Optional.of(lowIncomeCustomer));
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(2), eq("RC"), any(LocalDate.class))).thenReturn(Optional.empty());
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(2), eq("AP"), any(LocalDate.class))).thenReturn(Optional.empty());

        ArgumentCaptor<CreditCheck> captor = ArgumentCaptor.forClass(CreditCheck.class);
        when(creditCheckRepository.save(captor.capture())).thenAnswer(invocation -> {
            CreditCheck cc = invocation.getArgument(0);
            cc.setCreditId(101);
            return cc;
        });

        CreditCheckResponse response = creditCheckService.checkCredit(request);

        CreditCheck saved = captor.getValue();
        assertThat(saved.getCreditTier()).isEqualTo("E");
        assertThat(saved.getCreditScore()).isEqualTo((short) 520);
        assertThat(response.getMessage()).contains("Tier E");
    }

    @Test
    @DisplayName("checkCredit reuses existing valid credit check and does not save a new one")
    void testCheckCredit_reusesExisting() {
        CreditCheckRequest request = CreditCheckRequest.builder()
                .customerId(1)
                .monthlyDebt(new BigDecimal("500.00"))
                .bureauCode("EQ")
                .build();

        CreditCheck existingCheck = CreditCheck.builder()
                .creditId(50)
                .customer(highIncomeCustomer)
                .bureauCode("EQ")
                .creditScore((short) 800)
                .creditTier("A")
                .requestTs(LocalDateTime.now().minusDays(5))
                .responseTs(LocalDateTime.now().minusDays(5))
                .status("RC")
                .monthlyDebt(new BigDecimal("500.00"))
                .monthlyIncome(new BigDecimal("10000.00"))
                .dtiRatio(new BigDecimal("5.00"))
                .expiryDate(LocalDate.now().plusDays(25))
                .build();

        when(customerRepository.findById(1)).thenReturn(Optional.of(highIncomeCustomer));
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1), eq("RC"), any(LocalDate.class))).thenReturn(Optional.of(existingCheck));

        CreditCheckResponse response = creditCheckService.checkCredit(request);

        assertThat(response).isNotNull();
        assertThat(response.getCreditId()).isEqualTo(50);
        assertThat(response.getCreditTier()).isEqualTo("A");
        // Verify no new credit check was saved
        verify(creditCheckRepository, never()).save(any());
    }

    @Test
    @DisplayName("checkCredit with high DTI (>50%) reduces max financing by 25%")
    void testCheckCredit_dtiAdjustment() {
        // Customer with 120K income, monthly income = 10000
        // Monthly debt = 6000 -> DTI = (6000/10000)*100 = 60% (>50%)
        CreditCheckRequest request = CreditCheckRequest.builder()
                .customerId(1)
                .monthlyDebt(new BigDecimal("6000.00"))
                .bureauCode("EQ")
                .build();

        when(customerRepository.findById(1)).thenReturn(Optional.of(highIncomeCustomer));
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1), eq("RC"), any(LocalDate.class))).thenReturn(Optional.empty());
        when(creditCheckRepository.findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                eq(1), eq("AP"), any(LocalDate.class))).thenReturn(Optional.empty());

        ArgumentCaptor<CreditCheck> captor = ArgumentCaptor.forClass(CreditCheck.class);
        when(creditCheckRepository.save(captor.capture())).thenAnswer(invocation -> {
            CreditCheck cc = invocation.getArgument(0);
            cc.setCreditId(102);
            return cc;
        });

        CreditCheckResponse response = creditCheckService.checkCredit(request);

        // Base max financing: 120000 * 5 = 600000
        // DTI > 50%, so reduced by 25%: 600000 * 0.75 = 450000.00
        BigDecimal expectedMax = new BigDecimal("600000").multiply(new BigDecimal("0.75"))
                .setScale(2, RoundingMode.HALF_UP);
        assertThat(response.getMaxFinancing().compareTo(expectedMax)).isZero();

        CreditCheck saved = captor.getValue();
        assertThat(saved.getDtiRatio().compareTo(new BigDecimal("60.00"))).isZero();
    }

    @Test
    @DisplayName("findByCustomerId returns credit checks ordered by request date descending")
    void testFindByCustomerId() {
        CreditCheck check1 = CreditCheck.builder()
                .creditId(10)
                .customer(highIncomeCustomer)
                .bureauCode("EQ")
                .creditScore((short) 800)
                .creditTier("A")
                .requestTs(LocalDateTime.of(2026, 3, 1, 10, 0))
                .status("AP")
                .monthlyDebt(BigDecimal.ZERO)
                .monthlyIncome(new BigDecimal("10000.00"))
                .dtiRatio(BigDecimal.ZERO)
                .expiryDate(LocalDate.of(2026, 3, 31))
                .build();

        CreditCheck check2 = CreditCheck.builder()
                .creditId(11)
                .customer(highIncomeCustomer)
                .bureauCode("TU")
                .creditScore((short) 780)
                .creditTier("A")
                .requestTs(LocalDateTime.of(2026, 2, 1, 10, 0))
                .status("RC")
                .monthlyDebt(new BigDecimal("500.00"))
                .monthlyIncome(new BigDecimal("10000.00"))
                .dtiRatio(new BigDecimal("5.00"))
                .expiryDate(LocalDate.of(2026, 3, 3))
                .build();

        when(customerRepository.findById(1)).thenReturn(Optional.of(highIncomeCustomer));
        when(creditCheckRepository.findByCustomer_CustomerIdOrderByRequestTsDesc(1))
                .thenReturn(List.of(check1, check2));

        List<CreditCheckResponse> results = creditCheckService.findByCustomerId(1);

        assertThat(results).hasSize(2);
        assertThat(results.get(0).getCreditId()).isEqualTo(10);
        assertThat(results.get(1).getCreditId()).isEqualTo(11);
        verify(creditCheckRepository).findByCustomer_CustomerIdOrderByRequestTsDesc(1);
    }
}
