# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：在本机预设的项目目录之间快速切换。

function dev {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('start', 'serve', 'repo')]
        [string]$Target
    )

    $path = switch ($Target) {
        'start' { $env:PS_PROFILE_STARTUP_PATH }
        'serve' { $env:PS_PROFILE_SERVER_PATH }
        'repo' { $env:PS_PROFILE_REPOSITORIES_PATH }
    }

    if (-not $path) {
        Write-Warning "Path for dev $Target is not configured in env.ps1."
        return
    }

    Set-Location -LiteralPath $path
}
