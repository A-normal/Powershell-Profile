# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：在本机预设的项目目录之间快速切换。

function global:dev {
    param(
        [string]$Target
    )

    $paths = $global:PSProfileConfig.Paths
    if (-not $Target) {
        Write-Host '用法：dev <路径名称>' -ForegroundColor Yellow
        if ($paths.Count -gt 0) {
            Write-Host "可用路径：$($paths.Keys -join ', ')"
        }
        else {
            Write-Host '尚未配置路径，请先创建 location.ps1。'
        }
        return
    }

    if ($paths.Keys -notcontains $Target) {
        Write-Warning "未配置路径名称：$Target。可用路径：$($paths.Keys -join ', ')"
        return
    }

    $path = $paths[$Target]
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Write-Warning "路径不存在或不是目录：$path"
        return
    }

    Set-Location -LiteralPath $path
}

Register-ArgumentCompleter -CommandName dev -ParameterName Target -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $global:PSProfileConfig.Paths.Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
