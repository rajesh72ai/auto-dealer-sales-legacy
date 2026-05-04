package com.autosales.modules.agent.catalog;

import com.autosales.modules.agent.action.CurrentUserContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Serves the persona-ordered capability catalog to the Discovery UX
 * surfaces (chips, slash menu, atlas modal). One endpoint, one shape;
 * the frontend decides how to project it.
 */
@RestController
@RequestMapping("/api/agent/capabilities")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
@RequiredArgsConstructor
public class CapabilityController {

    private final CapabilityCatalogService catalogService;
    private final CurrentUserContext userContext;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list() {
        CurrentUserContext.Snapshot user = userContext.current();
        List<AgentCapability> ordered = catalogService.forRole(user == null ? null : user.getRole());

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("personaRole", user == null || user.getRole() == null ? null : user.getRole().name());
        body.put("capabilities", ordered);
        body.put("autoDiscoveredTile", catalogService.autoDiscoveredTile());
        return ResponseEntity.ok(body);
    }
}
