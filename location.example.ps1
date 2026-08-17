# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：本机路径配置模板；复制为 location.ps1 后填写真实路径。

# 键名会成为 j 命令的参数，也可被本机任务通过 PathKey 引用。
$global:PSProfileConfig.Paths = [ordered]@{
    project = 'C:\Path\To\Project'
    repo    = 'C:\Path\To\Repositories'
}
