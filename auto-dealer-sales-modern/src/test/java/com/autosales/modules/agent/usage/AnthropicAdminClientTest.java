package com.autosales.modules.agent.usage;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class AnthropicAdminClientTest {

    private final ObjectMapper mapper = new ObjectMapper();

    @Test
    void isConfigured_trueWhenKeySet() {
        AnthropicAdminClient client = new AnthropicAdminClient(
                mapper, "sk-ant-admin-abc", "https://api.anthropic.com", "2023-06-01");
        assertTrue(client.isConfigured());
    }

    @Test
    void isConfigured_falseWhenKeyEmpty() {
        AnthropicAdminClient client = new AnthropicAdminClient(mapper, "", "x", "v");
        assertFalse(client.isConfigured());
    }

    @Test
    void isConfigured_falseWhenKeyIsWhitespace() {
        AnthropicAdminClient client = new AnthropicAdminClient(mapper, "   ", "x", "v");
        assertFalse(client.isConfigured());
    }

    @Test
    void fetchMessagesUsage_throwsWhenNotConfigured() {
        AnthropicAdminClient client = new AnthropicAdminClient(mapper, "", "x", "v");
        assertThrows(IllegalStateException.class, () ->
                client.fetchMessagesUsage(Instant.now(), null, "1d", List.of("model")));
    }

    @Test
    void deserializes_usageReport_withNestedCacheAndToolUse() throws Exception {
        String body = """
                {
                  "data": [
                    {
                      "starting_at": "2026-04-16T00:00:00Z",
                      "ending_at":   "2026-04-17T00:00:00Z",
                      "results": [
                        {
                          "api_key_id": "ak_1",
                          "workspace_id": null,
                          "model": "claude-sonnet-4-6",
                          "service_tier": "standard",
                          "context_window": "0-200k",
                          "inference_geo": "us",
                          "uncached_input_tokens": 12345,
                          "cache_read_input_tokens": 200,
                          "cache_creation": {
                            "ephemeral_1h_input_tokens": 10,
                            "ephemeral_5m_input_tokens": 20
                          },
                          "output_tokens": 6789,
                          "server_tool_use": { "web_search_requests": 3 }
                        }
                      ]
                    }
                  ],
                  "has_more": false,
                  "next_page": null
                }
                """;
        AnthropicAdminClient.MessagesUsageReport report =
                mapper.readValue(body, AnthropicAdminClient.MessagesUsageReport.class);
        assertFalse(report.hasMore());
        assertEquals(1, report.data().size());
        AnthropicAdminClient.MessagesUsageBucket b = report.data().get(0);
        assertEquals("2026-04-16T00:00:00Z", b.startingAt());
        assertEquals(1, b.results().size());
        AnthropicAdminClient.MessagesUsageResult r = b.results().get(0);
        assertEquals("claude-sonnet-4-6", r.model());
        assertEquals(12345L, r.uncachedInputTokens());
        assertEquals(200L, r.cacheReadInputTokens());
        assertEquals(6789L, r.outputTokens());
        assertEquals(10L, r.cacheCreation().ephemeral1hInputTokens());
        assertEquals(20L, r.cacheCreation().ephemeral5mInputTokens());
        assertEquals(3L, r.serverToolUse().webSearchRequests());
    }

    @Test
    void deserializes_ignoresUnknownFields() throws Exception {
        String body = """
                {
                  "data": [],
                  "has_more": false,
                  "future_field": "whatever",
                  "another_new_field": 42
                }
                """;
        AnthropicAdminClient.MessagesUsageReport report =
                mapper.readValue(body, AnthropicAdminClient.MessagesUsageReport.class);
        assertNotNull(report);
        assertTrue(report.data().isEmpty());
    }
}
