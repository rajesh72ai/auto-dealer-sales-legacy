package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.entity.AgentActionProposal;
import com.autosales.modules.agent.action.repository.AgentActionProposalRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ConfirmationTokenService {

    private final AgentActionProposalRepository repo;
    private final ObjectMapper mapper;

    @Value("${agent.action.token-ttl-seconds:300}")
    private long ttlSeconds;

    @Transactional
    public AgentActionProposal create(String userId, String dealerCode, String conversationId,
                                      String toolName, String tier,
                                      Object payload, Object preview) {
        String payloadJson = toJson(payload);
        String previewJson = toJson(preview);
        String token = UUID.randomUUID().toString();
        LocalDateTime now = LocalDateTime.now();
        AgentActionProposal p = AgentActionProposal.builder()
                .token(token)
                .userId(userId)
                .dealerCode(dealerCode)
                .conversationId(conversationId)
                .toolName(toolName)
                .tier(tier)
                .payloadJson(payloadJson)
                .payloadHash(hash(payloadJson))
                .previewJson(previewJson)
                .status(AgentActionProposal.Status.PENDING.name())
                .expiresAt(now.plusSeconds(ttlSeconds))
                .createdTs(now)
                .build();
        return repo.save(p);
    }

    @Transactional(readOnly = true)
    public AgentActionProposal validate(String token, String userId) {
        AgentActionProposal p = repo.findByToken(token)
                .orElseThrow(() -> new IllegalArgumentException("Unknown proposal token"));
        if (!p.getUserId().equals(userId)) {
            throw new SecurityException("Proposal token belongs to a different user");
        }
        if (!AgentActionProposal.Status.PENDING.name().equals(p.getStatus())) {
            throw new IllegalStateException("Proposal is no longer pending: " + p.getStatus());
        }
        if (p.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("Proposal token has expired");
        }
        return p;
    }

    @Transactional
    public AgentActionProposal markConfirmed(String token, Long executionAuditId) {
        AgentActionProposal p = repo.findByToken(token)
                .orElseThrow(() -> new IllegalArgumentException("Unknown proposal token"));
        p.setStatus(AgentActionProposal.Status.CONFIRMED.name());
        p.setDecidedAt(LocalDateTime.now());
        p.setExecutionAuditId(executionAuditId);
        return repo.save(p);
    }

    @Transactional
    public AgentActionProposal markRejected(String token, String userId) {
        AgentActionProposal p = repo.findByToken(token)
                .orElseThrow(() -> new IllegalArgumentException("Unknown proposal token"));
        if (!p.getUserId().equals(userId)) {
            throw new SecurityException("Proposal token belongs to a different user");
        }
        p.setStatus(AgentActionProposal.Status.REJECTED.name());
        p.setDecidedAt(LocalDateTime.now());
        return repo.save(p);
    }

    @Transactional
    public int expireStale() {
        return repo.expirePending(LocalDateTime.now());
    }

    /**
     * Conversation-scoped variant of {@link #expireStale()}. Returns the proposals
     * just transitioned to EXPIRED so the caller can build a per-conversation
     * cancellation signal (e.g. a system note for the LLM's next replay).
     */
    @Transactional
    public List<AgentActionProposal> expireStaleForConversation(String conversationId) {
        if (conversationId == null || conversationId.isBlank()) return List.of();
        LocalDateTime now = LocalDateTime.now();
        List<AgentActionProposal> stale = repo.findExpiredPendingForConversation(conversationId, now);
        for (AgentActionProposal p : stale) {
            p.setStatus(AgentActionProposal.Status.EXPIRED.name());
            p.setDecidedAt(now);
            repo.save(p);
        }
        return stale;
    }

    private String toJson(Object o) {
        if (o == null) return "{}";
        try {
            return mapper.writeValueAsString(o);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize action payload/preview", e);
        }
    }

    static String hash(String payloadJson) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(payloadJson.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }
}
