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
        --tag=$GcpBackendImage `
        --machine-type=e2-highcpu-8 `
        --timeout=900s `
        --config=$null `
        -f Dockerfile.cloudrun `
        .
} finally {
    Pop-Location
}
Write-Done "Backend image pushed: $GcpBackendImage"

# --------------------------------------------------------------------
# 2. Deploy to Cloud Run
# --------------------------------------------------------------------
Write-Step "Deploying backend to Cloud Run service [$GcpBackendService]"

# JDBC URL uses Unix socket mounted by Cloud Run when --add-cloudsql-instances is set
$dbUrl = "jdbc:postgresql:///$GcpSqlDb`?host=/cloudsql/$GcpInstanceConnectionName"

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
    --set-env-vars="SPRING_PROFILES_ACTIVE=gcp,DB_URL=$dbUrl,DB_USERNAME=$GcpSqlUser" `
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
