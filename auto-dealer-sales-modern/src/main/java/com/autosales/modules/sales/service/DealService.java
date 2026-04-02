package com.autosales.modules.sales.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.security.SystemUser;
import com.autosales.common.security.SystemUserRepository;
import com.autosales.common.util.*;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.entity.IncentiveProgram;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.entity.TaxRate;
import com.autosales.modules.admin.repository.*;
import com.autosales.modules.customer.entity.CreditCheck;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CreditCheckRepository;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.sales.dto.*;
import com.autosales.modules.sales.entity.*;
import com.autosales.modules.sales.repository.*;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Core deal lifecycle service — the heart of the sales module.
 * Port of SLSWKS00.cbl (worksheet), SLSDESK0.cbl (desking/negotiation),
 * SLSVAL00.cbl (validation), SLSAPV00.cbl (approval), SLSTRD00.cbl (trade-in),
 * SLSINC00.cbl (incentives), SLSDLV00.cbl (delivery), SLSCAN00.cbl (cancellation).
 *
 * <p>Manages the full deal state machine:
 * WS (Worksheet) -> NE (Negotiating) -> PA (Pending Approval) -> AP (Approved)
 * -> FI (In F&I) -> CT (Contracted) -> DL (Delivered)
 * Any state -> CA (Cancelled) or UW (Unwound, if post-delivery).</p>
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class DealService {

    private static final int MONEY_SCALE = 2;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;
    private static final BigDecimal HUNDRED = new BigDecimal("100");

    // ACV condition multipliers: E=100%, G=85%, F=70%, P=55%
    private static final BigDecimal ACV_EXCELLENT = new BigDecimal("1.00");
    private static final BigDecimal ACV_GOOD = new BigDecimal("0.85");
    private static final BigDecimal ACV_FAIR = new BigDecimal("0.70");
    private static final BigDecimal ACV_POOR = new BigDecimal("0.55");

    private final SalesDealRepository dealRepository;
    private final CustomerRepository customerRepository;
    private final VehicleRepository vehicleRepository;
    private final TradeInRepository tradeInRepository;
    private final IncentiveAppliedRepository incentiveAppliedRepository;
    private final IncentiveProgramRepository incentiveProgramRepository;
    private final SalesApprovalRepository approvalRepository;
    private final DealLineItemRepository lineItemRepository;
    private final CreditCheckRepository creditCheckRepository;
    private final SystemConfigRepository configRepository;
    private final SystemUserRepository userRepository;
    private final PriceMasterRepository priceMasterRepository;
    private final TaxRateRepository taxRateRepository;
    private final DealerRepository dealerRepository;
    private final SequenceGenerator sequenceGenerator;
    private final PricingEngine pricingEngine;
    private final FieldFormatter fieldFormatter;
    private final StockPositionService stockPositionService;
    private final ResponseFormatter responseFormatter;

    public DealService(SalesDealRepository dealRepository,
                       CustomerRepository customerRepository,
                       VehicleRepository vehicleRepository,
                       TradeInRepository tradeInRepository,
                       IncentiveAppliedRepository incentiveAppliedRepository,
                       IncentiveProgramRepository incentiveProgramRepository,
                       SalesApprovalRepository approvalRepository,
                       DealLineItemRepository lineItemRepository,
                       CreditCheckRepository creditCheckRepository,
                       SystemConfigRepository configRepository,
                       SystemUserRepository userRepository,
                       PriceMasterRepository priceMasterRepository,
                       TaxRateRepository taxRateRepository,
                       DealerRepository dealerRepository,
                       SequenceGenerator sequenceGenerator,
                       PricingEngine pricingEngine,
                       FieldFormatter fieldFormatter,
                       StockPositionService stockPositionService,
                       ResponseFormatter responseFormatter) {
        this.dealRepository = dealRepository;
        this.customerRepository = customerRepository;
        this.vehicleRepository = vehicleRepository;
        this.tradeInRepository = tradeInRepository;
        this.incentiveAppliedRepository = incentiveAppliedRepository;
        this.incentiveProgramRepository = incentiveProgramRepository;
        this.approvalRepository = approvalRepository;
        this.lineItemRepository = lineItemRepository;
        this.creditCheckRepository = creditCheckRepository;
        this.configRepository = configRepository;
        this.userRepository = userRepository;
        this.priceMasterRepository = priceMasterRepository;
        this.taxRateRepository = taxRateRepository;
        this.dealerRepository = dealerRepository;
        this.sequenceGenerator = sequenceGenerator;
        this.pricingEngine = pricingEngine;
        this.fieldFormatter = fieldFormatter;
        this.stockPositionService = stockPositionService;
        this.responseFormatter = responseFormatter;
    }

    // ========================================================================
    // QUERY METHODS
    // ========================================================================

    /**
     * Find all deals for a dealer with optional status filter.
     */
    public PaginatedResponse<DealResponse> findAll(String dealerCode, String status, Pageable pageable) {
        log.debug("Finding deals - dealerCode={}, status={}, page={}", dealerCode, status, pageable);

        Page<SalesDeal> page;
        if (status != null && !status.isBlank()) {
            if (status.contains(",")) {
                List<String> statuses = java.util.Arrays.asList(status.split(","));
                page = dealRepository.findByDealerCodeAndDealStatusIn(dealerCode, statuses, pageable);
            } else {
                page = dealRepository.findByDealerCodeAndDealStatus(dealerCode, status, pageable);
            }
        } else {
            page = dealRepository.findByDealerCode(dealerCode, pageable);
        }

        List<DealResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a single deal by deal number.
     */
    public DealResponse findByDealNumber(String dealNumber) {
        log.debug("Finding deal by dealNumber={}", dealNumber);
        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));
        return toResponse(deal);
    }

    // ========================================================================
    // DEAL LIFECYCLE METHODS
    // ========================================================================

    /**
     * Create a new deal worksheet.
     * Port of SLSWKS00.cbl — sales worksheet entry.
     */
    @Transactional
    @Auditable(action = "INS", entity = "sales_deal", keyExpression = "#result.dealNumber")
    public DealResponse createDeal(CreateDealRequest request) {
        log.info("Creating deal - customerId={}, vin={}, dealer={}", request.getCustomerId(),
                request.getVin(), request.getDealerCode());

        // Validate customer exists
        Customer customer = customerRepository.findById(request.getCustomerId())
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(request.getCustomerId())));

        // Validate vehicle exists and status is AV (Available) or HD (Hold)
        Vehicle vehicle = vehicleRepository.findById(request.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", request.getVin()));
        if (!"AV".equals(vehicle.getVehicleStatus()) && !"HD".equals(vehicle.getVehicleStatus())) {
            throw new BusinessValidationException(
                    "Vehicle " + request.getVin() + " is not available for sale (status: " + vehicle.getVehicleStatus() + ")");
        }

        // Validate dealer exists
        Dealer dealer = dealerRepository.findById(request.getDealerCode())
                .orElseThrow(() -> new EntityNotFoundException("Dealer", request.getDealerCode()));

        // Generate deal number
        String dealNumber = sequenceGenerator.generateDealNumber();

        // Look up pricing via PRICE_MASTER for vehicle's year/make/model
        Optional<PriceMaster> priceMasterOpt = priceMasterRepository.findCurrentEffective(
                vehicle.getModelYear(), vehicle.getMakeCode(), vehicle.getModelCode(), LocalDate.now());

        BigDecimal vehiclePrice;
        BigDecimal totalOptions = BigDecimal.ZERO;
        BigDecimal destinationFee;
        BigDecimal invoicePrice;

        if (priceMasterOpt.isPresent()) {
            PriceMaster pm = priceMasterOpt.get();
            vehiclePrice = pm.getMsrp();
            destinationFee = pm.getDestinationFee();
            invoicePrice = pm.getInvoicePrice();
        } else {
            // Fallback: no price master record — log warning and default to zero
            log.warn("No current PriceMaster found for {}/{}/{} — defaulting to zero pricing",
                    vehicle.getModelYear(), vehicle.getMakeCode(), vehicle.getModelCode());
            vehiclePrice = BigDecimal.ZERO;
            destinationFee = BigDecimal.ZERO;
            invoicePrice = BigDecimal.ZERO;
        }

        // Calculate subtotal
        BigDecimal subtotal = vehiclePrice.add(totalOptions).add(destinationFee)
                .setScale(MONEY_SCALE, ROUNDING);

        // Front gross = vehiclePrice - invoicePrice
        BigDecimal frontGross = vehiclePrice.subtract(invoicePrice).setScale(MONEY_SCALE, ROUNDING);

        BigDecimal downPayment = defaultZero(request.getDownPayment());

        LocalDateTime now = LocalDateTime.now();

        SalesDeal deal = SalesDeal.builder()
                .dealNumber(dealNumber)
                .dealerCode(request.getDealerCode())
                .customerId(request.getCustomerId())
                .vin(request.getVin())
                .salespersonId(request.getSalespersonId())
                .dealType(request.getDealType())
                .dealStatus("WS")
                .vehiclePrice(vehiclePrice)
                .totalOptions(totalOptions)
                .destinationFee(destinationFee)
                .subtotal(subtotal)
                .tradeAllow(BigDecimal.ZERO)
                .tradePayoff(BigDecimal.ZERO)
                .netTrade(BigDecimal.ZERO)
                .rebatesApplied(BigDecimal.ZERO)
                .discountAmt(BigDecimal.ZERO)
                .docFee(BigDecimal.ZERO)
                .stateTax(BigDecimal.ZERO)
                .countyTax(BigDecimal.ZERO)
                .cityTax(BigDecimal.ZERO)
                .titleFee(BigDecimal.ZERO)
                .regFee(BigDecimal.ZERO)
                .totalPrice(subtotal)
                .downPayment(downPayment)
                .amountFinanced(subtotal.subtract(downPayment).setScale(MONEY_SCALE, ROUNDING))
                .frontGross(frontGross)
                .backGross(BigDecimal.ZERO)
                .totalGross(frontGross)
                .dealDate(LocalDate.now())
                .createdTs(now)
                .updatedTs(now)
                .build();

        // Recalculate taxes using dealer's jurisdiction
        recalculateDeal(deal, dealer);

        SalesDeal saved = dealRepository.save(deal);
        log.info("Created deal dealNumber={}", saved.getDealNumber());
        return toResponse(saved);
    }

    /**
     * Negotiate a deal — counter offer or discount.
     * Port of SLSDESK0.cbl — sales desk / desking transaction.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "sales_deal", keyExpression = "#dealNumber")
    public NegotiationResponse negotiate(String dealNumber, NegotiationRequest request) {
        log.info("Negotiating deal={}, action={}", dealNumber, request.getAction());

        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));

        // Verify status is WS (Worksheet) or NE (Negotiating)
        if (!"WS".equals(deal.getDealStatus()) && !"NE".equals(deal.getDealStatus())) {
            throw new BusinessValidationException(
                    "Deal " + dealNumber + " cannot be negotiated in status " + deal.getDealStatus());
        }

        Dealer dealer = dealerRepository.findById(deal.getDealerCode())
                .orElseThrow(() -> new EntityNotFoundException("Dealer", deal.getDealerCode()));

        BigDecimal previousPrice = deal.getVehiclePrice();

        if ("CO".equals(request.getAction())) {
            // Counter offer: set vehicle price to counter offer amount
            if (request.getAmount() == null || request.getAmount().signum() <= 0) {
                throw new BusinessValidationException("Counter offer amount must be greater than zero");
            }
            deal.setVehiclePrice(request.getAmount().setScale(MONEY_SCALE, ROUNDING));
            deal.setDiscountAmt(BigDecimal.ZERO); // clear any prior discount
        } else if ("DS".equals(request.getAction())) {
            // Discount: apply amount or percentage
            BigDecimal discountAmt;
            if (request.getDiscountPct() != null && request.getDiscountPct().signum() > 0) {
                // Percentage-based discount
                discountAmt = deal.getVehiclePrice().multiply(request.getDiscountPct())
                        .divide(HUNDRED, MONEY_SCALE, ROUNDING);
            } else if (request.getAmount() != null && request.getAmount().signum() > 0) {
                // Fixed amount discount
                discountAmt = request.getAmount().setScale(MONEY_SCALE, ROUNDING);
            } else {
                throw new BusinessValidationException("Discount requires either amount or discountPct");
            }

            // Cap discount at vehicle price
            if (discountAmt.compareTo(deal.getVehiclePrice()) > 0) {
                discountAmt = deal.getVehiclePrice();
            }
            deal.setDiscountAmt(discountAmt);
        }

        // Update status to NE (Negotiating)
        deal.setDealStatus("NE");
        deal.setUpdatedTs(LocalDateTime.now());

        // Recalculate all pricing
        recalculateDeal(deal, dealer);

        SalesDeal saved = dealRepository.save(deal);
        log.info("Negotiated deal={}, newPrice={}", dealNumber, saved.getVehiclePrice());

        // Look up invoice/holdback for gross analysis
        Vehicle vehicle = vehicleRepository.findById(deal.getVin()).orElse(null);
        PriceMaster pm = null;
        if (vehicle != null) {
            pm = priceMasterRepository.findCurrentEffective(
                    vehicle.getModelYear(), vehicle.getMakeCode(), vehicle.getModelCode(), LocalDate.now()).orElse(null);
        }

        return buildNegotiationResponse(saved, pm, request.getDeskNotes());
    }

    /**
     * Validate a deal — run all 10 validation checks.
     * Port of SLSVAL00.cbl — sales deal validation transaction.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "sales_deal", keyExpression = "#dealNumber")
    public ValidationResponse validate(String dealNumber) {
        log.info("Validating deal={}", dealNumber);

        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));

        List<String> errors = new ArrayList<>();

        // 1. Customer exists
        if (customerRepository.findById(deal.getCustomerId()).isEmpty()) {
            errors.add("Customer ID " + deal.getCustomerId() + " not found");
        }

        // 2. Vehicle exists
        Optional<Vehicle> vehicleOpt = vehicleRepository.findById(deal.getVin());
        if (vehicleOpt.isEmpty()) {
            errors.add("Vehicle VIN " + deal.getVin() + " not found");
        }

        // 3. Vehicle price > 0
        if (deal.getVehiclePrice() == null || deal.getVehiclePrice().signum() <= 0) {
            errors.add("Vehicle price must be greater than zero");
        }

        // 4. Salesperson exists and is active
        Optional<SystemUser> salesperson = userRepository.findByUserId(deal.getSalespersonId());
        if (salesperson.isEmpty()) {
            errors.add("Salesperson " + deal.getSalespersonId() + " not found");
        } else if (!"Y".equals(salesperson.get().getActiveFlag())) {
            errors.add("Salesperson " + deal.getSalespersonId() + " is not active");
        }

        // 5. Total price calculated (not zero)
        if (deal.getTotalPrice() == null || deal.getTotalPrice().signum() <= 0) {
            errors.add("Total price must be calculated and greater than zero");
        }

        // 6. Deal type is valid
        if (deal.getDealType() == null || !deal.getDealType().matches("[RLFW]")) {
            errors.add("Invalid deal type: " + deal.getDealType());
        }

        // 7. Down payment does not exceed total price
        if (deal.getDownPayment() != null && deal.getTotalPrice() != null
                && deal.getDownPayment().compareTo(deal.getTotalPrice()) > 0) {
            errors.add("Down payment ($" + deal.getDownPayment() + ") exceeds total price ($" + deal.getTotalPrice() + ")");
        }

        // 8. Trade-in payoff does not exceed allowance (if trade exists)
        List<TradeIn> trades = tradeInRepository.findBySalesDeal_DealNumber(dealNumber);
        for (TradeIn trade : trades) {
            if (trade.getPayoffAmt().compareTo(trade.getAllowanceAmt()) > 0) {
                errors.add("Trade-in payoff ($" + trade.getPayoffAmt() + ") exceeds allowance ($" + trade.getAllowanceAmt() + ")");
            }
        }

        // 9. Credit check exists for retail/lease deals
        if ("R".equals(deal.getDealType()) || "L".equals(deal.getDealType())) {
            Optional<CreditCheck> creditCheck = creditCheckRepository
                    .findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                            deal.getCustomerId(), "AP", LocalDate.now());
            if (creditCheck.isEmpty()) {
                errors.add("No approved, unexpired credit check found for customer " + deal.getCustomerId());
            }
        }

        // 10. Taxes calculated
        if (deal.getStateTax() == null || deal.getStateTax().signum() < 0) {
            errors.add("State tax has not been properly calculated");
        }

        boolean valid = errors.isEmpty();
        String newStatus = deal.getDealStatus();

        if (valid) {
            deal.setDealStatus("PA");
            deal.setUpdatedTs(LocalDateTime.now());
            dealRepository.save(deal);
            newStatus = "PA";
            log.info("Deal {} validated successfully, status -> PA", dealNumber);
        } else {
            log.warn("Deal {} validation failed with {} errors", dealNumber, errors.size());
        }

        return ValidationResponse.builder()
                .dealNumber(dealNumber)
                .valid(valid)
                .result(valid ? "DEAL VALID" : "VALIDATION FAILED")
                .errors(errors)
                .newStatus(newStatus)
                .build();
    }

    /**
     * Approve or reject a deal.
     * Port of SLSAPV00.cbl — sales approval transaction.
     */
    @Transactional
    @Auditable(action = "APV", entity = "sales_deal", keyExpression = "#dealNumber")
    public ApprovalResponse approve(String dealNumber, ApprovalRequest request) {
        log.info("Approving deal={}, action={}, approver={}", dealNumber, request.getAction(), request.getApproverId());

        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));

        // Verify deal is in PA (Pending Approval) status
        if (!"PA".equals(deal.getDealStatus())) {
            throw new BusinessValidationException(
                    "Deal " + dealNumber + " must be in Pending Approval status (current: " + deal.getDealStatus() + ")");
        }

        // Verify approver exists and has authority (M=Manager, G=GM, A=Admin user types)
        SystemUser approver = userRepository.findByUserId(request.getApproverId())
                .orElseThrow(() -> new EntityNotFoundException("User", request.getApproverId()));

        String userType = approver.getUserType();
        if (!"M".equals(userType) && !"G".equals(userType) && !"A".equals(userType)) {
            throw new BusinessValidationException(
                    "User " + request.getApproverId() + " does not have approval authority (type: " + userType + ")");
        }

        // Check approval threshold: negative front gross requires GM
        String thresholdMessage = null;
        if (deal.getFrontGross() != null && deal.getFrontGross().signum() < 0) {
            if (!"G".equals(userType) && !"A".equals(userType)) {
                throw new BusinessValidationException(
                        "Negative front gross deal requires General Manager approval (frontGross: "
                                + fieldFormatter.formatCurrency(deal.getFrontGross()) + ")");
            }
            thresholdMessage = "Negative front gross deal approved by GM override";
        }

        String oldStatus = deal.getDealStatus();
        String newStatus;

        if ("AP".equals(request.getAction())) {
            newStatus = "AP";
            deal.setDealStatus("AP");
            deal.setSalesManagerId(request.getApproverId());
        } else {
            // RJ — reject back to NE
            newStatus = "NE";
            deal.setDealStatus("NE");
        }

        deal.setUpdatedTs(LocalDateTime.now());
        dealRepository.save(deal);

        // Insert SalesApproval audit record
        SalesApproval approval = SalesApproval.builder()
                .dealNumber(dealNumber)
                .approvalType(request.getApprovalType())
                .approverId(request.getApproverId())
                .approvalStatus("AP".equals(request.getAction()) ? "A" : "R")
                .comments(request.getComments())
                .approvalTs(LocalDateTime.now())
                .build();
        approvalRepository.save(approval);

        log.info("Deal {} {} by {} — status {} -> {}", dealNumber,
                "AP".equals(request.getAction()) ? "approved" : "rejected",
                request.getApproverId(), oldStatus, newStatus);

        return ApprovalResponse.builder()
                .dealNumber(dealNumber)
                .approvalType(request.getApprovalType())
                .action(request.getAction())
                .approverId(request.getApproverId())
                .approverName(approver.getUserName())
                .oldStatus(oldStatus)
                .newStatus(newStatus)
                .oldStatusDescription(getStatusDescription(oldStatus))
                .newStatusDescription(getStatusDescription(newStatus))
                .thresholdMessage(thresholdMessage)
                .comments(request.getComments())
                .approvalTs(approval.getApprovalTs())
                .build();
    }

    /**
     * Add a trade-in vehicle to a deal.
     * Port of SLSTRD00.cbl — trade-in appraisal entry.
     */
    @Transactional
    @Auditable(action = "INS", entity = "trade_in", keyExpression = "#dealNumber")
    public TradeInResponse addTradeIn(String dealNumber, TradeInRequest request) {
        log.info("Adding trade-in to deal={}, make={}, model={}", dealNumber, request.getTradeMake(), request.getTradeModel());

        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));

        // Validate VIN if provided
        if (request.getVin() != null && !request.getVin().isBlank()) {
            VinValidator vinValidator = new VinValidator();
            VinValidationResult vinResult = vinValidator.validate(request.getVin());
            if (!vinResult.valid()) {
                throw new BusinessValidationException("Invalid trade-in VIN: " + vinResult.errorMessage());
            }
        }

        // Calculate ACV based on condition code
        // Base ACV is estimated from vehicle book value — use a simple formula based on year/odometer
        // In production, this would call an external valuation service (e.g., KBB/NADA)
        BigDecimal baseAcv = estimateBaseAcv(request.getTradeYear(), request.getOdometer());
        BigDecimal conditionMultiplier = getConditionMultiplier(request.getConditionCode());
        BigDecimal acvAmount = baseAcv.multiply(conditionMultiplier).setScale(MONEY_SCALE, ROUNDING);

        BigDecimal overAllow = defaultZero(request.getOverAllow());
        BigDecimal allowanceAmt = acvAmount.add(overAllow).setScale(MONEY_SCALE, ROUNDING);

        BigDecimal payoffAmt = defaultZero(request.getPayoffAmt());
        BigDecimal netTrade = allowanceAmt.subtract(payoffAmt).setScale(MONEY_SCALE, ROUNDING);

        TradeIn tradeIn = TradeIn.builder()
                .salesDeal(deal)
                .vin(request.getVin())
                .tradeYear(request.getTradeYear())
                .tradeMake(request.getTradeMake())
                .tradeModel(request.getTradeModel())
                .tradeColor(request.getTradeColor())
                .odometer(request.getOdometer())
                .conditionCode(request.getConditionCode())
                .acvAmount(acvAmount)
                .allowanceAmt(allowanceAmt)
                .overAllow(overAllow)
                .payoffAmt(payoffAmt)
                .payoffBank(request.getPayoffBank())
                .payoffAcct(request.getPayoffAcct())
                .appraisedBy(request.getAppraisedBy())
                .appraisedTs(LocalDateTime.now())
                .build();

        TradeIn saved = tradeInRepository.save(tradeIn);

        // Update deal with trade-in values and recalculate
        deal.setTradeAllow(allowanceAmt);
        deal.setTradePayoff(payoffAmt);
        deal.setNetTrade(netTrade);
        deal.setUpdatedTs(LocalDateTime.now());

        Dealer dealer = dealerRepository.findById(deal.getDealerCode())
                .orElseThrow(() -> new EntityNotFoundException("Dealer", deal.getDealerCode()));
        recalculateDeal(deal, dealer);
        dealRepository.save(deal);

        log.info("Added trade-in id={} to deal={}, netTrade={}", saved.getTradeId(), dealNumber, netTrade);

        return TradeInResponse.builder()
                .tradeId(saved.getTradeId())
                .dealNumber(dealNumber)
                .vin(saved.getVin())
                .tradeYear(saved.getTradeYear())
                .tradeMake(saved.getTradeMake())
                .tradeModel(saved.getTradeModel())
                .tradeColor(saved.getTradeColor())
                .odometer(saved.getOdometer())
                .conditionCode(saved.getConditionCode())
                .conditionDescription(getConditionDescription(saved.getConditionCode()))
                .acvAmount(acvAmount)
                .overAllow(overAllow)
                .allowanceAmt(allowanceAmt)
                .payoffAmt(payoffAmt)
                .netTrade(netTrade)
                .payoffBank(saved.getPayoffBank())
                .payoffAcct(saved.getPayoffAcct())
                .appraisedBy(saved.getAppraisedBy())
                .appraisedTs(saved.getAppraisedTs())
                .formattedAcv(fieldFormatter.formatCurrency(acvAmount))
                .formattedAllowance(fieldFormatter.formatCurrency(allowanceAmt))
                .formattedNetTrade(fieldFormatter.formatCurrency(netTrade))
                .build();
    }

    /**
     * Apply incentive programs to a deal.
     * Port of SLSINC00.cbl — incentive application transaction.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "sales_deal", keyExpression = "#dealNumber")
    public DealResponse applyIncentives(String dealNumber, ApplyIncentivesRequest request) {
        log.info("Applying incentives to deal={}, incentiveIds={}", dealNumber, request.getIncentiveIds());

        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));

        Vehicle vehicle = vehicleRepository.findById(deal.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", deal.getVin()));

        BigDecimal totalRebates = defaultZero(deal.getRebatesApplied());
        boolean hasNonStackable = false;
        List<IncentiveApplied> existingApplied = incentiveAppliedRepository.findByDealNumber(dealNumber);

        // Check if any existing applied incentive is non-stackable
        for (IncentiveApplied existing : existingApplied) {
            IncentiveProgram existingProg = incentiveProgramRepository.findById(existing.getIncentiveId()).orElse(null);
            if (existingProg != null && "N".equals(existingProg.getStackableFlag())) {
                hasNonStackable = true;
            }
        }

        for (String incentiveId : request.getIncentiveIds()) {
            IncentiveProgram program = incentiveProgramRepository.findById(incentiveId)
                    .orElseThrow(() -> new EntityNotFoundException("IncentiveProgram", incentiveId));

            // Validate incentive is active
            if (!"Y".equals(program.getActiveFlag())) {
                throw new BusinessValidationException("Incentive " + incentiveId + " is not active");
            }

            // Validate date range
            LocalDate today = LocalDate.now();
            if (today.isBefore(program.getStartDate()) || today.isAfter(program.getEndDate())) {
                throw new BusinessValidationException("Incentive " + incentiveId + " is outside its valid date range ("
                        + program.getStartDate() + " to " + program.getEndDate() + ")");
            }

            // Validate unit cap
            if (program.getMaxUnits() != null && program.getUnitsUsed() >= program.getMaxUnits()) {
                throw new BusinessValidationException("Incentive " + incentiveId + " has reached its maximum units ("
                        + program.getMaxUnits() + ")");
            }

            // Validate vehicle eligibility (year/make match)
            if (program.getModelYear() != null && !program.getModelYear().equals(vehicle.getModelYear())) {
                throw new BusinessValidationException("Incentive " + incentiveId + " is not valid for model year "
                        + vehicle.getModelYear());
            }
            if (program.getMakeCode() != null && !program.getMakeCode().equals(vehicle.getMakeCode())) {
                throw new BusinessValidationException("Incentive " + incentiveId + " is not valid for make "
                        + vehicle.getMakeCode());
            }
            if (program.getModelCode() != null && !program.getModelCode().isBlank()
                    && !program.getModelCode().equals(vehicle.getModelCode())) {
                throw new BusinessValidationException("Incentive " + incentiveId + " is not valid for model "
                        + vehicle.getModelCode());
            }

            // Validate stackability
            if (hasNonStackable) {
                throw new BusinessValidationException(
                        "Cannot add incentive " + incentiveId + " — a non-stackable incentive is already applied");
            }
            if ("N".equals(program.getStackableFlag()) && !existingApplied.isEmpty()) {
                throw new BusinessValidationException(
                        "Incentive " + incentiveId + " is non-stackable and other incentives are already applied");
            }

            // Check for duplicate application
            boolean alreadyApplied = existingApplied.stream()
                    .anyMatch(ia -> ia.getIncentiveId().equals(incentiveId));
            if (alreadyApplied) {
                throw new BusinessValidationException("Incentive " + incentiveId + " is already applied to this deal");
            }

            // Apply the incentive
            IncentiveApplied applied = IncentiveApplied.builder()
                    .dealNumber(dealNumber)
                    .incentiveId(incentiveId)
                    .amountApplied(program.getAmount())
                    .appliedTs(LocalDateTime.now())
                    .build();
            incentiveAppliedRepository.save(applied);

            // Increment units used on the program
            program.setUnitsUsed(program.getUnitsUsed() + 1);
            incentiveProgramRepository.save(program);

            totalRebates = totalRebates.add(program.getAmount());

            if ("N".equals(program.getStackableFlag())) {
                hasNonStackable = true;
            }
        }

        // Update deal rebates and recalculate
        deal.setRebatesApplied(totalRebates.setScale(MONEY_SCALE, ROUNDING));
        deal.setUpdatedTs(LocalDateTime.now());

        Dealer dealer = dealerRepository.findById(deal.getDealerCode())
                .orElseThrow(() -> new EntityNotFoundException("Dealer", deal.getDealerCode()));
        recalculateDeal(deal, dealer);

        SalesDeal saved = dealRepository.save(deal);
        log.info("Applied {} incentives to deal={}, totalRebates={}", request.getIncentiveIds().size(),
                dealNumber, totalRebates);

        return toResponse(saved);
    }

    /**
     * Complete/deliver a deal.
     * Port of SLSDLV00.cbl — deal delivery/completion transaction.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "sales_deal", keyExpression = "#dealNumber")
    public DealResponse completeDeal(String dealNumber, CompletionRequest request) {
        log.info("Completing deal={}", dealNumber);

        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));

        // Verify status is AP (Approved) or FI (In F&I)
        if (!"AP".equals(deal.getDealStatus()) && !"FI".equals(deal.getDealStatus())) {
            throw new BusinessValidationException(
                    "Deal " + dealNumber + " must be in Approved or In F&I status (current: " + deal.getDealStatus() + ")");
        }

        // Run completion checklist
        List<String> checklistErrors = new ArrayList<>();

        // 1. Insurance verified
        if (!request.isInsuranceVerified()) {
            checklistErrors.add("Insurance has not been verified");
        }

        // 2. Down payment check — if deal has amount financed, down payment should be > 0 or fully financed
        if (deal.getDownPayment() != null && deal.getDownPayment().signum() == 0
                && deal.getAmountFinanced() != null && deal.getAmountFinanced().compareTo(deal.getTotalPrice()) >= 0) {
            // Fully financed is OK — no error
        }

        // 3. Trade title received (if trade exists)
        List<TradeIn> trades = tradeInRepository.findBySalesDeal_DealNumber(dealNumber);
        if (!trades.isEmpty() && !request.isTradeTitleReceived()) {
            checklistErrors.add("Trade-in title has not been received");
        }

        // 4. Credit check must be approved for retail/lease
        if ("R".equals(deal.getDealType()) || "L".equals(deal.getDealType())) {
            Optional<CreditCheck> creditCheck = creditCheckRepository
                    .findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
                            deal.getCustomerId(), "AP", LocalDate.now());
            if (creditCheck.isEmpty()) {
                checklistErrors.add("No approved, unexpired credit check found for customer");
            }
        }

        if (!checklistErrors.isEmpty()) {
            throw new BusinessValidationException(
                    "Deal completion failed: " + String.join("; ", checklistErrors));
        }

        // Set delivery date
        LocalDate deliveryDate = request.getDeliveryDate() != null ? request.getDeliveryDate() : LocalDate.now();
        deal.setDeliveryDate(deliveryDate);

        // Override down payment if provided
        if (request.getDownPayment() != null) {
            deal.setDownPayment(request.getDownPayment().setScale(MONEY_SCALE, ROUNDING));
            deal.setAmountFinanced(
                    deal.getTotalPrice().subtract(deal.getDownPayment()).setScale(MONEY_SCALE, ROUNDING));
        }

        // Update deal status to DL (Delivered)
        deal.setDealStatus("DL");
        deal.setUpdatedTs(LocalDateTime.now());

        // Update vehicle status to SD (Sold) via stock position service
        stockPositionService.processSold(deal.getVin(), deal.getDealerCode(),
                deal.getSalespersonId(), "Deal " + dealNumber + " delivered");

        SalesDeal saved = dealRepository.save(deal);
        log.info("Completed deal={}, deliveryDate={}", dealNumber, deliveryDate);

        return toResponse(saved);
    }

    /**
     * Cancel or unwind a deal.
     * Port of SLSCAN00.cbl — deal cancellation transaction.
     */
    @Transactional
    @Auditable(action = "DEL", entity = "sales_deal", keyExpression = "#dealNumber")
    public DealResponse cancelDeal(String dealNumber, CancellationRequest request) {
        log.info("Cancelling deal={}, reason={}", dealNumber, request.getReason());

        SalesDeal deal = dealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("Deal", dealNumber));

        // Determine CA (not yet delivered) vs UW (unwind — post-delivery)
        boolean isDelivered = "DL".equals(deal.getDealStatus());
        String newStatus = isDelivered ? "UW" : "CA";

        // Cannot cancel an already cancelled/unwound deal
        if ("CA".equals(deal.getDealStatus()) || "UW".equals(deal.getDealStatus())) {
            throw new BusinessValidationException(
                    "Deal " + dealNumber + " is already " + getStatusDescription(deal.getDealStatus()));
        }

        // Reverse vehicle status: SD -> AV (if delivered, vehicle was marked sold)
        if (isDelivered) {
            stockPositionService.processReceive(deal.getVin(), deal.getDealerCode(),
                    deal.getSalespersonId(), "Deal " + dealNumber + " unwound: " + request.getReason());
        } else {
            // For non-delivered deals, release any hold
            Vehicle vehicle = vehicleRepository.findById(deal.getVin()).orElse(null);
            if (vehicle != null && "HD".equals(vehicle.getVehicleStatus())) {
                stockPositionService.processRelease(deal.getVin(), deal.getDealerCode(),
                        deal.getSalespersonId(), "Deal " + dealNumber + " cancelled: " + request.getReason());
            }
        }

        // Reverse incentives: decrement unitsUsed, delete IncentiveApplied records
        List<IncentiveApplied> appliedIncentives = incentiveAppliedRepository.findByDealNumber(dealNumber);
        for (IncentiveApplied applied : appliedIncentives) {
            IncentiveProgram program = incentiveProgramRepository.findById(applied.getIncentiveId()).orElse(null);
            if (program != null && program.getUnitsUsed() > 0) {
                program.setUnitsUsed(program.getUnitsUsed() - 1);
                incentiveProgramRepository.save(program);
            }
            incentiveAppliedRepository.delete(applied);
        }

        // Update deal status
        String oldStatus = deal.getDealStatus();
        deal.setDealStatus(newStatus);
        deal.setRebatesApplied(BigDecimal.ZERO);
        deal.setUpdatedTs(LocalDateTime.now());

        SalesDeal saved = dealRepository.save(deal);
        log.info("Deal {} {} (was {}): {}", dealNumber, newStatus, oldStatus, request.getReason());

        return toResponse(saved);
    }

    // ========================================================================
    // PRIVATE HELPERS
    // ========================================================================

    /**
     * Recalculate all deal pricing: subtotal, taxes, total, gross.
     */
    private void recalculateDeal(SalesDeal deal, Dealer dealer) {
        BigDecimal vehiclePrice = defaultZero(deal.getVehiclePrice());
        BigDecimal totalOptions = defaultZero(deal.getTotalOptions());
        BigDecimal destinationFee = defaultZero(deal.getDestinationFee());
        BigDecimal discountAmt = defaultZero(deal.getDiscountAmt());
        BigDecimal rebatesApplied = defaultZero(deal.getRebatesApplied());
        BigDecimal netTrade = defaultZero(deal.getNetTrade());
        BigDecimal downPayment = defaultZero(deal.getDownPayment());

        // Subtotal = vehiclePrice + totalOptions + destinationFee
        BigDecimal subtotal = vehiclePrice.add(totalOptions).add(destinationFee)
                .setScale(MONEY_SCALE, ROUNDING);
        deal.setSubtotal(subtotal);

        // Taxable base = subtotal - discountAmt - rebatesApplied - netTrade (min 0)
        BigDecimal taxableBase = subtotal.subtract(discountAmt).subtract(rebatesApplied).subtract(netTrade);
        if (taxableBase.signum() < 0) {
            taxableBase = BigDecimal.ZERO;
        }

        // Lookup tax rates for dealer's state/county/city
        BigDecimal stateRate = BigDecimal.ZERO;
        BigDecimal countyRate = BigDecimal.ZERO;
        BigDecimal cityRate = BigDecimal.ZERO;
        BigDecimal docFee = defaultZero(deal.getDocFee());
        BigDecimal titleFee = defaultZero(deal.getTitleFee());
        BigDecimal regFee = defaultZero(deal.getRegFee());

        // Look up effective tax rate for dealer's jurisdiction
        // Use dealer state + "00000" county/city as default, then cascade
        Optional<TaxRate> taxRateOpt = taxRateRepository.findCurrentEffective(
                dealer.getStateCode(), "00000", "00000", LocalDate.now());
        if (taxRateOpt.isPresent()) {
            TaxRate taxRate = taxRateOpt.get();
            stateRate = defaultZero(taxRate.getStateRate());
            countyRate = defaultZero(taxRate.getCountyRate());
            cityRate = defaultZero(taxRate.getCityRate());
            docFee = defaultZero(taxRate.getDocFeeMax());
            titleFee = defaultZero(taxRate.getTitleFee());
            regFee = defaultZero(taxRate.getRegFee());
        }

        // Calculate individual taxes
        BigDecimal stateTax = taxableBase.multiply(stateRate)
                .divide(HUNDRED, MONEY_SCALE, ROUNDING);
        BigDecimal countyTax = taxableBase.multiply(countyRate)
                .divide(HUNDRED, MONEY_SCALE, ROUNDING);
        BigDecimal cityTax = taxableBase.multiply(cityRate)
                .divide(HUNDRED, MONEY_SCALE, ROUNDING);

        deal.setStateTax(stateTax);
        deal.setCountyTax(countyTax);
        deal.setCityTax(cityTax);
        deal.setDocFee(docFee);
        deal.setTitleFee(titleFee);
        deal.setRegFee(regFee);

        // Total price = taxableBase + taxes + fees
        BigDecimal totalTax = stateTax.add(countyTax).add(cityTax);
        BigDecimal totalFees = docFee.add(titleFee).add(regFee);
        BigDecimal totalPrice = taxableBase.add(totalTax).add(totalFees).setScale(MONEY_SCALE, ROUNDING);
        deal.setTotalPrice(totalPrice);

        // Amount financed = totalPrice - downPayment
        BigDecimal amountFinanced = totalPrice.subtract(downPayment).setScale(MONEY_SCALE, ROUNDING);
        deal.setAmountFinanced(amountFinanced);

        // Front gross = vehiclePrice - invoicePrice (from PriceMaster)
        Vehicle vehicle = vehicleRepository.findById(deal.getVin()).orElse(null);
        if (vehicle != null) {
            Optional<PriceMaster> pmOpt = priceMasterRepository.findCurrentEffective(
                    vehicle.getModelYear(), vehicle.getMakeCode(), vehicle.getModelCode(), LocalDate.now());
            if (pmOpt.isPresent()) {
                PriceMaster pm = pmOpt.get();
                BigDecimal frontGross = vehiclePrice.subtract(discountAmt).subtract(pm.getInvoicePrice())
                        .setScale(MONEY_SCALE, ROUNDING);
                deal.setFrontGross(frontGross);

                // Back gross = holdback
                BigDecimal holdback;
                if (pm.getHoldbackAmt().signum() > 0) {
                    holdback = pm.getHoldbackAmt();
                } else {
                    holdback = pm.getInvoicePrice().multiply(pm.getHoldbackPct())
                            .divide(HUNDRED, MONEY_SCALE, ROUNDING);
                }
                deal.setBackGross(holdback.setScale(MONEY_SCALE, ROUNDING));
                deal.setTotalGross(deal.getFrontGross().add(deal.getBackGross()).setScale(MONEY_SCALE, ROUNDING));
            }
        }
    }

    /**
     * Build full DealResponse from a SalesDeal entity.
     */
    private DealResponse toResponse(SalesDeal deal) {
        // Lookup customer name
        String customerName = "";
        Optional<Customer> customerOpt = customerRepository.findById(deal.getCustomerId());
        if (customerOpt.isPresent()) {
            Customer c = customerOpt.get();
            customerName = c.getLastName() + ", " + c.getFirstName();
        }

        // Lookup vehicle description (year make model)
        String vehicleDesc = "";
        Optional<Vehicle> vehicleOpt = vehicleRepository.findById(deal.getVin());
        if (vehicleOpt.isPresent()) {
            Vehicle v = vehicleOpt.get();
            vehicleDesc = v.getModelYear() + " " + v.getMakeCode() + " " + v.getModelCode();
        }

        // Lookup salesperson name
        String salespersonName = "";
        Optional<SystemUser> salespersonOpt = userRepository.findByUserId(deal.getSalespersonId());
        if (salespersonOpt.isPresent()) {
            salespersonName = salespersonOpt.get().getUserName();
        }

        return DealResponse.builder()
                .dealNumber(deal.getDealNumber())
                .dealerCode(deal.getDealerCode())
                .customerId(deal.getCustomerId())
                .vin(deal.getVin())
                .salespersonId(deal.getSalespersonId())
                .salesManagerId(deal.getSalesManagerId())
                .dealType(deal.getDealType())
                .dealStatus(deal.getDealStatus())
                .vehiclePrice(deal.getVehiclePrice())
                .totalOptions(deal.getTotalOptions())
                .destinationFee(deal.getDestinationFee())
                .subtotal(deal.getSubtotal())
                .tradeAllow(deal.getTradeAllow())
                .tradePayoff(deal.getTradePayoff())
                .netTrade(deal.getNetTrade())
                .rebatesApplied(deal.getRebatesApplied())
                .discountAmt(deal.getDiscountAmt())
                .docFee(deal.getDocFee())
                .stateTax(deal.getStateTax())
                .countyTax(deal.getCountyTax())
                .cityTax(deal.getCityTax())
                .titleFee(deal.getTitleFee())
                .regFee(deal.getRegFee())
                .totalPrice(deal.getTotalPrice())
                .downPayment(deal.getDownPayment())
                .amountFinanced(deal.getAmountFinanced())
                .frontGross(deal.getFrontGross())
                .backGross(deal.getBackGross())
                .totalGross(deal.getTotalGross())
                .dealDate(deal.getDealDate())
                .deliveryDate(deal.getDeliveryDate())
                .createdTs(deal.getCreatedTs())
                .updatedTs(deal.getUpdatedTs())
                .customerName(customerName)
                .vehicleDesc(vehicleDesc)
                .salespersonName(salespersonName)
                .formattedVehiclePrice(fieldFormatter.formatCurrency(deal.getVehiclePrice()))
                .formattedTotalPrice(fieldFormatter.formatCurrency(deal.getTotalPrice()))
                .formattedFrontGross(fieldFormatter.formatCurrency(deal.getFrontGross()))
                .formattedDownPayment(fieldFormatter.formatCurrency(deal.getDownPayment()))
                .formattedAmountFinanced(fieldFormatter.formatCurrency(deal.getAmountFinanced()))
                .statusDescription(getStatusDescription(deal.getDealStatus()))
                .build();
    }

    /**
     * Build NegotiationResponse with full pricing breakdown.
     */
    private NegotiationResponse buildNegotiationResponse(SalesDeal deal, PriceMaster pm, String deskNotes) {
        BigDecimal msrp = BigDecimal.ZERO;
        BigDecimal invoicePrice = BigDecimal.ZERO;
        BigDecimal holdback = BigDecimal.ZERO;

        if (pm != null) {
            msrp = pm.getMsrp();
            invoicePrice = pm.getInvoicePrice();
            if (pm.getHoldbackAmt().signum() > 0) {
                holdback = pm.getHoldbackAmt();
            } else {
                holdback = pm.getInvoicePrice().multiply(pm.getHoldbackPct())
                        .divide(HUNDRED, MONEY_SCALE, ROUNDING);
            }
        }

        // Margin percentage = totalGross / vehiclePrice * 100
        BigDecimal marginPct = BigDecimal.ZERO;
        if (deal.getVehiclePrice() != null && deal.getVehiclePrice().signum() > 0
                && deal.getTotalGross() != null) {
            marginPct = deal.getTotalGross().multiply(HUNDRED)
                    .divide(deal.getVehiclePrice(), 4, ROUNDING);
        }

        return NegotiationResponse.builder()
                .dealNumber(deal.getDealNumber())
                .msrp(msrp)
                .invoicePrice(invoicePrice)
                .holdback(holdback)
                .currentOffer(deal.getVehiclePrice())
                .counterOffer(deal.getVehiclePrice())
                .discount(deal.getDiscountAmt())
                .rebates(deal.getRebatesApplied())
                .netTrade(deal.getNetTrade())
                .stateTax(deal.getStateTax())
                .countyTax(deal.getCountyTax())
                .cityTax(deal.getCityTax())
                .docFee(deal.getDocFee())
                .titleFee(deal.getTitleFee())
                .regFee(deal.getRegFee())
                .totalPrice(deal.getTotalPrice())
                .downPayment(deal.getDownPayment())
                .amountFinanced(deal.getAmountFinanced())
                .frontGross(deal.getFrontGross())
                .backGross(deal.getBackGross())
                .totalGross(deal.getTotalGross())
                .marginPct(marginPct)
                .deskNotes(deskNotes)
                .build();
    }

    /**
     * Map deal status code to human-readable description.
     */
    private String getStatusDescription(String status) {
        if (status == null) return "Unknown";
        return switch (status) {
            case "WS" -> "Worksheet";
            case "NE" -> "Negotiating";
            case "PA" -> "Pending Approval";
            case "AP" -> "Approved";
            case "FI" -> "In F&I";
            case "CT" -> "Contracted";
            case "DL" -> "Delivered";
            case "CA" -> "Cancelled";
            case "UW" -> "Unwound";
            default -> "Unknown (" + status + ")";
        };
    }

    /**
     * Get condition code multiplier for ACV calculation.
     */
    private BigDecimal getConditionMultiplier(String conditionCode) {
        return switch (conditionCode) {
            case "E" -> ACV_EXCELLENT;
            case "G" -> ACV_GOOD;
            case "F" -> ACV_FAIR;
            case "P" -> ACV_POOR;
            default -> ACV_FAIR; // default to fair
        };
    }

    /**
     * Get condition code description.
     */
    private String getConditionDescription(String conditionCode) {
        return switch (conditionCode) {
            case "E" -> "Excellent";
            case "G" -> "Good";
            case "F" -> "Fair";
            case "P" -> "Poor";
            default -> "Unknown";
        };
    }

    /**
     * Estimate base ACV for a trade-in based on age and mileage.
     * In production, this would call an external valuation service (KBB/NADA).
     * Stub uses a simple depreciation formula:
     *   base = $30,000 * (1 - age_years * 0.12) * (1 - miles_over_12k_per_year * 0.001)
     */
    private BigDecimal estimateBaseAcv(Short tradeYear, Integer odometer) {
        int currentYear = LocalDate.now().getYear();
        int age = currentYear - tradeYear;
        if (age < 0) age = 0;

        // Start with a $30,000 base
        BigDecimal base = new BigDecimal("30000.00");

        // Age depreciation: 12% per year, minimum 10% of base
        BigDecimal ageMultiplier = BigDecimal.ONE.subtract(
                new BigDecimal(age).multiply(new BigDecimal("0.12")));
        if (ageMultiplier.compareTo(new BigDecimal("0.10")) < 0) {
            ageMultiplier = new BigDecimal("0.10");
        }

        // Mileage adjustment: expected 12,000 miles/year
        int expectedMiles = age * 12000;
        int excessMiles = (odometer != null ? odometer : 0) - expectedMiles;
        BigDecimal mileageMultiplier = BigDecimal.ONE;
        if (excessMiles > 0) {
            // Deduct $0.05 per excess mile, capped at 30% reduction
            BigDecimal mileageDeduction = new BigDecimal(excessMiles).multiply(new BigDecimal("0.05"))
                    .divide(base, 4, ROUNDING);
            if (mileageDeduction.compareTo(new BigDecimal("0.30")) > 0) {
                mileageDeduction = new BigDecimal("0.30");
            }
            mileageMultiplier = BigDecimal.ONE.subtract(mileageDeduction);
        }

        return base.multiply(ageMultiplier).multiply(mileageMultiplier)
                .setScale(MONEY_SCALE, ROUNDING);
    }

    /**
     * Default null BigDecimal values to zero.
     */
    private BigDecimal defaultZero(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }
}
