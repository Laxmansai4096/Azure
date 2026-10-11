<#
.SYNOPSIS
    Bridge script allowing Antigravity to delegate tasks directly to Claude Code.

.PARAMETER Prompt
    The prompt or instruction to send to Claude Code.

.EXAMPLE
    .\run_claude.ps1 -Prompt "Review app.py and list potential performance bottlenecks"
#>

param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string]$Prompt
)

# 1. Ensure Claude executable is available
$claudeBin = $null
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCmd) {
    $claudeBin = $claudeCmd.Source
} elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.local\bin\claude.exe")) {
    $claudeBin = "$env:USERPROFILE\.local\bin\claude.exe"
} elseif ($env:HOME -and (Test-Path "$env:HOME/.local/bin/claude")) {
    $claudeBin = "$env:HOME/.local/bin/claude"
} else {
    Write-Error "Claude Code binary not found. Run installer: Windows: irm https://claude.ai/install.ps1 | iex  OR  Unix: curl -fsSL https://claude.ai/install.sh | bash"
    exit 1
}

# 2. Ensure OpenRouter Environment
if (-not $env:ANTHROPIC_BASE_URL) {
    $env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
}
if (-not $env:ANTHROPIC_AUTH_TOKEN) {
    if ($env:OPENROUTER_API_KEY) {
        $env:ANTHROPIC_AUTH_TOKEN = $env:OPENROUTER_API_KEY
    } else {
        Write-Error "ANTHROPIC_AUTH_TOKEN or OPENROUTER_API_KEY is not set. Run .agents/skills/claude-code/scripts/setup_free_openrouter.ps1 first."
        exit 1
    }
}
$env:ANTHROPIC_API_KEY = ""

# Set default free models if not customized
if (-not $env:ANTHROPIC_DEFAULT_SONNET_MODEL) {
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "cohere/north-mini-code:free"
}
if (-not $env:ANTHROPIC_DEFAULT_OPUS_MODEL) {
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL = "nvidia/nemotron-3-super-120b-a12b:free"
}
if (-not $env:ANTHROPIC_DEFAULT_HAIKU_MODEL) {
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "liquid/lfm-2.5-2.6b:free"
}

# 3. Execute Claude Code non-interactively without stdin blocking
Write-Host ">>> Antigravity delegating to Claude Code..." -ForegroundColor Cyan
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $claudeBin
$processInfo.Arguments = "-p `"$Prompt`" --dangerously-skip-permissions"
$processInfo.RedirectStandardInput = $true
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::Start($processInfo)
$process.StandardInput.Close() # Close stdin to prevent 3s wait
$output = $process.StandardOutput.ReadToEnd()
$errorOutput = $process.StandardError.ReadToEnd()
$process.WaitForExit()

if ($output) {
    Write-Output $output
}
if ($process.ExitCode -ne 0 -and $errorOutput) {
    Write-Warning $errorOutput
}
