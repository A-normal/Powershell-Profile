# Powershell-Profile

版权所有 © 2026 修仙者一号。许可证：GNU GPL v3.0（GPL-3.0-only）。

本文档说明本仓库的 PowerShell Profile 加载、配置与安装方式。

```text
profile.ps1
functions/
  dev.ps1
  git.ps1
  run.ps1
  utils.ps1
  ...
install.ps1
env.ps1        # 可同步：功能启用开关
location.ps1   # 仅本机：路径配置，已被 Git 忽略
```

`install.ps1` 会为运行它的 PowerShell 版本完成两件事：

1. 将仓库路径写入用户环境变量 `PS_PROFILE_ROOT`。
2. 在该版本默认的 `$PROFILE` 中加入一小段加载器；加载器读取 `PS_PROFILE_ROOT` 后导入 `profile.ps1`。

克隆仓库后，或移动仓库位置后，在仓库根目录执行：

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## 配置

`env.ps1` 可随仓库同步，只保存功能启用开关。值为 `'false'` 时，对应功能脚本不会加载：

```powershell
$env:PS_PROFILE_ENABLE_DEV = 'false'
$env:PS_PROFILE_ENABLE_GIT = 'true'
$env:PS_PROFILE_ENABLE_UTILS = 'true'
$env:PS_PROFILE_ENABLE_RUN = 'false'
```

`location.ps1` 仅保留在本机，保存各电脑不同的路径，且已在 `.gitignore` 中排除：

```powershell
$env:PS_PROFILE_STARTUP_PATH = '...'
$env:PS_PROFILE_SERVER_PATH = '...'
$env:PS_PROFILE_REPOSITORIES_PATH = '...'
```

`profile.ps1` 会先加载 `env.ps1`，再加载 `location.ps1`，最后按开关加载 `functions\` 下的脚本。路径配置缺失不会影响已启用的 Git 和工具脚本；仅启用 `dev` 时会提示缺少路径配置。

## PowerShell 7

如也使用 PowerShell 7，运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

PowerShell 7 与 Windows PowerShell 使用不同的 `$PROFILE`，各运行一次安装器即可。

## 许可证

本项目采用 GNU General Public License v3.0（GPL-3.0-only）。
