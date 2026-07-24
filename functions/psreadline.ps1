# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：配置交互式 PowerShell 会话的历史预测与按键行为。

# 非交互调用不加载命令行编辑器，避免影响脚本和重定向输出。
$isInteractiveConsole = $false
try {
    $isInteractiveConsole = -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected
}
catch {
    $isInteractiveConsole = $false
}

if ($isInteractiveConsole) {
    $psReadLine = Get-Module -ListAvailable PSReadLine |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($psReadLine) {
        try {
            Import-Module $psReadLine.Path -ErrorAction Stop
            Set-PSReadLineOption `
                -PredictionSource $global:PSProfileConfig.PSReadLine.PredictionSource `
                -PredictionViewStyle $global:PSProfileConfig.PSReadLine.PredictionViewStyle `
                -HistorySearchCursorMovesToEnd:$global:PSProfileConfig.PSReadLine.HistorySearchCursorMovesToEnd `
                -ErrorAction Stop
            Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction Stop
            Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction Stop
        }
        catch {
            # 交互配置失败时保持启动安静，详细状态由 pp doctor 检查。
        }
    }
}
