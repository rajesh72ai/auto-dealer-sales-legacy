package com.autosales.modules.agent.usage;

import com.autosales.modules.agent.TokenQuotaService;
import com.autosales.modules.agent.entity.AgentConversation;
import com.autosales.modules.agent.repository.AgentConversationRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.*;

/**
 * Combines Anthropic admin-API actuals (real $) with local DB metrics
 * (conversations, turns, active users) into a single admin rollup. The admin
 * actuals are org-wide and hourly-at-best granularity; local metrics fill in
 * the "who's using it" story that the actuals can't tell.
 */
@Service
@RequiredArgsConstructor
public class AgentUsageService {

    private static final Logger log = LoggerFactory.getLogger(AgentUsageService.class);

    private final AnthropicAdminClient adminClient;
    private final TokenQuotaService quotaService;
    private final AgentConversationRepository conversationRepo;

    @Value("${agent.pricing.input-per-million:3.00}")          private BigDecimal inputPerMillion;
    @Value("${agent.pricing.output-per-million:15.00}")        private BigDecimal outputPerMillion;
    @Value("${agent.pricing.cache-read-per-million:0.30}")     private BigDecimal cacheReadPerMillion;
    @Value("${agent.pricing.cache-write-5m-per-million:3.75}") private BigDecimal cacheWrite5mPerMillion;
    @Value("${agent.pricing.cache-write-1h-per-million:6.00}") private BigDecimal cacheWrite1hPerMillion;
    @Value("${agent.pricing.currency:USD}")                    private String currency;

    public boolean actualsAvailable() {
        return adminClient.isConfigured();
    }

    /**
     * Per-user quota view — fast, local-only, accurate. Uses the same counter
     * {@link TokenQuotaService} enforces on every turn, so the progress bar
     * matches the backend's refusal threshold exactly.
     */
    public Map<String, Object> quotaFor(String userId) {
        long quota = quotaService.dailyQuota();
        long used = quotaService.isEnabled() ? quotaService.usedToday(userId) : 0L;
        double pct = quota > 0 ? Math.min(1.0, (double) used / quota) : 0.0;
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("userId", userId);
        m.put("used", used);
        m.put("quota", quota);
        m.put("enabled", quotaService.isEnabled());
        m.put("percentage", Math.round(pct * 1000.0) / 10.0);
        m.put("remaining", Math.max(0L, quota - used));
        return m;
    }

    /**
     * Admin rollup for the range [from, to] inclusive at daily granularity.
     *
     * <p>If Anthropic admin key is not configured, actual-cost fields come back
     * empty and the page falls back to local-only estimates.</p>
     */
    public Map<String, Object> adminSummary(LocalDate from, LocalDate to) {
        if (to.isBefore(from)) throw new IllegalArgumentException("to must be on or after from");
        Instant startingAt = from.atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant endingAt = to.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC);

        List<DailyBucket> buckets = buildLocalDailyBuckets(from, to);

        boolean haveActuals = adminClient.isConfigured();
        String actualsError = null;
        if (haveActuals) {
            try {
                AnthropicAdminClient.MessagesUsageReport report =
                        adminClient.fetchMessagesUsage(startingAt, endingAt, "1d", List.of("model"));
                mergeActuals(buckets, report);
            } catch (Exception e) {
                log.warn("Anthropic admin API unavailable, returning local-only: {}", e.getMessage());
                actualsError = e.getMessage();
                haveActuals = false;
            }
        }

        Totals totals = sumTotals(buckets);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("from", from.toString());
        out.put("to", to.toString());
        out.put("actualsAvailable", haveActuals);
        if (actualsError != null) out.put("actualsError", actualsError);
        out.put("currency", currency);
        out.put("buckets", buckets);
        out.put("totals", totals);
        out.put("pricing", Map.of(
                "inputPerMillion", inputPerMillion,
                "outputPerMillion", outputPerMillion,
                "cacheReadPerMillion", cacheReadPerMillion,
                "cacheWrite5mPerMillion", cacheWrite5mPerMillion,
                "cacheWrite1hPerMillion", cacheWrite1hPerMillion
        ));
        return out;
    }

    // -- internal -------------------------------------------------------

    private List<DailyBucket> buildLocalDailyBuckets(LocalDate from, LocalDate to) {
        LocalDateTime fromTs = from.atStartOfDay();
        LocalDateTime toTs = to.plusDays(1).atStartOfDay();
        List<AgentConversation> allConvos = conversationRepo.findAll();

        Map<LocalDate, DailyBucket> byDay = new TreeMap<>();
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
            byDay.put(d, emptyBucket(d));
        }

        for (AgentConversation c : allConvos) {
            if (c.getUpdatedTs() == null) continue;
            if (c.getUpdatedTs().isBefore(fromTs) || !c.getUpdatedTs().isBefore(toTs)) continue;
            LocalDate day = c.getUpdatedTs().toLocalDate();
            DailyBucket b = byDay.get(day);
            if (b == null) continue;
            b.conversations++;
            b.turns += c.getTurnCount() == null ? 0 : c.getTurnCount();
            b.estimatedTokens += c.getTokenTotal() == null ? 0 : c.getTokenTotal();
            if (c.getUserId() != null) b.activeUsers.add(c.getUserId());
            if (c.getDealerCode() != null) b.activeDealers.add(c.getDealerCode());
        }

        return new ArrayList<>(byDay.values());
    }

    private DailyBucket emptyBucket(LocalDate day) {
        DailyBucket b = new DailyBucket();
        b.date = day.toString();
        b.activeUsers = new HashSet<>();
        b.activeDealers = new HashSet<>();
        return b;
    }

    private void mergeActuals(List<DailyBucket> buckets, AnthropicAdminClient.MessagesUsageReport report) {
        if (report == null || report.data() == null) return;
        Map<String, DailyBucket> byDate = new HashMap<>();
        for (DailyBucket b : buckets) byDate.put(b.date, b);

        for (AnthropicAdminClient.MessagesUsageBucket bucket : report.data()) {
            if (bucket.startingAt() == null) continue;
            String day = bucket.startingAt().substring(0, 10); // YYYY-MM-DD
            DailyBucket b = byDate.get(day);
            if (b == null) continue;

            if (bucket.results() == null) continue;
            for (AnthropicAdminClient.MessagesUsageResult r : bucket.results()) {
                long uncached = r.uncachedInputTokens();
                long cacheRead = r.cacheReadInputTokens();
                long cacheWrite1h = r.cacheCreation() == null ? 0 : r.cacheCreation().ephemeral1hInputTokens();
                long cacheWrite5m = r.cacheCreation() == null ? 0 : r.cacheCreation().ephemeral5mInputTokens();
                long output = r.outputTokens();

                b.actualInputTokens += uncached;
                b.actualCacheReadTokens += cacheRead;
                b.actualCacheWrite5mTokens += cacheWrite5m;
                b.actualCacheWrite1hTokens += cacheWrite1h;
                b.actualOutputTokens += output;

                b.actualCost = b.actualCost.add(costFor(uncached, output, cacheRead, cacheWrite5m, cacheWrite1h));

                if (r.model() != null && !r.model().isBlank()) {
                    b.modelBreakdown.merge(r.model(),
                            uncached + cacheRead + cacheWrite5m + cacheWrite1h + output,
                            Long::sum);
                }
            }
        }
    }

    private BigDecimal costFor(long uncachedInput, long output, long cacheRead,
                               long cacheWrite5m, long cacheWrite1h) {
        BigDecimal sum = BigDecimal.ZERO;
        sum = sum.add(priceOf(uncachedInput, inputPerMillion));
        sum = sum.add(priceOf(output, outputPerMillion));
        sum = sum.add(priceOf(cacheRead, cacheReadPerMillion));
        sum = sum.add(priceOf(cacheWrite5m, cacheWrite5mPerMillion));
        sum = sum.add(priceOf(cacheWrite1h, cacheWrite1hPerMillion));
        return sum.setScale(4, RoundingMode.HALF_UP);
    }

    private BigDecimal priceOf(long tokens, BigDecimal perMillion) {
        if (tokens <= 0) return BigDecimal.ZERO;
        return BigDecimal.valueOf(tokens)
                .multiply(perMillion)
                .divide(BigDecimal.valueOf(1_000_000), 6, RoundingMode.HALF_UP);
    }

    private Totals sumTotals(List<DailyBucket> buckets) {
        Totals t = new Totals();
        Set<String> uniqueUsers = new HashSet<>();
        Set<String> uniqueDealers = new HashSet<>();
        for (DailyBucket b : buckets) {
            t.conversations += b.conversations;
            t.turns += b.turns;
            t.estimatedTokens += b.estimatedTokens;
            t.actualInputTokens += b.actualInputTokens;
            t.actualCacheReadTokens += b.actualCacheReadTokens;
            t.actualCacheWrite5mTokens += b.actualCacheWrite5mTokens;
            t.actualCacheWrite1hTokens += b.actualCacheWrite1hTokens;
            t.actualOutputTokens += b.actualOutputTokens;
            t.actualCost = t.actualCost.add(b.actualCost);
            uniqueUsers.addAll(b.activeUsers);
            uniqueDealers.addAll(b.activeDealers);
        }
        t.uniqueActiveUsers = uniqueUsers.size();
        t.uniqueActiveDealers = uniqueDealers.size();
        return t;
    }

    // -- DTOs used in JSON response -------------------------------------

    public static class DailyBucket {
        public String date;                        // YYYY-MM-DD
        public int conversations;
        public int turns;
        public long estimatedTokens;               // from agent_conversation.token_total (our rough per-turn estimate)
        public long actualInputTokens;             // uncached input from Anthropic
        public long actualCacheReadTokens;
        public long actualCacheWrite5mTokens;
        public long actualCacheWrite1hTokens;
        public long actualOutputTokens;
        public BigDecimal actualCost = BigDecimal.ZERO;
        public Set<String> activeUsers;
        public Set<String> activeDealers;
        public Map<String, Long> modelBreakdown = new LinkedHashMap<>();
    }

    public static class Totals {
        public int conversations;
        public int turns;
        public long estimatedTokens;
        public long actualInputTokens;
        public long actualCacheReadTokens;
        public long actualCacheWrite5mTokens;
        public long actualCacheWrite1hTokens;
        public long actualOutputTokens;
        public BigDecimal actualCost = BigDecimal.ZERO;
        public int uniqueActiveUsers;
        public int uniqueActiveDealers;
    }
}
