# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：启动常用本地运行环境。

function global:run {
    param(
        [string]$Target,
        [string]$Mode
    )

    if (-not $Target) {
        Write-Host '用法：run wsl [user]' -ForegroundColor Yellow
        Write-Host '不带 user 时默认以 root 进入 WSL。'
        return
    }

    if ($Target -ne 'wsl') {
        Write-Warning "未知的运行目标：$Target"
        Write-Host '用法：run wsl [user]' -ForegroundColor Yellow
        return
    }

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Warning '找不到 wsl 命令；请检查 WSL 是否已启用。'
        return
    }

    if (-not $Mode) {
        & wsl -u root
        return
    }

    if ($Mode -eq 'user') {
        & wsl
        return
    }

    Write-Warning "未知的 WSL 模式：$Mode"
    Write-Host '用法：run wsl [user]' -ForegroundColor Yellow
}

Register-ArgumentCompleter -CommandName run -ParameterName Target -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    if ('wsl' -like "$wordToComplete*") {
        [System.Management.Automation.CompletionResult]::new('wsl', 'wsl', 'ParameterValue', 'wsl')
    }
}

Register-ArgumentCompleter -CommandName run -ParameterName Mode -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    if ('user' -like "$wordToComplete*") {
        [System.Management.Automation.CompletionResult]::new('user', 'user', 'ParameterValue', 'user')
    }
}
