# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：PowerShell Profile 主入口，按配置开关加载本机配置和功能脚本。

$global:PSProfileRoot = $PSScriptRoot

$envFile = Join-Path $PSScriptRoot 'env.ps1'
if (Test-Path -LiteralPath $envFile) {
    . $envFile
}
else {
    Write-Warning "缺少可同步配置文件：$envFile"
    return
}

# 重载时先清理本 Profile 管理的可选命令，避免关闭功能后残留旧定义。
$managedCommands = @('dev', 'g', 'run')
foreach ($managedCommand in $managedCommands) {
    Remove-Item -LiteralPath "Function:\$managedCommand" -Force -ErrorAction SilentlyContinue
}

# 路径只属于 Dev 功能；关闭 Dev 时不读取任何本机路径配置。
$locationFile = Join-Path $PSScriptRoot 'location.ps1'
if ($global:PSProfileConfig.Features.Dev -and (Test-Path -LiteralPath $locationFile)) {
    . $locationFile
}

$functionsPath = Join-Path $PSScriptRoot 'functions'
$coreFile = Join-Path $PSScriptRoot 'core\core.ps1'
if (Test-Path -LiteralPath $coreFile -PathType Leaf) {
    . $coreFile
}
else {
    Write-Warning "缺少 Profile 核心命令脚本：$coreFile"
}

$featureFiles = [ordered]@{
    Dev        = 'dev.ps1'
    Git        = 'git.ps1'
    Run        = 'run.ps1'
    PSReadLine = 'psreadline.ps1'
}

foreach ($featureName in $featureFiles.Keys) {
    if (-not $global:PSProfileConfig.Features[$featureName]) {
        continue
    }

    $featureFile = Join-Path $functionsPath $featureFiles[$featureName]
    if (Test-Path -LiteralPath $featureFile -PathType Leaf) {
        . $featureFile
    }
    else {
        Write-Warning "已启用功能 $featureName，但缺少脚本：$featureFile"
    }
}
