package com.autosales.modules.registration.repository;

import com.autosales.modules.registration.entity.RecallCampaign;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecallCampaignRepository extends JpaRepository<RecallCampaign, String> {

    Page<RecallCampaign> findByCampaignStatus(String campaignStatus, Pageable pageable);

    List<RecallCampaign> findBySeverity(String severity);
}
