package com.autosales.modules.agent.repository;

import com.autosales.modules.agent.entity.AgentMessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AgentMessageRepository extends JpaRepository<AgentMessageEntity, Long> {
    List<AgentMessageEntity> findByConversationIdOrderBySeqAsc(String conversationId);
    void deleteByConversationId(String conversationId);
    long countByConversationId(String conversationId);
}
