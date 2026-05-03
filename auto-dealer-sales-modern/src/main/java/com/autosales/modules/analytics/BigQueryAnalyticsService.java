package com.autosales.modules.analytics;

import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.google.cloud.bigquery.BigQuery;
import com.google.cloud.bigquery.BigQueryOptions;
import com.google.cloud.bigquery.Clustering;
import com.google.cloud.bigquery.DatasetInfo;
import com.google.cloud.bigquery.Field;
import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.bigquery.InsertAllRequest;
import com.google.cloud.bigquery.InsertAllResponse;
import com.google.cloud.bigquery.LegacySQLTypeName;
import com.google.cloud.bigquery.QueryJobConfiguration;
import com.google.cloud.bigquery.Schema;
import com.google.cloud.bigquery.StandardTableDefinition;
import com.google.cloud.bigquery.TableId;
import com.google.cloud.bigquery.TableInfo;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.bigquery.TimePartitioning;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * BigQuery analytics layer for AUTOSALES (B3a + B3b).
 *
 * <p><b>B3b — audit-log mirror:</b> subscribes to {@link AgentAuditEvent}
 * and async-inserts each audit row into the {@code tool_call_audit} table
 * inside the {@code autosales_analytics} dataset. Uses streaming insert via
 * {@code BigQuery.insertAll} — events arrive in BQ within a few seconds.
 * Failures are logged but never block the agent path.
 *
 * <p><b>B3a — cost analytics:</b> exposes query helpers that read the
 * Cloud Billing export table to compute per-day Gemini spend. The export is
 * enabled at the project level (one-time gcloud command) and lands in a
 * standard table {@code <project>.<billing_dataset>.gcp_billing_export_v1_<billing_id>}.
 *
 * <p>Activated only when {@code analytics.bigquery.enabled=true} (set in
 * {@code application-gcp.yml}). On the local Compose stack this bean does
 * not load.
 */
@Service
@ConditionalOnProperty(name = "analytics.bigquery.enabled", havingValue = "true")
public class BigQueryAnalyticsService {

    private static final Logger log = LoggerFactory.getLogger(BigQueryAnalyticsService.class);

    @Value("${analytics.bigquery.project-id:}")
    private String projectId;

    @Value("${analytics.bigquery.dataset:autosales_analytics}")
    private String dataset;

    @Value("${analytics.bigquery.audit-table:tool_call_audit}")
    private String auditTable;

    @Value("${analytics.bigquery.billing-table:}")
    private String billingTable;

    @Value("${analytics.bigquery.gemini-service-name:Vertex AI API}")
    private String geminiServiceName;

    private BigQuery bq;

    @PostConstruct
    void init() {
        BigQueryOptions.Builder b = BigQueryOptions.newBuilder();
        if (projectId != null && !projectId.isBlank()) b.setProjectId(projectId);
        this.bq = b.build().getService();
        log.info("BigQuery analytics enabled — project={} dataset={} auditTable={} billingTable={}",
                projectId, dataset, auditTable,
                billingTable == null || billingTable.isBlank() ? "(unset)" : billingTable);
        try {
            ensureDatasetAndTable();
        } catch (Exception e) {
            // Don't crash the app if BQ bootstrap fails — analytics simply won't work
            // until access is fixed. Logged loudly so the operator notices.
            log.error("BigQuery bootstrap failed — analytics writes will be no-ops: {}", e.getMessage());
        }
    }

    /**
     * Idempotently creates the analytics dataset and the {@code tool_call_audit}
     * mirror table on first boot. Saves the operator from running a separate
     * setup script and works around environments where the {@code bq} CLI is
     * unusable. Safe to run on every deploy — uses CREATE IF NOT EXISTS
     * semantics via the BigQuery client.
     */
    private void ensureDatasetAndTable() {
        if (bq.getDataset(dataset) == null) {
            log.info("Creating BigQuery dataset {} (us-central1)", dataset);
            bq.create(DatasetInfo.newBuilder(dataset)
                    .setLocation("us-central1")
                    .setDescription("AUTOSALES analytics — agent tool-call audit mirror + Gemini cost analytics")
                    .build());
        }
        TableId tid = TableId.of(dataset, auditTable);
        if (bq.getTable(tid) == null) {
            log.info("Creating BigQuery table {}.{} (partitioned by created_ts, clustered by tool_name + dealer_code)",
                    dataset, auditTable);
            Schema schema = Schema.of(
                    Field.of("audit_id",        LegacySQLTypeName.INTEGER),
                    Field.of("user_id",         LegacySQLTypeName.STRING),
                    Field.of("user_role",       LegacySQLTypeName.STRING),
                    Field.of("dealer_code",     LegacySQLTypeName.STRING),
                    Field.of("conversation_id", LegacySQLTypeName.STRING),
                    Field.of("proposal_token",  LegacySQLTypeName.STRING),
                    Field.of("tool_name",       LegacySQLTypeName.STRING),
                    Field.of("tier",            LegacySQLTypeName.STRING),
                    Field.of("status",          LegacySQLTypeName.STRING),
                    Field.of("dry_run",         LegacySQLTypeName.BOOLEAN),
                    Field.of("reversible",      LegacySQLTypeName.BOOLEAN),
                    Field.of("undone",          LegacySQLTypeName.BOOLEAN),
                    Field.of("elapsed_ms",      LegacySQLTypeName.INTEGER),
                    Field.of("http_status",     LegacySQLTypeName.INTEGER),
                    Field.of("error_message",   LegacySQLTypeName.STRING),
                    Field.of("created_ts",      LegacySQLTypeName.TIMESTAMP)
            );
            StandardTableDefinition def = StandardTableDefinition.newBuilder()
                    .setSchema(schema)
                    .setTimePartitioning(TimePartitioning.newBuilder(TimePartitioning.Type.DAY)
                            .setField("created_ts").build())
                    .setClustering(Clustering.newBuilder()
                            .setFields(java.util.List.of("tool_name", "dealer_code")).build())
                    .build();
            bq.create(TableInfo.newBuilder(tid, def)
                    .setDescription("Mirror of Cloud SQL agent_tool_call_audit; populated async by BigQueryAnalyticsService.")
                    .build());
        }
    }

    // ---------- B3b: audit-log mirror ----------

    @Async
    @EventListener
    public void onAuditEvent(AgentAuditEvent event) {
        AgentToolCallAudit a = event.audit();
        if (a == null) return;
        try {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("audit_id", a.getAuditId());
            row.put("user_id", a.getUserId());
            row.put("user_role", a.getUserRole());
            row.put("dealer_code", a.getDealerCode());
            row.put("conversation_id", a.getConversationId());
            row.put("proposal_token", a.getProposalToken());
            row.put("tool_name", a.getToolName());
            row.put("tier", a.getTier());
            row.put("status", a.getStatus());
            row.put("dry_run", a.getDryRun());
            row.put("reversible", a.getReversible());
            row.put("undone", a.getUndone());
            row.put("elapsed_ms", a.getElapsedMs());
            row.put("http_status", a.getHttpStatus());
            row.put("error_message", a.getErrorMessage());
            row.put("created_ts", iso(a.getCreatedTs()));

            InsertAllResponse resp = bq.insertAll(InsertAllRequest.newBuilder(TableId.of(dataset, auditTable))
                    .addRow(String.valueOf(a.getAuditId()), row)
                    .build());
            if (resp.hasErrors()) {
                log.warn("BQ audit insert had errors: {}", resp.getInsertErrors());
            }
        } catch (Exception e) {
            // Never block the OLTP path on BQ failure
            log.warn("BQ audit insert failed for auditId={}: {}", a.getAuditId(), e.getMessage());
        }
    }

    // ---------- B3b query: tool-call analytics ----------

    /**
     * Aggregate tool-call frequency, latency p50/p95, and failure rate over
     * a date range. Returns a list of per-tool rows.
     */
    public List<Map<String, Object>> toolCallAnalytics(LocalDate from, LocalDate to) {
        String sql = "SELECT tool_name, " +
                "       COUNT(*)                                          AS calls, " +
                "       COUNTIF(status = 'FAILED')                        AS failures, " +
                "       APPROX_QUANTILES(elapsed_ms, 100)[OFFSET(50)]     AS p50_ms, " +
                "       APPROX_QUANTILES(elapsed_ms, 100)[OFFSET(95)]     AS p95_ms, " +
                "       AVG(elapsed_ms)                                   AS avg_ms " +
                "  FROM `" + projectId + "." + dataset + "." + auditTable + "` " +
                " WHERE DATE(created_ts) BETWEEN @from AND @to " +
                " GROUP BY tool_name " +
                " ORDER BY calls DESC";
        return runQuery(sql, Map.of("from", from.toString(), "to", to.toString()));
    }

    /**
     * Per-day tool-call activity — useful for the analytics page's trend chart.
     */
    public List<Map<String, Object>> dailyActivity(LocalDate from, LocalDate to) {
        String sql = "SELECT DATE(created_ts)                                 AS day, " +
                "       COUNT(*)                                              AS calls, " +
                "       COUNT(DISTINCT conversation_id)                       AS conversations, " +
                "       COUNT(DISTINCT user_id)                               AS users, " +
                "       COUNTIF(tier = 'R')                                   AS reads, " +
                "       COUNTIF(tier IN ('A','B','C','D'))                    AS writes, " +
                "       COUNTIF(status = 'FAILED')                            AS failures " +
                "  FROM `" + projectId + "." + dataset + "." + auditTable + "` " +
                " WHERE DATE(created_ts) BETWEEN @from AND @to " +
                " GROUP BY day " +
                " ORDER BY day";
        return runQuery(sql, Map.of("from", from.toString(), "to", to.toString()));
    }

    // ---------- B3a query: Gemini cost from billing export ----------

    /**
     * Per-day Gemini cost from the Cloud Billing BigQuery export. Returns
     * empty if the billing export hasn't been configured yet (table id unset).
     */
    public List<Map<String, Object>> geminiCostByDay(LocalDate from, LocalDate to) {
        if (billingTable == null || billingTable.isBlank()) {
            return List.of(Map.of(
                    "info", "Billing export not configured — set analytics.bigquery.billing-table",
                    "day", from.toString(), "cost_usd", 0.0));
        }
        String sql = "SELECT DATE(usage_start_time)              AS day, " +
                "       service.description                       AS service, " +
                "       SUM(cost)                                 AS cost_usd " +
                "  FROM `" + billingTable + "` " +
                " WHERE service.description = @service " +
                "   AND DATE(usage_start_time) BETWEEN @from AND @to " +
                " GROUP BY day, service " +
                " ORDER BY day";
        return runQuery(sql, Map.of(
                "service", geminiServiceName,
                "from", from.toString(),
                "to", to.toString()));
    }

    // ---------- helpers ----------

    private List<Map<String, Object>> runQuery(String sql, Map<String, String> params) {
        try {
            QueryJobConfiguration.Builder b = QueryJobConfiguration.newBuilder(sql)
                    .setUseLegacySql(false)
                    // Cost guard — abort any single query above ~100MB.
                    .setMaximumBytesBilled(100L * 1024 * 1024);
            params.forEach((k, v) ->
                    b.addNamedParameter(k, com.google.cloud.bigquery.QueryParameterValue.string(v)));
            TableResult result = bq.query(b.build());
            List<Map<String, Object>> rows = new ArrayList<>();
            for (FieldValueList fv : result.iterateAll()) {
                Map<String, Object> row = new LinkedHashMap<>();
                result.getSchema().getFields().forEach(field -> {
                    var val = fv.get(field.getName());
                    if (val == null || val.isNull()) {
                        row.put(field.getName(), null);
                    } else {
                        // best-effort scalar coercion
                        try {
                            row.put(field.getName(), val.getValue());
                        } catch (Exception ex) {
                            row.put(field.getName(), val.getStringValue());
                        }
                    }
                });
                rows.add(row);
            }
            return rows;
        } catch (Exception e) {
            log.warn("BQ query failed: {}", e.getMessage());
            return List.of(Map.of("error", e.getMessage()));
        }
    }

    private static String iso(LocalDateTime ts) {
        if (ts == null) return null;
        return ts.toInstant(ZoneOffset.UTC).toString();
    }
}
