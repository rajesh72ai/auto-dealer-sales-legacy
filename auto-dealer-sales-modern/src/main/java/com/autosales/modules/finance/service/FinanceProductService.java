package com.autosales.modules.finance.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.modules.finance.dto.FinanceProductRequest;
import com.autosales.modules.finance.dto.FinanceProductResponse;
import com.autosales.modules.finance.entity.FinanceProduct;
import com.autosales.modules.finance.repository.FinanceProductRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for F&I product catalog and selection management.
 * Port of FINPRD00.cbl — F&I product selection transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class FinanceProductService {

    private final FinanceProductRepository financeProductRepository;
    private final SalesDealRepository salesDealRepository;
    private final FieldFormatter fieldFormatter;

    /**
     * Internal catalog item record for the hardcoded F&I product catalog.
     */
    private record ProductCatalogItem(
            String code, String name, short term, Integer miles,
            BigDecimal retailPrice, BigDecimal dealerCost) {

        BigDecimal profit() {
            return retailPrice.subtract(dealerCost);
        }
    }

    /**
     * Hardcoded F&I product catalog — 10 standard products.
     */
    private static final Map<String, ProductCatalogItem> CATALOG;

    static {
        Map<String, ProductCatalogItem> map = new LinkedHashMap<>();
        map.put("EXW", new ProductCatalogItem("EXW", "Extended Warranty",
                (short) 36, 12000, new BigDecimal("1995.00"), new BigDecimal("895.00")));
        map.put("GAP", new ProductCatalogItem("GAP", "GAP Insurance",
                (short) 36, null, new BigDecimal("895.00"), new BigDecimal("325.00")));
        map.put("PPT", new ProductCatalogItem("PPT", "Paint Protection",
                (short) 60, null, new BigDecimal("599.00"), new BigDecimal("125.00")));
        map.put("FBR", new ProductCatalogItem("FBR", "Fabric Protection",
                (short) 60, null, new BigDecimal("399.00"), new BigDecimal("75.00")));
        map.put("THF", new ProductCatalogItem("THF", "Theft Deterrent",
                (short) 60, null, new BigDecimal("695.00"), new BigDecimal("195.00")));
        map.put("MNT", new ProductCatalogItem("MNT", "Maintenance Plan",
                (short) 36, 50000, new BigDecimal("799.00"), new BigDecimal("375.00")));
        map.put("TIR", new ProductCatalogItem("TIR", "Tire and Wheel",
                (short) 36, 50000, new BigDecimal("599.00"), new BigDecimal("185.00")));
        map.put("DNT", new ProductCatalogItem("DNT", "Dent Repair",
                (short) 36, null, new BigDecimal("399.00"), new BigDecimal("95.00")));
        map.put("KEY", new ProductCatalogItem("KEY", "Key Replacement",
                (short) 60, null, new BigDecimal("299.00"), new BigDecimal("45.00")));
        map.put("LOJ", new ProductCatalogItem("LOJ", "LoJack GPS",
                (short) 48, null, new BigDecimal("995.00"), new BigDecimal("450.00")));
        CATALOG = Collections.unmodifiableMap(map);
    }

    /**
     * Get the full F&I product catalog for a deal, marking selected products.
     */
    public FinanceProductResponse getProductCatalog(String dealNumber) {
        log.debug("Getting F&I product catalog for deal={}", dealNumber);

        // Validate deal exists
        salesDealRepository.findById(dealNumber)
                .orElseThrow(() -> new EntityNotFoundException("SalesDeal", dealNumber));

        // Get existing selections
        List<FinanceProduct> selected = financeProductRepository.findByDealNumber(dealNumber);
        Set<String> selectedCodes = selected.stream()
                .map(FinanceProduct::getProductType)
                .collect(Collectors.toSet());

        return toResponse(dealNumber, selected, selectedCodes);
    }

    /**
     * Select F&I products for a deal (replaces all existing selections).
     */
    @Transactional
    @Auditable(action = "UPD", entity = "finance_product", keyExpression = "#request.dealNumber")
    public FinanceProductResponse selectProducts(FinanceProductRequest request) {
        log.info("Selecting F&I products for deal={}, products={}", request.getDealNumber(), request.getSelectedProducts());

        // Validate deal exists
        SalesDeal deal = salesDealRepository.findById(request.getDealNumber())
                .orElseThrow(() -> new EntityNotFoundException("SalesDeal", request.getDealNumber()));

        // Delete existing products for deal (reset)
        financeProductRepository.deleteByDealNumber(request.getDealNumber());

        // Create new product selections
        List<FinanceProduct> newProducts = new ArrayList<>();
        short seq = 1;
        BigDecimal totalRetail = BigDecimal.ZERO;
        BigDecimal totalCost = BigDecimal.ZERO;
        BigDecimal totalProfit = BigDecimal.ZERO;

        for (String code : request.getSelectedProducts()) {
            ProductCatalogItem item = CATALOG.get(code.toUpperCase());
            if (item == null) {
                log.warn("Unknown product code {} skipped for deal={}", code, request.getDealNumber());
                continue;
            }

            FinanceProduct product = FinanceProduct.builder()
                    .dealNumber(request.getDealNumber())
                    .productSeq(seq++)
                    .productType(item.code())
                    .productName(item.name())
                    .termMonths(item.term())
                    .mileageLimit(item.miles())
                    .retailPrice(item.retailPrice())
                    .dealerCost(item.dealerCost())
                    .grossProfit(item.profit())
                    .build();

            newProducts.add(product);
            totalRetail = totalRetail.add(item.retailPrice());
            totalCost = totalCost.add(item.dealerCost());
            totalProfit = totalProfit.add(item.profit());
        }

        financeProductRepository.saveAll(newProducts);

        // Update SalesDeal: backGross = totalProfit, totalGross = frontGross + backGross
        deal.setBackGross(totalProfit);
        deal.setTotalGross(deal.getFrontGross().add(totalProfit));
        deal.setUpdatedTs(LocalDateTime.now());
        salesDealRepository.save(deal);

        Set<String> selectedCodes = newProducts.stream()
                .map(FinanceProduct::getProductType)
                .collect(Collectors.toSet());

        log.info("Selected {} F&I products for deal={}, totalProfit={}",
                newProducts.size(), request.getDealNumber(), totalProfit);
        return toResponse(request.getDealNumber(), newProducts, selectedCodes);
    }

    // --- Private helpers ---

    private FinanceProductResponse toResponse(String dealNumber, List<FinanceProduct> selected,
                                               Set<String> selectedCodes) {
        BigDecimal totalRetail = BigDecimal.ZERO;
        BigDecimal totalCost = BigDecimal.ZERO;
        BigDecimal totalProfit = BigDecimal.ZERO;

        List<FinanceProductResponse.ProductItem> catalog = new ArrayList<>();
        for (ProductCatalogItem item : CATALOG.values()) {
            boolean isSelected = selectedCodes.contains(item.code());
            catalog.add(FinanceProductResponse.ProductItem.builder()
                    .code(item.code())
                    .name(item.name())
                    .term(item.term())
                    .miles(item.miles())
                    .retailPrice(item.retailPrice())
                    .dealerCost(item.dealerCost())
                    .profit(item.profit())
                    .selected(isSelected)
                    .build());

            if (isSelected) {
                totalRetail = totalRetail.add(item.retailPrice());
                totalCost = totalCost.add(item.dealerCost());
                totalProfit = totalProfit.add(item.profit());
            }
        }

        return FinanceProductResponse.builder()
                .dealNumber(dealNumber)
                .catalog(catalog)
                .selectedCount(selectedCodes.size())
                .totalRetail(totalRetail)
                .totalCost(totalCost)
                .totalProfit(totalProfit)
                .build();
    }
}
