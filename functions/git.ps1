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
        Write-Host '用法：g <f|sync|vv|sw|swp|s>' -ForegroundColor Yellow
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
        's' {
            if ($Arguments.Count -ne 0) {
                Write-Host '用法：g s' -ForegroundColor Yellow
                return
            }
            & git status
        }
        'sync' {
            if ($Arguments.Count -ne 0) {
                Write-Host '用法：g sync' -ForegroundColor Yellow
                return
            }

            # 1. 全量获取远端分支映射
            & git fetch --all --prune
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'git fetch 失败，已停止同步。'
                return
            }

            # 2. 遍历本地分支及其 upstream
            $refOutput = @(& git for-each-ref --format='%(refname:short)%09%(objectname)%09%(upstream:short)%09%(upstream)%09%(upstream:track)' refs/heads)
            if ($refOutput.Count -eq 0 -or ($refOutput.Count -eq 1 -and [string]::IsNullOrWhiteSpace($refOutput[0]))) {
                Write-Host '未发现任何本地分支。' -ForegroundColor Yellow
                return
            }

            $currentBranch = (& git symbolic-ref --short -q HEAD)
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($currentBranch)) {
                $currentBranch = $null
            } else {
                $currentBranch = $currentBranch.Trim()
            }

            $records = [System.Collections.Generic.List[pscustomobject]]::new()

            foreach ($line in $refOutput) {
                if ([string]::IsNullOrWhiteSpace($line)) {
                    continue
                }

                $parts = $line.Split("`t")
                $branchName    = if ($parts.Count -gt 0) { $parts[0].Trim() } else { '' }
                $localSha      = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
                $upstreamShort = if ($parts.Count -gt 2) { $parts[2].Trim() } else { '' }
                $upstreamRef   = if ($parts.Count -gt 3) { $parts[3].Trim() } else { '' }
                $track         = if ($parts.Count -gt 4) { $parts[4].Trim() } else { '' }

                if ([string]::IsNullOrWhiteSpace($branchName)) {
                    continue
                }

                # 无上游跟踪分支
                if ([string]::IsNullOrWhiteSpace($upstreamRef)) {
                    $records.Add([pscustomobject]@{
                        Tag     = 'SKIP'
                        Branch  = $branchName
                        Message = '无上游跟踪分支'
                        Color   = 'DarkGray'
                    })
                    continue
                }

                # 检查上游引用是否存在 / 是否已被删除 (Gone)
                $upstreamSha = (& git rev-parse --verify --quiet "$upstreamRef^{commit}")
                if ($upstreamSha) {
                    $upstreamSha = $upstreamSha.Trim()
                }

                if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstreamSha)) {
                    $records.Add([pscustomobject]@{
                        Tag     = 'WARN'
                        Branch  = $branchName
                        Message = '远端上游分支已被删除 [gone]，已跳过'
                        Color   = 'Yellow'
                    })
                    continue
                }

                # 已是最新
                if ($localSha -eq $upstreamSha) {
                    $records.Add([pscustomobject]@{
                        Tag     = 'OK'
                        Branch  = $branchName
                        Message = '已是最新'
                        Color   = 'Green'
                    })
                    continue
                }

                # 3. 安全祖先判定（Fast-Forward Only）
                & git merge-base --is-ancestor $localSha $upstreamSha
                $isAncestor = ($LASTEXITCODE -eq 0)

                if ($isAncestor) {
                    # 4. 分流更新：本地为远端祖先，可安全快进更新
                    if ($branchName -eq $currentBranch) {
                        # 当前分支：通过 git merge --ff-only 同步更新工作区与索引
                        $mergeTarget = if ($upstreamShort) { $upstreamShort } else { $upstreamRef }
                        $null = & git merge --ff-only $mergeTarget 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            $records.Add([pscustomobject]@{
                                Tag     = 'UPDATED'
                                Branch  = $branchName
                                Message = '快进更新完成'
                                Color   = 'Green'
                            })
                        } else {
                            $records.Add([pscustomobject]@{
                                Tag     = 'FAIL'
                                Branch  = $branchName
                                Message = '当前分支快进更新失败，已跳过'
                                Color   = 'Red'
                            })
                        }
                    } else {
                        # 非当前分支：原子更新引用指针，不触碰工作区与索引
                        $null = & git update-ref "refs/heads/$branchName" $upstreamSha $localSha 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            $records.Add([pscustomobject]@{
                                Tag     = 'UPDATED'
                                Branch  = $branchName
                                Message = '快进更新完成'
                                Color   = 'Green'
                            })
                        } else {
                            $records.Add([pscustomobject]@{
                                Tag     = 'FAIL'
                                Branch  = $branchName
                                Message = '引用更新失败，已跳过'
                                Color   = 'Red'
                            })
                        }
                    }
                } else {
                    # 5. 异常防御：Ahead 或 Diverged
                    $trackDesc = if ($track) { $track.Trim() } else { '' }
                    $msg = if ($trackDesc -match 'ahead' -and $trackDesc -match 'behind') {
                        "分支已分叉 $trackDesc，已跳过"
                    } elseif ($trackDesc -match 'ahead') {
                        "包含本地未推送提交 $trackDesc，已跳过"
                    } else {
                        $aheadCount = (& git rev-list --count "$upstreamSha..$localSha")
                        if ($aheadCount) {
                            $aheadCount = $aheadCount.Trim()
                        }
                        if ($LASTEXITCODE -eq 0 -and [int]::TryParse($aheadCount, [ref]$null) -and [int]$aheadCount -gt 0) {
                            "包含本地未推送提交 [ahead $aheadCount]，已跳过"
                        } else {
                            '分支分叉或包含本地私有提交，已跳过'
                        }
                    }

                    $records.Add([pscustomobject]@{
                        Tag     = 'WARN'
                        Branch  = $branchName
                        Message = $msg
                        Color   = 'Yellow'
                    })
                }
            }

            # 输出汇总状态表
            Write-Host ''
            Write-Host '分支同步结果：' -ForegroundColor Cyan
            $maxLen = 8
            foreach ($r in $records) {
                if ($r.Branch.Length -gt $maxLen) {
                    $maxLen = $r.Branch.Length
                }
            }

            foreach ($r in $records) {
                $padBranch = $r.Branch.PadRight($maxLen)
                Write-Host ("    [{0,-7}] {1} : {2}" -f $r.Tag, $padBranch, $r.Message) -ForegroundColor $r.Color
            }
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
            Write-Host '用法：g <f|sync|vv|sw|swp|s>' -ForegroundColor Yellow
            Write-Host '      g r <v|a>'
            Write-Host '      g st <l|a|d|p>'
        }
    }
}

Register-ArgumentCompleter -CommandName g -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    'f', 'sync', 'vv', 'sw', 'swp', 'r', 'st', 's' |
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
