package com.autosales.modules.agent;

import com.autosales.modules.agent.repository.AgentConversationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
public class TokenQuotaService {

    private static final Logger log = LoggerFactory.getLogger(TokenQuotaService.class);

    private final AgentConversationRepository conversationRepo;
    private final long dailyQuota;

    public TokenQuotaService(AgentConversationRepository conversationRepo,
                             @Value("${agent.daily-token-quota-per-user:0}") long dailyQuota) {
        this.conversationRepo = conversationRepo;
        this.dailyQuota = dailyQuota;
    }

    public boolean isEnabled() {
        return dailyQuota > 0;
    }

    public long dailyQuota() {
        return dailyQuota;
    }

    public long usedToday(String userId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        return conversationRepo.sumTokensForUserSince(userId, startOfDay);
    }

    public QuotaCheck check(String userId) {
        if (!isEnabled()) return new QuotaCheck(true, 0, 0);
        long used = usedToday(userId);
        boolean ok = used < dailyQuota;
        if (!ok) {
            log.warn("Agent quota exceeded for user {}: used={} quota={}", userId, used, dailyQuota);
        }
        return new QuotaCheck(ok, used, dailyQuota);
    }

    public record QuotaCheck(boolean allowed, long used, long quota) {
        public String friendlyRejection() {
            return String.format(
                    "You have reached today's AI Agent token limit (%d / %d). " +
                    "The quota resets at midnight. Please try again tomorrow or contact your admin.",
                    used, quota);
        }
    }
}
