package com.autosales.modules.customer.repository;

import com.autosales.modules.customer.entity.CustomerLead;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CustomerLeadRepository extends JpaRepository<CustomerLead, Integer> {

    List<CustomerLead> findByCustomer_CustomerId(Integer customerId);

    List<CustomerLead> findByDealerCodeAndLeadStatus(String dealerCode, String leadStatus);

    List<CustomerLead> findByAssignedSales(String assignedSales);

    Page<CustomerLead> findByDealerCode(String dealerCode, Pageable pageable);

    Page<CustomerLead> findByDealerCodeAndLeadStatus(String dealerCode, String status, Pageable pageable);

    Page<CustomerLead> findByDealerCodeAndAssignedSales(String dealerCode, String assignedSales, Pageable pageable);
}
