<#
.SYNOPSIS
    Queries OpenRouter's /api/v1/key endpoint to inspect remaining credits, budgets, and rate limits.

.PARAMETER ApiKey
    Optional OpenRouter API key. If omitted, uses $env:OPENROUTER_API_KEY or prompts.

.EXAMPLE
    .\check_key_limits.ps1
    .\check_key_limits.ps1 -ApiKey "sk-or-v1-..."
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY
)

if (-not $ApiKey) {
    if ($env:ANTHROPIC_AUTH_TOKEN -and $env:ANTHROPIC_AUTH_TOKEN.StartsWith("sk-or")) {
        $ApiKey = $env:ANTHROPIC_AUTH_TOKEN
    } else {
        $ApiKey = Read-Host "Enter OpenRouter API Key (sk-or-...)"
    }
}

if (-not $ApiKey) {
    Write-Error "No OpenRouter API Key found."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $ApiKey"
    "HTTP-Referer"  = "https://github.com/Laxmansai4096/Brd-gen"
    "X-Title"       = "Claude Code - Limits Check"
}

try {
    $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/key" -Headers $headers -Method Get

    $keyData = $response.data
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "          OpenRouter Key & Budget Status                  " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Label               : $($keyData.label)"
    Write-Host "Free Tier Account   : $($keyData.is_free_tier)"
    Write-Host "All-time Usage      : `$$([math]::Round($keyData.usage, 4))"
    Write-Host "Daily Usage (UTC)   : `$$([math]::Round($keyData.usage_daily, 4))"
    Write-Host "Weekly Usage (UTC)  : `$$([math]::Round($keyData.usage_weekly, 4))"
    Write-Host "Monthly Usage (UTC) : `$$([math]::Round($keyData.usage_monthly, 4))"
    Write-Host "----------------------------------------------------------"

    if ($null -ne $keyData.limit) {
        Write-Host "Key Limit           : `$$($keyData.limit)"
        Write-Host "Key Remaining       : `$$($keyData.limit_remaining)"
    } else {
        Write-Host "Key Limit           : Unlimited (Account balance applies)"
    }

    if ($null -ne $keyData.effective_budget) {
        $eff = $keyData.effective_budget
        Write-Host "Effective Budget    : $($eff.scope) (Limit: `$$($eff.limit_usd), Remaining: `$$($eff.remaining_usd))" -ForegroundColor Yellow
        Write-Host "Resets At           : $($eff.resets_at)"
    }

    if ($null -ne $keyData.free_model_daily_requests) {
        $free = $keyData.free_model_daily_requests
        Write-Host "Free Model Quota    : $($free.remaining) / $($free.limit) remaining today"
    }
    Write-Host "==========================================================" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to query OpenRouter key info: $_"
}
