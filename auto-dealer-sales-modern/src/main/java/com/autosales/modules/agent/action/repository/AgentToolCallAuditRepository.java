package com.autosales.modules.agent.action.repository;

import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface AgentToolCallAuditRepository extends JpaRepository<AgentToolCallAudit, Long> {

    List<AgentToolCallAudit> findByProposalToken(String proposalToken);

    Page<AgentToolCallAudit> findByUserIdOrderByCreatedTsDesc(String userId, Pageable pageable);

    Page<AgentToolCallAudit> findByConversationIdOrderByCreatedTsAsc(String conversationId, Pageable pageable);

    /**
     * Recent conversations with at least one audit row, newest activity first.
     * Used by the admin trace UI to populate a "pick a conversation" list.
     */
    @Query(value = """
            SELECT conversation_id              AS conversationId,
                   MAX(created_ts)              AS lastActivityTs,
                   COUNT(*)                     AS rowCount,
                   MAX(user_id)                 AS userId,
                   MAX(dealer_code)             AS dealerCode
              FROM agent_tool_call_audit
             WHERE conversation_id IS NOT NULL
             GROUP BY conversation_id
             ORDER BY MAX(created_ts) DESC
             LIMIT :limit
            """, nativeQuery = true)
    List<RecentConversationView> findRecentConversations(@Param("limit") int limit);

    interface RecentConversationView {
        String getConversationId();
        java.sql.Timestamp getLastActivityTs();
        Long getRowCount();
        String getUserId();
        String getDealerCode();
    }
}
