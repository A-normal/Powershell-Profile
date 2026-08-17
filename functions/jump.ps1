# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：根据本机路径配置在常用目录之间快速切换。

function global:j {
    param(
        [string]$Target
    )

    if ($args.Count -gt 0) {
        Write-Warning 'j 不接受额外参数。'
        Write-Host '用法：j <路径名称>' -ForegroundColor Yellow
        return
    }

    $paths = $global:PSProfileConfig.Paths
    if (-not $Target) {
        Write-Host '用法：j <路径名称>' -ForegroundColor Yellow
        if ($paths.Count -gt 0) {
            Write-Host "可用路径：$($paths.Keys -join ', ')"
        }
        else {
            Write-Host '尚未配置路径，请先创建 location.ps1。'
        }
        return
    }

    if (-not ($paths -is [System.Collections.IDictionary]) -or -not $paths.Contains($Target)) {
        Write-Warning "未配置路径名称：$Target。可用路径：$($paths.Keys -join ', ')"
        return
    }

    $path = [string]$paths[$Target]
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Write-Warning "路径不存在或不是目录：$path"
        return
    }

    Set-Location -LiteralPath $path
}

Register-ArgumentCompleter -CommandName j -ParameterName Target -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $global:PSProfileConfig.Paths.Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
