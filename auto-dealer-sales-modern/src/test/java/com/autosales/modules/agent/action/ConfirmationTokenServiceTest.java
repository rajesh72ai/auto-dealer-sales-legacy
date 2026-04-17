package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.entity.AgentActionProposal;
import com.autosales.modules.agent.action.repository.AgentActionProposalRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ConfirmationTokenServiceTest {

    @Mock private AgentActionProposalRepository repo;
    @Spy  private ObjectMapper mapper = new ObjectMapper();
    @InjectMocks private ConfirmationTokenService service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "ttlSeconds", 300L);
        lenient().when(repo.save(any(AgentActionProposal.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void create_generatesUuidAndHashesPayload() {
        AgentActionProposal p = service.create("ADMIN001", "DLR01", null,
                "create_deal", "A",
                Map.of("customerId", 7, "vin", "1HGCM82633A123456"),
                Map.of("summary", "would create deal"));

        assertNotNull(p.getToken());
        assertEquals(36, p.getToken().length());
        assertEquals("PENDING", p.getStatus());
        assertEquals("ADMIN001", p.getUserId());
        assertEquals("DLR01", p.getDealerCode());
        assertEquals("create_deal", p.getToolName());
        assertEquals(64, p.getPayloadHash().length());
        assertTrue(p.getExpiresAt().isAfter(LocalDateTime.now().plusSeconds(280)));
    }

    @Test
    void create_serializesPayloadAndPreviewToJson() {
        AgentActionProposal p = service.create("U1", "DLR01", "conv-1",
                "t", "A",
                Map.of("k", "v"),
                Map.of("summary", "x"));

        assertTrue(p.getPayloadJson().contains("\"k\""));
        assertTrue(p.getPreviewJson().contains("summary"));
    }

    @Test
    void validate_returnsPendingProposalForOwningUser() {
        AgentActionProposal p = sample("tok-1", "ADMIN001", "PENDING", LocalDateTime.now().plusMinutes(5));
        when(repo.findByToken("tok-1")).thenReturn(Optional.of(p));

        AgentActionProposal out = service.validate("tok-1", "ADMIN001");
        assertSame(p, out);
    }

    @Test
    void validate_rejectsWrongUser() {
        AgentActionProposal p = sample("tok-2", "ADMIN001", "PENDING", LocalDateTime.now().plusMinutes(5));
        when(repo.findByToken("tok-2")).thenReturn(Optional.of(p));
        assertThrows(SecurityException.class, () -> service.validate("tok-2", "SALESPER1"));
    }

    @Test
    void validate_rejectsExpired() {
        AgentActionProposal p = sample("tok-3", "U1", "PENDING", LocalDateTime.now().minusSeconds(1));
        when(repo.findByToken("tok-3")).thenReturn(Optional.of(p));
        assertThrows(IllegalStateException.class, () -> service.validate("tok-3", "U1"));
    }

    @Test
    void validate_rejectsAlreadyDecided() {
        AgentActionProposal p = sample("tok-4", "U1", "CONFIRMED", LocalDateTime.now().plusMinutes(5));
        when(repo.findByToken("tok-4")).thenReturn(Optional.of(p));
        assertThrows(IllegalStateException.class, () -> service.validate("tok-4", "U1"));
    }

    @Test
    void validate_rejectsUnknownToken() {
        when(repo.findByToken("tok-x")).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.validate("tok-x", "U1"));
    }

    @Test
    void markConfirmed_updatesStatusAndAuditId() {
        AgentActionProposal p = sample("tok-5", "U1", "PENDING", LocalDateTime.now().plusMinutes(5));
        when(repo.findByToken("tok-5")).thenReturn(Optional.of(p));

        AgentActionProposal out = service.markConfirmed("tok-5", 999L);

        assertEquals("CONFIRMED", out.getStatus());
        assertEquals(999L, out.getExecutionAuditId());
        assertNotNull(out.getDecidedAt());
    }

    @Test
    void markRejected_rejectsWrongUser() {
        AgentActionProposal p = sample("tok-6", "ADMIN001", "PENDING", LocalDateTime.now().plusMinutes(5));
        when(repo.findByToken("tok-6")).thenReturn(Optional.of(p));
        assertThrows(SecurityException.class, () -> service.markRejected("tok-6", "OTHER"));
    }

    @Test
    void markRejected_setsRejectedStatus() {
        AgentActionProposal p = sample("tok-7", "U1", "PENDING", LocalDateTime.now().plusMinutes(5));
        when(repo.findByToken("tok-7")).thenReturn(Optional.of(p));

        AgentActionProposal out = service.markRejected("tok-7", "U1");
        assertEquals("REJECTED", out.getStatus());
        assertNotNull(out.getDecidedAt());
    }

    @Test
    void hashIsDeterministic() {
        String a = ConfirmationTokenService.hash("{\"x\":1}");
        String b = ConfirmationTokenService.hash("{\"x\":1}");
        String c = ConfirmationTokenService.hash("{\"x\":2}");
        assertEquals(a, b);
        assertNotEquals(a, c);
    }

    private AgentActionProposal sample(String token, String userId, String status, LocalDateTime expires) {
        return AgentActionProposal.builder()
                .token(token)
                .userId(userId)
                .toolName("t")
                .tier("A")
                .payloadJson("{}")
                .payloadHash(ConfirmationTokenService.hash("{}"))
                .previewJson("{}")
                .status(status)
                .expiresAt(expires)
                .createdTs(LocalDateTime.now())
                .build();
    }
}
