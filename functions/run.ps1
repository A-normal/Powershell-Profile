# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：启动本机预先配置的应用或运行环境。

function global:run {
    param(
        [string]$Target,
        [string]$Action
    )

    if ($args.Count -gt 0) {
        Write-Warning 'run 不接受额外参数。'
        Write-Host '用法：run <目标> [动作]' -ForegroundColor Yellow
        return
    }

    $targets = $global:PSProfileConfig.RunTargets
    if (-not $Target) {
        Write-Host '用法：run <目标> [动作]' -ForegroundColor Yellow
        if ($targets.Count -gt 0) {
            Write-Host "可用目标：$($targets.Keys -join ', ')"
        }
        else {
            Write-Host '尚未配置运行目标，请先创建 tasks.ps1。'
        }
        return
    }

    if (-not ($targets -is [System.Collections.IDictionary]) -or -not $targets.Contains($Target)) {
        Write-Warning "未配置运行目标：$Target。可用目标：$($targets.Keys -join ', ')"
        return
    }

    $targetConfig = $targets[$Target]
    if (-not ($targetConfig -is [System.Collections.IDictionary]) -or
        -not $targetConfig.Contains('Actions') -or
        -not ($targetConfig['Actions'] -is [System.Collections.IDictionary])) {
        Write-Warning "运行目标配置格式不正确：$Target"
        return
    }

    $actions = $targetConfig['Actions']
    if (-not $Action -and $targetConfig.Contains('DefaultAction')) {
        $Action = [string]$targetConfig['DefaultAction']
    }

    if (-not $Action) {
        Write-Host '用法：run <目标> [动作]' -ForegroundColor Yellow
        Write-Host "目标 $Target 的可用动作：$($actions.Keys -join ', ')"
        return
    }

    if (-not $actions.Contains($Action)) {
        Write-Warning "目标 $Target 未配置动作：$Action。可用动作：$($actions.Keys -join ', ')"
        return
    }

    $pathKey = if ($targetConfig.Contains('PathKey')) { [string]$targetConfig['PathKey'] } else { $null }
    Invoke-PSProfileTask -Task $actions[$Action] -DefaultPathKey $pathKey
}

Register-ArgumentCompleter -CommandName run -ParameterName Target -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $global:PSProfileConfig.RunTargets.Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Register-ArgumentCompleter -CommandName run -ParameterName Action -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $target = [string]$fakeBoundParameters['Target']
    $targets = $global:PSProfileConfig.RunTargets
    if (-not $target -or -not ($targets -is [System.Collections.IDictionary]) -or
        -not $targets.Contains($target)) {
        return
    }

    $targetConfig = $targets[$target]
    if (-not ($targetConfig -is [System.Collections.IDictionary]) -or
        -not $targetConfig.Contains('Actions') -or
        -not ($targetConfig['Actions'] -is [System.Collections.IDictionary])) {
        return
    }

    $targetConfig['Actions'].Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
