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
        Executable      = $null
        Arguments       = @()
    }

    if (-not $Task) {
        $result.Message = '任务定义为空或格式不正确。'
        return [pscustomobject]$result
    }

    $executable = if ($Task.Contains('Executable')) { [string]$Task['Executable'] } else { $null }
    if ([string]::IsNullOrWhiteSpace($executable)) {
        $result.Message = '任务缺少 Executable。'
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

    $command = Get-Command $executable -ErrorAction SilentlyContinue
    if (-not $command) {
        $result.Message = "找不到任务所需命令：$executable"
        return [pscustomobject]$result
    }

    $arguments = if ($Task.Contains('Arguments')) { @($Task['Arguments']) } else { @() }
    $result.IsValid = $true
    $result.Message = if ($workingDirectory) {
        "$workingDirectory -> $executable"
    }
    else {
        $executable
    }
    $result.WorkingDirectory = $workingDirectory
    $result.Executable = $executable
    $result.Arguments = $arguments
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

        $taskArguments = @($resolvedTask.Arguments)
        & $resolvedTask.Executable @taskArguments
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
