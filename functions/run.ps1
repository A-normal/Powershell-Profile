# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：启动常用本地运行环境。

function run {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('wsl')]
        [string]$Target
    )

    if ($Target -eq 'wsl') {
        wsl -u root
    }
}
