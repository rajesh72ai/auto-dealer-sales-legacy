# One-time provisioning for the AUTOSALES GCP demo deployment.
# Idempotent — safe to re-run; existing resources are skipped.
#
# Creates: APIs, Artifact Registry repo, Cloud SQL instance + database + user,
# Secret Manager secrets (DB password, JWT secret), service account with
# Cloud SQL Client + Secret Accessor roles.
#
# Run BEFORE deploy-backend.ps1 / deploy-frontend.ps1.

. $PSScriptRoot/config.ps1

Write-Host "Provisioning AUTOSALES on GCP project [$GcpProjectId] in [$GcpRegion]..." -ForegroundColor Yellow

# --------------------------------------------------------------------
# 1. Enable required APIs
# --------------------------------------------------------------------
Write-Step "Enabling required APIs (this can take 1-2 min on first run)"
$apis = @(
    'run.googleapis.com',
    'sqladmin.googleapis.com',
    'artifactregistry.googleapis.com',
    'secretmanager.googleapis.com',
    'cloudbuild.googleapis.com',
    'iam.googleapis.com',
    'compute.googleapis.com'
)
gcloud services enable @apis --project=$GcpProjectId
Write-Done "APIs enabled"

# --------------------------------------------------------------------
# 2. Artifact Registry Docker repo
# --------------------------------------------------------------------
Write-Step "Creating Artifact Registry repo [$GcpArRepo]"
$existingRepo = gcloud artifacts repositories list --project=$GcpProjectId `
    --location=$GcpRegion --filter="name~/$GcpArRepo$" --format="value(name)" 2>$null
if ([string]::IsNullOrWhiteSpace($existingRepo)) {
    gcloud artifacts repositories create $GcpArRepo `
        --project=$GcpProjectId --location=$GcpRegion `
        --repository-format=docker `
        --description="AUTOSALES container images"
    Write-Done "Artifact Registry repo created"
} else {
    Write-Done "Artifact Registry repo already exists — skipping"
}

# Configure Docker auth for Artifact Registry (idempotent)
gcloud auth configure-docker $GcpArHost --quiet | Out-Null

# --------------------------------------------------------------------
# 3. Cloud SQL instance (Postgres 16, db-f1-micro, ~$8-10/mo)
# --------------------------------------------------------------------
Write-Step "Creating Cloud SQL Postgres instance [$GcpSqlInstance] (~5-7 min)"
$existingInstance = gcloud sql instances list --project=$GcpProjectId `
    --filter="name=$GcpSqlInstance" --format="value(name)" 2>$null
if ([string]::IsNullOrWhiteSpace($existingInstance)) {
    $rootPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    gcloud sql instances create $GcpSqlInstance `
        --project=$GcpProjectId `
        --database-version=$GcpSqlVersion `
        --tier=$GcpSqlTier `
        --region=$GcpRegion `
        --root-password=$rootPassword `
        --storage-size=10GB `
        --storage-type=SSD `
        --no-backup `
        --availability-type=zonal
    Write-Done "Cloud SQL instance created"
} else {
    Write-Done "Cloud SQL instance already exists — skipping"
}

# --------------------------------------------------------------------
# 4. Database + user
# --------------------------------------------------------------------
Write-Step "Creating database [$GcpSqlDb] and user [$GcpSqlUser]"

$existingDb = gcloud sql databases list --instance=$GcpSqlInstance --project=$GcpProjectId `
    --filter="name=$GcpSqlDb" --format="value(name)" 2>$null
if ([string]::IsNullOrWhiteSpace($existingDb)) {
    gcloud sql databases create $GcpSqlDb --instance=$GcpSqlInstance --project=$GcpProjectId
    Write-Done "Database created"
} else {
    Write-Done "Database already exists — skipping"
}

$existingUser = gcloud sql users list --instance=$GcpSqlInstance --project=$GcpProjectId `
    --filter="name=$GcpSqlUser" --format="value(name)" 2>$null
if ([string]::IsNullOrWhiteSpace($existingUser)) {
    $dbPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    gcloud sql users create $GcpSqlUser `
        --instance=$GcpSqlInstance --project=$GcpProjectId `
        --password=$dbPassword

    # Store the password we just generated in Secret Manager
    Write-Step "Storing DB password in Secret Manager [$GcpDbPasswordName]"
    $existingSecret = gcloud secrets list --project=$GcpProjectId `
        --filter="name~/$GcpDbPasswordName$" --format="value(name)" 2>$null
    if ([string]::IsNullOrWhiteSpace($existingSecret)) {
        $dbPassword | gcloud secrets create $GcpDbPasswordName `
            --project=$GcpProjectId --data-file=- --replication-policy=automatic
    } else {
        $dbPassword | gcloud secrets versions add $GcpDbPasswordName `
            --project=$GcpProjectId --data-file=-
    }
    Write-Done "DB user created and password stored"
} else {
    Write-Done "DB user already exists — assuming password is in Secret Manager"
}

# --------------------------------------------------------------------
# 5. JWT secret
# --------------------------------------------------------------------
Write-Step "Generating JWT secret [$GcpJwtSecretName]"
$existingJwt = gcloud secrets list --project=$GcpProjectId `
    --filter="name~/$GcpJwtSecretName$" --format="value(name)" 2>$null
if ([string]::IsNullOrWhiteSpace($existingJwt)) {
    # 64 random bytes, hex-encoded — well above HS256's 256-bit minimum
    $bytes = New-Object byte[] 64
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $jwt = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
    $jwt | gcloud secrets create $GcpJwtSecretName `
        --project=$GcpProjectId --data-file=- --replication-policy=automatic
    Write-Done "JWT secret created"
} else {
    Write-Done "JWT secret already exists — skipping"
}

# --------------------------------------------------------------------
# 6. Service account for Cloud Run backend
# --------------------------------------------------------------------
Write-Step "Creating service account [$GcpServiceAccount]"
$existingSa = gcloud iam service-accounts list --project=$GcpProjectId `
    --filter="email=$GcpServiceAccountEmail" --format="value(email)" 2>$null
if ([string]::IsNullOrWhiteSpace($existingSa)) {
    gcloud iam service-accounts create $GcpServiceAccount `
        --project=$GcpProjectId `
        --display-name="AUTOSALES Cloud Run runtime"
    Write-Done "Service account created"
} else {
    Write-Done "Service account already exists — skipping"
}

# Bind required roles (idempotent)
Write-Step "Binding IAM roles to service account"
$roles = @('roles/cloudsql.client', 'roles/secretmanager.secretAccessor')
foreach ($role in $roles) {
    gcloud projects add-iam-policy-binding $GcpProjectId `
        --member="serviceAccount:$GcpServiceAccountEmail" `
        --role=$role --condition=None | Out-Null
}
Write-Done "Roles bound: $($roles -join ', ')"

# --------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Provisioning complete." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Project              : $GcpProjectId"
Write-Host "  Region               : $GcpRegion"
Write-Host "  Cloud SQL instance   : $GcpInstanceConnectionName"
Write-Host "  Artifact Registry    : $GcpArHost/$GcpProjectId/$GcpArRepo"
Write-Host "  Service account      : $GcpServiceAccountEmail"
Write-Host "  JWT secret           : $GcpJwtSecretName"
Write-Host "  DB password secret   : $GcpDbPasswordName"
Write-Host ""
Write-Host "  Next: ./deploy-backend.ps1   (then) ./deploy-frontend.ps1"
Write-Host "============================================================" -ForegroundColor Yellow
