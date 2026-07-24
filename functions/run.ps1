function run {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('wsl')]
        [string]$Target
    )

    if ($Target -eq 'wsl') {
        wsl -u root
    }
}
