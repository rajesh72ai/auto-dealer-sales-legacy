package com.autosales.modules.analytics;

import com.autosales.modules.agent.action.entity.AgentToolCallAudit;

/**
 * Application event published every time an agent_tool_call_audit row is
 * persisted. Decouples the OLTP write path (Postgres) from the OLAP mirror
 * (BigQuery) — the analytics layer subscribes asynchronously, so an outage
 * in BigQuery never blocks the agent.
 */
public record AgentAuditEvent(AgentToolCallAudit audit) {}
