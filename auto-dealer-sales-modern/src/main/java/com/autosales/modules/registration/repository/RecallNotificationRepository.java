package com.autosales.modules.registration.repository;

import com.autosales.modules.registration.entity.RecallNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecallNotificationRepository extends JpaRepository<RecallNotification, Integer> {

    List<RecallNotification> findByRecallId(String recallId);

    List<RecallNotification> findByVin(String vin);

    boolean existsByRecallIdAndVin(String recallId, String vin);
}
