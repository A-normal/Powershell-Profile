# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：常用 Linux 习惯命令包装（ll、port、cp、mv、rm）。

function global:Format-PSProfileSize {
    param([long]$Bytes)

    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    if ($Bytes -lt 1GB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -lt 1TB) { return "{0:N1} GB" -f ($Bytes / 1GB) }
    return "{0:N1} TB" -f ($Bytes / 1TB)
}

function global:ll {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $showHidden = $false
    $sortByTime = $false
    $reverse = $false
    $targetPath = '.'

    if ($Arguments) {
        foreach ($arg in $Arguments) {
            if ($arg -in @('-?', '--help', '-help')) {
                Write-Host '用法：ll [-a] [-h] [-t] [-r] [路径]' -ForegroundColor Yellow
                Write-Host '  -a    显示隐藏文件与文件夹（对应 Get-ChildItem -Force）'
                Write-Host '  -h    以易读单位显示大小（KB/MB/GB，默认已启用）'
                Write-Host '  -t    按修改时间排序（最新在前）'
                Write-Host '  -r    反向排序'
                Write-Host '  支持常见组合参数，例如 ll -la、ll -lh、ll -lt 等'
                return
            }
            if ($arg -match '^-([a-zA-Z]+)$') {
                $flags = $Matches[1].ToCharArray()
                foreach ($f in $flags) {
                    switch ($f) {
                        'a' { $showHidden = $true }
                        't' { $sortByTime = $true }
                        'r' { $reverse = $true }
                        'l' { } # 默认长格式
                        'h' { } # 默认易读大小
                        default {
                            Write-Warning "未知参数选项：-$f"
                        }
                    }
                }
            }
            else {
                $targetPath = $arg
            }
        }
    }

    if (-not (Test-Path -LiteralPath $targetPath)) {
        Write-Warning "路径不存在：$targetPath"
        return
    }

    $gciParams = @{
        LiteralPath = $targetPath
    }
    if ($showHidden) {
        $gciParams['Force'] = $true
    }

    try {
        $items = Get-ChildItem @gciParams -ErrorAction Stop
    }
    catch {
        Write-Warning "读取路径失败：$($_.Exception.Message)"
        return
    }

    if (-not $items -or $items.Count -eq 0) {
        Write-Host "目录为空：$targetPath" -ForegroundColor DarkGray
        return
    }

    if ($sortByTime) {
        $items = $items | Sort-Object LastWriteTime -Descending:$(-not $reverse)
    }
    elseif ($reverse) {
        $items = $items | Sort-Object Name -Descending
    }

    $results = foreach ($item in $items) {
        $sizeStr = if ($item.PSIsContainer) {
            '<DIR>'
        }
        else {
            Format-PSProfileSize -Bytes $item.Length
        }

        [pscustomobject]@{
            Mode          = $item.Mode
            LastWriteTime = $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
            Length        = $sizeStr
            Name          = $item.Name
        }
    }

    if ($MyInvocation.PipelineLength -gt 1) {
        $results
    }
    else {
        $results | Format-Table -AutoSize
    }
}

function global:port {
    param(
        [Parameter(Position = 0)]
        [string]$TargetPort
    )

    $hasNetTcp = [bool](Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue)
    if (-not $hasNetTcp) {
        Write-Warning '当前系统未提供 Get-NetTCPConnection 命令，无法查询网络连接。'
        return
    }

    if ($TargetPort) {
        if ($TargetPort -in @('-?', '--help', '-help')) {
            Write-Host '用法：port [端口号]' -ForegroundColor Yellow
            Write-Host '  port 8080      查看占用指定端口的进程与状态'
            Write-Host '  port           列出所有处于 Listen 状态的 TCP 端口'
            return
        }

        $cleanPort = $TargetPort.TrimStart(':')
        $portNum = 0
        if (-not [int]::TryParse($cleanPort, [ref]$portNum) -or $portNum -le 0 -or $portNum -gt 65535) {
            Write-Warning "无效的端口号：$TargetPort（端口范围必须在 1 ~ 65535 之间）"
            Write-Host '用法：port [端口号]' -ForegroundColor Yellow
            return
        }

        $connections = Get-NetTCPConnection -LocalPort $portNum -ErrorAction SilentlyContinue
        if (-not $connections) {
            Write-Host "端口 $portNum 当前未被占用。" -ForegroundColor Cyan
            return
        }

        $results = foreach ($conn in $connections) {
            $procId = $conn.OwningProcess
            $procName = 'Unknown'
            $procPath = ''
            if ($procId -gt 0) {
                try {
                    $proc = Get-Process -Id $procId -ErrorAction Stop
                    $procName = $proc.ProcessName
                    $procPath = $proc.Path
                }
                catch {
                    $procName = '<受限/系统进程>'
                }
            }
            elseif ($procId -eq 0) {
                $procName = '<System Idle>'
            }

            [pscustomobject]@{
                Port         = $conn.LocalPort
                Protocol     = 'TCP'
                LocalAddress = $conn.LocalAddress
                State        = $conn.State
                PID          = $procId
                ProcessName  = $procName
                Path         = $procPath
            }
        }

        if ($MyInvocation.PipelineLength -gt 1) {
            $results
        }
        else {
            $results | Format-Table -AutoSize
        }
        return
    }

    # 无参数时列出所有处于 Listen 状态的 TCP 端口
    $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Sort-Object LocalPort
    if (-not $listeners) {
        Write-Host '未检测到处于 Listen 状态的 TCP 端口。' -ForegroundColor Cyan
        return
    }

    $procCache = @{}
    $results = foreach ($conn in $listeners) {
        $procId = $conn.OwningProcess
        if (-not $procCache.ContainsKey($procId)) {
            $pName = 'Unknown'
            if ($procId -gt 0) {
                try {
                    $p = Get-Process -Id $procId -ErrorAction Stop
                    $pName = $p.ProcessName
                }
                catch {
                    $pName = '<受限/系统进程>'
                }
            }
            elseif ($procId -eq 0) {
                $pName = '<System Idle>'
            }
            $procCache[$procId] = $pName
        }

        [pscustomobject]@{
            Port         = $conn.LocalPort
            Protocol     = 'TCP'
            LocalAddress = $conn.LocalAddress
            PID          = $procId
            ProcessName  = $procCache[$procId]
        }
    }

    if ($MyInvocation.PipelineLength -gt 1) {
        $results
    }
    else {
        $results | Format-Table -AutoSize
    }
}

Register-ArgumentCompleter -CommandName port -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty LocalPort -Unique |
            Sort-Object |
            ForEach-Object { [string]$_ } |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Port $_")
            }
    }
}

# 移除原生别名，使自定义包装函数生效
Remove-Item -LiteralPath 'Alias:cp' -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'Alias:mv' -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'Alias:rm' -Force -ErrorAction SilentlyContinue

function global:cp {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    if (-not $Arguments -or $Arguments.Count -lt 2) {
        Write-Host '用法：cp [-r|-f|-rf] <源路径...> <目标路径>' -ForegroundColor Yellow
        return
    }

    $recurse = $false
    $force = $false
    $paths = [System.Collections.Generic.List[string]]::new()

    foreach ($arg in $Arguments) {
        switch -Regex ($arg) {
            '^-([rR][fF]|[fF][rR])$' {
                $recurse = $true
                $force = $true
            }
            '^-([rR]|-[rR]ecurse)$' {
                $recurse = $true
            }
            '^-([fF]|-[fF]orce)$' {
                $force = $true
            }
            default {
                $paths.Add($arg)
            }
        }
    }

    if ($paths.Count -lt 2) {
        Write-Host '用法：cp [-r|-f|-rf] <源路径...> <目标路径>' -ForegroundColor Yellow
        return
    }

    $dest = $paths[$paths.Count - 1]
    $sources = $paths.GetRange(0, $paths.Count - 1)

    $params = @{
        Path        = $sources
        Destination = $dest
    }
    if ($recurse) { $params['Recurse'] = $true }
    if ($force) { $params['Force'] = $true }

    Microsoft.PowerShell.Management\Copy-Item @params
}

function global:mv {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    if (-not $Arguments -or $Arguments.Count -lt 2) {
        Write-Host '用法：mv [-f] <源路径...> <目标路径>' -ForegroundColor Yellow
        return
    }

    $force = $false
    $paths = [System.Collections.Generic.List[string]]::new()

    foreach ($arg in $Arguments) {
        switch -Regex ($arg) {
            '^-([fF]|-[fF]orce)$' {
                $force = $true
            }
            default {
                $paths.Add($arg)
            }
        }
    }

    if ($paths.Count -lt 2) {
        Write-Host '用法：mv [-f] <源路径...> <目标路径>' -ForegroundColor Yellow
        return
    }

    $dest = $paths[$paths.Count - 1]
    $sources = $paths.GetRange(0, $paths.Count - 1)

    $params = @{
        Path        = $sources
        Destination = $dest
    }
    if ($force) { $params['Force'] = $true }

    Microsoft.PowerShell.Management\Move-Item @params
}

function global:rm {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    if (-not $Arguments -or $Arguments.Count -eq 0) {
        Write-Host '用法：rm [-r|-f|-rf] <路径...>' -ForegroundColor Yellow
        return
    }

    $recurse = $false
    $force = $false
    $paths = [System.Collections.Generic.List[string]]::new()

    foreach ($arg in $Arguments) {
        switch -Regex ($arg) {
            '^-([rR][fF]|[fF][rR])$' {
                $recurse = $true
                $force = $true
            }
            '^-([rR]|-[rR]ecurse)$' {
                $recurse = $true
            }
            '^-([fF]|-[fF]orce)$' {
                $force = $true
            }
            default {
                $paths.Add($arg)
            }
        }
    }

    if ($paths.Count -eq 0) {
        Write-Host '用法：rm [-r|-f|-rf] <路径...>' -ForegroundColor Yellow
        return
    }

    $params = @{
        Path = $paths
    }
    if ($recurse) { $params['Recurse'] = $true }
    if ($force) { $params['Force'] = $true }

    Microsoft.PowerShell.Management\Remove-Item @params
}
