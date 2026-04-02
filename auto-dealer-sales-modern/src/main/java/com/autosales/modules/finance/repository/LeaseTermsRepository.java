package com.autosales.modules.finance.repository;

import com.autosales.modules.finance.entity.LeaseTerms;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface LeaseTermsRepository extends JpaRepository<LeaseTerms, String> {

    Optional<LeaseTerms> findByFinanceId(String financeId);
}
