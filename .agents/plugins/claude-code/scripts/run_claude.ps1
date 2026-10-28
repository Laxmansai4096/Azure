<#
.SYNOPSIS
    Bridge script allowing Antigravity to delegate tasks directly to Claude Code.
    Supports both native Claude CLI and Zero-Install OpenRouter API mode for corporate environments.

.PARAMETER Prompt
    The prompt or instruction to send to Claude.

.EXAMPLE
    .\run_claude.ps1 -Prompt "Review app.py and list potential performance bottlenecks"
#>

param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string]$Prompt
)

# 1. Check if Claude binary is installed
$claudeBin = $null
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCmd) {
    $claudeBin = $claudeCmd.Source
} elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.local\bin\claude.exe")) {
    $claudeBin = "$env:USERPROFILE\.local\bin\claude.exe"
} elseif ($env:HOME -and (Test-Path "$env:HOME/.local/bin/claude")) {
    $claudeBin = "$env:HOME/.local/bin/claude"
}

# 2. If Claude binary is NOT installed, seamlessly use the Zero-Install API Bridge!
if (-not $claudeBin) {
    Write-Host "[Zero-Install Mode] Claude CLI binary not detected. Routing request through native OpenRouter bridge..." -ForegroundColor Yellow
    $askScript = Join-Path $PSScriptRoot "..\..\..\skills\claude-code\scripts\ask_claude.ps1"
    if (-not (Test-Path $askScript)) {
        $askScript = Join-Path $PSScriptRoot "..\scripts\ask_claude.ps1"
    }
    if (Test-Path $askScript) {
        & $askScript -Prompt $Prompt
        exit $LASTEXITCODE
    } else {
        Write-Error "Could not find ask_claude.ps1 bridge script."
        exit 1
    }
}

# 3. If Claude binary IS installed, run through Claude Code CLI
if (-not $env:ANTHROPIC_BASE_URL) {
    $env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
}
if (-not $env:ANTHROPIC_AUTH_TOKEN) {
    if ($env:OPENROUTER_API_KEY) {
        $env:ANTHROPIC_AUTH_TOKEN = $env:OPENROUTER_API_KEY
    } else {
        $envFile = Join-Path $PSScriptRoot "..\..\..\..\.env.local"
        if (Test-Path $envFile) {
            Get-Content $envFile | ForEach-Object {
                if ($_ -match "^\s*OPENROUTER_API_KEY\s*=\s*(.+)$") {
                    $env:ANTHROPIC_AUTH_TOKEN = $matches[1].Trim()
                }
            }
        }
    }
}
$env:ANTHROPIC_API_KEY = ""

Write-Host ">>> Antigravity delegating to Claude Code CLI..." -ForegroundColor Cyan
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $claudeBin
$processInfo.Arguments = "-p `"$Prompt`" --dangerously-skip-permissions"
$processInfo.RedirectStandardInput = $true
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::Start($processInfo)
$process.StandardInput.Close()
$output = $process.StandardOutput.ReadToEnd()
$errorOutput = $process.StandardError.ReadToEnd()
$process.WaitForExit()

if ($output) {
    Write-Output $output
}
if ($process.ExitCode -ne 0 -and $errorOutput) {
    Write-Warning $errorOutput
}
