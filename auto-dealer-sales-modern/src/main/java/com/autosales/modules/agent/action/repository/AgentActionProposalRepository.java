package com.autosales.modules.agent.action.repository;

import com.autosales.modules.agent.action.entity.AgentActionProposal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface AgentActionProposalRepository extends JpaRepository<AgentActionProposal, String> {

    Optional<AgentActionProposal> findByToken(String token);

    List<AgentActionProposal> findByUserIdAndStatusOrderByCreatedTsDesc(String userId, String status);

    @Query("SELECT p FROM AgentActionProposal p " +
           "WHERE p.conversationId = :conversationId AND p.status = 'PENDING' " +
           "AND p.expiresAt < :now ORDER BY p.createdTs ASC")
    List<AgentActionProposal> findExpiredPendingForConversation(@Param("conversationId") String conversationId,
                                                                @Param("now") LocalDateTime now);

    @Modifying
    @Query("UPDATE AgentActionProposal p SET p.status = 'EXPIRED' " +
           "WHERE p.status = 'PENDING' AND p.expiresAt < :now")
    int expirePending(@Param("now") LocalDateTime now);
}
