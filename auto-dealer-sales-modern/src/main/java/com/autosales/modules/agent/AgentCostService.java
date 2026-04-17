package com.autosales.modules.agent;

import com.autosales.modules.agent.entity.AgentConversation;
import com.autosales.modules.agent.entity.AgentMessageEntity;
import com.autosales.modules.agent.repository.AgentConversationRepository;
import com.autosales.modules.agent.repository.AgentMessageRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Aggregates real per-turn token usage into cost rollups.
 *
 * <p>Assistant rows on {@code agent_message} carry {@code prompt_tokens} and
 * {@code completion_tokens} from V44 onward. Older rows (pre-V44) have null
 * token columns — their cost is estimated from {@code agent_conversation.token_total}
 * at a blended rate, and flagged via {@code estimatedFraction}.</p>
 */
@Service
public class AgentCostService {

    private final AgentConversationRepository conversationRepo;
    private final AgentMessageRepository messageRepo;
    private final BigDecimal inputPerMillion;
    private final BigDecimal outputPerMillion;
    private final String currency;

    public AgentCostService(AgentConversationRepository conversationRepo,
                            AgentMessageRepository messageRepo,
                            @Value("${agent.pricing.input-per-million:3.00}") BigDecimal inputPerMillion,
                            @Value("${agent.pricing.output-per-million:15.00}") BigDecimal outputPerMillion,
                            @Value("${agent.pricing.currency:USD}") String currency) {
        this.conversationRepo = conversationRepo;
        this.messageRepo = messageRepo;
        this.inputPerMillion = inputPerMillion;
        this.outputPerMillion = outputPerMillion;
        this.currency = currency;
    }

    public record TurnCost(int promptTokens, int completionTokens, int totalTokens,
                           BigDecimal inputCost, BigDecimal outputCost, BigDecimal totalCost,
                           String currency) {}

    /** Compute cost for a single turn's token usage. */
    public TurnCost computeTurn(int promptTokens, int completionTokens) {
        BigDecimal inputCost = BigDecimal.valueOf(promptTokens)
                .multiply(inputPerMillion)
                .divide(BigDecimal.valueOf(1_000_000), 6, RoundingMode.HALF_UP);
        BigDecimal outputCost = BigDecimal.valueOf(completionTokens)
                .multiply(outputPerMillion)
                .divide(BigDecimal.valueOf(1_000_000), 6, RoundingMode.HALF_UP);
        return new TurnCost(
                promptTokens, completionTokens, promptTokens + completionTokens,
                inputCost.setScale(4, RoundingMode.HALF_UP),
                outputCost.setScale(4, RoundingMode.HALF_UP),
                inputCost.add(outputCost).setScale(4, RoundingMode.HALF_UP),
                currency);
    }

    public Map<String, Object> summary(String userId, LocalDate from, LocalDate to) {
        LocalDateTime fromTs = from.atStartOfDay();
        LocalDateTime toTs = to.plusDays(1).atStartOfDay();

        List<AgentConversation> conversations = userId == null || userId.isBlank()
                ? conversationRepo.findAll()
                : conversationRepo.findByUserIdOrderByUpdatedTsDesc(userId);

        long promptTokens = 0;
        long completionTokens = 0;
        long totalTokensAccounted = 0;
        long totalTokensFromConvo = 0;
        int turnsWithUsage = 0;
        int turnsWithoutUsage = 0;
        int conversationCount = 0;

        for (AgentConversation c : conversations) {
            if (c.getUpdatedTs() == null) continue;
            if (c.getUpdatedTs().isBefore(fromTs) || !c.getUpdatedTs().isBefore(toTs)) continue;
            conversationCount++;
            totalTokensFromConvo += c.getTokenTotal() == null ? 0 : c.getTokenTotal();

            List<AgentMessageEntity> msgs = messageRepo.findByConversationIdOrderBySeqAsc(c.getConversationId());
            for (AgentMessageEntity m : msgs) {
                if (!"assistant".equals(m.getRole())) continue;
                if (m.getPromptTokens() != null || m.getCompletionTokens() != null) {
                    int pt = m.getPromptTokens() == null ? 0 : m.getPromptTokens();
                    int ct = m.getCompletionTokens() == null ? 0 : m.getCompletionTokens();
                    promptTokens += pt;
                    completionTokens += ct;
                    totalTokensAccounted += pt + ct;
                    turnsWithUsage++;
                } else {
                    turnsWithoutUsage++;
                }
            }
        }

        // For turns without per-column data, estimate at a blended rate using
        // the conversation-level rollup residual: (conv total) − (accounted).
        long residualTokens = Math.max(0, totalTokensFromConvo - totalTokensAccounted);
        BigDecimal blendedPerMillion = inputPerMillion.add(outputPerMillion).divide(BigDecimal.valueOf(2));
        BigDecimal residualCost = BigDecimal.valueOf(residualTokens)
                .multiply(blendedPerMillion)
                .divide(BigDecimal.valueOf(1_000_000), 4, RoundingMode.HALF_UP);

        BigDecimal inputCost = BigDecimal.valueOf(promptTokens)
                .multiply(inputPerMillion)
                .divide(BigDecimal.valueOf(1_000_000), 4, RoundingMode.HALF_UP);
        BigDecimal outputCost = BigDecimal.valueOf(completionTokens)
                .multiply(outputPerMillion)
                .divide(BigDecimal.valueOf(1_000_000), 4, RoundingMode.HALF_UP);
        BigDecimal totalCost = inputCost.add(outputCost).add(residualCost);

        Map<String, Object> tokens = new LinkedHashMap<>();
        tokens.put("input", promptTokens);
        tokens.put("output", completionTokens);
        tokens.put("accountedTotal", totalTokensAccounted);
        tokens.put("residual", residualTokens);
        tokens.put("grandTotal", totalTokensAccounted + residualTokens);

        Map<String, Object> cost = new LinkedHashMap<>();
        cost.put("input", inputCost);
        cost.put("output", outputCost);
        cost.put("residualEstimated", residualCost);
        cost.put("total", totalCost);
        cost.put("currency", currency);

        Map<String, Object> pricing = new LinkedHashMap<>();
        pricing.put("inputPerMillion", inputPerMillion);
        pricing.put("outputPerMillion", outputPerMillion);
        pricing.put("currency", currency);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("userId", userId);
        out.put("from", from.toString());
        out.put("to", to.toString());
        out.put("conversations", conversationCount);
        out.put("turns", turnsWithUsage + turnsWithoutUsage);
        out.put("turnsWithExactUsage", turnsWithUsage);
        out.put("turnsEstimated", turnsWithoutUsage);
        out.put("estimatedFraction", (turnsWithUsage + turnsWithoutUsage) == 0
                ? 0.0
                : (double) turnsWithoutUsage / (turnsWithUsage + turnsWithoutUsage));
        out.put("tokens", tokens);
        out.put("cost", cost);
        out.put("pricing", pricing);
        return out;
    }
}
