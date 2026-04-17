package com.autosales.modules.agent.action.repository;

import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AgentToolCallAuditRepository extends JpaRepository<AgentToolCallAudit, Long> {

    List<AgentToolCallAudit> findByProposalToken(String proposalToken);

    Page<AgentToolCallAudit> findByUserIdOrderByCreatedTsDesc(String userId, Pageable pageable);

    Page<AgentToolCallAudit> findByConversationIdOrderByCreatedTsAsc(String conversationId, Pageable pageable);
}
