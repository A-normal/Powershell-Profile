# Copyright (c) 2026 修仙者一号
# SPDX-License-Identifier: GPL-3.0-only
# 文件用途：安装或更新默认 $PROFILE 加载器，并记录本仓库的位置。

[CmdletBinding(SupportsShouldProcess)]
# 用法：在仓库根目录执行 .\install.ps1。
# 若仓库搬家，重新执行一次即可更新环境变量中的仓库路径。
param([string]$ProjectPath)

# 未指定路径时，默认把本脚本所在目录当作项目根目录。
if (-not $ProjectPath) {
    $ProjectPath = $PSScriptRoot
}

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
$entryPoint = Join-Path $projectRoot 'profile.ps1'
# 防止误在非本项目目录运行安装器。
if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
    throw "profile.ps1 was not found in: $projectRoot"
}

$loader = @'
# >>> PowershellProfile >>>
# 默认 $PROFILE 不保存仓库绝对路径，只从用户环境变量读取项目位置。
$profileRoot = $env:PS_PROFILE_ROOT
if (-not $profileRoot) {
    $profileRoot = [Environment]::GetEnvironmentVariable('PS_PROFILE_ROOT', 'User')
}
$profileEntry = Join-Path $profileRoot 'profile.ps1'
# 找到项目入口后，以点源方式加载函数和本机环境配置。
if (Test-Path -LiteralPath $profileEntry -PathType Leaf) {
    . $profileEntry
}
else {
    Write-Warning "PowershellProfile was not found: $profileEntry"
}
# <<< PowershellProfile <<<
'@

# 同时写入用户级环境变量和当前 PowerShell 进程：当前窗口无需重开即可使用。
if ($PSCmdlet.ShouldProcess('PS_PROFILE_ROOT (User environment variable)', "Set to $projectRoot")) {
    [Environment]::SetEnvironmentVariable('PS_PROFILE_ROOT', $projectRoot, 'User')
    $env:PS_PROFILE_ROOT = $projectRoot
}

$profileDirectory = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
# 首次使用时，默认 Profile 所在目录可能尚不存在。
if (-not (Test-Path -LiteralPath $profileDirectory)) {
    if ($PSCmdlet.ShouldProcess($profileDirectory, 'Create profile directory')) {
        New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    }
}

$profilePath = $PROFILE.CurrentUserCurrentHost
# 清理早期版本曾创建的独立加载器；新版直接由默认 Profile 读取环境变量。
$legacyLoader = Join-Path $profileDirectory 'PowershellProfile.loader.ps1'
$existing = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw } else { '' }
# 仅替换本项目用标记包围的区块，不影响用户自己写在 $PROFILE 中的内容。
$pattern = '(?s)\r?\n?# >>> PowershellProfile(?: managed loader)? >>>.*?# <<< PowershellProfile(?: managed loader)? <<<\r?\n?'
$updated = [regex]::Replace($existing, $pattern, '').TrimEnd()
if ($updated) { $updated += [Environment]::NewLine + [Environment]::NewLine }
$updated += $loader

if ($PSCmdlet.ShouldProcess($profilePath, 'Install PowershellProfile loader')) {
    Set-Content -LiteralPath $profilePath -Value $updated -Encoding utf8
}

if (Test-Path -LiteralPath $legacyLoader) {
    if ($PSCmdlet.ShouldProcess($legacyLoader, 'Remove obsolete PowershellProfile loader')) {
        Remove-Item -LiteralPath $legacyLoader -Force
    }
}
