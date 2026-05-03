package com.autosales.modules.agent;

import com.autosales.common.security.SystemUser;
import com.autosales.common.security.SystemUserRepository;
import com.autosales.modules.agent.repository.AgentConversationRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TokenQuotaServiceTest {

    @Mock private AgentConversationRepository repo;
    @Mock private SystemUserRepository userRepo;

    @Test
    void zeroQuotaDisablesEnforcement() {
        TokenQuotaService svc = new TokenQuotaService(repo, userRepo, 0);
        assertFalse(svc.isEnabled());
        TokenQuotaService.QuotaCheck chk = svc.check("ADMIN001");
        assertTrue(chk.allowed());
        verify(repo, never()).sumTokensForUserSince(any(), any());
    }

    @Test
    void allowsWhenUsedUnderQuota() {
        TokenQuotaService svc = new TokenQuotaService(repo, userRepo, 200000);
        when(userRepo.findByUserId("ADMIN001")).thenReturn(Optional.empty());
        when(repo.sumTokensForUserSince(eq("ADMIN001"), any(LocalDateTime.class))).thenReturn(50000L);

        TokenQuotaService.QuotaCheck chk = svc.check("ADMIN001");
        assertTrue(chk.allowed());
        assertEquals(50000, chk.used());
        assertEquals(200000, chk.quota());
        assertFalse(chk.disabled());
    }

    @Test
    void blocksWhenUsedAtOrAboveQuota() {
        TokenQuotaService svc = new TokenQuotaService(repo, userRepo, 200000);
        when(userRepo.findByUserId("ADMIN001")).thenReturn(Optional.empty());
        when(repo.sumTokensForUserSince(eq("ADMIN001"), any(LocalDateTime.class))).thenReturn(200000L);

        TokenQuotaService.QuotaCheck chk = svc.check("ADMIN001");
        assertFalse(chk.allowed());
        assertFalse(chk.disabled());
        assertTrue(chk.friendlyRejection().contains("200000"));
    }

    @Test
    void usedToday_queriesFromStartOfDay() {
        TokenQuotaService svc = new TokenQuotaService(repo, userRepo, 100);
        when(repo.sumTokensForUserSince(eq("U1"), any(LocalDateTime.class))).thenReturn(42L);
        assertEquals(42, svc.usedToday("U1"));
    }

    @Test
    void perUserOverrideHonored() {
        TokenQuotaService svc = new TokenQuotaService(repo, userRepo, 200000);
        SystemUser u = SystemUser.builder().userId("FINGUY01")
                .agentEnabled(true).agentDailyTokenQuota(50000).build();
        when(userRepo.findByUserId("FINGUY01")).thenReturn(Optional.of(u));
        when(repo.sumTokensForUserSince(eq("FINGUY01"), any(LocalDateTime.class))).thenReturn(40000L);

        TokenQuotaService.QuotaCheck chk = svc.check("FINGUY01");
        assertTrue(chk.allowed());
        assertEquals(50000, chk.quota(), "should use per-user override, not the 200000 default");
    }

    @Test
    void disabledUserShortCircuitsWithDistinctMessage() {
        TokenQuotaService svc = new TokenQuotaService(repo, userRepo, 200000);
        SystemUser u = SystemUser.builder().userId("CONTRACT").agentEnabled(false).build();
        when(userRepo.findByUserId("CONTRACT")).thenReturn(Optional.of(u));

        TokenQuotaService.QuotaCheck chk = svc.check("CONTRACT");
        assertFalse(chk.allowed());
        assertTrue(chk.disabled());
        assertTrue(chk.friendlyRejection().contains("disabled"));
        // Disabled users don't even consume the quota lookup
        verify(repo, never()).sumTokensForUserSince(any(), any());
    }

    @Test
    void perUserOverrideOfNullFallsBackToDefault() {
        TokenQuotaService svc = new TokenQuotaService(repo, userRepo, 200000);
        SystemUser u = SystemUser.builder().userId("ADMIN001")
                .agentEnabled(true).agentDailyTokenQuota(null).build();
        when(userRepo.findByUserId("ADMIN001")).thenReturn(Optional.of(u));
        when(repo.sumTokensForUserSince(eq("ADMIN001"), any(LocalDateTime.class))).thenReturn(100L);

        TokenQuotaService.QuotaCheck chk = svc.check("ADMIN001");
        assertTrue(chk.allowed());
        assertEquals(200000, chk.quota(), "null override should fall through to default");
    }
}
