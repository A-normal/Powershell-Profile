function dev {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('start', 'serve', 'repo')]
        [string]$Target
    )

    $path = switch ($Target) {
        'start' { $env:PS_PROFILE_STARTUP_PATH }
        'serve' { $env:PS_PROFILE_SERVER_PATH }
        'repo' { $env:PS_PROFILE_REPOSITORIES_PATH }
    }

    if (-not $path) {
        Write-Warning "Path for dev $Target is not configured in env.ps1."
        return
    }

    Set-Location -LiteralPath $path
}
