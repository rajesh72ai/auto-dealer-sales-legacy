package com.autosales.modules.registration.repository;

import com.autosales.modules.registration.entity.Registration;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RegistrationRepository extends JpaRepository<Registration, String> {

    Optional<Registration> findByDealNumber(String dealNumber);

    List<Registration> findByVin(String vin);

    List<Registration> findByCustomerId(Integer customerId);

    Page<Registration> findByRegStatus(String regStatus, Pageable pageable);

    Page<Registration> findByRegState(String regState, Pageable pageable);

    boolean existsByDealNumber(String dealNumber);
}
