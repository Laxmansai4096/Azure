<#
.SYNOPSIS
    Configures environment variables for running Claude Code via OpenRouter in PowerShell.

.DESCRIPTION
    Sets the required Anthropic gateway variables to route Claude Code through OpenRouter:
    - ANTHROPIC_BASE_URL: https://openrouter.ai/api
    - ANTHROPIC_AUTH_TOKEN: <OpenRouter API Key>
    - ANTHROPIC_API_KEY: "" (blank to prevent direct Anthropic conflicts)
    - Default model configurations with 1M context markers

.EXAMPLE
    .\setup_openrouter.ps1 -ApiKey "sk-or-v1-..."
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY
)

if (-not $ApiKey) {
    Write-Host "Please provide an OpenRouter API Key via -ApiKey or set `$env:OPENROUTER_API_KEY." -ForegroundColor Yellow
    $ApiKey = Read-Host "Enter OpenRouter API Key (sk-or-...)"
}

if (-not $ApiKey) {
    Write-Error "No OpenRouter API key provided. Exiting."
    exit 1
}

# 1. Core OpenRouter Gateway Settings
$env:OPENROUTER_API_KEY = $ApiKey
$env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
$env:ANTHROPIC_AUTH_TOKEN = $ApiKey
$env:ANTHROPIC_API_KEY = "" # Must be explicitly empty
$env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"

# 2. Recommended Model Mappings (with 1M context window marker)
$env:ANTHROPIC_DEFAULT_FABLE_MODEL = "~anthropic/claude-fable-latest[1m]"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = "~anthropic/claude-opus-latest[1m]"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "~anthropic/claude-sonnet-latest[1m]"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "~anthropic/claude-haiku-latest"
$env:CLAUDE_CODE_SUBAGENT_MODEL = "~anthropic/claude-opus-latest[1m]"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Claude Code + OpenRouter Environment Successfully Set! " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "ANTHROPIC_BASE_URL : $env:ANTHROPIC_BASE_URL"
Write-Host "ANTHROPIC_AUTH_TOKEN : sk-or-...$( $ApiKey.Substring([Math]::Max(0, $ApiKey.Length - 6)) )"
Write-Host "ANTHROPIC_API_KEY    : [EMPTY]"
Write-Host "Gateway Discovery    : Enabled (1)"
Write-Host ""
Write-Host "To install Claude Code if not installed:" -ForegroundColor Cyan
Write-Host "  irm https://claude.ai/install.ps1 | iex" -ForegroundColor Gray
Write-Host "To start Claude Code:" -ForegroundColor Cyan
Write-Host "  claude" -ForegroundColor Gray
