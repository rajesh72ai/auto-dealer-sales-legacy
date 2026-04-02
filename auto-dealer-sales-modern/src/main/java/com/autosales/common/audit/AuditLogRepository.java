package com.autosales.common.audit;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface AuditLogRepository extends JpaRepository<AuditLog, Integer> {

    @Query("SELECT a FROM AuditLog a WHERE " +
            "(:userId IS NULL OR a.userId = :userId) AND " +
            "(:tableName IS NULL OR a.tableName = :tableName) AND " +
            "(:actionType IS NULL OR a.actionType = :actionType) AND " +
            "(CAST(:from AS timestamp) IS NULL OR a.auditTs >= :from) AND " +
            "(CAST(:to AS timestamp) IS NULL OR a.auditTs <= :to)")
    Page<AuditLog> search(
            @Param("userId") String userId,
            @Param("tableName") String tableName,
            @Param("actionType") String actionType,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query("SELECT a.actionType, COUNT(a) FROM AuditLog a GROUP BY a.actionType")
    List<Object[]> countByActionType();
}
