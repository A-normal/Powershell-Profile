[CmdletBinding(SupportsShouldProcess)]
param([string]$ProjectPath)

if (-not $ProjectPath) {
    $ProjectPath = $PSScriptRoot
}

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
$entryPoint = Join-Path $projectRoot 'profile.ps1'
if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
    throw "profile.ps1 was not found in: $projectRoot"
}

$loader = @'
# >>> PowershellProfile >>>
$profileRoot = $env:PS_PROFILE_ROOT
if (-not $profileRoot) {
    $profileRoot = [Environment]::GetEnvironmentVariable('PS_PROFILE_ROOT', 'User')
}
$profileEntry = Join-Path $profileRoot 'profile.ps1'
if (Test-Path -LiteralPath $profileEntry -PathType Leaf) {
    . $profileEntry
}
else {
    Write-Warning "PowershellProfile was not found: $profileEntry"
}
# <<< PowershellProfile <<<
'@

if ($PSCmdlet.ShouldProcess('PS_PROFILE_ROOT (User environment variable)', "Set to $projectRoot")) {
    [Environment]::SetEnvironmentVariable('PS_PROFILE_ROOT', $projectRoot, 'User')
    $env:PS_PROFILE_ROOT = $projectRoot
}

$profileDirectory = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
if (-not (Test-Path -LiteralPath $profileDirectory)) {
    if ($PSCmdlet.ShouldProcess($profileDirectory, 'Create profile directory')) {
        New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    }
}

$profilePath = $PROFILE.CurrentUserCurrentHost
$legacyLoader = Join-Path $profileDirectory 'PowershellProfile.loader.ps1'
$existing = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw } else { '' }
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
