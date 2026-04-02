package com.autosales.modules.registration.repository;

import com.autosales.modules.registration.entity.Warranty;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WarrantyRepository extends JpaRepository<Warranty, Integer> {

    List<Warranty> findByVin(String vin);

    List<Warranty> findByDealNumber(String dealNumber);

    List<Warranty> findByVinAndActiveFlag(String vin, String activeFlag);

    boolean existsByVinAndDealNumber(String vin, String dealNumber);
}
