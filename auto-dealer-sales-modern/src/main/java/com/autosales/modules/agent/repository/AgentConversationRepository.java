package com.autosales.modules.agent.repository;

import com.autosales.modules.agent.entity.AgentConversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AgentConversationRepository extends JpaRepository<AgentConversation, String> {
    List<AgentConversation> findByUserIdOrderByUpdatedTsDesc(String userId);

    @Query("SELECT COALESCE(SUM(c.tokenTotal), 0) FROM AgentConversation c " +
           "WHERE c.userId = :userId AND c.updatedTs >= :since")
    long sumTokensForUserSince(@Param("userId") String userId, @Param("since") LocalDateTime since);
}
