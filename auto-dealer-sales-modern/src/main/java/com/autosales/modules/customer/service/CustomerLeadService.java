package com.autosales.modules.customer.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.customer.dto.LeadRequest;
import com.autosales.modules.customer.dto.LeadResponse;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.entity.CustomerLead;
import com.autosales.modules.customer.repository.CustomerLeadRepository;
import com.autosales.modules.customer.repository.CustomerRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

/**
 * Service for customer lead management.
 * Port of CUSTLEAD0.cbl — customer lead tracking transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class CustomerLeadService {

    private static final Set<String> CLOSED_STATUSES = Set.of("WN", "LS", "DD");

    private final CustomerLeadRepository leadRepository;
    private final CustomerRepository customerRepository;
    private final ResponseFormatter responseFormatter;

    public CustomerLeadService(CustomerLeadRepository leadRepository,
                               CustomerRepository customerRepository,
                               ResponseFormatter responseFormatter) {
        this.leadRepository = leadRepository;
        this.customerRepository = customerRepository;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all leads for a dealer with optional filtering by status or salesperson.
     */
    public PaginatedResponse<LeadResponse> findAll(String dealerCode, String status,
                                                    String assignedSales, Pageable pageable) {
        log.debug("Finding leads - dealerCode={}, status={}, assignedSales={}", dealerCode, status, assignedSales);

        Page<CustomerLead> page;
        if (status != null && !status.isBlank()) {
            page = leadRepository.findByDealerCodeAndLeadStatus(dealerCode, status, pageable);
        } else if (assignedSales != null && !assignedSales.isBlank()) {
            page = leadRepository.findByDealerCodeAndAssignedSales(dealerCode, assignedSales, pageable);
        } else {
            page = leadRepository.findByDealerCode(dealerCode, pageable);
        }

        List<LeadResponse> content = page.getContent().stream()
                .map(this::toResponse)
                .toList();

        return responseFormatter.paginated(content, page.getNumber(), page.getTotalPages(), page.getTotalElements());
    }

    /**
     * Find a single lead by ID.
     */
    public LeadResponse findById(Integer leadId) {
        log.debug("Finding lead by id={}", leadId);
        CustomerLead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new EntityNotFoundException("CustomerLead", String.valueOf(leadId)));
        return toResponse(lead);
    }

    /**
     * Create a new lead record.
     */
    @Transactional
    @Auditable(action = "INS", entity = "customer_lead", keyExpression = "#result.leadId")
    public LeadResponse create(LeadRequest request) {
        log.info("Creating lead for customerId={}, dealerCode={}", request.getCustomerId(), request.getDealerCode());

        // Validate customer exists
        Customer customer = customerRepository.findById(request.getCustomerId())
                .orElseThrow(() -> new EntityNotFoundException("Customer", String.valueOf(request.getCustomerId())));

        LocalDateTime now = LocalDateTime.now();
        CustomerLead entity = CustomerLead.builder()
                .customer(customer)
                .dealerCode(request.getDealerCode())
                .leadSource(request.getLeadSource())
                .interestModel(request.getInterestModel())
                .interestYear(request.getInterestYear())
                .leadStatus("NW")
                .assignedSales(request.getAssignedSales())
                .followUpDate(request.getFollowUpDate())
                .contactCount((short) 0)
                .notes(request.getNotes())
                .createdTs(now)
                .updatedTs(now)
                .build();

        CustomerLead saved = leadRepository.save(entity);
        log.info("Created lead id={}", saved.getLeadId());
        return toResponse(saved);
    }

    /**
     * Update the status of an existing lead.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "customer_lead", keyExpression = "#leadId")
    public LeadResponse updateStatus(Integer leadId, String newStatus) {
        log.info("Updating lead id={} to status={}", leadId, newStatus);

        CustomerLead existing = leadRepository.findById(leadId)
                .orElseThrow(() -> new EntityNotFoundException("CustomerLead", String.valueOf(leadId)));

        // Validate status transition: can't update closed leads
        if (CLOSED_STATUSES.contains(existing.getLeadStatus())) {
            throw new IllegalStateException(
                    "Cannot update lead in closed status: " + existing.getLeadStatus());
        }

        existing.setLeadStatus(newStatus);
        existing.setContactCount((short) (existing.getContactCount() + 1));
        existing.setLastContactDt(LocalDate.now());
        existing.setUpdatedTs(LocalDateTime.now());

        CustomerLead saved = leadRepository.save(existing);
        log.info("Updated lead id={} to status={}", saved.getLeadId(), newStatus);
        return toResponse(saved);
    }

    // --- Private helpers ---

    private LeadResponse toResponse(CustomerLead entity) {
        Customer customer = entity.getCustomer();
        String customerName = customer != null
                ? customer.getLastName() + ", " + customer.getFirstName()
                : "";

        // Determine if overdue: followUpDate < today and status not closed
        boolean overdue = false;
        if (entity.getFollowUpDate() != null
                && entity.getFollowUpDate().isBefore(LocalDate.now())
                && !CLOSED_STATUSES.contains(entity.getLeadStatus())) {
            overdue = true;
        }

        return LeadResponse.builder()
                .leadId(entity.getLeadId())
                .customerId(customer != null ? customer.getCustomerId() : null)
                .customerName(customerName)
                .dealerCode(entity.getDealerCode())
                .leadSource(entity.getLeadSource())
                .interestModel(entity.getInterestModel())
                .interestYear(entity.getInterestYear())
                .leadStatus(entity.getLeadStatus())
                .assignedSales(entity.getAssignedSales())
                .followUpDate(entity.getFollowUpDate())
                .lastContactDt(entity.getLastContactDt())
                .contactCount(entity.getContactCount())
                .notes(entity.getNotes())
                .createdTs(entity.getCreatedTs())
                .updatedTs(entity.getUpdatedTs())
                .overdue(overdue)
                .build();
    }
}
