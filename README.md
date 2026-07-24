# Powershell-Profile

```text
profile.ps1
functions/
  dev.ps1
  git.ps1
  run.ps1
install.ps1
env.ps1        # local only, ignored by Git
```

`install.ps1` does two things for the PowerShell version that runs it:

1. Stores the repository path in the user environment variable `PS_PROFILE_ROOT`.
2. Adds a small loader to that version's default `$PROFILE`. The loader reads `PS_PROFILE_ROOT` and imports `profile.ps1`.

Run it after cloning, or after moving the repository:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Local paths and switches live in `env.ps1`; it is never committed. Available settings are:

```powershell
$env:PS_PROFILE_SERVER_PATH = '...'
$env:PS_PROFILE_REPOSITORIES_PATH = '...'
$env:PS_PROFILE_ENABLE_DEV = 'true'
$env:PS_PROFILE_ENABLE_GIT = 'true'
$env:PS_PROFILE_ENABLE_RUN = 'true'
$env:PS_PROFILE_STARTUP_PATH = '...'
```

If you also use PowerShell 7, run `pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1` once from PowerShell 7; its `$PROFILE` is separate from Windows PowerShell's.
