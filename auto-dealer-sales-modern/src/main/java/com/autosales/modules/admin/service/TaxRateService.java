package com.autosales.modules.admin.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.common.util.TaxCalculationResult;
import com.autosales.modules.admin.dto.TaxCalculationRequest;
import com.autosales.modules.admin.dto.TaxRateRequest;
import com.autosales.modules.admin.dto.TaxRateResponse;
import com.autosales.modules.admin.entity.TaxRate;
import com.autosales.modules.admin.entity.TaxRateId;
import com.autosales.modules.admin.repository.TaxRateRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;

/**
 * Service for tax rate management and tax calculation.
 * Port of ADMTAX00.cbl — tax rate maintenance and COMTAXL0.cbl — tax calculation.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class TaxRateService {

    private static final BigDecimal MAX_COMBINED_RATE = new BigDecimal("0.15");
    private static final BigDecimal TEST_AMOUNT_30K = new BigDecimal("30000");

    private final TaxRateRepository repository;
    private final ResponseFormatter responseFormatter;

    public TaxRateService(TaxRateRepository repository,
                          ResponseFormatter responseFormatter) {
        this.repository = repository;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all tax rates with optional filtering by state code.
     */
    public PaginatedResponse<TaxRateResponse> findAll(String stateCode, Pageable pageable) {
        log.debug("Finding tax rates - stateCode={}, page={}", stateCode, pageable);

        Page<TaxRate> page;
        if (stateCode != null) {
            page = repository.findByStateCode(stateCode, pageable);
        } else {
            page = repository.findAll(pageable);
        }

        List<TaxRateResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find the currently effective tax rate for a specific jurisdiction.
     */
    public TaxRateResponse findCurrentEffective(String state, String county, String city) {
        log.debug("Finding current effective tax rate for state={}, county={}, city={}", state, county, city);
        TaxRate entity = repository.findCurrentEffective(state, county, city, LocalDate.now())
                .orElseThrow(() -> new EntityNotFoundException("TaxRate",
                        state + "/" + county + "/" + city + " (effective)"));
        return toResponse(entity);
    }

    /**
     * Create a new tax rate record.
     */
    @Transactional
    @Auditable(action = "INS", entity = "tax_rate", keyExpression = "#request.stateCode + '/' + #request.countyCode + '/' + #request.cityCode")
    public TaxRateResponse create(TaxRateRequest request) {
        log.info("Creating tax rate state={}, county={}, city={}, effective={}",
                request.getStateCode(), request.getCountyCode(), request.getCityCode(), request.getEffectiveDate());

        validateCombinedRate(request);

        TaxRate entity = toEntity(request);
        TaxRate saved = repository.save(entity);
        log.info("Created tax rate for {}/{}/{} effective {}",
                saved.getStateCode(), saved.getCountyCode(), saved.getCityCode(), saved.getEffectiveDate());
        return toResponse(saved);
    }

    /**
     * Update an existing tax rate record.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "tax_rate", keyExpression = "#state + '/' + #county + '/' + #city")
    public TaxRateResponse update(String state, String county, String city, LocalDate date, TaxRateRequest request) {
        log.info("Updating tax rate state={}, county={}, city={}, effective={}", state, county, city, date);

        validateCombinedRate(request);

        TaxRateId id = new TaxRateId(state, county, city, date);
        TaxRate existing = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("TaxRate",
                        state + "/" + county + "/" + city + "/" + date));

        // Update mutable fields (not composite key)
        existing.setStateRate(request.getStateRate());
        existing.setCountyRate(request.getCountyRate());
        existing.setCityRate(request.getCityRate());
        existing.setDocFeeMax(request.getDocFeeMax());
        existing.setTitleFee(request.getTitleFee());
        existing.setRegFee(request.getRegFee());
        existing.setExpiryDate(request.getExpiryDate());

        TaxRate saved = repository.save(existing);
        log.info("Updated tax rate for {}/{}/{} effective {}",
                saved.getStateCode(), saved.getCountyCode(), saved.getCityCode(), saved.getEffectiveDate());
        return toResponse(saved);
    }

    /**
     * Calculate taxes for a given amount and jurisdiction.
     * Port of COMTAXL0.cbl — multi-jurisdiction tax calculation routine.
     */
    public TaxCalculationResult calculateTax(TaxCalculationRequest request) {
        log.debug("Calculating tax for amount={}, state={}, county={}, city={}",
                request.getTaxableAmount(), request.getStateCode(), request.getCountyCode(), request.getCityCode());

        TaxRate rate = repository.findCurrentEffective(
                        request.getStateCode(), request.getCountyCode(), request.getCityCode(), LocalDate.now())
                .orElseThrow(() -> new EntityNotFoundException("TaxRate",
                        request.getStateCode() + "/" + request.getCountyCode() + "/" + request.getCityCode() + " (effective)"));

        BigDecimal tradeAllowance = request.getTradeAllowance() != null ? request.getTradeAllowance() : BigDecimal.ZERO;
        BigDecimal netTaxable = request.getTaxableAmount().subtract(tradeAllowance).max(BigDecimal.ZERO);

        BigDecimal stateTax = netTaxable.multiply(rate.getStateRate()).setScale(2, RoundingMode.HALF_UP);
        BigDecimal countyTax = netTaxable.multiply(rate.getCountyRate()).setScale(2, RoundingMode.HALF_UP);
        BigDecimal cityTax = netTaxable.multiply(rate.getCityRate()).setScale(2, RoundingMode.HALF_UP);
        BigDecimal totalTax = stateTax.add(countyTax).add(cityTax);

        BigDecimal totalFees = rate.getDocFeeMax().add(rate.getTitleFee()).add(rate.getRegFee());
        BigDecimal grandTotal = totalTax.add(totalFees);

        log.debug("Tax calculated: stateTax={}, countyTax={}, cityTax={}, totalTax={}", stateTax, countyTax, cityTax, totalTax);

        return new TaxCalculationResult(stateTax, countyTax, cityTax,
                rate.getDocFeeMax(), rate.getTitleFee(), rate.getRegFee(),
                totalTax, totalFees, grandTotal);
    }

    private void validateCombinedRate(TaxRateRequest request) {
        BigDecimal combined = request.getStateRate().add(request.getCountyRate()).add(request.getCityRate());
        if (combined.compareTo(MAX_COMBINED_RATE) > 0) {
            throw new BusinessValidationException(
                    "Combined tax rate (" + combined + ") exceeds maximum allowed rate of " + MAX_COMBINED_RATE);
        }
    }

    private TaxRateResponse toResponse(TaxRate entity) {
        BigDecimal combinedRate = entity.getStateRate().add(entity.getCountyRate()).add(entity.getCityRate());
        BigDecimal combinedPctValue = combinedRate.multiply(new BigDecimal("100")).setScale(2, RoundingMode.HALF_UP);
        BigDecimal testTax = TEST_AMOUNT_30K.multiply(combinedRate).setScale(2, RoundingMode.HALF_UP);

        return TaxRateResponse.builder()
                .stateCode(entity.getStateCode())
                .countyCode(entity.getCountyCode())
                .cityCode(entity.getCityCode())
                .stateRate(entity.getStateRate())
                .countyRate(entity.getCountyRate())
                .cityRate(entity.getCityRate())
                .docFeeMax(entity.getDocFeeMax())
                .titleFee(entity.getTitleFee())
                .regFee(entity.getRegFee())
                .effectiveDate(entity.getEffectiveDate())
                .expiryDate(entity.getExpiryDate())
                .combinedRate(combinedRate)
                .combinedPct(combinedPctValue.toPlainString() + "%")
                .testTaxOn30K(testTax)
                .build();
    }

    private TaxRate toEntity(TaxRateRequest request) {
        return TaxRate.builder()
                .stateCode(request.getStateCode())
                .countyCode(request.getCountyCode())
                .cityCode(request.getCityCode())
                .effectiveDate(request.getEffectiveDate())
                .stateRate(request.getStateRate())
                .countyRate(request.getCountyRate())
                .cityRate(request.getCityRate())
                .docFeeMax(request.getDocFeeMax())
                .titleFee(request.getTitleFee())
                .regFee(request.getRegFee())
                .expiryDate(request.getExpiryDate())
                .build();
    }
}
