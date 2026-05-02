# Stop the Cloud SQL instance to drop ongoing cost from ~$10/mo to
# ~$1-2/mo (storage only). Data is preserved. Use start-sql.ps1 to
# bring it back online — takes about 30 seconds.
#
# Cloud Run services are unaffected (they scale to zero on their own
# and don't bill while idle).

. $PSScriptRoot/config.ps1

Write-Step "Stopping Cloud SQL instance [$GcpSqlInstance]"
gcloud sql instances patch $GcpSqlInstance `
    --project=$GcpProjectId `
    --activation-policy=NEVER `
    --quiet
Assert-GcloudOk "stop SQL instance"

Write-Done "Cloud SQL stopped — billing now ~$1-2/mo for storage only"
Write-Host ""
Write-Host "  Resume with: ./start-sql.ps1"
