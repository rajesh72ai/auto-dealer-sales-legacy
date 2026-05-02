# Build + push the React frontend image (vite build + nginx), then deploy
# to Cloud Run. nginx reverse-proxies /api/* to the backend Cloud Run URL,
# so the browser sees one origin and no CORS is needed.
#
# Run AFTER deploy-backend.ps1 (we read the backend URL from Cloud Run).

. $PSScriptRoot/config.ps1

$projectRoot = Resolve-Path "$PSScriptRoot/.."

# --------------------------------------------------------------------
# 1. Read backend URL
# --------------------------------------------------------------------
Write-Step "Looking up backend Cloud Run URL"
$backendUrl = gcloud run services describe $GcpBackendService `
    --project=$GcpProjectId --region=$GcpRegion `
    --format='value(status.url)' 2>$null

if ([string]::IsNullOrWhiteSpace($backendUrl)) {
    throw "Backend service [$GcpBackendService] not found. Run ./deploy-backend.ps1 first."
}
Write-Done "Backend URL: $backendUrl"

# --------------------------------------------------------------------
# 2. Build via Cloud Build
# --------------------------------------------------------------------
Write-Step "Building frontend image via Cloud Build"
Push-Location "$projectRoot/frontend"
try {
    gcloud builds submit `
        --project=$GcpProjectId `
        --region=$GcpRegion `
        --config=cloudbuild-cloudrun.yaml `
        --substitutions=_IMAGE=$GcpFrontendImage `
        .
} finally {
    Pop-Location
}
Write-Done "Frontend image pushed: $GcpFrontendImage"

# --------------------------------------------------------------------
# 3. Deploy to Cloud Run
# --------------------------------------------------------------------
Write-Step "Deploying frontend to Cloud Run service [$GcpFrontendService]"
gcloud run deploy $GcpFrontendService `
    --project=$GcpProjectId `
    --region=$GcpRegion `
    --image=$GcpFrontendImage `
    --allow-unauthenticated `
    --memory=256Mi `
    --cpu=1 `
    --min-instances=0 `
    --max-instances=2 `
    --concurrency=80 `
    --timeout=300 `
    --port=8080 `
    --set-env-vars="BACKEND_URL=$backendUrl"

Write-Done "Frontend deployed"

# --------------------------------------------------------------------
# 4. Print frontend URL
# --------------------------------------------------------------------
$frontendUrl = gcloud run services describe $GcpFrontendService `
    --project=$GcpProjectId --region=$GcpRegion `
    --format='value(status.url)'

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Frontend URL : $frontendUrl" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Open in browser, login as: ADMIN001 / Admin123"
Write-Host "  AI widgets auto-hide in Phase A (re-enabled in Phase B via Gemini)"
Write-Host "============================================================" -ForegroundColor Yellow
