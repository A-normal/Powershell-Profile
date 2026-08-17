# Powershell-Profile

版权所有 © 2026 修仙者一号。许可证：GNU GPL v3.0（GPL-3.0-only）。

这是面向个人多台 Windows 电脑的 PowerShell 7 配置，提供路径跳转、白名单任务、Git 快捷命令、PSReadLine 交互设置和环境自检。仓库只同步通用能力，真实路径和实际任务保存在本机配置中。

## 文件结构

```text
profile.ps1
core/
  core.ps1
  invoke-task.ps1
functions/
  dev.ps1
  git.ps1
  jump.ps1
  psreadline.ps1
  run.ps1
install.ps1
env.ps1                 # 可同步：功能与交互配置
location.example.ps1    # 可同步：本机路径模板
tasks.example.ps1       # 可同步：本机任务模板
location.ps1            # 仅本机：真实路径，已被 Git 忽略
tasks.ps1               # 仅本机：真实任务，已被 Git 忽略
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

## 本机配置

首次使用时复制两个模板：

```powershell
Copy-Item .\location.example.ps1 .\location.ps1
Copy-Item .\tasks.example.ps1 .\tasks.ps1
```

`location.ps1` 保存路径键和真实目录：

```powershell
$global:PSProfileConfig.Paths = [ordered]@{
    project = 'C:\Path\To\Project'
    repo    = 'C:\Path\To\Repositories'
}
```

路径键会成为 `j` 的参数，也可被任务通过 `PathKey` 引用。新增路径只需修改本机文件。

`tasks.ps1` 保存开发任务和运行目标。任务必须把可执行程序与参数数组分开声明：

```powershell
$global:PSProfileConfig.Development = [ordered]@{
    project = [ordered]@{
        PathKey = 'project'
        Actions = [ordered]@{
            action = [ordered]@{
                Executable = 'tool'
                Arguments  = @('argument')
            }
        }
    }
}
```

`dev` 和 `run` 只执行配置表中精确匹配的项目、目标和动作，不接受额外参数。任务执行器不使用 `Invoke-Expression`，不会解释或拼接命令字符串。配置了工作目录时，执行结束后会恢复原目录；子目录也不能越过对应的项目根目录。

## 可同步配置

`env.ps1` 保存功能开关和 PSReadLine 设置，不包含真实路径或实际任务：

```powershell
$global:PSProfileConfig = [ordered]@{
    Features = [ordered]@{
        Jump       = $true
        Dev        = $true
        Git        = $true
        Run        = $true
        PSReadLine = $true
    }
    Paths       = [ordered]@{}
    Development = [ordered]@{}
    RunTargets  = [ordered]@{}
}
```

PSReadLine 仅在交互式终端中配置，默认使用历史预测和列表视图；上下方向键按照已输入的前缀搜索历史命令。

关闭 `Jump`、`Dev`、`Git` 或 `Run` 后执行 `pp reload`，对应命令会从当前 Shell 中卸载。所有相关功能都关闭时，不会读取本机路径和任务配置；帮助和自检也会按功能开关过滤。

## 命令说明

直接执行 `pp` 或 `pp help` 可以随时查看简要用法。

| 命令 | 用途 |
| --- | --- |
| `pp help` | 显示简要命令说明 |
| `pp doctor` | 检查 PowerShell、加载器、路径、任务和外部依赖 |
| `pp reload` | 在当前窗口重新加载配置与函数 |
| `pp root` | 进入本仓库目录 |
| `j <名称>` | 进入 `location.ps1` 中配置的目录 |
| `dev <项目> <动作>` | 在项目目录中执行预设开发任务 |
| `run <目标> [动作]` | 启动预设应用或运行环境 |
| `g f` | 执行 `git fetch --all --prune` |
| `g sync` | 获取远端信息成功后执行 `git pull --ff-only` |
| `g vv` | 查看本地分支及其上游 |
| `g sw <分支>` | 使用 `git switch` 切换分支 |

`j`、`dev` 和 `run` 会根据本机配置动态提供 Tab 补全。所有入口在缺少参数时都会显示简短用法，不进入 PowerShell 的参数补问。

## 自检与修复

```powershell
pp doctor
```

`pp doctor` 会检查本机配置结构、路径引用、工作目录边界和任务依赖，只报告 `OK / WARN / FAIL`，不会执行任务、安装软件、重写加载器或修改配置。

若加载器或 `PS_PROFILE_ROOT` 有问题，在 PowerShell 7 中重新执行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

外部依赖不会由本仓库安装。启用相关功能前，应自行准备对应工具。

## 许可证

本项目采用 GNU General Public License v3.0（GPL-3.0-only）。
