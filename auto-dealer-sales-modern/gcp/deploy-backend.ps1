# Build + push the Spring Boot backend image, then deploy to Cloud Run.
# On first deploy, Spring Boot startup runs Flyway V1-V68 against the empty
# Cloud SQL database. Subsequent deploys just apply any new migrations.
#
# Run AFTER setup.ps1.

. $PSScriptRoot/config.ps1

$projectRoot = Resolve-Path "$PSScriptRoot/.."

# --------------------------------------------------------------------
# 1. Build via Cloud Build (no local Docker required)
# --------------------------------------------------------------------
Write-Step "Building backend image via Cloud Build"
Push-Location $projectRoot
try {
    gcloud builds submit `
        --project=$GcpProjectId `
        --region=$GcpRegion `
        --config=cloudbuild-cloudrun.yaml `
        --substitutions=_IMAGE=$GcpBackendImage `
        .
    Assert-GcloudOk "Cloud Build (backend)"
} finally {
    Pop-Location
}
Write-Done "Backend image pushed: $GcpBackendImage"

# --------------------------------------------------------------------
# 2. Deploy to Cloud Run
# --------------------------------------------------------------------
Write-Step "Deploying backend to Cloud Run service [$GcpBackendService]"

# JDBC URL uses the Cloud SQL Postgres Socket Factory library (added in pom.xml).
# The library connects via the SA's IAM identity using the standard JDBC URL form
# below. --add-cloudsql-instances on Cloud Run is still useful (mounts the socket
# as a fast path), but the socket factory works with or without it.
$dbUrl = "jdbc:postgresql:///$GcpSqlDb`?cloudSqlInstance=$GcpInstanceConnectionName&socketFactory=com.google.cloud.sql.postgres.SocketFactory"

# CORS allow-list — must include the public frontend Cloud Run URL or browsers
# get 403 on POSTs (browsers attach `Origin: <frontend-url>` to every POST,
# Spring's CorsFilter rejects unknown origins before any controller runs).
#
# Cloud Run gives a single service TWO URLs and either may appear as Origin:
#   - new format:    https://<service>-<projectNumber>.<region>.run.app
#   - legacy format: https://<service>-<hash>-<region>.a.run.app
# `gcloud run services describe` returns the legacy format; the new format
# must be computed. Include both to be safe.
$projectNumber = gcloud projects describe $GcpProjectId --format='value(projectNumber)'
$frontendUrlNew    = "https://$GcpFrontendService-$projectNumber.$GcpRegion.run.app"
$frontendUrlLegacy = gcloud run services describe $GcpFrontendService `
    --project=$GcpProjectId --region=$GcpRegion --format='value(status.url)' 2>$null
$origins = @($frontendUrlNew, $frontendUrlLegacy, "http://localhost:3004") `
    | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } `
    | Select-Object -Unique
$corsOrigins = $origins -join ','

gcloud run deploy $GcpBackendService `
    --project=$GcpProjectId `
    --region=$GcpRegion `
    --image=$GcpBackendImage `
    --service-account=$GcpServiceAccountEmail `
    --add-cloudsql-instances=$GcpInstanceConnectionName `
    --allow-unauthenticated `
    --memory=1Gi `
    --cpu=1 `
    --min-instances=0 `
    --max-instances=2 `
    --concurrency=80 `
    --timeout=300 `
    --port=8080 `
    --set-env-vars="^|^SPRING_PROFILES_ACTIVE=gcp|DB_URL=$dbUrl|DB_USERNAME=$GcpSqlUser|CORS_ALLOWED_ORIGINS=$corsOrigins" `
    --set-secrets="DB_PASSWORD=$GcpDbPasswordName`:latest,JWT_SECRET=$GcpJwtSecretName`:latest"

Write-Done "Backend deployed"

# --------------------------------------------------------------------
# 3. Print backend URL
# --------------------------------------------------------------------
$backendUrl = gcloud run services describe $GcpBackendService `
    --project=$GcpProjectId --region=$GcpRegion `
    --format='value(status.url)'

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Backend URL : $backendUrl" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Smoke test:  curl $backendUrl/actuator/health"
Write-Host "  Login API :  POST $backendUrl/api/auth/login  (ADMIN001 / Admin123)"
Write-Host "  Pass to frontend deploy:  ./deploy-frontend.ps1"
Write-Host "============================================================" -ForegroundColor Yellow
