# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：可同步的 PowerShell Profile 功能与交互配置。

$global:PSProfileConfig = [ordered]@{
    Features   = [ordered]@{
        Dev        = $false
        Git        = $true
        Run        = $false
        PSReadLine = $true
    }
    PSReadLine = [ordered]@{
        PredictionSource              = 'History'
        PredictionViewStyle           = 'ListView'
        HistorySearchCursorMovesToEnd = $true
    }
    Paths      = [ordered]@{}
}
