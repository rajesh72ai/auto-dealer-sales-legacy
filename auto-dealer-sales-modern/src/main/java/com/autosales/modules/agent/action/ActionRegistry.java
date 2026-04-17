package com.autosales.modules.agent.action;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
@RequiredArgsConstructor
public class ActionRegistry {

    private static final Logger log = LoggerFactory.getLogger(ActionRegistry.class);

    private final ApplicationContext context;

    private final Map<String, ActionHandler> handlers = new LinkedHashMap<>();

    @PostConstruct
    void load() {
        Map<String, ActionHandler> beans = context.getBeansOfType(ActionHandler.class);
        for (ActionHandler h : beans.values()) {
            String name = h.toolName();
            if (name == null || name.isBlank()) {
                log.warn("ActionHandler {} has blank toolName — skipping", h.getClass().getName());
                continue;
            }
            ActionHandler prior = handlers.put(name, h);
            if (prior != null) {
                log.error("Duplicate ActionHandler for tool '{}' — keeping {}, dropping {}",
                          name, prior.getClass().getName(), h.getClass().getName());
            }
        }
        if (handlers.isEmpty()) {
            log.info("ActionRegistry loaded 0 handlers (expected during Stage 1 plumbing)");
        } else {
            log.info("ActionRegistry loaded {} handlers: {}", handlers.size(), handlers.keySet());
        }
    }

    public Optional<ActionHandler> find(String toolName) {
        return Optional.ofNullable(handlers.get(toolName));
    }

    public ActionHandler require(String toolName) {
        return find(toolName).orElseThrow(() ->
            new IllegalArgumentException("Unknown or unauthorised agent tool: " + toolName));
    }

    public Collection<ActionHandler> all() {
        return Collections.unmodifiableCollection(handlers.values());
    }

    public Set<String> names() {
        return Collections.unmodifiableSet(handlers.keySet());
    }
}
