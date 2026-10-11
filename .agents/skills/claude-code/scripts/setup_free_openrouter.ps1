<#
.SYNOPSIS
    Configures Claude Code to run 100% FREE using verified active OpenRouter free models.

.DESCRIPTION
    Points Claude Code to currently active OpenRouter :free models:
    - Sonnet Role  -> cohere/north-mini-code:free (Specialized coding model)
    - Opus Role    -> nvidia/nemotron-3-super-120b-a12b:free (120B reasoning model)
    - Haiku Role   -> liquid/lfm-2.5-2.6b:free (Fast lightweight model)
    - Subagents    -> cohere/north-mini-code:free

.PARAMETER ApiKey
    Your free OpenRouter API key from https://openrouter.ai/settings/keys
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY
)

# 1. Ensure Claude is available in current session PATH
$localBin = if ($env:USERPROFILE) { "$env:USERPROFILE\.local\bin" } else { "$env:HOME/.local/bin" }
if ($env:Path -notlike "*$localBin*") {
    $env:Path = "$localBin;$env:Path"
}

# 2. Acquire Key
if (-not $ApiKey) {
    if ($env:OPENROUTER_API_KEY -and $env:OPENROUTER_API_KEY.StartsWith("sk-or")) {
        $ApiKey = $env:OPENROUTER_API_KEY
    } elseif ($env:ANTHROPIC_AUTH_TOKEN -and $env:ANTHROPIC_AUTH_TOKEN.StartsWith("sk-or")) {
        $ApiKey = $env:ANTHROPIC_AUTH_TOKEN
    } else {
        Write-Host "Please provide your OpenRouter API Key (get one free at https://openrouter.ai/settings/keys)" -ForegroundColor Yellow
        $ApiKey = Read-Host "Enter OpenRouter API Key (sk-or-...)"
    }
}

# 3. OpenRouter Gateway Config
$env:OPENROUTER_API_KEY = $ApiKey
$env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
$env:ANTHROPIC_AUTH_TOKEN = $ApiKey
$env:ANTHROPIC_API_KEY = "" # Must be explicitly empty
$env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"

# 4. Verified Active Free Models (:free)
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "cohere/north-mini-code:free"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL   = "nvidia/nemotron-3-super-120b-a12b:free"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL  = "liquid/lfm-2.5-2.6b:free"
$env:ANTHROPIC_DEFAULT_FABLE_MODEL  = "nvidia/nemotron-3-super-120b-a12b:free"
$env:CLAUDE_CODE_SUBAGENT_MODEL     = "cohere/north-mini-code:free"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   Claude Code Configured for Verified FREE Models!       " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Coding Model (Sonnet) : cohere/north-mini-code:free"
Write-Host "Reasoning (Opus)      : nvidia/nemotron-3-super-120b-a12b:free"
Write-Host "Fast Model (Haiku)    : liquid/lfm-2.5-2.6b:free"
Write-Host "Daily Free Quota      : 50 free requests/day"
Write-Host ""
Write-Host "NEXT STEP: Run claude in this terminal:" -ForegroundColor Cyan
Write-Host "  claude" -ForegroundColor Yellow
