# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：在本机项目目录中执行预先配置的开发任务。

function global:dev {
    param(
        [string]$Project,
        [string]$Action
    )

    if ($args.Count -gt 0) {
        Write-Warning 'dev 不接受额外参数。'
        Write-Host '用法：dev <项目> <动作>' -ForegroundColor Yellow
        return
    }

    $projects = $global:PSProfileConfig.Development
    if (-not $Project) {
        Write-Host '用法：dev <项目> <动作>' -ForegroundColor Yellow
        if ($projects.Count -gt 0) {
            Write-Host "可用项目：$($projects.Keys -join ', ')"
        }
        else {
            Write-Host '尚未配置开发任务，请先创建 tasks.ps1。'
        }
        return
    }

    if (-not ($projects -is [System.Collections.IDictionary]) -or -not $projects.Contains($Project)) {
        Write-Warning "未配置开发项目：$Project。可用项目：$($projects.Keys -join ', ')"
        return
    }

    $projectConfig = $projects[$Project]
    if (-not ($projectConfig -is [System.Collections.IDictionary]) -or
        -not $projectConfig.Contains('Actions') -or
        -not ($projectConfig['Actions'] -is [System.Collections.IDictionary])) {
        Write-Warning "开发项目配置格式不正确：$Project"
        return
    }

    $actions = $projectConfig['Actions']
    if (-not $Action) {
        Write-Host '用法：dev <项目> <动作>' -ForegroundColor Yellow
        Write-Host "项目 $Project 的可用动作：$($actions.Keys -join ', ')"
        return
    }

    if (-not $actions.Contains($Action)) {
        Write-Warning "项目 $Project 未配置动作：$Action。可用动作：$($actions.Keys -join ', ')"
        return
    }

    $pathKey = if ($projectConfig.Contains('PathKey')) { [string]$projectConfig['PathKey'] } else { $null }
    Invoke-PSProfileTask -Task $actions[$Action] -DefaultPathKey $pathKey
}

Register-ArgumentCompleter -CommandName dev -ParameterName Project -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $global:PSProfileConfig.Development.Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Register-ArgumentCompleter -CommandName dev -ParameterName Action -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $project = [string]$fakeBoundParameters['Project']
    $projects = $global:PSProfileConfig.Development
    if (-not $project -or -not ($projects -is [System.Collections.IDictionary]) -or
        -not $projects.Contains($project)) {
        return
    }

    $projectConfig = $projects[$project]
    if (-not ($projectConfig -is [System.Collections.IDictionary]) -or
        -not $projectConfig.Contains('Actions') -or
        -not ($projectConfig['Actions'] -is [System.Collections.IDictionary])) {
        return
    }

    $projectConfig['Actions'].Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
