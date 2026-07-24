# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：常用 Git 操作的快捷命令。

function global:g {
    param(
        [string]$Command,
        [string]$Arg
    )

    if (-not $Command) {
        Write-Host '用法：g <f|sync|vv|sw> [参数]' -ForegroundColor Yellow
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning '找不到 git 命令；请检查 Git 是否已安装并加入 PATH。'
        return
    }

    switch ($Command) {
        'f' { & git fetch --all --prune }
        'sync' {
            & git fetch --all --prune
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'git fetch 失败，已停止同步。'
                return
            }
            & git pull --ff-only
        }
        'vv' { & git branch -vv }
        'sw' {
            if (-not $Arg) {
                Write-Host '用法：g sw <分支名称>' -ForegroundColor Yellow
                return
            }
            & git switch -- $Arg
        }
        default {
            Write-Warning "未知的 Git 子命令：$Command"
            Write-Host '用法：g <f|sync|vv|sw> [参数]' -ForegroundColor Yellow
        }
    }
}

Register-ArgumentCompleter -CommandName g -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    'f', 'sync', 'vv', 'sw' |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
