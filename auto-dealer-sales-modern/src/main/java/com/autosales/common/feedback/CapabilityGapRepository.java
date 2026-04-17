package com.autosales.common.feedback;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CapabilityGapRepository extends JpaRepository<CapabilityGapLog, Long> {

    Page<CapabilityGapLog> findByStatusOrderByCreatedTsDesc(String status, Pageable pageable);

    Page<CapabilityGapLog> findAllByOrderByCreatedTsDesc(Pageable pageable);

    @Query("""
            SELECT g.requestedCapability AS capability, g.category AS category,
                   g.appId AS appId,
                   COUNT(g) AS requestCount, MAX(g.createdTs) AS lastRequested
            FROM CapabilityGapLog g
            WHERE g.status IN ('NEW', 'REVIEWED')
            GROUP BY g.requestedCapability, g.category, g.appId
            ORDER BY COUNT(g) DESC
            """)
    List<CapabilityGapSummary> findGapSummary();

    long countByStatus(String status);
}
