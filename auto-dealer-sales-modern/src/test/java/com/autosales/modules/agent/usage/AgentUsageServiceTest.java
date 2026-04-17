package com.autosales.modules.agent.usage;

import com.autosales.modules.agent.TokenQuotaService;
import com.autosales.modules.agent.entity.AgentConversation;
import com.autosales.modules.agent.repository.AgentConversationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgentUsageServiceTest {

    @Mock private AnthropicAdminClient adminClient;
    @Mock private TokenQuotaService quotaService;
    @Mock private AgentConversationRepository conversationRepo;
    @InjectMocks private AgentUsageService service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "inputPerMillion", new BigDecimal("3.00"));
        ReflectionTestUtils.setField(service, "outputPerMillion", new BigDecimal("15.00"));
        ReflectionTestUtils.setField(service, "cacheReadPerMillion", new BigDecimal("0.30"));
        ReflectionTestUtils.setField(service, "cacheWrite5mPerMillion", new BigDecimal("3.75"));
        ReflectionTestUtils.setField(service, "cacheWrite1hPerMillion", new BigDecimal("6.00"));
        ReflectionTestUtils.setField(service, "currency", "USD");
    }

    @Test
    void actualsAvailable_delegatesToClient() {
        when(adminClient.isConfigured()).thenReturn(true);
        assertTrue(service.actualsAvailable());
    }

    @Test
    void quotaFor_reportsUsedAndRemaining() {
        when(quotaService.isEnabled()).thenReturn(true);
        when(quotaService.dailyQuota()).thenReturn(200_000L);
        when(quotaService.usedToday("ADMIN001")).thenReturn(25_000L);

        Map<String, Object> out = service.quotaFor("ADMIN001");
        assertEquals("ADMIN001", out.get("userId"));
        assertEquals(25_000L, out.get("used"));
        assertEquals(200_000L, out.get("quota"));
        assertEquals(true, out.get("enabled"));
        assertEquals(12.5, (double) out.get("percentage"), 0.01);
        assertEquals(175_000L, out.get("remaining"));
    }

    @Test
    void quotaFor_clampsPercentageAt100WhenOverQuota() {
        when(quotaService.isEnabled()).thenReturn(true);
        when(quotaService.dailyQuota()).thenReturn(10_000L);
        when(quotaService.usedToday("U")).thenReturn(25_000L);

        Map<String, Object> out = service.quotaFor("U");
        assertEquals(100.0, (double) out.get("percentage"), 0.01);
        assertEquals(0L, out.get("remaining"));
    }

    @Test
    void quotaFor_returnsZeroWhenDisabled() {
        when(quotaService.isEnabled()).thenReturn(false);
        when(quotaService.dailyQuota()).thenReturn(0L);

        Map<String, Object> out = service.quotaFor("X");
        assertEquals(0L, out.get("used"));
        assertEquals(false, out.get("enabled"));
    }

    @Test
    void adminSummary_localOnlyWhenAdminNotConfigured() {
        when(adminClient.isConfigured()).thenReturn(false);
        when(conversationRepo.findAll()).thenReturn(List.of(
                convo("c1", "DLR01", "SALES001", 3, 1200,
                        LocalDate.of(2026, 4, 15).atTime(10, 0)),
                convo("c2", "DLR02", "MGR001",   5, 3500,
                        LocalDate.of(2026, 4, 16).atTime(14, 30))
        ));

        Map<String, Object> out = service.adminSummary(LocalDate.of(2026, 4, 15), LocalDate.of(2026, 4, 16));
        assertFalse((boolean) out.get("actualsAvailable"));
        assertEquals("USD", out.get("currency"));

        @SuppressWarnings("unchecked")
        List<AgentUsageService.DailyBucket> buckets =
                (List<AgentUsageService.DailyBucket>) out.get("buckets");
        assertEquals(2, buckets.size());
        assertEquals(1, buckets.get(0).conversations);
        assertEquals(1, buckets.get(1).conversations);
        assertEquals(3, buckets.get(0).turns);
        assertEquals(5, buckets.get(1).turns);

        AgentUsageService.Totals totals = (AgentUsageService.Totals) out.get("totals");
        assertEquals(2, totals.conversations);
        assertEquals(8, totals.turns);
        assertEquals(2, totals.uniqueActiveUsers);
        assertEquals(2, totals.uniqueActiveDealers);
        verify(adminClient, never()).fetchMessagesUsage(any(), any(), any(), any());
    }

    @Test
    void adminSummary_mergesActualsAndComputesRealCost() {
        when(adminClient.isConfigured()).thenReturn(true);
        when(conversationRepo.findAll()).thenReturn(List.of(
                convo("c1", "DLR01", "SALES001", 2, 800,
                        LocalDate.of(2026, 4, 16).atTime(9, 0))
        ));
        AnthropicAdminClient.MessagesUsageBucket bucket =
                new AnthropicAdminClient.MessagesUsageBucket(
                        "2026-04-16T00:00:00Z",
                        "2026-04-17T00:00:00Z",
                        List.of(new AnthropicAdminClient.MessagesUsageResult(
                                null, null, "claude-sonnet-4-6",
                                null, null, null,
                                100_000L, 10_000L,
                                new AnthropicAdminClient.CacheCreation(0L, 5_000L),
                                40_000L,
                                new AnthropicAdminClient.ServerToolUse(0L))));
        when(adminClient.fetchMessagesUsage(any(), any(), any(), any()))
                .thenReturn(new AnthropicAdminClient.MessagesUsageReport(List.of(bucket), false, null));

        Map<String, Object> out = service.adminSummary(
                LocalDate.of(2026, 4, 16), LocalDate.of(2026, 4, 16));
        assertTrue((boolean) out.get("actualsAvailable"));

        AgentUsageService.Totals totals = (AgentUsageService.Totals) out.get("totals");
        assertEquals(100_000L, totals.actualInputTokens);
        assertEquals(10_000L, totals.actualCacheReadTokens);
        assertEquals(5_000L, totals.actualCacheWrite5mTokens);
        assertEquals(40_000L, totals.actualOutputTokens);

        // 100K input  * $3/M  = $0.30
        // 10K  cache  * $0.30/M = $0.003
        // 5K  write5m * $3.75/M = $0.01875
        // 40K output  * $15/M = $0.60
        // total = $0.92175
        assertEquals(0, new BigDecimal("0.9218").compareTo(
                totals.actualCost.setScale(4, java.math.RoundingMode.HALF_UP)));
    }

    @Test
    void adminSummary_degradesGracefullyWhenAdminCallFails() {
        when(adminClient.isConfigured()).thenReturn(true);
        when(conversationRepo.findAll()).thenReturn(List.of());
        when(adminClient.fetchMessagesUsage(any(), any(), any(), any()))
                .thenThrow(new AnthropicAdminClient.AdminApiException("upstream 503"));

        Map<String, Object> out = service.adminSummary(
                LocalDate.of(2026, 4, 16), LocalDate.of(2026, 4, 16));
        assertFalse((boolean) out.get("actualsAvailable"));
        assertTrue(((String) out.get("actualsError")).contains("upstream 503"));
    }

    @Test
    void adminSummary_rejectsInverseRange() {
        assertThrows(IllegalArgumentException.class, () -> service.adminSummary(
                LocalDate.of(2026, 4, 16), LocalDate.of(2026, 4, 15)));
    }

    private AgentConversation convo(String id, String dealer, String userId,
                                    int turns, int tokens, LocalDateTime updatedAt) {
        return AgentConversation.builder()
                .conversationId(id)
                .userId(userId)
                .dealerCode(dealer)
                .turnCount(turns)
                .tokenTotal(tokens)
                .createdTs(updatedAt)
                .updatedTs(updatedAt)
                .build();
    }
}
