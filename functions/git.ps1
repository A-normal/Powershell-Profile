# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：常用 Git 操作的快捷命令。

function global:g {
    param(
        [string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    if (-not $Command) {
        Write-Host '用法：g <f|sync|vv|sw|swp>' -ForegroundColor Yellow
        Write-Host '      g r <v|a>'
        Write-Host '      g st <l|a|d|p>'
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning '找不到 git 命令；请检查 Git 是否已安装并加入 PATH。'
        return
    }

    switch ($Command) {
        'f' {
            if ($Arguments.Count -ne 0) {
                Write-Host '用法：g f' -ForegroundColor Yellow
                return
            }
            & git fetch --all --prune
        }
        'sync' {
            if ($Arguments.Count -ne 0) {
                Write-Host '用法：g sync' -ForegroundColor Yellow
                return
            }
            & git fetch --all --prune
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'git fetch 失败，已停止同步。'
                return
            }
            & git pull --ff-only
        }
        'vv' {
            if ($Arguments.Count -ne 0) {
                Write-Host '用法：g vv' -ForegroundColor Yellow
                return
            }
            & git branch -vv
        }
        'sw' {
            if ($Arguments.Count -ne 1 -or [string]::IsNullOrWhiteSpace($Arguments[0])) {
                Write-Host '用法：g sw <分支名称>' -ForegroundColor Yellow
                return
            }
            & git switch -- $Arguments[0]
        }
        'swp' {
            if ($Arguments.Count -ne 1 -or [string]::IsNullOrWhiteSpace($Arguments[0])) {
                Write-Host '用法：g swp <分支名称>' -ForegroundColor Yellow
                return
            }

            $branchName = $Arguments[0]
            & git switch -- $branchName
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'git switch 失败，已停止拉取。'
                return
            }

            & git pull --ff-only
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "已切换到分支 $branchName，但 git pull --ff-only 失败。"
            }
        }
        'r' {
            if ($Arguments.Count -eq 0) {
                Write-Host '用法：g r <v|a>' -ForegroundColor Yellow
                return
            }

            $remoteAction = $Arguments[0]
            $remoteArguments = @($Arguments | Select-Object -Skip 1)
            switch ($remoteAction) {
                'v' {
                    if ($remoteArguments.Count -ne 0) {
                        Write-Host '用法：g r v' -ForegroundColor Yellow
                        return
                    }
                    & git remote -v
                }
                'a' {
                    if ($remoteArguments.Count -ne 2 -or
                        [string]::IsNullOrWhiteSpace($remoteArguments[0]) -or
                        [string]::IsNullOrWhiteSpace($remoteArguments[1]) -or
                        $remoteArguments[0].StartsWith('-')) {
                        Write-Host '用法：g r a <远端名称> <URL>' -ForegroundColor Yellow
                        return
                    }
                    & git remote add $remoteArguments[0] $remoteArguments[1]
                }
                default {
                    Write-Warning "未知的 remote 动作：$remoteAction"
                    Write-Host '用法：g r <v|a>' -ForegroundColor Yellow
                }
            }
        }
        'st' {
            if ($Arguments.Count -eq 0) {
                Write-Host '用法：g st <l|a|d|p>' -ForegroundColor Yellow
                return
            }

            $stashAction = $Arguments[0]
            $stashArguments = @($Arguments | Select-Object -Skip 1)
            switch ($stashAction) {
                'l' {
                    if ($stashArguments.Count -ne 0) {
                        Write-Host '用法：g st l' -ForegroundColor Yellow
                        return
                    }
                    & git stash list
                }
                'a' {
                    if ($stashArguments.Count -gt 1 -or
                        ($stashArguments.Count -eq 1 -and $stashArguments[0] -notmatch '^\d+$')) {
                        Write-Host '用法：g st a [序号]' -ForegroundColor Yellow
                        return
                    }
                    if ($stashArguments.Count -eq 0) {
                        & git stash apply
                    }
                    else {
                        & git stash apply $stashArguments[0]
                    }
                }
                'd' {
                    if ($stashArguments.Count -ne 1 -or $stashArguments[0] -notmatch '^\d+$') {
                        Write-Host '用法：g st d <序号>' -ForegroundColor Yellow
                        return
                    }
                    & git stash drop $stashArguments[0]
                }
                'p' {
                    $message = ($stashArguments -join ' ').Trim()
                    if ([string]::IsNullOrWhiteSpace($message)) {
                        Write-Host '用法：g st p <说明>' -ForegroundColor Yellow
                        return
                    }
                    & git stash push -u -m $message
                }
                default {
                    Write-Warning "未知的 stash 动作：$stashAction"
                    Write-Host '用法：g st <l|a|d|p>' -ForegroundColor Yellow
                }
            }
        }
        default {
            Write-Warning "未知的 Git 子命令：$Command"
            Write-Host '用法：g <f|sync|vv|sw|swp>' -ForegroundColor Yellow
            Write-Host '      g r <v|a>'
            Write-Host '      g st <l|a|d|p>'
        }
    }
}

Register-ArgumentCompleter -CommandName g -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    'f', 'sync', 'vv', 'sw', 'swp', 'r', 'st' |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Register-ArgumentCompleter -CommandName g -ParameterName Arguments -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if ($commandAst.CommandElements.Count -gt 3 -or
        ($commandAst.CommandElements.Count -eq 3 -and [string]::IsNullOrEmpty($wordToComplete))) {
        return
    }

    $actions = switch ([string]$fakeBoundParameters['Command']) {
        'r' { 'v', 'a' }
        'st' { 'l', 'a', 'd', 'p' }
        default { @() }
    }

    $actions |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
