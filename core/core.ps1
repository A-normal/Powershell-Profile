# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：PowerShell Profile 的帮助、诊断、重载和目录入口。

function global:pp {
    param(
        [string]$Command
    )

    if (-not $Command) {
        $Command = 'help'
    }

    switch ($Command) {
        'help' {
            Write-Host 'PowerShell Profile 命令：' -ForegroundColor Cyan
            Write-Host '  pp help             显示本说明'
            Write-Host '  pp doctor           检查配置、路径和外部依赖'
            Write-Host '  pp reload           在当前窗口重新加载配置'
            Write-Host '  pp root             进入 Profile 仓库目录'
            if ($global:PSProfileConfig.Features.Jump -or
                $global:PSProfileConfig.Features.Dev -or
                $global:PSProfileConfig.Features.Git -or
                $global:PSProfileConfig.Features.Run) {
                Write-Host ''
                Write-Host '已启用的工作命令：' -ForegroundColor Cyan
            }
            if ($global:PSProfileConfig.Features.Jump) {
                Write-Host '  j <名称>             进入本机配置的目录'
            }
            if ($global:PSProfileConfig.Features.Dev) {
                Write-Host '  dev <项目> <动作>    执行预设开发任务'
            }
            if ($global:PSProfileConfig.Features.Git) {
                Write-Host '  g f                 获取并清理远端分支信息'
                Write-Host '  g sync              仅以 fast-forward 方式同步当前分支'
                Write-Host '  g vv                查看本地分支及其上游'
                Write-Host '  g sw <分支>         切换分支'
            }
            if ($global:PSProfileConfig.Features.Run) {
                Write-Host '  run <目标> [动作]    启动预设运行目标'
            }
            return
        }
        'reload' {
            $entryPoint = Join-Path $global:PSProfileRoot 'profile.ps1'
            if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
                Write-Warning "找不到 Profile 入口：$entryPoint"
                return
            }

            . $entryPoint
            Write-Host 'PowerShell Profile 已重新加载。' -ForegroundColor Green
            return
        }
        'root' {
            if (-not (Test-Path -LiteralPath $global:PSProfileRoot -PathType Container)) {
                Write-Warning "Profile 仓库目录不存在：$global:PSProfileRoot"
                return
            }

            Set-Location -LiteralPath $global:PSProfileRoot
            return
        }
        'doctor' {
            $checks = [System.Collections.Generic.List[object]]::new()

            $checks.Add([pscustomobject]@{
                    Status  = if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.PSVersion.Major -ge 7) { 'OK' } else { 'FAIL' }
                    Item    = 'PowerShell'
                    Message = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
                })

            $rootIsValid = Test-Path -LiteralPath (Join-Path $global:PSProfileRoot 'profile.ps1') -PathType Leaf
            $checks.Add([pscustomobject]@{
                    Status  = if ($rootIsValid) { 'OK' } else { 'FAIL' }
                    Item    = '仓库入口'
                    Message = $global:PSProfileRoot
                })

            $userRoot = [Environment]::GetEnvironmentVariable('PS_PROFILE_ROOT', 'User')
            $rootMatches = $false
            if ($userRoot) {
                try {
                    $rootMatches = [string]::Equals(
                        [IO.Path]::GetFullPath($userRoot).TrimEnd('\'),
                        [IO.Path]::GetFullPath($global:PSProfileRoot).TrimEnd('\'),
                        [StringComparison]::OrdinalIgnoreCase
                    )
                }
                catch {
                    $rootMatches = $false
                }
            }
            $checks.Add([pscustomobject]@{
                    Status  = if ($rootMatches) { 'OK' } else { 'FAIL' }
                    Item    = 'PS_PROFILE_ROOT'
                    Message = if ($userRoot) { $userRoot } else { '未设置；请重新运行 install.ps1' }
                })

            $profilePath = $PROFILE.CurrentUserCurrentHost
            $loaderExists = Test-Path -LiteralPath $profilePath -PathType Leaf
            $loaderManaged = $loaderExists -and [bool](Select-String -LiteralPath $profilePath -SimpleMatch '# >>> PowershellProfile >>>' -Quiet)
            $loaderCurrent = $loaderManaged -and [bool](Select-String -LiteralPath $profilePath -SimpleMatch '# PowershellProfile 加载器版本：2' -Quiet)
            $checks.Add([pscustomobject]@{
                    Status  = if ($loaderCurrent) { 'OK' } else { 'FAIL' }
                    Item    = 'Profile 加载器'
                    Message = if ($loaderCurrent) { $profilePath } else { "未安装或版本过旧；请运行 $global:PSProfileRoot\install.ps1" }
                })

            $usesPaths = $global:PSProfileConfig.Features.Jump -or
                $global:PSProfileConfig.Features.Dev -or
                $global:PSProfileConfig.Features.Run
            if ($usesPaths) {
                $locationFile = Join-Path $global:PSProfileRoot 'location.ps1'
                $checks.Add([pscustomobject]@{
                        Status  = if (Test-Path -LiteralPath $locationFile -PathType Leaf) { 'OK' } else { 'WARN' }
                        Item    = '路径配置'
                        Message = if (Test-Path -LiteralPath $locationFile -PathType Leaf) { $locationFile } else { '未配置；请复制 location.example.ps1 为 location.ps1' }
                    })

                if ($global:PSProfileConfig.Paths.Count -eq 0) {
                    $checks.Add([pscustomobject]@{
                            Status  = 'WARN'
                            Item    = '本机路径'
                            Message = '路径表为空。'
                        })
                }
                else {
                    foreach ($pathName in $global:PSProfileConfig.Paths.Keys) {
                        $configuredPath = $global:PSProfileConfig.Paths[$pathName]
                        $checks.Add([pscustomobject]@{
                                Status  = if (Test-Path -LiteralPath $configuredPath -PathType Container) { 'OK' } else { 'FAIL' }
                                Item    = "路径 $pathName"
                                Message = $configuredPath
                            })
                    }
                }
            }

            if ($global:PSProfileConfig.Features.Dev -or $global:PSProfileConfig.Features.Run) {
                $tasksFile = Join-Path $global:PSProfileRoot 'tasks.ps1'
                $checks.Add([pscustomobject]@{
                        Status  = if (Test-Path -LiteralPath $tasksFile -PathType Leaf) { 'OK' } else { 'WARN' }
                        Item    = '任务配置'
                        Message = if (Test-Path -LiteralPath $tasksFile -PathType Leaf) { $tasksFile } else { '未配置；请复制 tasks.example.ps1 为 tasks.ps1' }
                    })
            }

            if ($global:PSProfileConfig.Features.Dev) {
                $projects = $global:PSProfileConfig.Development
                if ($projects.Count -eq 0) {
                    $checks.Add([pscustomobject]@{
                            Status  = 'WARN'
                            Item    = '开发任务'
                            Message = '未配置任何项目。'
                        })
                }
                else {
                    foreach ($projectName in $projects.Keys) {
                        $projectConfig = $projects[$projectName]
                        if (-not ($projectConfig -is [System.Collections.IDictionary]) -or
                            -not $projectConfig.Contains('PathKey') -or
                            [string]::IsNullOrWhiteSpace([string]$projectConfig['PathKey']) -or
                            -not $projectConfig.Contains('Actions') -or
                            -not ($projectConfig['Actions'] -is [System.Collections.IDictionary])) {
                            $checks.Add([pscustomobject]@{
                                    Status  = 'FAIL'
                                    Item    = "开发项目 $projectName"
                                    Message = '配置格式不正确；必须包含 PathKey 和 Actions。'
                                })
                            continue
                        }

                        foreach ($actionName in $projectConfig['Actions'].Keys) {
                            $resolvedTask = Resolve-PSProfileTask `
                                -Task $projectConfig['Actions'][$actionName] `
                                -DefaultPathKey ([string]$projectConfig['PathKey'])
                            $checks.Add([pscustomobject]@{
                                    Status  = if ($resolvedTask.IsValid) { 'OK' } else { 'FAIL' }
                                    Item    = "开发任务 $projectName $actionName"
                                    Message = $resolvedTask.Message
                                })
                        }
                    }
                }
            }

            if ($global:PSProfileConfig.Features.Run) {
                $targets = $global:PSProfileConfig.RunTargets
                if ($targets.Count -eq 0) {
                    $checks.Add([pscustomobject]@{
                            Status  = 'WARN'
                            Item    = '运行目标'
                            Message = '未配置任何目标。'
                        })
                }
                else {
                    foreach ($targetName in $targets.Keys) {
                        $targetConfig = $targets[$targetName]
                        if (-not ($targetConfig -is [System.Collections.IDictionary]) -or
                            -not $targetConfig.Contains('Actions') -or
                            -not ($targetConfig['Actions'] -is [System.Collections.IDictionary])) {
                            $checks.Add([pscustomobject]@{
                                    Status  = 'FAIL'
                                    Item    = "运行目标 $targetName"
                                    Message = '配置格式不正确；必须包含 Actions。'
                                })
                            continue
                        }

                        $actions = $targetConfig['Actions']
                        if ($targetConfig.Contains('DefaultAction') -and
                            -not $actions.Contains([string]$targetConfig['DefaultAction'])) {
                            $checks.Add([pscustomobject]@{
                                    Status  = 'FAIL'
                                    Item    = "运行目标 $targetName"
                                    Message = "默认动作不存在：$($targetConfig['DefaultAction'])"
                                })
                        }

                        $pathKey = if ($targetConfig.Contains('PathKey')) { [string]$targetConfig['PathKey'] } else { $null }
                        foreach ($actionName in $actions.Keys) {
                            $resolvedTask = Resolve-PSProfileTask `
                                -Task $actions[$actionName] `
                                -DefaultPathKey $pathKey
                            $checks.Add([pscustomobject]@{
                                    Status  = if ($resolvedTask.IsValid) { 'OK' } else { 'FAIL' }
                                    Item    = "运行任务 $targetName $actionName"
                                    Message = $resolvedTask.Message
                                })
                        }
                    }
                }
            }

            if ($global:PSProfileConfig.Features.Git) {
                $gitCommand = Get-Command git -ErrorAction SilentlyContinue
                $checks.Add([pscustomobject]@{
                        Status  = if ($gitCommand) { 'OK' } else { 'FAIL' }
                        Item    = 'Git'
                        Message = if ($gitCommand) { $gitCommand.Source } else { '找不到 git 命令' }
                    })
            }

            if ($global:PSProfileConfig.Features.PSReadLine) {
                $psReadLine = Get-Module -ListAvailable PSReadLine |
                    Sort-Object Version -Descending |
                    Select-Object -First 1
                $checks.Add([pscustomobject]@{
                        Status  = if ($psReadLine) { 'OK' } else { 'FAIL' }
                        Item    = 'PSReadLine'
                        Message = if ($psReadLine) { "$($psReadLine.Version) - $($psReadLine.Path)" } else { '找不到 PSReadLine 模块' }
                    })
            }

            Write-Host 'PowerShell Profile 自检：' -ForegroundColor Cyan
            foreach ($check in $checks) {
                $color = switch ($check.Status) {
                    'OK' { 'Green' }
                    'WARN' { 'Yellow' }
                    default { 'Red' }
                }
                Write-Host ("[{0,-4}] {1}：{2}" -f $check.Status, $check.Item, $check.Message) -ForegroundColor $color
            }

            $failed = @($checks | Where-Object Status -eq 'FAIL').Count
            $warnings = @($checks | Where-Object Status -eq 'WARN').Count
            Write-Host "结果：$failed 项失败，$warnings 项警告。"
            return
        }
        default {
            Write-Warning "未知的 pp 子命令：$Command"
            Write-Host '用法：pp <help|doctor|reload|root>' -ForegroundColor Yellow
        }
    }
}

Register-ArgumentCompleter -CommandName pp -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    'help', 'doctor', 'reload', 'root' |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
