$envFile = Join-Path $PSScriptRoot 'env.ps1'
if (Test-Path -LiteralPath $envFile) {
    . $envFile
}
else {
    Write-Warning "Missing local configuration: $envFile"
}

# 路径只属于本机，不与仓库同步；location.ps1 由 .gitignore 排除。
# 必须在加载功能脚本前读取，dev 和启动目录都会使用其中的路径变量。
$locationFile = Join-Path $PSScriptRoot 'location.ps1'
if (Test-Path -LiteralPath $locationFile) {
    . $locationFile
}
elseif ($env:PS_PROFILE_ENABLE_DEV -ne 'false') {
    Write-Warning "Missing local path configuration: $locationFile"
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
if ($env:PS_PROFILE_ENABLE_UTILS -ne 'false') {
    . (Join-Path $functionsPath 'utils.ps1')
}

if ($env:PS_PROFILE_STARTUP_PATH -and (Test-Path -LiteralPath $env:PS_PROFILE_STARTUP_PATH -PathType Container)) {
    Set-Location -LiteralPath $env:PS_PROFILE_STARTUP_PATH
}

Write-Host ""
Write-Host "🚀 PowerShell Ready" -ForegroundColor Green
Write-Host ""
