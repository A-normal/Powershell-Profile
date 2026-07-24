# Powershell-Profile

版权所有 © 2026 修仙者一号。许可证：GNU GPL v3.0（GPL-3.0-only）。

这是面向个人多台 Windows 电脑的 PowerShell 7 配置，提供路径跳转、Git 快捷命令、WSL 启动、PSReadLine 交互设置和环境自检。

## 文件结构

```text
profile.ps1
core/
  core.ps1
functions/
  dev.ps1
  git.ps1
  psreadline.ps1
  run.ps1
install.ps1
env.ps1                 # 可同步：功能与交互配置
location.example.ps1    # 可同步：本机路径模板
location.ps1            # 仅本机：真实路径，已被 Git 忽略
```

## 安装

本配置仅正式支持 PowerShell 7。克隆仓库后，在仓库根目录执行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

安装器会：

1. 将仓库路径写入用户环境变量 `PS_PROFILE_ROOT`。
2. 在 PowerShell 7 的 `$PROFILE.CurrentUserCurrentHost` 中安装带标记的加载器。
3. 只替换本项目自己的加载区块，不改动 `$PROFILE` 中的其他内容。

仓库移动后重新执行一次安装器即可。若严格要求脚本输出不受任何 Profile 影响，使用 `pwsh -NoProfile`。

## 本机路径

首次使用时复制路径模板：

```powershell
Copy-Item .\location.example.ps1 .\location.ps1
```

然后在 `location.ps1` 中填写本机真实路径：

```powershell
$global:PSProfileConfig.Paths = [ordered]@{
    work   = 'C:\Path\To\Work'
    server = 'C:\Path\To\Server'
    repo   = 'C:\Path\To\Repositories'
}
```

路径键名会直接成为 `dev` 的参数，并参与 Tab 补全。新增路径只需修改 `location.ps1`，无需修改函数代码。

## 可同步配置

`env.ps1` 保存功能开关和 PSReadLine 设置，不使用环境变量向子进程传播内部配置：

```powershell
$global:PSProfileConfig = [ordered]@{
    Features = [ordered]@{
        Dev        = $true
        Git        = $true
        Run        = $true
        PSReadLine = $true
    }
    PSReadLine = [ordered]@{
        PredictionSource             = 'History'
        PredictionViewStyle          = 'ListView'
        HistorySearchCursorMovesToEnd = $true
    }
    Paths = [ordered]@{}
}
```

PSReadLine 仅在交互式终端中配置，默认使用历史预测和列表视图；上下方向键按照已输入的前缀搜索历史命令。

关闭 `Dev`、`Git` 或 `Run` 后执行 `pp reload`，对应命令会从当前 Shell 中卸载。`Dev` 关闭时不会读取 `location.ps1`，帮助和自检也不会展示或检查本机路径。

## 命令说明

直接执行 `pp` 或 `pp help` 可以随时查看简要用法。

| 命令 | 用途 |
| --- | --- |
| `pp help` | 显示简要命令说明 |
| `pp doctor` | 检查 PowerShell 版本、加载器、路径和外部依赖 |
| `pp reload` | 在当前窗口重新加载配置与函数 |
| `pp root` | 进入本仓库目录 |
| `dev <名称>` | 进入 `location.ps1` 中配置的目录 |
| `g f` | 执行 `git fetch --all --prune` |
| `g sync` | 获取远端信息成功后执行 `git pull --ff-only` |
| `g vv` | 查看本地分支及其上游 |
| `g sw <分支>` | 使用 `git switch` 切换分支 |
| `run wsl` | 以 root 进入 WSL |
| `run wsl user` | 使用 WSL 配置的默认普通用户 |

所有入口在缺少参数时都会显示简短用法，不进入 PowerShell 的参数补问。

## 自检与修复

```powershell
pp doctor
```

`pp doctor` 只报告 `OK / WARN / FAIL`，不会安装软件、重写加载器或修改配置。若加载器或 `PS_PROFILE_ROOT` 有问题，在 PowerShell 7 中重新执行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

外部依赖也不会由本仓库安装。启用相关功能前，应自行准备 Git、WSL 和 PSReadLine。

## 许可证

本项目采用 GNU General Public License v3.0（GPL-3.0-only）。
