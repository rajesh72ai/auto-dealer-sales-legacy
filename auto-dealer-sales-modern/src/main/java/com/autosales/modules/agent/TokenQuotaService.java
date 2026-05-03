package com.autosales.modules.agent;

import com.autosales.common.security.SystemUser;
import com.autosales.common.security.SystemUserRepository;
import com.autosales.modules.agent.repository.AgentConversationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Enforces daily token quota for the AI agent. Resolution order per user:
 *
 * <ol>
 *   <li>If the user's {@code agent_enabled = false}, the agent is disabled
 *       for them entirely — return a {@link QuotaCheck#disabled disabled}
 *       result with a distinct rejection message ("Agent access is disabled
 *       for your account…"). No tokens consumed.</li>
 *   <li>If {@code agent_daily_token_quota} is non-null, use that as the cap
 *       (per-user override).</li>
 *   <li>Otherwise fall through to the global default
 *       {@code agent.daily-token-quota-per-user} from config.</li>
 * </ol>
 *
 * <p>This was originally a single global quota; the per-user policy + admin
 * UI was added (B-tokenadmin, 2026-05-03) to support varying quotas per
 * role/contractor and to allow disabling the agent for specific accounts.
 */
@Service
public class TokenQuotaService {

    private static final Logger log = LoggerFactory.getLogger(TokenQuotaService.class);

    private final AgentConversationRepository conversationRepo;
    private final SystemUserRepository userRepo;
    private final long defaultDailyQuota;

    public TokenQuotaService(AgentConversationRepository conversationRepo,
                             SystemUserRepository userRepo,
                             @Value("${agent.daily-token-quota-per-user:0}") long defaultDailyQuota) {
        this.conversationRepo = conversationRepo;
        this.userRepo = userRepo;
        this.defaultDailyQuota = defaultDailyQuota;
    }

    public boolean isEnabled() {
        return defaultDailyQuota > 0;
    }

    public long defaultDailyQuota() {
        return defaultDailyQuota;
    }

    /**
     * Backwards-compatibility alias for the global default quota — pre-dates
     * the per-user-override resolution added in B-tokenadmin. Kept so
     * existing callers (e.g., AgentUsageService) don't need to change.
     */
    public long dailyQuota() {
        return defaultDailyQuota;
    }

    public long usedToday(String userId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        return conversationRepo.sumTokensForUserSince(userId, startOfDay);
    }

    public QuotaCheck check(String userId) {
        if (!isEnabled()) return new QuotaCheck(true, 0, 0, false);

        Optional<SystemUser> userOpt = userRepo.findByUserId(userId);

        // 1. Per-user disable — short-circuit, no quota consumed.
        if (userOpt.isPresent()) {
            SystemUser u = userOpt.get();
            if (Boolean.FALSE.equals(u.getAgentEnabled())) {
                log.info("Agent disabled for user {} (per agent_enabled=false)", userId);
                return new QuotaCheck(false, 0, 0, true);
            }
        }

        // 2. Resolve effective quota: per-user override > global default.
        long effectiveQuota = userOpt
                .map(SystemUser::getAgentDailyTokenQuota)
                .filter(q -> q != null)
                .map(Integer::longValue)
                .orElse(defaultDailyQuota);

        long used = usedToday(userId);
        boolean ok = used < effectiveQuota;
        if (!ok) {
            log.warn("Agent quota exceeded for user {}: used={} quota={} (override={})",
                    userId, used, effectiveQuota, effectiveQuota != defaultDailyQuota);
        }
        return new QuotaCheck(ok, used, effectiveQuota, false);
    }

    public record QuotaCheck(boolean allowed, long used, long quota, boolean disabled) {
        public String friendlyRejection() {
            if (disabled) {
                return "AI Agent access is disabled for your account. Please contact your administrator if you need access.";
            }
            return String.format(
                    "You have reached today's AI Agent token limit (%d / %d). " +
                    "The quota resets at midnight. Please try again tomorrow or contact your admin.",
                    used, quota);
        }
    }
}
