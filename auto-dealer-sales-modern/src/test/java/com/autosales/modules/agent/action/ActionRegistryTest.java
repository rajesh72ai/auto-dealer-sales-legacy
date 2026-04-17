package com.autosales.modules.agent.action;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class ActionRegistryTest {

    @Test
    void load_withNoHandlers_leavesRegistryEmpty() {
        try (AnnotationConfigApplicationContext ctx =
                     new AnnotationConfigApplicationContext(EmptyConfig.class)) {
            ActionRegistry reg = ctx.getBean(ActionRegistry.class);
            assertTrue(reg.all().isEmpty());
            assertTrue(reg.find("anything").isEmpty());
            assertThrows(IllegalArgumentException.class, () -> reg.require("anything"));
        }
    }

    @Test
    void load_discoversHandlersAndIndexesByToolName() {
        try (AnnotationConfigApplicationContext ctx =
                     new AnnotationConfigApplicationContext(WithHandlersConfig.class)) {
            ActionRegistry reg = ctx.getBean(ActionRegistry.class);
            assertEquals(2, reg.all().size());
            assertTrue(reg.find("fake_one").isPresent());
            assertTrue(reg.find("fake_two").isPresent());
            assertEquals(Set.of("fake_one", "fake_two"), reg.names());
        }
    }

    @Configuration
    static class EmptyConfig {
        @Bean public ActionRegistry actionRegistry(org.springframework.context.ApplicationContext ctx) {
            return new ActionRegistry(ctx);
        }
    }

    @Configuration
    static class WithHandlersConfig {
        @Bean public ActionRegistry actionRegistry(org.springframework.context.ApplicationContext ctx) {
            return new ActionRegistry(ctx);
        }
        @Bean public ActionHandler fakeOne() { return new FakeHandler("fake_one"); }
        @Bean public ActionHandler fakeTwo() { return new FakeHandler("fake_two"); }
    }

    static class FakeHandler implements ActionHandler {
        private final String name;
        FakeHandler(String name) { this.name = name; }
        @Override public String toolName() { return name; }
        @Override public Tier tier() { return Tier.A; }
        @Override public Set<UserRole> allowedRoles() { return Set.of(UserRole.ADMIN); }
        @Override public String endpointDescriptor() { return "POST /fake"; }
        @Override public ImpactPreview dryRun(Map<String, Object> p, CurrentUserContext.Snapshot u) {
            return ImpactPreview.builder().summary("fake").build();
        }
        @Override public Object execute(Map<String, Object> p, CurrentUserContext.Snapshot u) {
            return Map.of("ok", true);
        }
    }
}
