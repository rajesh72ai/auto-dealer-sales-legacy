package com.autosales.modules.finance.service;

import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.modules.finance.dto.FinanceProductRequest;
import com.autosales.modules.finance.dto.FinanceProductResponse;
import com.autosales.modules.finance.entity.FinanceProduct;
import com.autosales.modules.finance.repository.FinanceProductRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
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
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for FinanceProductService — F&I product catalog and selection.
 * Port of FINPRD00.cbl — F&I product selection transaction.
 *
 * Legacy COBOL business rules validated:
 * - 10 hardcoded products (EXW, GAP, PPT, FBR, THF, MNT, TIR, DNT, KEY, LOJ) (FINPRD00)
 * - Product prices: EXW=$1995/$895, GAP=$895/$325, etc. (FINPRD00 WS-PRODUCT-CATALOG)
 * - Selection replaces all existing (delete + re-insert pattern) (FINPRD00)
 * - BACK_GROSS = SUM(GROSS_PROFIT), TOTAL_GROSS = FRONT_GROSS + BACK_GROSS (FINPRD00)
 * - Unknown product codes skipped with warning (FINPRD00 INSPECT/TALLYING)
 * - Product sequence auto-incremented (FINPRD00 MAX(PRODUCT_SEQ) + 1)
 */
@ExtendWith(MockitoExtension.class)
class FinanceProductServiceTest {

    @Mock private FinanceProductRepository financeProductRepository;
    @Mock private SalesDealRepository salesDealRepository;
    @Mock private FieldFormatter fieldFormatter;

    @InjectMocks
    private FinanceProductService financeProductService;

    private SalesDeal testDeal;

    @BeforeEach
    void setUp() {
        testDeal = SalesDeal.builder()
                .dealNumber("D000000001")
                .dealerCode("DLR01")
                .customerId(1001)
                .vin("1HGCM82633A004352")
                .dealStatus("FI")
                .vehiclePrice(new BigDecimal("35000.00"))
                .frontGross(new BigDecimal("4000.00"))
                .backGross(BigDecimal.ZERO)
                .totalGross(new BigDecimal("4000.00"))
                .totalPrice(new BigDecimal("38608.94"))
                .subtotal(new BigDecimal("36095.00"))
                .totalOptions(BigDecimal.ZERO)
                .destinationFee(new BigDecimal("1095.00"))
                .tradeAllow(BigDecimal.ZERO)
                .tradePayoff(BigDecimal.ZERO)
                .netTrade(BigDecimal.ZERO)
                .rebatesApplied(BigDecimal.ZERO)
                .discountAmt(BigDecimal.ZERO)
                .downPayment(new BigDecimal("5000.00"))
                .amountFinanced(new BigDecimal("33608.94"))
                .stateTax(new BigDecimal("2255.94"))
                .countyTax(BigDecimal.ZERO)
                .cityTax(BigDecimal.ZERO)
                .docFee(new BigDecimal("150.00"))
                .titleFee(new BigDecimal("33.00"))
                .regFee(new BigDecimal("75.00"))
                .dealDate(LocalDate.now())
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    // ========================================================================
    // 1. GET PRODUCT CATALOG
    // ========================================================================

    @Test
    @DisplayName("getProductCatalog: returns all 10 products with none selected")
    void testGetCatalog_noSelections() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(Collections.emptyList());

        FinanceProductResponse response = financeProductService.getProductCatalog("D000000001");

        assertNotNull(response);
        assertEquals("D000000001", response.getDealNumber());
        // All 10 catalog products from FINPRD00
        assertEquals(10, response.getCatalog().size());
        assertEquals(0, response.getSelectedCount());
        assertEquals(0, response.getTotalRetail().compareTo(BigDecimal.ZERO));

        // Verify catalog order and pricing (matches FINPRD00 WS-PRODUCT-CATALOG)
        FinanceProductResponse.ProductItem exw = response.getCatalog().get(0);
        assertEquals("EXW", exw.getCode());
        assertEquals("Extended Warranty", exw.getName());
        assertEquals(0, new BigDecimal("1995.00").compareTo(exw.getRetailPrice()));
        assertEquals(0, new BigDecimal("895.00").compareTo(exw.getDealerCost()));
        assertEquals(0, new BigDecimal("1100.00").compareTo(exw.getProfit()));
        assertFalse(exw.isSelected());
    }

    @Test
    @DisplayName("getProductCatalog: existing selections marked as selected")
    void testGetCatalog_withExistingSelections() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));

        FinanceProduct exw = FinanceProduct.builder()
                .dealNumber("D000000001").productSeq((short) 1).productType("EXW")
                .productName("Extended Warranty").retailPrice(new BigDecimal("1995.00"))
                .dealerCost(new BigDecimal("895.00")).grossProfit(new BigDecimal("1100.00"))
                .build();
        FinanceProduct gap = FinanceProduct.builder()
                .dealNumber("D000000001").productSeq((short) 2).productType("GAP")
                .productName("GAP Insurance").retailPrice(new BigDecimal("895.00"))
                .dealerCost(new BigDecimal("325.00")).grossProfit(new BigDecimal("570.00"))
                .build();
        when(financeProductRepository.findByDealNumber("D000000001")).thenReturn(List.of(exw, gap));

        FinanceProductResponse response = financeProductService.getProductCatalog("D000000001");

        assertEquals(2, response.getSelectedCount());
        assertEquals(0, new BigDecimal("2890.00").compareTo(response.getTotalRetail())); // 1995+895
        assertEquals(0, new BigDecimal("1220.00").compareTo(response.getTotalCost()));   // 895+325
        assertEquals(0, new BigDecimal("1670.00").compareTo(response.getTotalProfit())); // 1100+570

        // EXW and GAP should be marked selected
        assertTrue(response.getCatalog().stream()
                .filter(p -> "EXW".equals(p.getCode())).findFirst().get().isSelected());
        assertTrue(response.getCatalog().stream()
                .filter(p -> "GAP".equals(p.getCode())).findFirst().get().isSelected());
        // Others not selected
        assertFalse(response.getCatalog().stream()
                .filter(p -> "PPT".equals(p.getCode())).findFirst().get().isSelected());
    }

    @Test
    @DisplayName("getProductCatalog: deal not found → EntityNotFoundException")
    void testGetCatalog_dealNotFound() {
        when(salesDealRepository.findById("D999")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> financeProductService.getProductCatalog("D999"));
    }

    // ========================================================================
    // 2. SELECT PRODUCTS (FINPRD00)
    // ========================================================================

    @Test
    @DisplayName("selectProducts: 3 products selected — gross recalculated, deal updated (FINPRD00)")
    void testSelectProducts_success() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeProductRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));

        FinanceProductRequest request = FinanceProductRequest.builder()
                .dealNumber("D000000001")
                .selectedProducts(List.of("EXW", "GAP", "MNT"))
                .build();

        FinanceProductResponse response = financeProductService.selectProducts(request);

        assertNotNull(response);
        assertEquals(3, response.getSelectedCount());

        // Verify totals: EXW($1995/$895) + GAP($895/$325) + MNT($799/$375)
        BigDecimal expectedRetail = new BigDecimal("1995.00").add(new BigDecimal("895.00")).add(new BigDecimal("799.00")); // 3689
        BigDecimal expectedCost = new BigDecimal("895.00").add(new BigDecimal("325.00")).add(new BigDecimal("375.00"));   // 1595
        BigDecimal expectedProfit = expectedRetail.subtract(expectedCost); // 2094
        assertEquals(0, expectedRetail.compareTo(response.getTotalRetail()));
        assertEquals(0, expectedCost.compareTo(response.getTotalCost()));
        assertEquals(0, expectedProfit.compareTo(response.getTotalProfit()));

        // Verify existing products deleted first (reset pattern from FINPRD00)
        verify(financeProductRepository).deleteByDealNumber("D000000001");

        // Verify SalesDeal.backGross and totalGross updated
        // BACK_GROSS = SUM(GROSS_PROFIT), TOTAL_GROSS = FRONT_GROSS + BACK_GROSS
        assertEquals(0, expectedProfit.compareTo(testDeal.getBackGross()));
        assertEquals(0, new BigDecimal("4000.00").add(expectedProfit).compareTo(testDeal.getTotalGross()));
        verify(salesDealRepository).save(testDeal);
    }

    @Test
    @DisplayName("selectProducts: unknown product code skipped with warning (FINPRD00 INSPECT/TALLYING)")
    void testSelectProducts_unknownCodeSkipped() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeProductRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));

        FinanceProductRequest request = FinanceProductRequest.builder()
                .dealNumber("D000000001")
                .selectedProducts(List.of("EXW", "XYZ", "GAP")) // XYZ is unknown
                .build();

        FinanceProductResponse response = financeProductService.selectProducts(request);

        // Only 2 valid products saved (XYZ skipped)
        assertEquals(2, response.getSelectedCount());
        BigDecimal expectedRetail = new BigDecimal("1995.00").add(new BigDecimal("895.00")); // 2890
        assertEquals(0, expectedRetail.compareTo(response.getTotalRetail()));

        // Verify saveAll called with only 2 products
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<FinanceProduct>> captor = ArgumentCaptor.forClass(List.class);
        verify(financeProductRepository).saveAll(captor.capture());
        assertEquals(2, captor.getValue().size());
    }

    @Test
    @DisplayName("selectProducts: product sequence auto-incremented (FINPRD00 seq pattern)")
    void testSelectProducts_sequenceAutoIncremented() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeProductRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));

        FinanceProductRequest request = FinanceProductRequest.builder()
                .dealNumber("D000000001")
                .selectedProducts(List.of("EXW", "GAP", "LOJ"))
                .build();

        financeProductService.selectProducts(request);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<FinanceProduct>> captor = ArgumentCaptor.forClass(List.class);
        verify(financeProductRepository).saveAll(captor.capture());
        List<FinanceProduct> saved = captor.getValue();
        assertEquals((short) 1, saved.get(0).getProductSeq());
        assertEquals((short) 2, saved.get(1).getProductSeq());
        assertEquals((short) 3, saved.get(2).getProductSeq());
    }

    @Test
    @DisplayName("selectProducts: empty selection list — backGross zeroed out")
    void testSelectProducts_emptySelection() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeProductRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));

        FinanceProductRequest request = FinanceProductRequest.builder()
                .dealNumber("D000000001")
                .selectedProducts(List.of()) // No products
                .build();

        FinanceProductResponse response = financeProductService.selectProducts(request);

        assertEquals(0, response.getSelectedCount());
        assertEquals(0, BigDecimal.ZERO.compareTo(response.getTotalProfit()));
        // backGross = 0, totalGross = frontGross + 0
        assertEquals(0, BigDecimal.ZERO.compareTo(testDeal.getBackGross()));
        assertEquals(0, new BigDecimal("4000.00").compareTo(testDeal.getTotalGross()));
    }

    @Test
    @DisplayName("selectProducts: all 10 products — maximum F&I gross (FINPRD00 full catalog)")
    void testSelectProducts_allTenProducts() {
        when(salesDealRepository.findById("D000000001")).thenReturn(Optional.of(testDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(inv -> inv.getArgument(0));
        when(financeProductRepository.saveAll(anyList())).thenAnswer(inv -> inv.getArgument(0));

        FinanceProductRequest request = FinanceProductRequest.builder()
                .dealNumber("D000000001")
                .selectedProducts(List.of("EXW", "GAP", "PPT", "FBR", "THF", "MNT", "TIR", "DNT", "KEY", "LOJ"))
                .build();

        FinanceProductResponse response = financeProductService.selectProducts(request);

        assertEquals(10, response.getSelectedCount());
        // Total retail: 1995+895+599+399+695+799+599+399+299+995 = 7674
        assertEquals(0, new BigDecimal("7674.00").compareTo(response.getTotalRetail()));
        // Total cost: 895+325+125+75+195+375+185+95+45+450 = 2765
        assertEquals(0, new BigDecimal("2765.00").compareTo(response.getTotalCost()));
        // Total profit: 7674 - 2765 = 4909
        assertEquals(0, new BigDecimal("4909.00").compareTo(response.getTotalProfit()));
    }

    @Test
    @DisplayName("selectProducts: deal not found → EntityNotFoundException")
    void testSelectProducts_dealNotFound() {
        when(salesDealRepository.findById("D999")).thenReturn(Optional.empty());

        FinanceProductRequest request = FinanceProductRequest.builder()
                .dealNumber("D999")
                .selectedProducts(List.of("EXW"))
                .build();

        assertThrows(EntityNotFoundException.class,
                () -> financeProductService.selectProducts(request));
    }
}
