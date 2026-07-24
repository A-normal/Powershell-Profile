# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：PowerShell Profile 的通用辅助命令。

# 重新加载profile环境
function reload {
    . $PROFILE
    Write-Host ""
    Write-Host "✔ Profile Reloaded" -ForegroundColor Green
    Write-Host ""
}
