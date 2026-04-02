package com.autosales.modules.finance.service;

import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.admin.repository.ModelMasterRepository;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.finance.dto.DealDocumentResponse;
import com.autosales.modules.finance.entity.FinanceApp;
import com.autosales.modules.finance.entity.FinanceProduct;
import com.autosales.modules.finance.entity.LeaseTerms;
import com.autosales.modules.finance.repository.FinanceAppRepository;
import com.autosales.modules.finance.repository.FinanceProductRepository;
import com.autosales.modules.finance.repository.LeaseTermsRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Read-only document assembly service for deal closing documents.
 * Port of FINDOC00.cbl — finance document assembly transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class DealDocumentService {

    private static final int MONEY_SCALE = 2;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;

    private final SalesDealRepository salesDealRepository;
    private final CustomerRepository customerRepository;
    private final VehicleRepository vehicleRepository;
    private final ModelMasterRepository modelMasterRepository;
    private final FinanceAppRepository financeAppRepository;
    private final LeaseTermsRepository leaseTermsRepository;
    private final FinanceProductRepository financeProductRepository;
    private final DealerRepository dealerRepository;
    private final FieldFormatter fieldFormatter;

    /**
     * Generate a complete deal document package for closing.
     */
    public DealDocumentResponse generateDocument(String dealNumber) {
        log.info("Generating deal document for deal={}", dealNumber);

        // Fetch deal (required)
        SalesDeal deal = salesDealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("SalesDeal", dealNumber));

        // Fetch customer
        Customer customer = customerRepository.findById(deal.getCustomerId())
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(deal.getCustomerId())));

        // Fetch vehicle
        Vehicle vehicle = vehicleRepository.findById(deal.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", deal.getVin()));

        // Fetch model master for vehicle description
        ModelMasterId modelId = new ModelMasterId(vehicle.getModelYear(), vehicle.getMakeCode(), vehicle.getModelCode());
        Optional<ModelMaster> modelMaster = modelMasterRepository.findById(modelId);
        String modelName = modelMaster.map(ModelMaster::getModelName).orElse(vehicle.getModelCode());

        // Fetch dealer
        Dealer dealer = dealerRepository.findById(deal.getDealerCode())
                .orElseThrow(() -> new EntityNotFoundException("Dealer", deal.getDealerCode()));

        // Fetch latest finance app for this deal
        List<FinanceApp> finApps = financeAppRepository.findByDealNumber(dealNumber);
        FinanceApp financeApp = finApps.isEmpty() ? null : finApps.get(finApps.size() - 1);

        // Fetch lease terms if applicable
        LeaseTerms leaseTerms = null;
        if (financeApp != null && "S".equals(financeApp.getFinanceType())) {
            leaseTerms = leaseTermsRepository.findByFinanceId(financeApp.getFinanceId()).orElse(null);
        }

        // Fetch F&I products
        List<FinanceProduct> fiProducts = financeProductRepository.findByDealNumber(dealNumber);

        // Determine document type
        String documentType;
        if (financeApp != null) {
            documentType = switch (financeApp.getFinanceType()) {
                case "L" -> "Retail Installment Contract";
                case "S" -> "Lease Agreement";
                case "C" -> "Cash Purchase Receipt";
                default -> "Sales Contract";
            };
        } else {
            documentType = "Cash Purchase Receipt";
        }

        // Assemble Seller
        DealDocumentResponse.Seller seller = DealDocumentResponse.Seller.builder()
                .dealerName(dealer.getDealerName())
                .address(dealer.getAddressLine1())
                .city(dealer.getCity())
                .state(dealer.getStateCode())
                .zip(dealer.getZipCode())
                .build();

        // Assemble Buyer
        String customerName = customer.getFirstName() + " " + customer.getLastName();
        DealDocumentResponse.Buyer buyer = DealDocumentResponse.Buyer.builder()
                .customerName(customerName)
                .address(customer.getAddressLine1())
                .city(customer.getCity())
                .state(customer.getStateCode())
                .zip(customer.getZipCode())
                .build();

        // Assemble Vehicle
        DealDocumentResponse.Vehicle vehicleInfo = DealDocumentResponse.Vehicle.builder()
                .year(vehicle.getModelYear())
                .make(vehicle.getMakeCode())
                .modelName(modelName)
                .vin(vehicle.getVin())
                .stockNumber(vehicle.getStockNumber())
                .odometer(vehicle.getOdometer())
                .build();

        // Assemble Pricing
        BigDecimal totalTaxes = deal.getStateTax().add(deal.getCountyTax()).add(deal.getCityTax());
        BigDecimal totalFees = deal.getDocFee().add(deal.getTitleFee()).add(deal.getRegFee());
        DealDocumentResponse.Pricing pricing = DealDocumentResponse.Pricing.builder()
                .vehiclePrice(deal.getVehiclePrice())
                .options(deal.getTotalOptions())
                .destination(deal.getDestinationFee())
                .rebates(deal.getRebatesApplied())
                .tradeAllowance(deal.getTradeAllow())
                .taxes(totalTaxes)
                .fees(totalFees)
                .totalPrice(deal.getTotalPrice())
                .downPayment(deal.getDownPayment())
                .amountFinanced(deal.getAmountFinanced())
                .build();

        // Assemble Finance Terms
        DealDocumentResponse.FinanceTerms financeTerms = null;
        if (financeApp != null && !"C".equals(financeApp.getFinanceType())) {
            BigDecimal monthlyPayment = financeApp.getMonthlyPayment() != null
                    ? financeApp.getMonthlyPayment() : BigDecimal.ZERO;
            BigDecimal totalOfPayments = BigDecimal.ZERO;
            BigDecimal financeCharge = BigDecimal.ZERO;
            if (financeApp.getTermMonths() != null) {
                totalOfPayments = monthlyPayment.multiply(new BigDecimal(financeApp.getTermMonths()))
                        .setScale(MONEY_SCALE, ROUNDING);
                financeCharge = totalOfPayments.subtract(deal.getAmountFinanced())
                        .setScale(MONEY_SCALE, ROUNDING);
            }

            BigDecimal apr = financeApp.getAprApproved() != null
                    ? financeApp.getAprApproved() : financeApp.getAprRequested();

            financeTerms = DealDocumentResponse.FinanceTerms.builder()
                    .apr(apr)
                    .termMonths(financeApp.getTermMonths())
                    .monthlyPayment(monthlyPayment)
                    .totalOfPayments(totalOfPayments)
                    .financeCharge(financeCharge)
                    .build();
        }

        // Assemble F&I Products
        List<DealDocumentResponse.FiProduct> fiProductList = fiProducts.stream()
                .map(p -> DealDocumentResponse.FiProduct.builder()
                        .productName(p.getProductName())
                        .retailPrice(p.getRetailPrice())
                        .build())
                .collect(Collectors.toList());

        log.info("Generated {} document for deal={}", documentType, dealNumber);
        return DealDocumentResponse.builder()
                .dealNumber(dealNumber)
                .documentType(documentType)
                .seller(seller)
                .buyer(buyer)
                .vehicle(vehicleInfo)
                .pricing(pricing)
                .financeTerms(financeTerms)
                .fiProducts(fiProductList)
                .build();
    }
}
