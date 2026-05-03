package com.autosales.modules.agent.action;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.agent.action.dto.PrerequisiteGap;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class PrerequisiteResolverTest {

    private final PrerequisiteResolver resolver = new PrerequisiteResolver();

    @Test
    void analyze_returnsNullWhenHandlerHasNoPrereqs() {
        ActionHandler handler = new SimpleHandler("noop", List.of());
        assertNull(resolver.analyze(handler, Map.of()));
    }

    @Test
    void analyze_returnsNullWhenAllPrereqsSatisfied() {
        ActionHandler handler = new SimpleHandler("create_lead", List.of(
                new Prerequisite("customerId", "customer", "list_customers", "create_customer",
                        "customerId", "hint", List.of("firstName"))));
        Map<String, Object> payload = new HashMap<>();
        payload.put("customerId", 42);
        assertNull(resolver.analyze(handler, payload));
    }

    @Test
    void analyze_returnsGapWhenPrereqMissing() {
        ActionHandler handler = new SimpleHandler("create_lead", List.of(
                new Prerequisite("customerId", "customer", "list_customers", "create_customer",
                        "customerId", "We need a customer first.",
                        List.of("firstName", "lastName", "phone"))));

        PrerequisiteGap gap = resolver.analyze(handler, Map.of("dealerCode", "DLR01"));
        assertNotNull(gap);
        assertEquals("create_lead", gap.getParentTool());
        assertEquals(1, gap.getUnmet().size());
        PrerequisiteGap.UnmetPrereq u = gap.getUnmet().get(0);
        assertEquals("customerId", u.getPayloadField());
        assertEquals("customer", u.getEntityName());
        assertEquals("list_customers", u.getFinderToolName());
        assertEquals("create_customer", u.getSatisfierToolName());
        assertEquals(List.of("firstName", "lastName", "phone"), u.getRequiredUserData());
        assertTrue(gap.getSummary().contains("create_lead"));
        assertTrue(gap.getSummary().contains("customer"));
    }

    @Test
    void analyze_treatsZeroNumericIdAsUnsatisfied() {
        ActionHandler handler = new SimpleHandler("create_lead", List.of(
                new Prerequisite("customerId", "customer", "list_customers", "create_customer",
                        "customerId", "hint", List.of("firstName"))));
        Map<String, Object> payload = new HashMap<>();
        payload.put("customerId", 0); // a zero id is invalid for our schemas
        PrerequisiteGap gap = resolver.analyze(handler, payload);
        assertNotNull(gap);
    }

    @Test
    void analyze_returnsAllUnmetWhenMultiplePrereqs() {
        ActionHandler handler = new SimpleHandler("apply_incentive", List.of(
                new Prerequisite("dealNumber", "deal", "list_deals", null,
                        null, "Deal must exist.", List.of()),
                new Prerequisite("incentiveId", "incentive", "list_incentives", null,
                        null, "Incentive must exist.", List.of())));
        PrerequisiteGap gap = resolver.analyze(handler, Map.of());
        assertNotNull(gap);
        assertEquals(2, gap.getUnmet().size());
    }

    /** Minimal ActionHandler test double. */
    private static final class SimpleHandler implements ActionHandler {
        private final String name;
        private final List<Prerequisite> prereqs;
        SimpleHandler(String name, List<Prerequisite> prereqs) {
            this.name = name; this.prereqs = prereqs;
        }
        @Override public String toolName() { return name; }
        @Override public Tier tier() { return Tier.A; }
        @Override public Set<UserRole> allowedRoles() { return Set.of(UserRole.ADMIN); }
        @Override public String endpointDescriptor() { return "POST /test"; }
        @Override public ImpactPreview dryRun(Map<String, Object> p, CurrentUserContext.Snapshot u) {
            return ImpactPreview.builder().toolName(name).tier("A").build();
        }
        @Override public Object execute(Map<String, Object> p, CurrentUserContext.Snapshot u) { return null; }
        @Override public List<Prerequisite> prerequisites() { return prereqs; }
    }
}
