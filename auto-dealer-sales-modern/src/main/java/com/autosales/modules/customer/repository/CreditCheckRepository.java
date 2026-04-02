package com.autosales.modules.customer.repository;

import com.autosales.modules.customer.entity.CreditCheck;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface CreditCheckRepository extends JpaRepository<CreditCheck, Integer> {

    List<CreditCheck> findByCustomer_CustomerId(Integer customerId);

    List<CreditCheck> findByCustomer_CustomerIdAndStatus(Integer customerId, String status);

    List<CreditCheck> findByCustomer_CustomerIdOrderByRequestTsDesc(Integer customerId);

    Optional<CreditCheck> findFirstByCustomer_CustomerIdAndStatusAndExpiryDateGreaterThanEqual(
            Integer customerId, String status, LocalDate date);
}
