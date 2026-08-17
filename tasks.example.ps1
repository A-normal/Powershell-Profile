# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：本机任务配置模板；复制为 tasks.ps1 后填写固定任务。

$global:PSProfileConfig.Development = [ordered]@{
    project = [ordered]@{
        PathKey = 'project'
        Actions = [ordered]@{
            action = [ordered]@{
                Executable = 'tool'
                Arguments  = @('argument')
            }
        }
    }
}

$global:PSProfileConfig.RunTargets = [ordered]@{
    environment = [ordered]@{
        DefaultAction = 'default'
        Actions       = [ordered]@{
            default = [ordered]@{
                Executable = 'tool'
                Arguments  = @()
            }
        }
    }
}
