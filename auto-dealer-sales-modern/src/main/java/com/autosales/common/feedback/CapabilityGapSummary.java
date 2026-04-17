package com.autosales.common.feedback;

import java.time.LocalDateTime;

/**
 * Projection interface for the gap-frequency summary query.
 * Spring Data JPA maps columns to these getters automatically.
 */
public interface CapabilityGapSummary {
    String getCapability();
    String getCategory();
    String getAppId();
    Long getRequestCount();
    LocalDateTime getLastRequested();
}
