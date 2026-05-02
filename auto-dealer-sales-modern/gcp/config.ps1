# Shared config for all gcp/*.ps1 scripts.
# Source this from each script: . $PSScriptRoot/config.ps1

$ErrorActionPreference = 'Stop'

$Global:GcpProjectId       = 'auto-sales-ai-enabled'
$Global:GcpRegion          = 'us-central1'
$Global:GcpArRepo          = 'autosales'
$Global:GcpSqlInstance     = 'autosales-pg'
$Global:GcpSqlTier         = 'db-f1-micro'
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
