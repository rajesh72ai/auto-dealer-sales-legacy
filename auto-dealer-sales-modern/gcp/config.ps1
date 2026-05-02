# Shared config for all gcp/*.ps1 scripts.
# Source this from each script: . $PSScriptRoot/config.ps1

# Note on error handling — PS 5.1 treats native-command stderr as halting
# errors when ErrorActionPreference is 'Stop' (NativeCommandError). gcloud
# writes informational status (e.g. "Listing items...") to stderr, which
# triggers this. Keep at 'Continue' and check $LASTEXITCODE explicitly via
# Assert-GcloudOk after critical writes.
$ErrorActionPreference = 'Continue'

$Global:GcpProjectId       = 'auto-sales-ai-enabled'
$Global:GcpRegion          = 'us-central1'
$Global:GcpArRepo          = 'autosales'
$Global:GcpSqlInstance     = 'autosales-pg'
$Global:GcpSqlTier         = 'db-f1-micro'
$Global:GcpSqlEdition      = 'ENTERPRISE'   # ENTERPRISE_PLUS is gcloud's new default but doesn't support shared-core tiers
$Global:GcpSqlVersion      = 'POSTGRES_16'
$Global:GcpSqlDb           = 'autosales'
$Global:GcpSqlUser         = 'autosales'
$Global:GcpServiceAccount  = 'autosales-app'
$Global:GcpBackendService  = 'autosales-backend'
$Global:GcpFrontendService = 'autosales-frontend'
$Global:GcpJwtSecretName   = 'autosales-jwt-secret'
$Global:GcpDbPasswordName  = 'autosales-db-password'

# Derived values
$Global:GcpInstanceConnectionName = "$($Global:GcpProjectId):$($Global:GcpRegion):$($Global:GcpSqlInstance)"
$Global:GcpServiceAccountEmail    = "$($Global:GcpServiceAccount)@$($Global:GcpProjectId).iam.gserviceaccount.com"
$Global:GcpArHost                 = "$($Global:GcpRegion)-docker.pkg.dev"
$Global:GcpBackendImage           = "$($Global:GcpArHost)/$($Global:GcpProjectId)/$($Global:GcpArRepo)/backend:latest"
$Global:GcpFrontendImage          = "$($Global:GcpArHost)/$($Global:GcpProjectId)/$($Global:GcpArRepo)/frontend:latest"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Done {
    param([string]$Message)
    Write-Host "    [done] $Message" -ForegroundColor Green
}

function Assert-GcloudOk {
    param([string]$Description)
    if ($LASTEXITCODE -ne 0) {
        throw "gcloud failed: $Description (exit code $LASTEXITCODE)"
    }
}

# Write a string to Secret Manager as exact bytes (no PowerShell-added newline).
# `$value | gcloud secrets ... --data-file=-` appends a CRLF on Windows, which
# corrupts secrets like passwords. Use a temp file with WriteAllText to avoid it.
function Set-SecretValue {
    param(
        [Parameter(Mandatory)] [string]$SecretName,
        [Parameter(Mandatory)] [string]$Value,
        [Parameter(Mandatory)] [string]$ProjectId
    )
    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempFile, $Value)
    try {
        $existing = gcloud secrets list --project=$ProjectId --filter="name~/$SecretName$" --format="value(name)"
        if ([string]::IsNullOrWhiteSpace($existing)) {
            gcloud secrets create $SecretName --project=$ProjectId --data-file=$tempFile --replication-policy=automatic
            Assert-GcloudOk "create secret $SecretName"
        } else {
            gcloud secrets versions add $SecretName --project=$ProjectId --data-file=$tempFile
            Assert-GcloudOk "add version to secret $SecretName"
        }
    } finally {
        Remove-Item $tempFile -Force
    }
}
