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
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Service for credit check processing.
 * Port of CUSTCRD00.cbl — customer credit check transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class CreditCheckService {

    private final CreditCheckRepository creditCheckRepository;
    private final CustomerRepository customerRepository;
    private final FieldFormatter fieldFormatter;
    private final ResponseFormatter responseFormatter;

    public CreditCheckService(CreditCheckRepository creditCheckRepository,
                              CustomerRepository customerRepository,
                              FieldFormatter fieldFormatter,
                              ResponseFormatter responseFormatter) {
        this.creditCheckRepository = creditCheckRepository;
        this.customerRepository = customerRepository;
        this.fieldFormatter = fieldFormatter;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Run a credit check for a customer. Reuses existing valid credit check if available.
     */
    @Transactional
    public CreditCheckResponse checkCredit(CreditCheckRequest request) {
        log.info("Processing credit check for customerId={}", request.getCustomerId());

        Customer customer = customerRepository.findById(request.getCustomerId())
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(request.getCustomerId())));

        // Check for existing valid credit check (status='RC' or 'AP', expiry >= today)
        Optional<CreditCheck> existingRc = creditCheckRepository
                .findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                        request.getCustomerId(), "RC", LocalDate.now());
        if (existingRc.isPresent()) {
            log.info("Reusing existing credit check id={} (status=RC)", existingRc.get().getCreditId());
            return toResponse(existingRc.get(), customer);
        }

        Optional<CreditCheck> existingAp = creditCheckRepository
                .findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                        request.getCustomerId(), "AP", LocalDate.now());
        if (existingAp.isPresent()) {
            log.info("Reusing existing credit check id={} (status=AP)", existingAp.get().getCreditId());
            return toResponse(existingAp.get(), customer);
        }

        // Calculate credit tier and related values
        BigDecimal annualIncome = customer.getAnnualIncome() != null
                ? customer.getAnnualIncome() : BigDecimal.ZERO;
        BigDecimal monthlyIncome = annualIncome.divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_UP);

        BigDecimal monthlyDebt = request.getMonthlyDebt() != null
                ? request.getMonthlyDebt() : BigDecimal.ZERO;

        String bureauCode = request.getBureauCode() != null ? request.getBureauCode() : "EQ";

        // Determine credit tier by income
        String creditTier;
        short creditScore;
        int multiplier;
        if (annualIncome.compareTo(BigDecimal.valueOf(100000)) > 0) {
            creditTier = "A";
            creditScore = 800;
            multiplier = 5;
        } else if (annualIncome.compareTo(BigDecimal.valueOf(75000)) > 0) {
            creditTier = "B";
            creditScore = 720;
            multiplier = 4;
        } else if (annualIncome.compareTo(BigDecimal.valueOf(50000)) > 0) {
            creditTier = "C";
            creditScore = 660;
            multiplier = 3;
        } else if (annualIncome.compareTo(BigDecimal.valueOf(35000)) > 0) {
            creditTier = "D";
            creditScore = 600;
            multiplier = 2;
        } else {
            creditTier = "E";
            creditScore = 520;
            multiplier = 1;
        }

        // Calculate DTI ratio
        BigDecimal dtiRatio = BigDecimal.ZERO;
        if (monthlyIncome.compareTo(BigDecimal.ZERO) > 0) {
            dtiRatio = monthlyDebt.divide(monthlyIncome, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(2, RoundingMode.HALF_UP);
        }

        // Calculate max financing
        BigDecimal maxFinancing = annualIncome.multiply(BigDecimal.valueOf(multiplier));

        // DTI adjustment: >50% reduce 25%, >40% reduce 10%
        if (dtiRatio.compareTo(BigDecimal.valueOf(50)) > 0) {
            maxFinancing = maxFinancing.multiply(BigDecimal.valueOf(0.75)).setScale(2, RoundingMode.HALF_UP);
        } else if (dtiRatio.compareTo(BigDecimal.valueOf(40)) > 0) {
            maxFinancing = maxFinancing.multiply(BigDecimal.valueOf(0.90)).setScale(2, RoundingMode.HALF_UP);
        }

        // Save credit check
        LocalDateTime now = LocalDateTime.now();
        CreditCheck creditCheck = CreditCheck.builder()
                .customer(customer)
                .bureauCode(bureauCode)
                .creditScore(creditScore)
                .creditTier(creditTier)
                .requestTs(now)
                .responseTs(now)
                .status("AP")
                .monthlyDebt(monthlyDebt)
                .monthlyIncome(monthlyIncome)
                .dtiRatio(dtiRatio)
                .expiryDate(LocalDate.now().plusDays(30))
                .build();

        CreditCheck saved = creditCheckRepository.save(creditCheck);
        log.info("Created credit check id={}, tier={}, score={}", saved.getCreditId(), creditTier, creditScore);

        CreditCheckResponse response = toResponse(saved, customer);
        response.setMaxFinancing(maxFinancing);
        response.setMessage("Credit check approved - Tier " + creditTier);
        return response;
    }

    /**
     * Find a credit check by ID.
     */
    public CreditCheckResponse findById(Integer creditId) {
        log.debug("Finding credit check by id={}", creditId);
        CreditCheck creditCheck = creditCheckRepository.findById(creditId)
                .orElseThrow(() -> new EntityNotFoundException("CreditCheck", String.valueOf(creditId)));
        Customer customer = creditCheck.getCustomer();
        return toResponse(creditCheck, customer);
    }

    /**
     * Find all credit checks for a customer, most recent first.
     */
    public List<CreditCheckResponse> findByCustomerId(Integer customerId) {
        log.debug("Finding credit checks for customerId={}", customerId);

        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(customerId)));

        return creditCheckRepository.findByCustomer_CustomerIdOrderByRequestTsDesc(customerId).stream()
                .map(cc -> toResponse(cc, customer))
                .toList();
    }

    // --- Private helpers ---

    private CreditCheckResponse toResponse(CreditCheck entity, Customer customer) {
        String customerName = customer.getLastName() + ", " + customer.getFirstName();
        BigDecimal annualIncome = customer.getAnnualIncome() != null
                ? customer.getAnnualIncome() : BigDecimal.ZERO;

        String creditTierDesc = describeTier(entity.getCreditTier());

        // Recalculate max financing for display
        int multiplier = switch (entity.getCreditTier() != null ? entity.getCreditTier() : "E") {
            case "A" -> 5;
            case "B" -> 4;
            case "C" -> 3;
            case "D" -> 2;
            default -> 1;
        };
        BigDecimal maxFinancing = annualIncome.multiply(BigDecimal.valueOf(multiplier));

        // Apply DTI adjustment
        BigDecimal dtiRatio = entity.getDtiRatio() != null ? entity.getDtiRatio() : BigDecimal.ZERO;
        if (dtiRatio.compareTo(BigDecimal.valueOf(50)) > 0) {
            maxFinancing = maxFinancing.multiply(BigDecimal.valueOf(0.75)).setScale(2, RoundingMode.HALF_UP);
        } else if (dtiRatio.compareTo(BigDecimal.valueOf(40)) > 0) {
            maxFinancing = maxFinancing.multiply(BigDecimal.valueOf(0.90)).setScale(2, RoundingMode.HALF_UP);
        }

        return CreditCheckResponse.builder()
                .creditId(entity.getCreditId())
                .customerId(customer.getCustomerId())
                .customerName(customerName)
                .annualIncome(annualIncome)
                .monthlyIncome(entity.getMonthlyIncome())
                .creditTier(entity.getCreditTier())
                .creditTierDesc(creditTierDesc)
                .creditScore(entity.getCreditScore())
                .bureauCode(entity.getBureauCode())
                .dtiRatio(entity.getDtiRatio())
                .monthlyDebt(entity.getMonthlyDebt())
                .maxFinancing(maxFinancing)
                .expiryDate(entity.getExpiryDate())
                .status(entity.getStatus())
                .message(null)
                .build();
    }

    private String describeTier(String tier) {
        if (tier == null) return "Unknown";
        return switch (tier) {
            case "A" -> "Excellent (A)";
            case "B" -> "Good (B)";
            case "C" -> "Fair (C)";
            case "D" -> "Subprime (D)";
            case "E" -> "Deep Subprime (E)";
            default -> "Unknown";
        };
    }
}
