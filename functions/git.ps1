# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：常用 Git 操作的快捷命令。

function g {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('f', 'sync', 'vv', 'co')]
        [string]$Cmd,
        [string]$Arg
    )

    switch ($Cmd) {
        'f' { & git fetch --all --prune }
        'sync' {
            & git fetch --all --prune
            & git pull
        }
        'vv' { & git branch -vv }
        'co' {
            if (-not $Arg) {
                Write-Host 'Usage: g co <branch>' -ForegroundColor Yellow
                return
            }
            & git checkout $Arg
        }
    }
}
