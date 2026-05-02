# OPTIONAL — tears down all Cloud Run + Cloud SQL resources to stop billing.
# Useful between demo windows or when the trial credit needs to last longer.
# Secrets and Artifact Registry images are kept (cheap; quick redeploy on next setup).
#
# Use --AlsoSecrets / --AlsoImages to delete those too.

param(
    [switch]$AlsoSecrets,
    [switch]$AlsoImages
)

. $PSScriptRoot/config.ps1

Write-Host "Tearing down AUTOSALES on GCP project [$GcpProjectId]..." -ForegroundColor Yellow
Write-Host ""

Write-Step "Deleting Cloud Run frontend [$GcpFrontendService]"
gcloud run services delete $GcpFrontendService `
    --project=$GcpProjectId --region=$GcpRegion --quiet 2>$null

Write-Step "Deleting Cloud Run backend [$GcpBackendService]"
gcloud run services delete $GcpBackendService `
    --project=$GcpProjectId --region=$GcpRegion --quiet 2>$null

Write-Step "Deleting Cloud SQL instance [$GcpSqlInstance] (this is the big-cost item)"
gcloud sql instances delete $GcpSqlInstance --project=$GcpProjectId --quiet 2>$null

if ($AlsoSecrets) {
    Write-Step "Deleting secrets"
    gcloud secrets delete $GcpJwtSecretName --project=$GcpProjectId --quiet 2>$null
    gcloud secrets delete $GcpDbPasswordName --project=$GcpProjectId --quiet 2>$null
}

if ($AlsoImages) {
    Write-Step "Deleting Artifact Registry repo [$GcpArRepo]"
    gcloud artifacts repositories delete $GcpArRepo `
        --project=$GcpProjectId --location=$GcpRegion --quiet 2>$null
}

Write-Done "Teardown complete"
Write-Host ""
Write-Host "Re-run ./setup.ps1 to recreate everything."
