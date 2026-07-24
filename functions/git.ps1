function g {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('f', 'sync', 'vv', 'co')]
        [string]$Cmd,
        [string]$Arg
    )

    switch ($Cmd) {
        'f' { & git fetch --all --prune }
        'sync' {
            & git fetch --all --prune
            & git pull
        }
        'vv' { & git branch -vv }
        'co' {
            if (-not $Arg) {
                Write-Host 'Usage: g co <branch>' -ForegroundColor Yellow
                return
            }
            & git checkout $Arg
        }
    }
}
