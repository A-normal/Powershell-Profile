# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：本机路径配置模板；复制为 location.ps1 后填写真实路径。

# 键名会成为 dev 命令的参数，并自动参与 Tab 补全。
$global:PSProfileConfig.Paths = [ordered]@{
    work   = 'C:\Path\To\Work'
    server = 'C:\Path\To\Server'
    repo   = 'C:\Path\To\Repositories'
}
