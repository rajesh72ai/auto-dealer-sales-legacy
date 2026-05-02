# Bring the Cloud SQL instance back online after stop-sql.ps1.
# Takes ~30 seconds. Data + schema + users are preserved across stop/start.

. $PSScriptRoot/config.ps1

Write-Step "Starting Cloud SQL instance [$GcpSqlInstance]"
gcloud sql instances patch $GcpSqlInstance `
    --project=$GcpProjectId `
    --activation-policy=ALWAYS `
    --quiet
Assert-GcloudOk "start SQL instance"

Write-Step "Waiting for instance to become RUNNABLE"
$retries = 0
do {
    Start-Sleep -Seconds 5
    $state = gcloud sql instances describe $GcpSqlInstance --project=$GcpProjectId --format='value(state)'
    Write-Host "    state = $state"
    $retries++
} while ($state -ne 'RUNNABLE' -and $retries -lt 30)

if ($state -ne 'RUNNABLE') {
    throw "Instance did not become RUNNABLE after 150s. Check console."
}

Write-Done "Cloud SQL is up — backend should reconnect on next request"
