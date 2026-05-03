package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.dto.PrerequisiteGap;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Detects and articulates unmet prerequisites for an {@link ActionHandler}.
 * The resolver does not chase prerequisites itself — that's the frontend's
 * job (it presents the gap card, collects user input, fires propose calls
 * for the satisfier in turn). The resolver's role is purely diagnostic:
 * given a payload and a handler, return a {@link PrerequisiteGap} or null.
 */
@Service
@RequiredArgsConstructor
public class PrerequisiteResolver {

    /**
     * Inspect the payload against the handler's declared prerequisites.
     * Returns null if all prereqs are satisfied (the parent action can
     * proceed). Otherwise returns a gap describing what is missing and
     * how to resolve it.
     */
    public PrerequisiteGap analyze(ActionHandler handler, Map<String, Object> payload) {
        List<Prerequisite> declared = handler.prerequisites();
        if (declared == null || declared.isEmpty()) return null;

        List<PrerequisiteGap.UnmetPrereq> unmet = new ArrayList<>();
        for (Prerequisite p : declared) {
            if (isSatisfied(payload, p.payloadField())) continue;
            unmet.add(PrerequisiteGap.UnmetPrereq.builder()
                    .payloadField(p.payloadField())
                    .entityName(p.entityName())
                    .finderToolName(p.finderToolName())
                    .satisfierToolName(p.satisfierToolName())
                    .resultField(p.resultField())
                    .userFacingHint(p.userFacingHint())
                    .requiredUserData(p.requiredUserData())
                    .build());
        }
        if (unmet.isEmpty()) return null;

        StringBuilder summary = new StringBuilder("Before ").append(handler.toolName())
                .append(" can run, we need: ");
        for (int i = 0; i < unmet.size(); i++) {
            if (i > 0) summary.append("; ");
            summary.append(unmet.get(i).getEntityName())
                    .append(" (").append(unmet.get(i).getPayloadField()).append(")");
        }
        summary.append(".");

        return PrerequisiteGap.builder()
                .parentTool(handler.toolName())
                .parentTier(handler.tier().getCode())
                .summary(summary.toString())
                .unmet(unmet)
                .originalPayload(payload)
                .build();
    }

    private static boolean isSatisfied(Map<String, Object> payload, String field) {
        if (payload == null) return false;
        Object v = payload.get(field);
        if (v == null) return false;
        if (v instanceof CharSequence cs && cs.length() == 0) return false;
        if (v instanceof Number n && n.intValue() == 0) {
            // A zero numeric id is invalid for our schemas — treat as unset.
            return false;
        }
        return true;
    }
}
