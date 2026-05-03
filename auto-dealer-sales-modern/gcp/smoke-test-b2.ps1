# B2 live smoke test - verifies on Cloud Run that:
#   1. The agent answers a read question via Gemini function calling
#   2. The tool-call audit row is persisted (visible in the trace endpoint)
#   3. A propose-style request returns a proposal envelope (and is recorded)
#
# Prereqs: deploy-backend.ps1 + deploy-frontend.ps1 have run successfully.
# Auth: uses ADMIN001 / Admin123 against the live Cloud Run frontend.

. $PSScriptRoot/config.ps1

$gcloud = "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"

$frontendUrl = & $gcloud run services describe $GcpFrontendService `
    --project=$GcpProjectId --region=$GcpRegion `
    --format='value(status.url)' 2>$null
if ([string]::IsNullOrWhiteSpace($frontendUrl)) {
    throw "Frontend not deployed. Run ./deploy-frontend.ps1 first."
}
Write-Host "Frontend: $frontendUrl" -ForegroundColor Cyan

# 1. Login
Write-Host ""
Write-Host "== 1. Login as ADMIN001 ==" -ForegroundColor Yellow
$loginResp = Invoke-RestMethod -Uri "$frontendUrl/api/auth/login" -Method Post `
    -Body '{"userId":"ADMIN001","password":"Admin123"}' `
    -ContentType 'application/json' -Headers @{ 'Origin' = $frontendUrl }
$token = $loginResp.accessToken
$headers = @{ Authorization = "Bearer $token"; 'Origin' = $frontendUrl }
Write-Host "  OK got token (len=$($token.Length))"

# 2. Read prompt - exercises function calling + audit write
Write-Host ""
Write-Host "== 2. Read prompt: How many vehicles in my dealership? ==" -ForegroundColor Yellow
$readBody = '{"userMessage":"How many vehicles in my dealership? Brief answer."}'
$readStart = Get-Date
$readResp = Invoke-RestMethod -Uri "$frontendUrl/api/agent" -Method Post `
    -Body $readBody -ContentType 'application/json' -Headers $headers
$readMs = ((Get-Date) - $readStart).TotalMilliseconds
Write-Host "  Reply: $($readResp.reply)"
Write-Host "  Tokens: prompt=$($readResp.usage.promptTokens) completion=$($readResp.usage.completionTokens)"
Write-Host "  Latency: $([int]$readMs) ms"
$readConvId = $readResp.conversationId
Write-Host "  conversationId: $readConvId"
if ($readResp.proposal) {
    Write-Host "  WARN: read prompt unexpectedly produced a proposal" -ForegroundColor Red
}

# 3. Trace check - verify the function_call audit row was persisted
Write-Host ""
Write-Host "== 3. Trace endpoint - verify audit rows ==" -ForegroundColor Yellow
Start-Sleep -Seconds 1
$traceResp = Invoke-RestMethod -Uri "$frontendUrl/api/admin/agent-trace/$readConvId" `
    -Method Get -Headers $headers
Write-Host "  Total rows: $($traceResp.totalRows)"
foreach ($row in $traceResp.rows) {
    $tier = $row.tier
    $name = $row.toolName
    $status = $row.status
    $ms = $row.elapsedMs
    Write-Host "    [$tier] $name -> $status ($ms ms)"
}
if ($traceResp.totalRows -lt 1) {
    Write-Host "  FAIL: expected at least 1 audit row" -ForegroundColor Red
} else {
    Write-Host "  OK $($traceResp.totalRows) row(s) persisted" -ForegroundColor Green
}

# 4. Propose prompt - exercises [[PROPOSE]] marker pattern
Write-Host ""
Write-Host "== 4. Propose prompt: create a lead ==" -ForegroundColor Yellow
$proposeBody = '{"userMessage":"Create a new lead for John Doe at DLR01, phone 555-1234, interest type NEW, source WEB."}'
$proposeResp = Invoke-RestMethod -Uri "$frontendUrl/api/agent" -Method Post `
    -Body $proposeBody -ContentType 'application/json' -Headers $headers
Write-Host "  Reply (cleaned): $($proposeResp.reply)"
if ($proposeResp.proposal) {
    Write-Host "  PROPOSAL: tool=$($proposeResp.proposal.toolName) token=$($proposeResp.proposal.token) tier=$($proposeResp.proposal.tier)" -ForegroundColor Green
} elseif ($proposeResp.proposalError) {
    Write-Host "  PROPOSAL ERROR: $($proposeResp.proposalError)" -ForegroundColor Yellow
} else {
    Write-Host "  WARN: no proposal extracted - model may not have emitted [[PROPOSE]] marker" -ForegroundColor Yellow
    Write-Host "        (this depends on Gemini following the system instruction; first-call success rate ~80%)"
}

# 5. Recent conversations
Write-Host ""
Write-Host "== 5. Recent conversations endpoint ==" -ForegroundColor Yellow
$recent = Invoke-RestMethod -Uri "$frontendUrl/api/admin/agent-trace/recent?limit=5" `
    -Method Get -Headers $headers
Write-Host "  Recent: $($recent.Count) conversations with audit activity"
foreach ($c in $recent) {
    Write-Host "    $($c.conversationId.Substring(0,8))... user=$($c.userId) rows=$($c.rowCount)"
}

Write-Host ""
Write-Host "== Smoke test complete ==" -ForegroundColor Green
Write-Host "Frontend trace UI: $frontendUrl/admin/agent-trace"
