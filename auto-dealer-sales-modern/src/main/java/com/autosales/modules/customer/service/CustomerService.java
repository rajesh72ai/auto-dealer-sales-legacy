package com.autosales.modules.customer.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.security.SystemUser;
import com.autosales.common.security.SystemUserRepository;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.customer.dto.CustomerHistoryResponse;
import com.autosales.modules.customer.dto.CustomerRequest;
import com.autosales.modules.customer.dto.CustomerResponse;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
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
import java.util.Optional;

/**
 * Service for customer management.
 * Port of CUSTMNT00.cbl — customer maintenance transaction,
 * CUSTINQ00.cbl — customer inquiry, and CUSTHST00.cbl — customer history.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final DealerRepository dealerRepository;
    private final SalesDealRepository salesDealRepository;
    private final VehicleRepository vehicleRepository;
    private final SystemUserRepository systemUserRepository;
    private final FieldFormatter fieldFormatter;
    private final ResponseFormatter responseFormatter;

    public CustomerService(CustomerRepository customerRepository,
                           DealerRepository dealerRepository,
                           SalesDealRepository salesDealRepository,
                           VehicleRepository vehicleRepository,
                           SystemUserRepository systemUserRepository,
                           FieldFormatter fieldFormatter,
                           ResponseFormatter responseFormatter) {
        this.customerRepository = customerRepository;
        this.dealerRepository = dealerRepository;
        this.salesDealRepository = salesDealRepository;
        this.vehicleRepository = vehicleRepository;
        this.systemUserRepository = systemUserRepository;
        this.fieldFormatter = fieldFormatter;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all customers for a dealer with optional sorting.
     */
    public PaginatedResponse<CustomerResponse> findAll(String dealerCode, String sort, Pageable pageable) {
        log.debug("Finding customers - dealerCode={}, sort={}, page={}", dealerCode, sort, pageable);

        Sort sorting = resolveSort(sort);
        Pageable sortedPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sorting);

        Page<Customer> page = customerRepository.findByDealerCode(dealerCode, sortedPageable);

        List<CustomerResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Search customers by various criteria.
     */
    public PaginatedResponse<CustomerResponse> search(String searchType, String searchValue,
                                                       String dealerCode, Pageable pageable) {
        log.debug("Searching customers - type={}, value={}, dealer={}", searchType, searchValue, dealerCode);

        Page<Customer> page;
        switch (searchType.toUpperCase()) {
            case "LN" -> page = customerRepository.findByDealerCodeAndLastNameContainingIgnoreCase(
                    dealerCode, searchValue, pageable);
            case "FN" -> page = customerRepository.findByDealerCodeAndFirstNameContainingIgnoreCase(
                    dealerCode, searchValue, pageable);
            case "PH" -> {
                String digits = searchValue.replaceAll("\\D", "");
                page = customerRepository.findByDealerCodeAndCellPhone(dealerCode, digits, pageable);
                if (page.isEmpty()) {
                    page = customerRepository.findByDealerCodeAndHomePhone(dealerCode, digits, pageable);
                }
            }
            case "ID" -> {
                Integer id = Integer.valueOf(searchValue);
                Optional<Customer> customer = customerRepository.findById(id);
                if (customer.isPresent() && customer.get().getDealerCode().equals(dealerCode)) {
                    List<CustomerResponse> content = List.of(toResponse(customer.get()));
                    return responseFormatter.paginated(content, 0, 1, 1);
                }
                return responseFormatter.paginated(List.of(), 0, 0, 0);
            }
            default -> throw new IllegalArgumentException("Invalid search type: " + searchType);
        }

        List<CustomerResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a single customer by ID.
     */
    public CustomerResponse findById(Integer id) {
        log.debug("Finding customer by id={}", id);
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(id)));
        return toResponse(customer);
    }

    /**
     * Create a new customer record.
     */
    @Transactional
    @Auditable(action = "INS", entity = "customer", keyExpression = "#result.customerId")
    public CustomerResponse create(CustomerRequest request) {
        log.info("Creating customer - lastName={}, dealerCode={}", request.getLastName(), request.getDealerCode());

        // Validate dealer exists
        if (!dealerRepository.existsById(request.getDealerCode())) {
            throw new EntityNotFoundException("Dealer", request.getDealerCode());
        }

        // Duplicate check: last name + cell phone
        if (request.getCellPhone() != null) {
            Optional<Customer> duplicate = customerRepository.findByLastNameAndCellPhoneAndDealerCode(
                    request.getLastName(), request.getCellPhone(), request.getDealerCode());
            if (duplicate.isPresent()) {
                throw new DuplicateEntityException("Customer",
                        request.getLastName() + "/" + request.getCellPhone());
            }
        }

        // Auto-assign salesperson if not provided (round-robin from system_user where dealer and type='S')
        if (request.getAssignedSales() == null || request.getAssignedSales().isBlank()) {
            String salesperson = assignSalesperson(request.getDealerCode());
            request.setAssignedSales(salesperson);
        }

        Customer entity = toEntity(request);
        LocalDateTime now = LocalDateTime.now();
        entity.setCreatedTs(now);
        entity.setUpdatedTs(now);

        Customer saved = customerRepository.save(entity);
        log.info("Created customer id={}", saved.getCustomerId());
        return toResponse(saved);
    }

    /**
     * Update an existing customer record.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "customer", keyExpression = "#id")
    public CustomerResponse update(Integer id, CustomerRequest request) {
        log.info("Updating customer id={}", id);

        Customer existing = customerRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(id)));

        // Update mutable fields (not customerId, createdTs)
        existing.setFirstName(request.getFirstName());
        existing.setLastName(request.getLastName());
        existing.setMiddleInit(request.getMiddleInit());
        existing.setDateOfBirth(request.getDateOfBirth());
        existing.setSsnLast4(request.getSsnLast4());
        existing.setDriversLicense(request.getDriversLicense());
        existing.setDlState(request.getDlState());
        existing.setAddressLine1(request.getAddressLine1());
        existing.setAddressLine2(request.getAddressLine2());
        existing.setCity(request.getCity());
        existing.setStateCode(request.getStateCode());
        existing.setZipCode(request.getZipCode());
        existing.setHomePhone(request.getHomePhone());
        existing.setCellPhone(request.getCellPhone());
        existing.setEmail(request.getEmail());
        existing.setEmployerName(request.getEmployerName());
        existing.setAnnualIncome(request.getAnnualIncome());
        existing.setCustomerType(request.getCustomerType());
        existing.setSourceCode(request.getSourceCode());
        existing.setDealerCode(request.getDealerCode());
        existing.setAssignedSales(request.getAssignedSales());
        existing.setUpdatedTs(LocalDateTime.now());

        Customer saved = customerRepository.save(existing);
        log.info("Updated customer id={}", saved.getCustomerId());
        return toResponse(saved);
    }

    /**
     * Get purchase history for a customer.
     * Port of CUSTHST00.cbl — customer history inquiry.
     */
    public CustomerHistoryResponse getHistory(Integer customerId) {
        log.debug("Getting history for customer id={}", customerId);

        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(customerId)));

        List<SalesDeal> deals = salesDealRepository.findByCustomerIdOrderByDealDateDesc(customerId);

        List<CustomerHistoryResponse.DealSummary> dealSummaries = new ArrayList<>();
        BigDecimal totalSpent = BigDecimal.ZERO;

        for (SalesDeal deal : deals) {
            // Look up vehicle for year/make/model
            String yearMakeModel = "";
            Optional<Vehicle> vehicle = vehicleRepository.findById(deal.getVin());
            if (vehicle.isPresent()) {
                Vehicle v = vehicle.get();
                yearMakeModel = v.getModelYear() + " " + v.getMakeCode() + " " + v.getModelCode();
            }

            dealSummaries.add(CustomerHistoryResponse.DealSummary.builder()
                    .dealNumber(deal.getDealNumber())
                    .dealDate(deal.getDealDate())
                    .vin(deal.getVin())
                    .yearMakeModel(yearMakeModel)
                    .dealType(deal.getDealType())
                    .salePrice(deal.getTotalPrice())
                    .tradeAllow(deal.getTradeAllow())
                    .build());

            totalSpent = totalSpent.add(deal.getTotalPrice());
        }

        int totalPurchases = deals.size();
        BigDecimal averageDeal = totalPurchases > 0
                ? totalSpent.divide(BigDecimal.valueOf(totalPurchases), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        String repeatStatus = totalPurchases >= 3 ? "Loyal" : totalPurchases == 2 ? "Repeat" : "First-Time";

        String customerName = customer.getLastName() + ", " + customer.getFirstName();

        return CustomerHistoryResponse.builder()
                .customerId(customerId)
                .customerName(customerName)
                .repeatStatus(repeatStatus)
                .totalPurchases(totalPurchases)
                .totalSpent(totalSpent)
                .averageDeal(averageDeal)
                .deals(dealSummaries)
                .build();
    }

    // --- Private helpers ---

    private Sort resolveSort(String sort) {
        if (sort == null) {
            sort = "name";
        }
        return switch (sort.toLowerCase()) {
            case "date" -> Sort.by(Sort.Direction.DESC, "createdTs");
            case "type" -> Sort.by(Sort.Direction.ASC, "customerType").and(Sort.by(Sort.Direction.ASC, "lastName"));
            default -> Sort.by(Sort.Direction.ASC, "lastName").and(Sort.by(Sort.Direction.ASC, "firstName"));
        };
    }

    /**
     * Round-robin salesperson assignment from system_user where dealer and type='S'.
     */
    private String assignSalesperson(String dealerCode) {
        List<SystemUser> salespeople = systemUserRepository.findAll().stream()
                .filter(u -> dealerCode.equals(u.getDealerCode())
                        && "S".equals(u.getUserType())
                        && "Y".equals(u.getActiveFlag()))
                .toList();

        if (salespeople.isEmpty()) {
            log.warn("No active salespeople found for dealer={}, leaving unassigned", dealerCode);
            return null;
        }

        // Simple round-robin based on current time modulo number of salespeople
        int index = (int) (System.currentTimeMillis() % salespeople.size());
        return salespeople.get(index).getUserId();
    }

    private CustomerResponse toResponse(Customer entity) {
        String fullName = entity.getLastName() + ", " + entity.getFirstName();

        return CustomerResponse.builder()
                .customerId(entity.getCustomerId())
                .firstName(entity.getFirstName())
                .lastName(entity.getLastName())
                .middleInit(entity.getMiddleInit())
                .dateOfBirth(entity.getDateOfBirth())
                .ssnLast4(entity.getSsnLast4())
                .driversLicense(entity.getDriversLicense())
                .dlState(entity.getDlState())
                .addressLine1(entity.getAddressLine1())
                .addressLine2(entity.getAddressLine2())
                .city(entity.getCity())
                .stateCode(entity.getStateCode())
                .zipCode(entity.getZipCode())
                .homePhone(entity.getHomePhone())
                .cellPhone(entity.getCellPhone())
                .email(entity.getEmail())
                .employerName(entity.getEmployerName())
                .annualIncome(entity.getAnnualIncome())
                .customerType(entity.getCustomerType())
                .sourceCode(entity.getSourceCode())
                .dealerCode(entity.getDealerCode())
                .assignedSales(entity.getAssignedSales())
                .createdTs(entity.getCreatedTs())
                .updatedTs(entity.getUpdatedTs())
                .formattedPhone(fieldFormatter.formatPhone(entity.getHomePhone()))
                .formattedCellPhone(fieldFormatter.formatPhone(entity.getCellPhone()))
                .fullName(fullName)
                .build();
    }

    private Customer toEntity(CustomerRequest request) {
        return Customer.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .middleInit(request.getMiddleInit())
                .dateOfBirth(request.getDateOfBirth())
                .ssnLast4(request.getSsnLast4())
                .driversLicense(request.getDriversLicense())
                .dlState(request.getDlState())
                .addressLine1(request.getAddressLine1())
                .addressLine2(request.getAddressLine2())
                .city(request.getCity())
                .stateCode(request.getStateCode())
                .zipCode(request.getZipCode())
                .homePhone(request.getHomePhone())
                .cellPhone(request.getCellPhone())
                .email(request.getEmail())
                .employerName(request.getEmployerName())
                .annualIncome(request.getAnnualIncome())
                .customerType(request.getCustomerType())
                .sourceCode(request.getSourceCode())
                .dealerCode(request.getDealerCode())
                .assignedSales(request.getAssignedSales())
                .build();
    }
}
