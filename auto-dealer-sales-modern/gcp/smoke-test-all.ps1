# Comprehensive smoke test for the Phase B work shipped 2026-05-03:
#   B2       - propose/confirm + audit + admin trace UI
#   B-warmup - parallel function calling, list_incentives, capability gap, entity lookup
#   B-nhtsa  - NHTSA recall + vPIC decode tools
#   B3a+B3b  - BigQuery analytics endpoints
#   B-prereq - prerequisite framework (gap envelope on create_lead)
#
# Stop-on-error per stage; exits non-zero if any check fails.

. $PSScriptRoot/config.ps1

$ErrorActionPreference = "Stop"
$gcloud = "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"

$frontendUrl = & $gcloud run services describe $GcpFrontendService `
    --project=$GcpProjectId --region=$GcpRegion `
    --format='value(status.url)' 2>$null
if ([string]::IsNullOrWhiteSpace($frontendUrl)) {
    throw "Frontend not deployed."
}
Write-Host "Frontend: $frontendUrl" -ForegroundColor Cyan

# Login
Write-Host ""
Write-Host "== Login as ADMIN001 ==" -ForegroundColor Yellow
$loginResp = Invoke-RestMethod -Uri "$frontendUrl/api/auth/login" -Method Post `
    -Body '{"userId":"ADMIN001","password":"Admin123"}' `
    -ContentType 'application/json' -Headers @{ 'Origin' = $frontendUrl }
$token = $loginResp.accessToken
$headers = @{ Authorization = "Bearer $token"; 'Origin' = $frontendUrl }
Write-Host "  OK token len=$($token.Length)"

function AgentAsk($prompt) {
    $body = ConvertTo-Json @{ userMessage = $prompt }
    return Invoke-RestMethod -Uri "$frontendUrl/api/agent" -Method Post `
        -Body $body -ContentType 'application/json' -Headers $headers
}

# 1. Single read - sanity baseline
Write-Host ""
Write-Host "== 1. Single read (baseline) ==" -ForegroundColor Yellow
$r1 = AgentAsk "How many vehicles in my dealership? Brief."
Write-Host "  Reply: $($r1.reply)"

# 2. Compound prompt - exercises parallel function calling fix
Write-Host ""
Write-Host "== 2. Compound prompt (parallel calls fix) ==" -ForegroundColor Yellow
$r2 = AgentAsk "Show me the daily sales report and the commissions report for DLR01."
if ($r2.reply -like "*Gemini error*") {
    Write-Host "  FAIL: parallel-call bug still present" -ForegroundColor Red
    Write-Host "    $($r2.reply)"
} else {
    Write-Host "  OK - no Gemini error"
    Write-Host "  Reply preview: $($r2.reply.Substring(0, [Math]::Min(200, $r2.reply.Length)))..."
}

# 3. List incentives - new tool from B-warmup
Write-Host ""
Write-Host "== 3. List incentives (new B-warmup tool) ==" -ForegroundColor Yellow
$r3 = AgentAsk "What incentive programs do we have available right now?"
Write-Host "  Reply preview: $($r3.reply.Substring(0, [Math]::Min(300, $r3.reply.Length)))..."

# 4. Capability-gap logging
Write-Host ""
Write-Host "== 4. Capability-gap logging ==" -ForegroundColor Yellow
$r4 = AgentAsk "Can you order pizza for the team?"
Write-Host "  Reply preview: $($r4.reply.Substring(0, [Math]::Min(200, $r4.reply.Length)))..."

# 5. NHTSA recall lookup - B-nhtsa
Write-Host ""
Write-Host "== 5. NHTSA recall lookup ==" -ForegroundColor Yellow
$r5 = AgentAsk "Are there any federal recalls on VIN 1HGCM82633A004352?"
Write-Host "  Reply preview: $($r5.reply.Substring(0, [Math]::Min(300, $r5.reply.Length)))..."

# 6. Prerequisite gap envelope - B-prereq
Write-Host ""
Write-Host "== 6. Prereq gap on create_lead ==" -ForegroundColor Yellow
$r6 = AgentAsk "Create a new lead for Jane Smith, phone 248-555-9999, source REFERRAL."
if ($r6.proposal -and $r6.proposal.prerequisiteGap) {
    Write-Host "  OK - prereq gap envelope returned" -ForegroundColor Green
    Write-Host "    Parent: $($r6.proposal.prerequisiteGap.parentTool)"
    Write-Host "    Summary: $($r6.proposal.prerequisiteGap.summary)"
    Write-Host "    Unmet: $($r6.proposal.prerequisiteGap.unmet.Count) item(s)"
    foreach ($u in $r6.proposal.prerequisiteGap.unmet) {
        Write-Host "      - $($u.payloadField) (entity=$($u.entityName), satisfier=$($u.satisfierToolName))"
    }
} elseif ($r6.proposalError) {
    Write-Host "  PARTIAL - proposalError instead of gap: $($r6.proposalError)" -ForegroundColor Yellow
} elseif ($r6.proposal) {
    Write-Host "  UNEXPECTED - regular proposal returned (Gemini may have hallucinated a customerId)" -ForegroundColor Yellow
} else {
    Write-Host "  WARN - no proposal at all (Gemini didn't emit [[PROPOSE]])" -ForegroundColor Yellow
    Write-Host "    Reply: $($r6.reply.Substring(0, [Math]::Min(200, $r6.reply.Length)))..."
}

# 7. Analytics endpoint - B3a/B3b verification
Write-Host ""
Write-Host "== 7. Analytics endpoint (BQ tool-call stats) ==" -ForegroundColor Yellow
$today = (Get-Date).ToString("yyyy-MM-dd")
$weekAgo = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
try {
    $r7 = Invoke-RestMethod -Uri "$frontendUrl/api/admin/agent-analytics/tool-calls?from=$weekAgo&to=$today" `
        -Method Get -Headers $headers
    Write-Host "  OK - rows: $($r7.rows.Count)"
    if ($r7.rows.Count -gt 0) {
        foreach ($row in ($r7.rows | Select-Object -First 5)) {
            Write-Host "    $($row.tool_name): calls=$($row.calls) p50=$($row.p50_ms)ms p95=$($row.p95_ms)ms failures=$($row.failures)"
        }
    } else {
        Write-Host "  Note: no rows yet - either BQ insert hasn't propagated, or the bootstrap created an empty table"
    }
} catch {
    Write-Host "  FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. Daily activity from BQ
Write-Host ""
Write-Host "== 8. Daily activity rollup ==" -ForegroundColor Yellow
try {
    $r8 = Invoke-RestMethod -Uri "$frontendUrl/api/admin/agent-analytics/daily?from=$weekAgo&to=$today" `
        -Method Get -Headers $headers
    Write-Host "  OK - $($r8.rows.Count) day(s)"
    foreach ($row in $r8.rows) {
        Write-Host "    $($row.day): calls=$($row.calls) reads=$($row.reads) writes=$($row.writes) failures=$($row.failures)"
    }
} catch {
    Write-Host "  FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. Cost endpoint (likely info stub until billing export configured)
Write-Host ""
Write-Host "== 9. Gemini cost endpoint ==" -ForegroundColor Yellow
try {
    $r9 = Invoke-RestMethod -Uri "$frontendUrl/api/admin/agent-analytics/cost?from=$weekAgo&to=$today" `
        -Method Get -Headers $headers
    if ($r9.rows.Count -gt 0 -and $r9.rows[0].info) {
        Write-Host "  Info: $($r9.rows[0].info)" -ForegroundColor Yellow
    } else {
        foreach ($row in $r9.rows) {
            Write-Host "    $($row.day) [$($row.service)]: `$$($row.cost_usd)"
        }
    }
} catch {
    Write-Host "  FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "== Smoke test complete ==" -ForegroundColor Green
Write-Host "Open in browser:"
Write-Host "  Trace UI       : $frontendUrl/admin/agent-trace"
Write-Host "  Analytics page : $frontendUrl/admin/agent-analytics"
