# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：校验并执行本机白名单任务，不解释或拼接命令字符串。

function global:Resolve-PSProfileTask {
    param(
        [System.Collections.IDictionary]$Task,
        [string]$DefaultPathKey
    )

    $result = [ordered]@{
        IsValid         = $false
        Message         = $null
        WorkingDirectory = $null
        Steps           = @()
    }

    if (-not $Task) {
        $result.Message = '任务定义为空或格式不正确。'
        return [pscustomobject]$result
    }

    $hasSingleStep = $Task.Contains('Executable')
    $hasMultipleSteps = $Task.Contains('Steps')
    if ($hasSingleStep -eq $hasMultipleSteps) {
        $result.Message = '任务必须且只能配置 Executable 或 Steps 其中一种格式。'
        return [pscustomobject]$result
    }

    $pathKey = $DefaultPathKey
    if ($Task.Contains('PathKey') -and -not [string]::IsNullOrWhiteSpace([string]$Task['PathKey'])) {
        $pathKey = [string]$Task['PathKey']
    }

    $workingDirectory = $null
    if (-not [string]::IsNullOrWhiteSpace($pathKey)) {
        $paths = $global:PSProfileConfig.Paths
        if (-not ($paths -is [System.Collections.IDictionary]) -or -not $paths.Contains($pathKey)) {
            $result.Message = "未配置任务引用的路径键：$pathKey"
            return [pscustomobject]$result
        }

        $basePath = [string]$paths[$pathKey]
        if (-not (Test-Path -LiteralPath $basePath -PathType Container)) {
            $result.Message = "任务路径不存在或不是目录：$basePath"
            return [pscustomobject]$result
        }

        try {
            $basePath = [IO.Path]::GetFullPath($basePath).TrimEnd('\', '/')
            $workingDirectory = $basePath

            if ($Task.Contains('Subdirectory') -and
                -not [string]::IsNullOrWhiteSpace([string]$Task['Subdirectory'])) {
                $workingDirectory = [IO.Path]::GetFullPath(
                    (Join-Path $basePath ([string]$Task['Subdirectory']))
                ).TrimEnd('\', '/')

                $pathPrefix = $basePath + [IO.Path]::DirectorySeparatorChar
                $insideBasePath = [string]::Equals(
                    $workingDirectory,
                    $basePath,
                    [StringComparison]::OrdinalIgnoreCase
                ) -or $workingDirectory.StartsWith($pathPrefix, [StringComparison]::OrdinalIgnoreCase)

                if (-not $insideBasePath) {
                    $result.Message = "任务子目录越过项目根目录：$workingDirectory"
                    return [pscustomobject]$result
                }
            }
        }
        catch {
            $result.Message = "无法解析任务目录：$($_.Exception.Message)"
            return [pscustomobject]$result
        }

        if (-not (Test-Path -LiteralPath $workingDirectory -PathType Container)) {
            $result.Message = "任务工作目录不存在：$workingDirectory"
            return [pscustomobject]$result
        }
    }
    elseif ($Task.Contains('Subdirectory') -and
        -not [string]::IsNullOrWhiteSpace([string]$Task['Subdirectory'])) {
        $result.Message = '任务配置了 Subdirectory，但没有可用的 PathKey。'
        return [pscustomobject]$result
    }

    $stepDefinitions = if ($hasMultipleSteps) { @($Task['Steps']) } else { @($Task) }
    if ($stepDefinitions.Count -eq 0) {
        $result.Message = '任务的 Steps 不能为空。'
        return [pscustomobject]$result
    }

    $resolvedSteps = [System.Collections.Generic.List[object]]::new()
    for ($stepIndex = 0; $stepIndex -lt $stepDefinitions.Count; $stepIndex++) {
        $step = $stepDefinitions[$stepIndex]
        if (-not ($step -is [System.Collections.IDictionary])) {
            $result.Message = "任务步骤 $($stepIndex + 1) 格式不正确。"
            return [pscustomobject]$result
        }

        $executable = if ($step.Contains('Executable')) { [string]$step['Executable'] } else { $null }
        if ([string]::IsNullOrWhiteSpace($executable)) {
            $result.Message = "任务步骤 $($stepIndex + 1) 缺少 Executable。"
            return [pscustomobject]$result
        }

        $command = Get-Command $executable -ErrorAction SilentlyContinue
        if (-not $command) {
            $result.Message = "找不到任务步骤 $($stepIndex + 1) 所需命令：$executable"
            return [pscustomobject]$result
        }

        $resolvedSteps.Add([pscustomobject]@{
                Executable = $executable
                Arguments  = if ($step.Contains('Arguments')) { @($step['Arguments']) } else { @() }
            })
    }

    $stepSummary = @($resolvedSteps | ForEach-Object Executable) -join ' -> '
    $result.IsValid = $true
    $result.Message = if ($workingDirectory) {
        "$workingDirectory -> $stepSummary"
    }
    else {
        $stepSummary
    }
    $result.WorkingDirectory = $workingDirectory
    $result.Steps = @($resolvedSteps)
    return [pscustomobject]$result
}

function global:Invoke-PSProfileTask {
    param(
        [System.Collections.IDictionary]$Task,
        [string]$DefaultPathKey
    )

    $resolvedTask = Resolve-PSProfileTask -Task $Task -DefaultPathKey $DefaultPathKey
    if (-not $resolvedTask.IsValid) {
        Write-Warning $resolvedTask.Message
        return
    }

    $locationChanged = $false
    try {
        if ($resolvedTask.WorkingDirectory) {
            Push-Location -LiteralPath $resolvedTask.WorkingDirectory
            $locationChanged = $true
        }

        for ($stepIndex = 0; $stepIndex -lt $resolvedTask.Steps.Count; $stepIndex++) {
            $step = $resolvedTask.Steps[$stepIndex]
            $taskArguments = @($step.Arguments)
            $lastErrorBefore = $global:Error[0]
            $global:LASTEXITCODE = 0
            & $step.Executable @taskArguments
            $invocationSucceeded = $?
            $hasNewError = -not [object]::ReferenceEquals($lastErrorBefore, $global:Error[0])
            $stepSucceeded = $invocationSucceeded -and -not $hasNewError -and $LASTEXITCODE -eq 0

            if (-not $stepSucceeded) {
                $exitMessage = if ($null -ne $LASTEXITCODE) { "，退出码：$LASTEXITCODE" } else { $null }
                Write-Warning "任务步骤 $($stepIndex + 1) 执行失败$exitMessage；已停止后续步骤。"
                return
            }
        }
    }
    catch {
        Write-Warning "任务执行失败：$($_.Exception.Message)"
    }
    finally {
        if ($locationChanged) {
            Pop-Location
        }
    }
}
