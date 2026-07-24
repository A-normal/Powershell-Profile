$envFile = Join-Path $PSScriptRoot 'env.ps1'
if (Test-Path -LiteralPath $envFile) {
    . $envFile
}
else {
    Write-Warning "Missing local configuration: $envFile"
}

$functionsPath = Join-Path $PSScriptRoot 'functions'

if ($env:PS_PROFILE_ENABLE_DEV -ne 'false') {
    . (Join-Path $functionsPath 'dev.ps1')
}
if ($env:PS_PROFILE_ENABLE_GIT -ne 'false') {
    . (Join-Path $functionsPath 'git.ps1')
}
if ($env:PS_PROFILE_ENABLE_RUN -ne 'false') {
    . (Join-Path $functionsPath 'run.ps1')
}

if ($env:PS_PROFILE_STARTUP_PATH -and (Test-Path -LiteralPath $env:PS_PROFILE_STARTUP_PATH -PathType Container)) {
    Set-Location -LiteralPath $env:PS_PROFILE_STARTUP_PATH
}

Write-Host ""
Write-Host "🚀 PowerShell Ready" -ForegroundColor Green
Write-Host ""