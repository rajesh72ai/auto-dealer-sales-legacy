package com.autosales.modules.agent;

import com.autosales.modules.agent.entity.AgentConversation;
import com.autosales.modules.agent.entity.AgentMessageEntity;
import com.autosales.modules.agent.repository.AgentConversationRepository;
import com.autosales.modules.agent.repository.AgentMessageRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for AI Agent conversations. Server-side history lets the frontend
 * send only the current turn; the server reconstructs the full context for the
 * LLM and saves each turn for audit + cost analysis.
 */
@Service
@Transactional
public class AgentConversationService {

    // Cap how many prior turns we replay to the LLM. Older turns are kept in
    // the DB for audit but dropped from context to bound token growth.
    private static final int MAX_REPLAY_TURNS = 20;

    private final AgentConversationRepository conversationRepo;
    private final AgentMessageRepository messageRepo;

    public AgentConversationService(AgentConversationRepository conversationRepo,
                                    AgentMessageRepository messageRepo) {
        this.conversationRepo = conversationRepo;
        this.messageRepo = messageRepo;
    }

    public AgentConversation create(String userId, String dealerCode, String model, String firstUserMessage) {
        String id = UUID.randomUUID().toString();
        AgentConversation conv = AgentConversation.builder()
                .conversationId(id)
                .userId(userId)
                .dealerCode(dealerCode)
                .model(model)
                .title(deriveTitle(firstUserMessage))
                .turnCount(0)
                .tokenTotal(0)
                .build();
        return conversationRepo.save(conv);
    }

    @Transactional(readOnly = true)
    public Optional<AgentConversation> findById(String conversationId) {
        return conversationRepo.findById(conversationId);
    }

    @Transactional(readOnly = true)
    public List<AgentConversation> listForUser(String userId) {
        return conversationRepo.findByUserIdOrderByUpdatedTsDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> loadReplayMessages(String conversationId) {
        List<AgentMessageEntity> all = messageRepo.findByConversationIdOrderBySeqAsc(conversationId);
        int start = Math.max(0, all.size() - MAX_REPLAY_TURNS);
        List<Map<String, Object>> out = new ArrayList<>();
        for (int i = start; i < all.size(); i++) {
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("role", all.get(i).getRole());
            entry.put("content", all.get(i).getContent());
            out.add(entry);
        }
        return out;
    }

    public void appendTurn(String conversationId, String userMessage, String assistantMessage, int tokensUsed) {
        appendTurn(conversationId, userMessage, assistantMessage, tokensUsed, null, null);
    }

    public void appendTurn(String conversationId,
                           String userMessage,
                           String assistantMessage,
                           int tokensUsed,
                           Integer promptTokens,
                           Integer completionTokens) {
        AgentConversation conv = conversationRepo.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("conversation not found: " + conversationId));

        int nextSeq = (int) messageRepo.countByConversationId(conversationId);

        AgentMessageEntity userRow = AgentMessageEntity.builder()
                .conversationId(conversationId)
                .role("user")
                .content(userMessage)
                .seq(nextSeq)
                .build();
        messageRepo.save(userRow);

        AgentMessageEntity botRow = AgentMessageEntity.builder()
                .conversationId(conversationId)
                .role("assistant")
                .content(assistantMessage == null ? "" : assistantMessage)
                .seq(nextSeq + 1)
                .promptTokens(promptTokens)
                .completionTokens(completionTokens)
                .build();
        messageRepo.save(botRow);

        int effectiveTotal = tokensUsed > 0 ? tokensUsed
                : (promptTokens != null ? promptTokens : 0) + (completionTokens != null ? completionTokens : 0);

        conv.setTurnCount(conv.getTurnCount() + 1);
        conv.setTokenTotal(conv.getTokenTotal() + Math.max(0, effectiveTotal));
        conv.setUpdatedTs(LocalDateTime.now());
        // Refine title if still default and we now have content to summarize
        if (conv.getTitle() == null || conv.getTitle().isBlank()) {
            conv.setTitle(deriveTitle(userMessage));
        }
        conversationRepo.save(conv);
    }

    /**
     * Append a synthetic system note to the conversation — used by
     * {@link com.autosales.modules.agent.action.ActionService#confirm} to
     * inject the result of a just-executed write back into the agent's
     * memory (B-prereq follow-up).
     *
     * <p>Without this, after the user clicks Execute on a ProposalCard the
     * action commits to the DB but Gemini's conversation history never
     * sees the result. Subsequent turns fail to chain compound actions
     * because the model "doesn't know" what just happened.
     *
     * <p>The note is stored with role={@code system} so any LLM that replays
     * the conversation reads it as authoritative ground truth, distinct
     * from user / assistant turns.
     */
    public void appendSystemNote(String conversationId, String note) {
        AgentConversation conv = conversationRepo.findById(conversationId).orElse(null);
        if (conv == null) return;
        int nextSeq = (int) messageRepo.countByConversationId(conversationId);
        AgentMessageEntity row = AgentMessageEntity.builder()
                .conversationId(conversationId)
                .role("system")
                .content(note)
                .seq(nextSeq)
                .build();
        messageRepo.save(row);
        conv.setUpdatedTs(LocalDateTime.now());
        conversationRepo.save(conv);
    }

    public void delete(String conversationId) {
        messageRepo.deleteByConversationId(conversationId);
        conversationRepo.deleteById(conversationId);
    }

    private String deriveTitle(String firstUserMessage) {
        if (firstUserMessage == null) return "New conversation";
        String trimmed = firstUserMessage.trim().replaceAll("\\s+", " ");
        if (trimmed.length() <= 60) return trimmed;
        return trimmed.substring(0, 57) + "…";
    }
}
