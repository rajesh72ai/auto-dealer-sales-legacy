package com.autosales.modules.finance.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.*;
import com.autosales.modules.finance.dto.*;
import com.autosales.modules.finance.entity.FinanceApp;
import com.autosales.modules.finance.entity.LeaseTerms;
import com.autosales.modules.finance.repository.FinanceAppRepository;
import com.autosales.modules.finance.repository.LeaseTermsRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Service for finance application lifecycle management.
 * Port of FINAPP00.cbl (application), FINAPV00.cbl (approval),
 * FINCAL00.cbl (loan calculator), FINLSE00.cbl (lease calculator).
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class FinanceAppService {

    private static final int MONEY_SCALE = 2;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;

    private static final Map<String, String> FINANCE_TYPE_NAMES = Map.of(
            "L", "Loan", "S", "Lease", "C", "Cash");
    private static final Map<String, String> STATUS_NAMES = Map.of(
            "NW", "New", "AP", "Approved", "CD", "Conditional", "DN", "Declined");

    private final FinanceAppRepository financeAppRepository;
    private final LeaseTermsRepository leaseTermsRepository;
    private final SalesDealRepository salesDealRepository;
    private final LoanCalculator loanCalculator;
    private final LeaseCalculator leaseCalculator;
    private final FieldFormatter fieldFormatter;

    /**
     * List finance applications with optional filters.
     */
    public PaginatedResponse<FinanceAppResponse> listApplications(String dealNumber, String status,
                                                                    String financeType, int page, int size) {
        log.debug("Listing finance apps - deal={}, status={}, type={}, page={}", dealNumber, status, financeType, page);

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "submittedTs"));
        Page<FinanceApp> result;

        if (dealNumber != null && !dealNumber.isBlank()) {
            result = financeAppRepository.findByDealNumber(dealNumber, pageable);
        } else if (status != null && !status.isBlank()) {
            result = financeAppRepository.findByAppStatus(status, pageable);
        } else if (financeType != null && !financeType.isBlank()) {
            result = financeAppRepository.findByFinanceType(financeType, pageable);
        } else {
            result = financeAppRepository.findAll(pageable);
        }

        List<FinanceAppResponse> content = result.getContent().stream()
                .map(this::toResponse)
                .toList();

        return new PaginatedResponse<>("success", null, content,
                result.getNumber(), result.getTotalPages(), result.getTotalElements(), LocalDateTime.now());
    }

    /**
     * Get a single finance application by ID.
     */
    public FinanceAppResponse getApplication(String financeId) {
        log.debug("Getting finance application id={}", financeId);
        FinanceApp app = financeAppRepository.findByFinanceId(financeId)
                .orElseThrow(() -> new EntityNotFoundException("FinanceApp", financeId));
        return toResponse(app);
    }

    /**
     * Create a new finance application on a deal.
     */
    @Transactional
    @Auditable(action = "INS", entity = "finance_app", keyExpression = "#result.financeId")
    public FinanceAppResponse createApplication(FinanceAppRequest request) {
        log.info("Creating finance app for deal={}, type={}", request.getDealNumber(), request.getFinanceType());

        // Validate deal exists with status AP
        SalesDeal deal = salesDealRepository.findById(request.getDealNumber())
                .orElseThrow(() -> new EntityNotFoundException("SalesDeal", request.getDealNumber()));
        if (!"AP".equals(deal.getDealStatus())) {
            throw new BusinessValidationException(
                    "Deal must be in Approved (AP) status to submit finance application. Current status: "
                            + deal.getDealStatus());
        }

        // Validate finance type
        String type = request.getFinanceType();
        if (!"L".equals(type) && !"S".equals(type) && !"C".equals(type)) {
            throw new BusinessValidationException("Finance type must be L (Loan), S (Lease), or C (Cash)");
        }

        // For Loan/Lease, lender is required
        if (("L".equals(type) || "S".equals(type))
                && (request.getLenderCode() == null || request.getLenderCode().isBlank())) {
            throw new BusinessValidationException("Lender code is required for Loan and Lease finance types");
        }

        // Validate APR range
        if (request.getAprRequested() != null
                && (request.getAprRequested().compareTo(BigDecimal.ZERO) < 0
                    || request.getAprRequested().compareTo(new BigDecimal("30")) > 0)) {
            throw new BusinessValidationException("APR must be between 0 and 30%");
        }

        // Validate term range
        if (request.getTermMonths() != null
                && (request.getTermMonths() < 12 || request.getTermMonths() > 84)) {
            throw new BusinessValidationException("Term must be between 12 and 84 months");
        }

        // Generate finance ID: FIN + last 9 digits of millis
        String millis = String.valueOf(System.currentTimeMillis());
        String financeId = "FIN" + millis.substring(Math.max(0, millis.length() - 9));

        BigDecimal downPayment = request.getDownPayment() != null ? request.getDownPayment() : BigDecimal.ZERO;

        FinanceApp entity = FinanceApp.builder()
                .financeId(financeId)
                .dealNumber(request.getDealNumber())
                .customerId(deal.getCustomerId())
                .financeType(type)
                .lenderCode(request.getLenderCode())
                .appStatus("NW")
                .amountRequested(request.getAmountRequested())
                .aprRequested(request.getAprRequested())
                .termMonths(request.getTermMonths())
                .downPayment(downPayment)
                .submittedTs(LocalDateTime.now())
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        // For LOAN type: compute monthly payment
        if ("L".equals(type) && request.getAprRequested() != null && request.getTermMonths() != null) {
            BigDecimal netPrincipal = request.getAmountRequested().subtract(downPayment);
            if (netPrincipal.compareTo(new BigDecimal("500")) >= 0) {
                LoanCalculationResult calc = loanCalculator.calculate(
                        netPrincipal, request.getAprRequested(), request.getTermMonths());
                entity.setMonthlyPayment(calc.monthlyPayment());
            }
        }

        // Update deal status from AP to FI
        deal.setDealStatus("FI");
        deal.setUpdatedTs(LocalDateTime.now());
        salesDealRepository.save(deal);

        FinanceApp saved = financeAppRepository.save(entity);
        log.info("Created finance app id={} for deal={}", saved.getFinanceId(), saved.getDealNumber());
        return toResponse(saved);
    }

    /**
     * Approve, conditionally approve, or decline a finance application.
     */
    @Transactional
    @Auditable(action = "APV", entity = "finance_app", keyExpression = "#request.financeId")
    public FinanceApprovalResponse approveOrDecline(FinanceApprovalRequest request) {
        log.info("Processing finance decision id={}, action={}", request.getFinanceId(), request.getAction());

        FinanceApp app = financeAppRepository.findByFinanceId(request.getFinanceId())
                .orElseThrow(() -> new EntityNotFoundException("FinanceApp", request.getFinanceId()));

        // Can only decide on NW or CD applications
        if (!"NW".equals(app.getAppStatus()) && !"CD".equals(app.getAppStatus())) {
            throw new BusinessValidationException(
                    "Cannot change decision on application with status: " + app.getAppStatus()
                            + ". Only New (NW) or Conditional (CD) applications can be decided.");
        }

        String action = request.getAction();
        if (!"AP".equals(action) && !"CD".equals(action) && !"DN".equals(action)) {
            throw new BusinessValidationException("Action must be AP (Approve), CD (Conditional), or DN (Decline)");
        }

        // For AP: amountApproved and aprApproved required
        if ("AP".equals(action)) {
            if (request.getAmountApproved() == null) {
                throw new BusinessValidationException("Approved amount is required for approval");
            }
            if (request.getAprApproved() == null) {
                throw new BusinessValidationException("Approved APR is required for approval");
            }
            app.setAmountApproved(request.getAmountApproved());
            app.setAprApproved(request.getAprApproved());

            // Recalculate monthly payment for Loan type
            if ("L".equals(app.getFinanceType()) && app.getTermMonths() != null) {
                BigDecimal netAmount = request.getAmountApproved().subtract(app.getDownPayment());
                if (netAmount.compareTo(new BigDecimal("500")) >= 0) {
                    LoanCalculationResult calc = loanCalculator.calculate(
                            netAmount, request.getAprApproved(), app.getTermMonths());
                    app.setMonthlyPayment(calc.monthlyPayment());
                }
            }
        }

        // For CD: stipulations required, max 200 chars
        if ("CD".equals(action)) {
            if (request.getStipulations() == null || request.getStipulations().isBlank()) {
                throw new BusinessValidationException("Stipulations are required for conditional approval");
            }
            if (request.getStipulations().length() > 200) {
                throw new BusinessValidationException("Stipulations cannot exceed 200 characters");
            }
            app.setStipulations(request.getStipulations());
            // Optionally set approved amounts if provided
            if (request.getAmountApproved() != null) {
                app.setAmountApproved(request.getAmountApproved());
            }
            if (request.getAprApproved() != null) {
                app.setAprApproved(request.getAprApproved());
            }
        }

        app.setAppStatus(action);
        app.setDecisionTs(LocalDateTime.now());
        app.setUpdatedTs(LocalDateTime.now());

        FinanceApp saved = financeAppRepository.save(app);

        // Build comparison response
        BigDecimal monthlyPayment = saved.getMonthlyPayment();
        BigDecimal totalOfPayments = null;
        BigDecimal totalInterest = null;
        if (monthlyPayment != null && saved.getTermMonths() != null) {
            totalOfPayments = monthlyPayment.multiply(new BigDecimal(saved.getTermMonths()))
                    .setScale(MONEY_SCALE, ROUNDING);
            BigDecimal financed = saved.getAmountApproved() != null
                    ? saved.getAmountApproved().subtract(saved.getDownPayment())
                    : saved.getAmountRequested().subtract(saved.getDownPayment());
            totalInterest = totalOfPayments.subtract(financed).setScale(MONEY_SCALE, ROUNDING);
        }

        String actionName = switch (action) {
            case "AP" -> "Approved";
            case "CD" -> "Conditional";
            case "DN" -> "Declined";
            default -> action;
        };

        log.info("Finance decision complete id={}, action={}", saved.getFinanceId(), action);
        return FinanceApprovalResponse.builder()
                .financeId(saved.getFinanceId())
                .dealNumber(saved.getDealNumber())
                .action(action)
                .actionName(actionName)
                .originalAmount(saved.getAmountRequested())
                .originalApr(saved.getAprRequested())
                .originalTerm(saved.getTermMonths())
                .approvedAmount(saved.getAmountApproved())
                .approvedApr(saved.getAprApproved())
                .monthlyPayment(monthlyPayment)
                .totalOfPayments(totalOfPayments)
                .totalInterest(totalInterest)
                .stipulations(saved.getStipulations())
                .decisionTs(saved.getDecisionTs())
                .newStatus(action)
                .build();
    }

    /**
     * Pure loan calculation — no database interaction.
     */
    public LoanCalculatorResponse calculateLoan(LoanCalculatorRequest request) {
        log.debug("Calculating loan - principal={}, apr={}, term={}",
                request.getPrincipal(), request.getApr(), request.getTermMonths());

        // Validate
        if (request.getPrincipal().compareTo(new BigDecimal("500")) < 0) {
            throw new BusinessValidationException("Principal must be at least $500");
        }
        if (request.getApr().compareTo(BigDecimal.ZERO) < 0
                || request.getApr().compareTo(new BigDecimal("30")) > 0) {
            throw new BusinessValidationException("APR must be between 0% and 30%");
        }

        BigDecimal downPayment = request.getDownPayment() != null ? request.getDownPayment() : BigDecimal.ZERO;
        BigDecimal netPrincipal = request.getPrincipal().subtract(downPayment);
        int termMonths = request.getTermMonths() != null ? request.getTermMonths() : 60;

        // Primary calculation
        LoanCalculationResult primary = loanCalculator.calculate(netPrincipal, request.getApr(), termMonths);

        // Term comparisons for 36, 48, 60, 72 months
        List<LoanCalculatorResponse.TermComparison> comparisons = new ArrayList<>();
        for (int term : new int[]{36, 48, 60, 72}) {
            if (term >= 6 && term <= 84) {
                LoanCalculationResult comp = loanCalculator.calculate(netPrincipal, request.getApr(), term);
                comparisons.add(LoanCalculatorResponse.TermComparison.builder()
                        .term(term)
                        .monthlyPayment(comp.monthlyPayment())
                        .totalPayments(comp.totalOfPayments())
                        .totalInterest(comp.totalInterest())
                        .build());
            }
        }

        // Convert amortization entries
        List<LoanCalculatorResponse.AmortizationEntry> schedule = primary.amortizationSchedule().stream()
                .map(e -> LoanCalculatorResponse.AmortizationEntry.builder()
                        .month(e.month())
                        .payment(e.payment())
                        .principal(e.principalPortion())
                        .interest(e.interestPortion())
                        .cumulativeInterest(e.cumulativeInterest())
                        .balance(e.remainingBalance())
                        .build())
                .toList();

        return LoanCalculatorResponse.builder()
                .principal(request.getPrincipal())
                .downPayment(downPayment)
                .netPrincipal(netPrincipal)
                .apr(request.getApr())
                .termMonths(termMonths)
                .monthlyPayment(primary.monthlyPayment())
                .totalOfPayments(primary.totalOfPayments())
                .totalInterest(primary.totalInterest())
                .comparisons(comparisons)
                .amortizationSchedule(schedule)
                .build();
    }

    /**
     * Lease calculation with optional deal association.
     */
    @Transactional
    @Auditable(action = "INS", entity = "lease_terms", keyExpression = "#request.dealNumber")
    public LeaseCalculatorResponse calculateLease(LeaseCalculatorRequest request) {
        log.debug("Calculating lease - capCost={}, term={}", request.getCapitalizedCost(), request.getTermMonths());

        // Apply defaults for nulls
        BigDecimal capCostReduction = request.getCapCostReduction() != null
                ? request.getCapCostReduction() : BigDecimal.ZERO;
        BigDecimal residualPct = request.getResidualPct() != null
                ? request.getResidualPct() : new BigDecimal("55.00");
        BigDecimal moneyFactor = request.getMoneyFactor() != null
                ? request.getMoneyFactor() : new BigDecimal("0.00125");
        int termMonths = request.getTermMonths() != null ? request.getTermMonths() : 36;
        BigDecimal taxRate = request.getTaxRate() != null
                ? request.getTaxRate() : new BigDecimal("7.0");
        BigDecimal acqFee = request.getAcqFee() != null
                ? request.getAcqFee() : new BigDecimal("695");
        BigDecimal securityDeposit = request.getSecurityDeposit() != null
                ? request.getSecurityDeposit() : BigDecimal.ZERO;

        LeaseCalculationResult calc = leaseCalculator.calculate(
                request.getCapitalizedCost(), capCostReduction, residualPct,
                moneyFactor, termMonths, taxRate, acqFee, securityDeposit);

        // If dealNumber provided: find finance app with type S, create/update LeaseTerms
        if (request.getDealNumber() != null && !request.getDealNumber().isBlank()) {
            Optional<FinanceApp> finApp = financeAppRepository.findByDealNumberAndFinanceType(
                    request.getDealNumber(), "S");
            if (finApp.isPresent()) {
                LeaseTerms terms = leaseTermsRepository.findByFinanceId(finApp.get().getFinanceId())
                        .orElse(LeaseTerms.builder().financeId(finApp.get().getFinanceId()).build());

                terms.setResidualPct(residualPct);
                terms.setResidualAmt(calc.residualAmount());
                terms.setMoneyFactor(moneyFactor);
                terms.setCapitalizedCost(request.getCapitalizedCost());
                terms.setCapCostReduce(capCostReduction);
                terms.setAdjCapCost(calc.adjustedCapCost());
                terms.setDepreciationAmt(calc.monthlyDepreciation());
                terms.setFinanceCharge(calc.monthlyFinanceCharge());
                terms.setMonthlyTax(calc.monthlyTax());
                terms.setMilesPerYear(12000);
                terms.setExcessMileChg(new BigDecimal("0.25"));
                terms.setDispositionFee(new BigDecimal("395.00"));
                terms.setAcqFee(acqFee);
                terms.setSecurityDeposit(securityDeposit);

                leaseTermsRepository.save(terms);

                // Update finance app monthly payment
                FinanceApp app = finApp.get();
                app.setMonthlyPayment(calc.totalMonthlyPayment());
                app.setUpdatedTs(LocalDateTime.now());
                financeAppRepository.save(app);
            }
        }

        BigDecimal totalOfPayments = calc.totalMonthlyPayment()
                .multiply(new BigDecimal(termMonths))
                .setScale(MONEY_SCALE, ROUNDING);
        BigDecimal totalInterestEquiv = totalOfPayments
                .subtract(request.getCapitalizedCost().subtract(capCostReduction))
                .setScale(MONEY_SCALE, ROUNDING);

        return LeaseCalculatorResponse.builder()
                .capitalizedCost(request.getCapitalizedCost())
                .capCostReduction(capCostReduction)
                .residualPct(residualPct)
                .moneyFactor(moneyFactor)
                .termMonths(termMonths)
                .taxRate(taxRate)
                .acqFee(acqFee)
                .securityDeposit(securityDeposit)
                .adjustedCapCost(calc.adjustedCapCost())
                .residualAmount(calc.residualAmount())
                .monthlyDepreciation(calc.monthlyDepreciation())
                .monthlyFinanceCharge(calc.monthlyFinanceCharge())
                .monthlyTax(calc.monthlyTax())
                .totalMonthlyPayment(calc.totalMonthlyPayment())
                .equivalentApr(calc.equivalentApr())
                .driveOffAmount(calc.driveOffAmount())
                .totalOfPayments(totalOfPayments)
                .totalInterestEquivalent(totalInterestEquiv)
                .build();
    }

    // --- Private helpers ---

    private FinanceAppResponse toResponse(FinanceApp entity) {
        String financeTypeName = FINANCE_TYPE_NAMES.getOrDefault(entity.getFinanceType(), entity.getFinanceType());
        String statusName = STATUS_NAMES.getOrDefault(entity.getAppStatus(), entity.getAppStatus());

        BigDecimal totalOfPayments = null;
        BigDecimal totalInterest = null;
        if (entity.getMonthlyPayment() != null && entity.getTermMonths() != null) {
            totalOfPayments = entity.getMonthlyPayment()
                    .multiply(new BigDecimal(entity.getTermMonths()))
                    .setScale(MONEY_SCALE, ROUNDING);
            BigDecimal baseAmount = entity.getAmountApproved() != null
                    ? entity.getAmountApproved() : entity.getAmountRequested();
            BigDecimal financed = baseAmount.subtract(entity.getDownPayment());
            totalInterest = totalOfPayments.subtract(financed).setScale(MONEY_SCALE, ROUNDING);
        }

        return FinanceAppResponse.builder()
                .financeId(entity.getFinanceId())
                .dealNumber(entity.getDealNumber())
                .customerId(entity.getCustomerId())
                .financeType(entity.getFinanceType())
                .lenderCode(entity.getLenderCode())
                .lenderName(entity.getLenderName())
                .appStatus(entity.getAppStatus())
                .amountRequested(entity.getAmountRequested())
                .amountApproved(entity.getAmountApproved())
                .aprRequested(entity.getAprRequested())
                .aprApproved(entity.getAprApproved())
                .termMonths(entity.getTermMonths())
                .monthlyPayment(entity.getMonthlyPayment())
                .downPayment(entity.getDownPayment())
                .creditTier(entity.getCreditTier())
                .stipulations(entity.getStipulations())
                .submittedTs(entity.getSubmittedTs())
                .decisionTs(entity.getDecisionTs())
                .fundedTs(entity.getFundedTs())
                .financeTypeName(financeTypeName)
                .statusName(statusName)
                .totalOfPayments(totalOfPayments)
                .totalInterest(totalInterest)
                .build();
    }
}
