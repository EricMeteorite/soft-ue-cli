# soft-ue-cli 本地独立部署与使用指南

## 1. 你现在要达到的目标

你提出的要求可以拆成两层：

1. soft-ue-cli 本身必须 100% 只在当前仓库目录里安装和运行。
2. 想让 UE 项目真正响应命令，UE 进程里必须存在 SoftUEBridge 插件。

第 1 点可以做到完全独立。

第 2 点无法做到“零项目接触”，因为没有插件就没有桥接服务，CLI 也就无法控制 UE。能做到的最小影响方案是：

1. 不改系统环境。
2. 不改引擎目录。
3. 只在目标 UE 项目目录里增加一个项目级插件目录，并在 .uproject 里启用它。
4. 需要时可以一键卸载，恢复到未接入状态。

这也是本仓库现在支持的最安全接入边界。

## 2. 当前仓库分析结果

这个项目由两部分组成：

1. Python CLI: soft_ue_cli
2. Unreal 插件: soft_ue_cli/plugin_data/SoftUEBridge

工作链路如下：

1. 你在终端执行 soft-ue-cli 命令。
2. Python CLI 用 HTTP/JSON-RPC 请求本地桥接地址。
3. UE 里的 SoftUEBridge 插件在 127.0.0.1 上开启本地服务。
4. 插件在 UE 主线程里执行操作并返回 JSON。

关键结论：

1. Python 侧运行时依赖只有 httpx。
2. 项目测试已通过，当前仓库在本地 .venv 中可独立运行。
3. 插件不会改引擎源码，它按项目级插件方式接入。
4. 插件启动后会在目标项目根目录下写入 .soft-ue-bridge/instance.json，用于让 CLI 自动发现端口。
5. 插件默认只绑定 127.0.0.1，而不是对外网开放。

## 3. 我已经为你准备好的内容

我在当前仓库新增了以下脚本：

1. tools/bootstrap-local.ps1
作用：在当前仓库内创建或复用 .venv，并安装 soft-ue-cli 与测试依赖，然后自动跑验证。

2. tools/soft-ue-cli.ps1
作用：不激活虚拟环境，直接调用仓库内 .venv 运行 CLI。

3. tools/soft-ue-cli.cmd
作用：Windows 命令行包装器，双击或 cmd 下都能直接调用。

4. tools/install-project-plugin.ps1
作用：把插件复制到某个 UE 项目的 Plugins/SoftUEBridge，并自动写入 .uproject 的 Plugins 配置。

5. tools/uninstall-project-plugin.ps1
作用：从 UE 项目里移除插件目录、移除 .uproject 插件项，并清理 .soft-ue-bridge 运行状态目录。

## 4. 当前已经验证过什么

我已经在当前仓库目录内完成并验证了下面这些步骤：

1. 使用当前仓库下的 .venv 进行本地安装。
2. 仅在 .venv 内安装 soft-ue-cli 和 pytest。
3. 完整执行 tools/bootstrap-local.ps1。
4. 运行测试套件。
5. 测试结果：112 passed。
6. 在仓库内的沙盒 UE 项目上验证了 install-project-plugin.ps1 与 uninstall-project-plugin.ps1，确认它们可以安装并完整回退。

这意味着 Python CLI 侧已经满足“只在本文件夹中安装和运行”的要求。
同时也意味着项目级接入脚本本身已经做过一次仓库内验证，但我没有触碰你的真实 ProjectR。

## 5. 第一步：只部署 soft-ue-cli 本体

在当前仓库根目录打开 PowerShell，然后执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\bootstrap-local.ps1
```

完成后，你就可以用下面任意一种方式运行 CLI：

```powershell
.\tools\soft-ue-cli.cmd --help
```

或者：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\soft-ue-cli.ps1 --help
```

注意：

1. 不需要 activate 虚拟环境。
2. 不需要 pip install 到系统环境。
3. 不会改 PATH。
4. 删除本仓库目录后，Python 侧不会在系统里留下任何安装痕迹。

## 6. 第二步：以最小影响方式接入你的 UE 项目

你的环境是：

1. 源码版引擎目录：D:/Git/Github/UESource/UnrealEngine56
2. UE 项目目录：D:/Git/Github/UESource/ProjectR

如果你要让 soft-ue-cli 真正控制这个项目，请执行下面这一步。它不会改引擎目录，只会改 ProjectR 自己。

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\install-project-plugin.ps1 -ProjectRoot "D:\Git\Github\UESource\ProjectR"
```

这个脚本只会做两件事：

1. 复制插件到 ProjectR/Plugins/SoftUEBridge
2. 在 ProjectR 根目录下的 .uproject 文件里启用 SoftUEBridge

不会做的事情：

1. 不改引擎目录。
2. 不改系统环境变量。
3. 不安装系统级 Python 包。
4. 不写注册表。
5. 不修改除目标项目之外的任何地方。

## 7. 第三步：重新生成并编译 UE 项目

插件复制到项目后，UE 还不知道新加了一个 C++ 插件，所以需要重新生成并编译。

建议流程：

1. 关闭 Unreal Editor。
2. 对 ProjectR 的 .uproject 重新生成项目文件。
3. 用你的源码版引擎对应的 IDE 工程编译 ProjectR Editor。
4. 启动编辑器。

只要你是项目级插件接入，就不会修改 UnrealEngine56 本身。

## 8. 第四步：确认桥接服务是否启动

启动编辑器后，插件会尝试在本机 127.0.0.1 上启动本地服务，默认从 8080 开始找可用端口。

然后在当前仓库根目录执行：

```powershell
.\tools\soft-ue-cli.cmd check-setup "D:\Git\Github\UESource\ProjectR"
```

如果一切正常，你会看到三类检查：

1. 插件文件存在。
2. .uproject 已启用 SoftUEBridge。
3. Bridge server 可连接。

## 9. 第五步：开始使用

先看帮助：

```powershell
.\tools\soft-ue-cli.cmd --help
```

常用命令示例：

查看桥状态：

```powershell
.\tools\soft-ue-cli.cmd status
```

查看当前关卡对象：

```powershell
.\tools\soft-ue-cli.cmd query-level --limit 20
```

按类筛选对象：

```powershell
.\tools\soft-ue-cli.cmd query-level --class-filter StaticMeshActor --limit 20
```

生成 Actor：

```powershell
.\tools\soft-ue-cli.cmd spawn-actor PointLight --location 0,0,300 --rotation 0,0,0
```

读取控制台变量：

```powershell
.\tools\soft-ue-cli.cmd get-console-var r.VSync
```

设置控制台变量：

```powershell
.\tools\soft-ue-cli.cmd set-console-var r.VSync 0
```

抓取日志：

```powershell
.\tools\soft-ue-cli.cmd get-logs --lines 50
```

开始 PIE：

```powershell
.\tools\soft-ue-cli.cmd pie-session start --mode SelectedViewport
```

停止 PIE：

```powershell
.\tools\soft-ue-cli.cmd pie-session stop
```

截图：

```powershell
.\tools\soft-ue-cli.cmd capture-screenshot viewport --output screenshot.png
```

## 10. 最适合小白的实际使用顺序

建议你严格按这个顺序来：

1. 先运行 tools/bootstrap-local.ps1
2. 再运行 tools/soft-ue-cli.cmd --help
3. 确认你能看到完整帮助
4. 再执行 install-project-plugin.ps1，把插件接入 ProjectR
5. 重新生成并编译 ProjectR
6. 启动 UE 编辑器
7. 执行 tools/soft-ue-cli.cmd check-setup "D:\Git\Github\UESource\ProjectR"
8. 成功后先执行 status
9. 再执行 query-level
10. 最后再尝试 spawn-actor、PIE、截图等写操作

不要一开始就做会修改内容的命令。先读状态，再做写入，是最稳的。

## 11. 怎样做到可逆

如果你后面不想用了，在当前仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\uninstall-project-plugin.ps1 -ProjectRoot "D:\Git\Github\UESource\ProjectR"
```

这个脚本会：

1. 删除 ProjectR/Plugins/SoftUEBridge
2. 从 .uproject 里移除 SoftUEBridge 条目
3. 删除 ProjectR/.soft-ue-bridge

然后你还可以直接删除当前 soft-ue-cli 仓库目录。

这样清理后：

1. 系统环境不会留下 Python 包安装痕迹。
2. 引擎目录不会留下任何改动。
3. UE 项目也会被回退到未接入状态。

## 12. 重要现实边界

有一件事需要说清楚：

如果你的标准是“删除 soft-ue-cli 文件夹前，UE 项目和引擎都从未被接触过”，那就不可能真的控制 UE。

因为 soft-ue-cli 控制 UE 的前提，是 UE 项目里必须实际存在并编译过 SoftUEBridge 插件。

所以可实现的最优方案不是“零接触”，而是：

1. 引擎零接触。
2. 系统环境零接触。
3. 项目最小接触。
4. 项目接触完全可逆。

这已经是当前架构下的最小代价方案。

## 13. 如果 check-setup 失败，按这个顺序排查

1. 先确认项目里已经有 Plugins/SoftUEBridge
2. 再确认 .uproject 的 Plugins 数组里有 SoftUEBridge 且 Enabled 为 true
3. 再确认项目已经重新生成并编译
4. 再确认编辑器已经启动到项目主界面
5. 再看 UE 日志里有没有 SoftUEBridge server started 或 port unavailable 之类的日志
6. 最后再执行 tools/soft-ue-cli.cmd status 或 check-setup

## 14. 结论

现在这套方案满足以下目标：

1. Python CLI 彻底限制在当前仓库目录内运行。
2. 不污染系统 Python。
3. 不修改系统环境变量。
4. 不修改你的源码版引擎目录。
5. 只在需要时才对目标 UE 项目做项目级接入。
6. 可以通过卸载脚本回退项目改动。

对于你的使用场景，这是当前项目能实现的最稳妥部署方式。