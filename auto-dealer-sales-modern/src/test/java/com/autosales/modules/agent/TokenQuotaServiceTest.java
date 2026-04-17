package com.autosales.modules.agent;

import com.autosales.modules.agent.repository.AgentConversationRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TokenQuotaServiceTest {

    @Mock private AgentConversationRepository repo;

    @Test
    void zeroQuotaDisablesEnforcement() {
        TokenQuotaService svc = new TokenQuotaService(repo, 0);
        assertFalse(svc.isEnabled());
        TokenQuotaService.QuotaCheck chk = svc.check("ADMIN001");
        assertTrue(chk.allowed());
        verify(repo, never()).sumTokensForUserSince(any(), any());
    }

    @Test
    void allowsWhenUsedUnderQuota() {
        TokenQuotaService svc = new TokenQuotaService(repo, 200000);
        when(repo.sumTokensForUserSince(eq("ADMIN001"), any(LocalDateTime.class))).thenReturn(50000L);

        TokenQuotaService.QuotaCheck chk = svc.check("ADMIN001");
        assertTrue(chk.allowed());
        assertEquals(50000, chk.used());
        assertEquals(200000, chk.quota());
    }

    @Test
    void blocksWhenUsedAtOrAboveQuota() {
        TokenQuotaService svc = new TokenQuotaService(repo, 200000);
        when(repo.sumTokensForUserSince(eq("ADMIN001"), any(LocalDateTime.class))).thenReturn(200000L);

        TokenQuotaService.QuotaCheck chk = svc.check("ADMIN001");
        assertFalse(chk.allowed());
        assertTrue(chk.friendlyRejection().contains("200000"));
    }

    @Test
    void usedToday_queriesFromStartOfDay() {
        TokenQuotaService svc = new TokenQuotaService(repo, 100);
        when(repo.sumTokensForUserSince(eq("U1"), any(LocalDateTime.class))).thenReturn(42L);
        assertEquals(42, svc.usedToday("U1"));
    }
}
