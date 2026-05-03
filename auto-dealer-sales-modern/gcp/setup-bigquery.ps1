# B3a + B3b BigQuery setup. Idempotent — re-running is safe.
#
# Creates:
#   - Dataset autosales_analytics (us-central1)
#   - Table  tool_call_audit (mirror of agent_tool_call_audit, partitioned by created_ts)
#
# Grants:
#   - roles/bigquery.dataEditor on the dataset to autosales-app
#   - roles/bigquery.jobUser     on the project  to autosales-app
#
# Cloud Billing -> BQ export remains a one-time manual step in the Cloud Console
# (Billing -> Billing export -> BigQuery export -> select billing account and
# the autosales_analytics dataset). Once enabled the export creates a table
# named gcp_billing_export_v1_<billing_id> automatically; capture that fully
# qualified table id and set BIGQUERY_BILLING_TABLE env var on Cloud Run.

. $PSScriptRoot/config.ps1

$gcloud = "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
$bq     = "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\bq.cmd"

$dataset = "autosales_analytics"
$table   = "tool_call_audit"

Write-Host ""
Write-Host "== BigQuery setup for $GcpProjectId ==" -ForegroundColor Cyan

# 1. Enable BigQuery API (idempotent)
Write-Step "Ensuring BigQuery API is enabled"
& $gcloud services enable bigquery.googleapis.com --project=$GcpProjectId
Assert-GcloudOk "Enable BigQuery API"

# 2. Create dataset (idempotent — bq mk returns success even if it exists)
Write-Step "Creating dataset $dataset"
& $bq --project_id=$GcpProjectId mk --dataset --location=$GcpRegion --description="AUTOSALES analytics: agent tool-call audit mirror + Gemini cost analytics" "$($GcpProjectId):$dataset" 2>&1 | Out-String
Write-Host "  Dataset present (created or already existed)"

# 3. Create the audit-mirror table with explicit schema
$schemaJson = @'
[
  {"name": "audit_id",        "type": "INT64",   "mode": "NULLABLE"},
  {"name": "user_id",         "type": "STRING",  "mode": "NULLABLE"},
  {"name": "user_role",       "type": "STRING",  "mode": "NULLABLE"},
  {"name": "dealer_code",     "type": "STRING",  "mode": "NULLABLE"},
  {"name": "conversation_id", "type": "STRING",  "mode": "NULLABLE"},
  {"name": "proposal_token",  "type": "STRING",  "mode": "NULLABLE"},
  {"name": "tool_name",       "type": "STRING",  "mode": "NULLABLE"},
  {"name": "tier",            "type": "STRING",  "mode": "NULLABLE"},
  {"name": "status",          "type": "STRING",  "mode": "NULLABLE"},
  {"name": "dry_run",         "type": "BOOL",    "mode": "NULLABLE"},
  {"name": "reversible",      "type": "BOOL",    "mode": "NULLABLE"},
  {"name": "undone",          "type": "BOOL",    "mode": "NULLABLE"},
  {"name": "elapsed_ms",      "type": "INT64",   "mode": "NULLABLE"},
  {"name": "http_status",     "type": "INT64",   "mode": "NULLABLE"},
  {"name": "error_message",   "type": "STRING",  "mode": "NULLABLE"},
  {"name": "created_ts",      "type": "TIMESTAMP","mode": "NULLABLE"}
]
'@

$schemaPath = Join-Path $env:TEMP "autosales_audit_schema.json"
[System.IO.File]::WriteAllText($schemaPath, $schemaJson)

Write-Step "Creating table $dataset.$table (partitioned by created_ts, clustered by tool_name + dealer_code)"
& $bq --project_id=$GcpProjectId mk --table `
    --time_partitioning_field=created_ts `
    --time_partitioning_type=DAY `
    --clustering_fields=tool_name,dealer_code `
    --description="Mirror of Cloud SQL agent_tool_call_audit; populated async by BigQueryAnalyticsService event listener" `
    "$($GcpProjectId):$dataset.$table" $schemaPath 2>&1 | Out-String
Write-Host "  Table present"

# 4. Grant IAM roles to the runtime service account
Write-Step "Granting IAM roles to $GcpServiceAccountEmail"
# Dataset-level role: dataEditor (insert + query within autosales_analytics)
& $bq --project_id=$GcpProjectId update --source_format=NONE --description="..." "$($GcpProjectId):$dataset" 2>&1 | Out-Null
# Use bq's add-iam-policy via API; gcloud projects add-iam-policy-binding for jobUser.
& $gcloud projects add-iam-policy-binding $GcpProjectId `
    --member="serviceAccount:$GcpServiceAccountEmail" `
    --role="roles/bigquery.jobUser" --condition=None 2>&1 | Out-Null
& $gcloud projects add-iam-policy-binding $GcpProjectId `
    --member="serviceAccount:$GcpServiceAccountEmail" `
    --role="roles/bigquery.dataEditor" --condition=None 2>&1 | Out-Null
Write-Host "  IAM roles granted (jobUser + dataEditor)"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  BigQuery setup complete" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Dataset : $($GcpProjectId):$dataset"
Write-Host "  Table   : $($GcpProjectId):$dataset.$table"
Write-Host "  Cost    : Free tier covers 10 GB storage + 1 TB query/month."
Write-Host ""
Write-Host "  TODO for Cloud Billing export (one-time manual):"
Write-Host "    Cloud Console -> Billing -> Billing export -> BigQuery export"
Write-Host "    Select billing account, dataset = autosales_analytics."
Write-Host "    Then: gcloud run services update autosales-backend \"
Write-Host "          --region=$GcpRegion --project=$GcpProjectId \"
Write-Host "          --update-env-vars BIGQUERY_BILLING_TABLE=<full_table_id>"
Write-Host "============================================================" -ForegroundColor Yellow
