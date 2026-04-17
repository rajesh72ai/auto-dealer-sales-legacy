package com.autosales.modules.agent.action.dto;

import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImpactPreview {

    private String toolName;
    private String tier;
    private String summary;

    @Builder.Default
    private List<String> changes = new ArrayList<>();

    @Builder.Default
    private List<String> warnings = new ArrayList<>();

    private Object detail;

    private boolean reversible;

    public ImpactPreview addChange(String line) {
        if (this.changes == null) this.changes = new ArrayList<>();
        this.changes.add(line);
        return this;
    }

    public ImpactPreview addWarning(String line) {
        if (this.warnings == null) this.warnings = new ArrayList<>();
        this.warnings.add(line);
        return this;
    }
}
