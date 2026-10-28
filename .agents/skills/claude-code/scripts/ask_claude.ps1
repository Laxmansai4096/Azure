param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Prompt,

    [Parameter(Mandatory=$false)]
    [string]$FilePath = "",

    [Parameter(Mandatory=$false)]
    [string]$Model = "",

    [Parameter(Mandatory=$false)]
    [string]$ApiKey = ""
)

# 1. Resolve API Key
if (-not $ApiKey) {
    if ($env:OPENROUTER_API_KEY) {
        $ApiKey = $env:OPENROUTER_API_KEY
    } else {
        $envFile = Join-Path $PSScriptRoot "..\..\..\..\.env.local"
        if (Test-Path $envFile) {
            $lines = Get-Content $envFile
            foreach ($line in $lines) {
                if ($line -match "^\s*OPENROUTER_API_KEY\s*=\s*(.+)$") {
                    $ApiKey = $matches[1].Trim()
                    break
                }
            }
        }
    }
}

if (-not $ApiKey) {
    Write-Error "No OpenRouter API key found. Pass -ApiKey or add OPENROUTER_API_KEY to .env.local"
    exit 1
}

# 2. Prepare Context from File
$fullPrompt = $Prompt
if ($FilePath -and (Test-Path $FilePath)) {
    $fileContent = Get-Content -Path $FilePath -Raw
    $fileName = Split-Path $FilePath -Leaf
    $fullPrompt = $Prompt + [Environment]::NewLine + [Environment]::NewLine + "--- File: " + $fileName + " ---" + [Environment]::NewLine + $fileContent
}

# 3. Model Selection
$primaryModel = if ($Model) { $Model } else { "anthropic/claude-sonnet-4.5" }
$freeFallbackModel = "cohere/north-mini-code:free"

$headers = @{
    "Authorization" = "Bearer $ApiKey"
    "Content-Type"  = "application/json"
    "HTTP-Referer"  = "https://github.com/Laxmansai4096/claude"
    "X-Title"       = "Antigravity Zero-Install Claude Bridge"
}

function Call-OpenRouter([string]$targetModel) {
    $payloadObj = @{
        model = $targetModel
        messages = @(
            @{ role = "user"; content = $fullPrompt }
        )
    }
    $jsonPayload = $payloadObj | ConvertTo-Json -Depth 5
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)
    return Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $utf8Bytes -ContentType "application/json; charset=utf-8"
}

try {
    Write-Host "[Consulting Model: $primaryModel]" -ForegroundColor Cyan
    $res = Call-OpenRouter -targetModel $primaryModel
    $reply = $res.choices[0].message.content
    Write-Host "`n=== Response from $primaryModel ===" -ForegroundColor Green
    Write-Output $reply
} catch {
    $errObj = $null
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        if ($stream) {
            $reader = New-Object System.IO.StreamReader($stream)
            $errBody = $reader.ReadToEnd()
            $errObj = $errBody | ConvertFrom-Json
        }
    } catch {}

    $statusCode = 0
    if ($errObj -and $errObj.error -and $errObj.error.code) {
        $statusCode = [int]$errObj.error.code
    }

    if (($statusCode -eq 402 -or $statusCode -eq 404) -and ($primaryModel -ne $freeFallbackModel)) {
        Write-Warning "Primary model ($primaryModel) returned code $statusCode ($($errObj.error.message))"
        Write-Host "[Falling back to Free Model: $freeFallbackModel]" -ForegroundColor Yellow
        try {
            $fallbackRes = Call-OpenRouter -targetModel $freeFallbackModel
            $reply = $fallbackRes.choices[0].message.content
            Write-Host "`n=== Response from $freeFallbackModel ===" -ForegroundColor Green
            Write-Output $reply
        } catch {
            Write-Error "Fallback model failed: $_"
        }
    } else {
        if ($errObj -and $errObj.error -and $errObj.error.message) {
            Write-Error "API Error: $($errObj.error.message)"
        } else {
            Write-Error "Request failed: $_"
        }
    }
}
