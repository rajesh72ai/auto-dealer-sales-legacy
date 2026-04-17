package com.autosales.modules.agent.action;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.handlers.ApproveDealHandler;
import com.autosales.modules.agent.action.handlers.CreateDealHandler;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Explicit refusal coverage: verifies role gates are set up correctly so the
 * ActionService security check rejects unauthorized callers before any
 * downstream write runs.
 */
class RoleRefusalTest {

    @Test
    void approveDeal_onlyManagersAndAdminsAllowed() {
        ApproveDealHandler handler = new ApproveDealHandler(null, null);
        Set<UserRole> allowed = handler.allowedRoles();
        assertTrue(allowed.contains(UserRole.MANAGER));
        assertTrue(allowed.contains(UserRole.ADMIN));
        assertFalse(allowed.contains(UserRole.SALESPERSON),
                "approve_deal must refuse SALESPERSON");
        assertFalse(allowed.contains(UserRole.CLERK),
                "approve_deal must refuse CLERK");
        assertFalse(allowed.contains(UserRole.FINANCE),
                "approve_deal must refuse FINANCE");
    }

    @Test
    void createDeal_allowsSalesperson() {
        CreateDealHandler handler = new CreateDealHandler(null, null);
        assertTrue(handler.allowedRoles().contains(UserRole.SALESPERSON));
    }

    @Test
    void snapshotHasRoleCheck_matchesAllowedSet() {
        CurrentUserContext.Snapshot sales =
                new CurrentUserContext.Snapshot("SALES001", UserRole.SALESPERSON, "DLR01");
        CurrentUserContext.Snapshot mgr =
                new CurrentUserContext.Snapshot("MGR001", UserRole.MANAGER, "DLR01");
        CurrentUserContext.Snapshot anon =
                new CurrentUserContext.Snapshot("anonymous", null, null);

        assertTrue(sales.hasRole(UserRole.SALESPERSON, UserRole.MANAGER));
        assertFalse(sales.hasRole(UserRole.MANAGER, UserRole.ADMIN));
        assertTrue(mgr.hasRole(UserRole.MANAGER, UserRole.ADMIN));
        assertFalse(anon.hasRole(UserRole.MANAGER));
    }
}
