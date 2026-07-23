# ProjectR 可操作范围总表（soft-ue-cli）

更新日期：2026-04-01

本文不是泛泛介绍，而是基于当前 `soft-ue-cli` 仓库能力、当前 `ProjectR` 接入状态、以及对 `ProjectR` 的实时查询结果整理出的可操作范围说明。目标是回答一个具体问题：

`如果让我对 D:\Git\Github\UESource\ProjectR 进行操作，我现在到底能动哪些东西，能动到什么深度，哪些能读不能写，哪些当前还不能直接做。`

## 1. 当前实测状态

- 目标项目：`D:\Git\Github\UESource\ProjectR`
- 项目文件：`D:\Git\Github\UESource\ProjectR\ProjectR.uproject`
- 引擎版本：`5.7.4-0+UE5`
- `SoftUEBridge`：已在 `ProjectR.uproject` 中启用
- Bridge 地址：`http://127.0.0.1:8080`
- 当前 Bridge 状态：`running = true`
- 当前会话报告的工具数：`52`
- 当前 UE 进程上报的插件版本：`1.3.2`

注意：

- 当前仓库里的 CLI 版本是 `1.6.1`。
- 当前仓库内置的插件包版本声明也已经同步为 `1.6.1`。
- 但 `ProjectR` 当前运行中的 UE 会话仍上报 `1.3.2`。
- 这意味着：`ProjectR` 现在的桥接能力大体可用，但若要保证和本仓库完全一致，仍建议把最新插件重新安装到项目并重新编译启动一次。

## 2. ProjectR 当前内容快照

以下数据来自对 `ProjectR` 的实时查询，范围限定在 `/Game`：

| 类型 | 当前匹配数 | 示例 |
| --- | ---: | --- |
| Blueprint | 2552 | `/Game/Art/BP/BP_BattleLight` |
| AnimBlueprint | 45 | `/Game/Gameplay/Character/AnimBp_Template` |
| WidgetBlueprint | 252 | `/Game/Gameplay/UI/GameUI/Dialog/UMG_CommonDialog` |
| Material | 759 | `/Game/Art_6/Shader/Master/UI/M_UI_ScreenDot` |
| MaterialInstanceConstant | 4268 | `/Game/Art_6/Shader/MI/UI/MI_UI_ScreenDot` |
| NiagaraSystem | 616 | `/Game/Art_6/UI/UI_Fx/Niagara/Map/NS_UI_HeiSeGuoChang_02` |
| DataTable | 9 | `/Game/GameConfigs/DataTable/DataTableRichTextStyle` |
| StateTree | 0 | 当前查询未发现 `/Game` 下 StateTree 资产 |

从 `ProjectR.uproject` 看，项目本身启用了 `Niagara`、`NiagaraFluids`、`NiagaraUIRenderer`、`GameplayAbilities`、`KawaiiPhysics`、`PhysicsControl` 等插件，因此文档中对这些领域的判断不是空谈，而是和项目实际内容相关。

## 3. 总体结论

如果 `ProjectR` 的 UE 编辑器处于运行状态，且 `SoftUEBridge` 可达，那么我现在对 `ProjectR` 的能力可以分成四层：

1. 连接与诊断层
2. 运行时世界与调试层
3. 资产检索与只读分析层
4. 部分资产写入与图编辑层

最重要的结论是：

- `Blueprint / AnimBlueprint / Material / WidgetBlueprint / DataTable / 运行时 Actor / PIE / 日志 / 截图 / 构建 / Python` 这些板块，我现在是可以实际操作的。
- `Niagara` 我现在能做的是“查、找、开、预览、引用分析、结合运行时验证效果”，但没有专用的 Niagara 图和模块栈编辑能力。
- `Niagara 暂存模块 / Scratch Pad Module / Niagara Module Stack` 当前没有直接命令支持，不能承诺直接改。
- `StateTree` 命令层面支持读写，但 `ProjectR` 当前实时查询没有发现 StateTree 资产。

## 4. 操作前提

### 4.1 必要前提

- UE 编辑器或运行时实例必须已启动。
- `SoftUEBridge` 插件必须已加载。
- `http://127.0.0.1:8080/bridge` 必须可达，或者项目目录下存在有效的 `.soft-ue-bridge/instance.json`。

### 4.2 不同命令的运行条件

- 纯查询型资产命令：需要编辑器进程在线。
- 运行时命令：需要当前世界存在，部分命令要求 PIE。
- `inspect-runtime-widgets`：必须在 PIE 会话中。
- `trigger-input`：通常对 PIE 或运行中的 Game 实例才有意义。
- `build-and-relaunch` / `trigger-live-coding`：要求当前工程可编译，且编辑器环境允许该流程执行。

### 4.3 当前版本对齐提醒

- 当前 `ProjectR` 在线会话上报插件版本还是 `1.3.2`。
- 本仓库已经是 `1.6.1`。
- 因此本文写的是“当前 CLI 能力 + 当前项目接入状态”的组合视图。
- 若要让本文和项目现场 100% 对齐，建议先重新把最新 `SoftUEBridge` 装进 `ProjectR` 并重编译。

## 5. 我现在能操作哪些大板块

## 5.1 连接、健康检查、项目信息

能做：

- 检查插件文件是否存在
- 检查 `.uproject` 是否启用了 `SoftUEBridge`
- 检查 Bridge 服务是否可连通
- 获取项目名、项目路径、引擎版本、插件版本、Bridge 端口
- 获取类继承关系

对应命令：

- `check-setup`
- `status`
- `project-info`
- `class-hierarchy`

适合用途：

- 确认 `ProjectR` 是否接好
- 快速验证当前是哪个项目、哪个引擎、哪个插件版本
- 确认某个类的父类、子类、继承链

## 5.2 运行时关卡、Actor、属性、函数

能做：

- 查询当前关卡中的 Actor
- 按名称、类、搜索词、Tag 过滤 Actor
- 查询组件列表
- 查询 Actor 和组件的属性值
- 运行时调用 `BlueprintCallable` 函数
- 运行时修改 Actor / 组件属性
- 运行时读取 Actor / 组件属性
- 运行时生成 Actor

对应命令：

- `query-level`
- `spawn-actor`
- `call-function`
- `set-property`
- `get-property`

细节能力：

- `query-level` 不只是返回名字，还能带位置、旋转、缩放。
- 可以打开 `--components` 看组件。
- 可以打开 `--include-properties` 看 Actor 和组件属性。
- 还能看 `--include-foliage` 和 `--include-grass` 相关信息。

当前实测：

- 当前地图可读到 `Map_0`。
- 运行时查询已能返回当前世界中的 Actor 列表。

适合用途：

- 查当前地图里有哪些对象
- 定位某个蓝图类是否真的生成了
- 动态调试灯光、特效触发器、交互对象
- 对场景对象做无侵入读取或小范围运行时改动

## 5.3 日志、控制台变量、输入、PIE

能做：

- 读取输出日志
- 按过滤条件查日志
- 读取和写入 CVar
- 启动 / 停止 / 暂停 / 恢复 PIE
- 向 PIE 或运行中的游戏发送输入

对应命令：

- `get-logs`
- `get-console-var`
- `set-console-var`
- `pie-session`
- `trigger-input`

适合用途：

- 验证功能是否报错
- 调整渲染和调试类 CVar
- 自动化触发一段交互流程
- 在 PIE 中复现 UI 或玩法问题

## 5.4 资产搜索、打开、预览、差异、引用

能做：

- 全项目搜索资产
- 按类、路径、模式匹配搜索
- 对指定资产做属性级 inspect
- 打开资产编辑器
- 取资产预览图
- 查看资产 diff
- 查找引用关系

对应命令：

- `query-asset`
- `open-asset`
- `get-asset-preview`
- `get-asset-diff`
- `find-references`

适合用途：

- 找某个 UI、特效、材质、蓝图到底在哪
- 查某个资产被哪些蓝图或其他资源引用
- 在改动前先取预览、对比差异

注意：

- `query-asset` 是一切内容盘点的基础工具。
- 只要资产能被 Unreal 资产注册表识别，它通常就能被搜索到。
- 但“能搜索到”不等于“有专用编辑命令”。

## 5.5 Blueprint 资产级读写

能做：

- 查询 Blueprint 的函数、变量、组件、默认值、图信息
- 查询 Blueprint 图结构
- 添加组件
- 改 Blueprint CDO 或组件属性
- 修改实现接口
- 创建 Blueprint 资产

对应命令：

- `query-blueprint`
- `query-blueprint-graph`
- `add-component`
- `set-asset-property`
- `modify-interface`
- `create-asset`

图编辑能力：

- `add-graph-node`
- `remove-graph-node`
- `connect-graph-pins`
- `disconnect-graph-pin`
- `insert-graph-node`
- `set-node-position`
- `set-node-property`
- `compile-blueprint`
- `save-asset`

这意味着我对 Blueprint 的能力不是只读，而是已经到“图级编辑”：

- 可以往图里加节点
- 可以删节点
- 可以连线 / 断线
- 可以在两节点之间插入新节点
- 可以设置节点属性
- 可以编译和保存

适合用途：

- 自动加函数节点
- 批量修蓝图图线
- 自动加组件、改组件默认值
- 改接口实现
- 做规则化的蓝图资产修改

当前实测：

- `ProjectR` 当前 `/Game` 下 Blueprint 数量很多，说明这块是高价值板块。
- 示例资产：`/Game/Art/BP/BP_BattleLight`

## 5.6 AnimBlueprint、AnimLayer、动画图

能做：

- 创建 AnimBlueprint
- 查询 AnimBlueprint 结构和图
- 在动画图里加节点
- 在两个动画节点之间插入节点
- 设置动画图节点属性
- 编译和保存 AnimBlueprint
- 修改接口，包含 AnimLayerInterface 相关操作

对应命令：

- `create-asset ... AnimBlueprint --skeleton`
- `query-blueprint`
- `query-blueprint-graph`
- `add-graph-node`
- `insert-graph-node`
- `set-node-property`
- `modify-interface`
- `compile-blueprint`
- `save-asset`

细节能力：

- `add-graph-node` 明确支持 `AnimLayerFunction`
- `insert-graph-node` 明确支持 `AnimGraphNode_LinkedAnimLayer`
- `set-node-property` 明确支持动画图节点的内部结构属性和 pin 默认值

适合用途：

- 自动化构建或修补 AnimGraph
- 给动画节点补默认参数
- 批量插入 Layer、过渡节点、功能节点

当前实测：

- `ProjectR` 当前 `/Game` 下存在 45 个 AnimBlueprint。

当前边界：

- 没有看到针对 `Animation Sequence`、`Montage`、`Notify Track`、`BlendSpace`、`Control Rig` 的专用命令。
- 所以动画图可改，不代表所有动画资产类型都能深度改。

## 5.7 材质、材质实例、材质图、MPC

这是当前能力里非常强的一块。

能做：

- 查询 Material / MaterialInstance 参数
- 查询材质图节点
- 看节点位置
- 看父材质链
- 按参数名过滤
- 创建 Material 资产
- 对 Material 图添加节点
- 删除节点
- 连接节点
- 断开节点
- 调整节点位置
- 读写 Material Parameter Collection

对应命令：

- `query-material`
- `query-mpc`
- `create-asset ... Material`
- `add-graph-node`
- `remove-graph-node`
- `connect-graph-pins`
- `disconnect-graph-pin`
- `set-node-position`
- `save-asset`

当前实测：

- `ProjectR` `/Game` 下 Material 约 759 个
- `ProjectR` `/Game` 下 MaterialInstanceConstant 约 4268 个
- 示例材质：`/Game/Art_6/Shader/Master/UI/M_UI_ScreenDot`
- 实测 `query-material` 已能读出该材质的标量参数、向量参数、纹理参数

对材质能做到的粒度：

- 查参数名和值
- 看图结构
- 往图里加表达式节点
- 对节点做连线和断线
- 改布局位置
- 对 `MPC` 做读和写

这意味着以下事情是可以做的：

- 排查材质实例参数来源
- 分析主材质结构
- 给材质图插入 / 删除部分表达式节点
- 调试和修改 `MPC` 运行时参数

当前边界：

- 没有专门的 `MaterialFunction` 管理命令。
- 没有专门的“材质表达式创建后任意属性编辑”命令文档化承诺，写能力主要体现在图节点增删连断和创建时带属性。
- 对非常复杂的材质图批量改造可以做，但需要逐资产验证。

## 5.8 UMG、WidgetBlueprint、运行时 Widget

能做：

- 查询 WidgetBlueprint 的完整控件树
- 查看 slot 属性
- 查看绑定
- 查看动画
- 查看默认值
- 在 WidgetBlueprint 中新增控件
- 在 PIE 中查看运行时 Widget 树
- 看运行时几何、层级、属性
- 可选查看底层 Slate 数据

对应命令：

- `inspect-widget-blueprint`
- `inspect-runtime-widgets`
- `add-widget`
- `capture-screenshot`
- `capture-viewport`

当前实测：

- `ProjectR` `/Game` 下 WidgetBlueprint 约 252 个
- 示例：`/Game/Gameplay/UI/GameUI/Dialog/UMG_CommonDialog`
- 实测已经能读出该 Widget Blueprint 的层级、slot、命名控件和总控件数

能做到的典型事情：

- 把某个 UI 蓝图的树结构完整导出来
- 看控件 anchoring、offset、alignment、z-order
- 在 PIE 里查某个控件有没有生成、在哪、尺寸是多少
- 增加新的 Widget 到 Widget Blueprint

当前边界：

- 没有显式 `remove-widget` 命令。
- 没有专用“批量改动画轨、时序”的 Widget 动画编辑命令。
- 运行时 Widget 检查依赖 PIE。

## 5.9 DataTable

能做：

- 搜索和定位 DataTable
- inspect DataTable 结构和行
- 新增或更新行
- 创建 DataTable

对应命令：

- `query-asset --asset-path <DataTable>`
- `add-datatable-row`
- `create-asset ... DataTable --row-struct`

当前实测：

- `ProjectR` `/Game` 下 DataTable 约 9 个
- 示例：`/Game/GameConfigs/DataTable/DataTableRichTextStyle`

适合用途：

- 修配置表
- 生成测试行
- 对接玩法配置批量化处理

当前边界：

- 没有单独暴露 `delete-datatable-row` 命令。

## 5.10 StateTree

命令层面支持：

- `query-statetree`
- `add-statetree-state`
- `add-statetree-task`
- `add-statetree-transition`
- `remove-statetree-state`

能力上意味着：

- 能读取 StateTree 的状态层级、任务、转换、评估器、参数
- 能新增状态
- 能新增任务
- 能新增转换
- 能删除状态

当前实测：

- `ProjectR` `/Game` 当前没有查到 StateTree 资产

结论：

- 这是“CLI 支持，但 ProjectR 当前未发现实际资产”的板块。
- 如果之后项目里出现 StateTree，这块可以直接用。

## 5.11 Niagara、特效、VFX

这是最需要说清边界的一块。

### 现在明确能做的

- 搜索 Niagara 资产
- 打开 Niagara 资产
- 获取预览图
- 查引用
- 结合运行时日志、截图、PIE、Actor 查询去验证 Niagara 效果是否被触发
- 查询承载 Niagara 的蓝图、组件、材质、UI 资产

对应命令：

- `query-asset --class NiagaraSystem`
- `query-asset --class NiagaraEmitter`
- `open-asset`
- `get-asset-preview`
- `find-references`
- `query-level`
- `get-logs`
- `capture-screenshot`
- `capture-viewport`

当前实测：

- `ProjectR` `/Game` 下 NiagaraSystem 约 616 个
- 全库可见 NiagaraEmitter 约 85 个
- 示例系统：`/Game/Art_6/UI/UI_Fx/Niagara/Map/NS_UI_HeiSeGuoChang_02`

### 现在没有专用命令支持的

以下内容当前不能直接承诺“可编辑”：

- Niagara System 图结构查询
- Niagara Emitter 图结构查询
- Niagara Module Stack 编辑
- Niagara Module 增删
- Niagara Scratch Pad / 暂存模块编辑
- Niagara Renderer 配置深改
- Niagara 参数绑定图编辑
- Niagara Script / Data Interface 连线编辑
- Simulation Stage 编辑

换句话说：

- 对 Niagara，我现在更强的是“检索、定位、打开、分析引用、结合运行时验证”。
- 不是“像改 Blueprint Graph 那样直接改 Niagara Graph”。

### 关于“Niagara 的暂存模块”

如果你指的是：

- Scratch Pad Module
- 临时模块
- Niagara Stack 里的自定义模块
- 发射器脚本 / 粒子更新脚本中的模块项

那么当前版本没有直接对应命令。我不能像改 Blueprint 节点或材质节点那样，直接对它们做图级编辑。

## 5.12 特效相关的其它可控点

虽然没有 Niagara 图编辑，但特效链路中以下部分仍然可控：

- 承载特效的蓝图逻辑
- 触发特效的运行时 Actor
- 控制特效参数的材质和 `MPC`
- UI 特效相关 Widget 层级
- 运行时输入、PIE 和截图验证流程

因此对“特效系统整体联调”仍然有价值，只是“特效资产本体的 Niagara 图编辑”目前不是强项。

## 5.13 截图、视口、可视化验证

能做：

- 捕获编辑器窗口
- 捕获指定 tab
- 捕获区域
- 捕获 viewport
- 直接抓当前可视状态做验证

对应命令：

- `capture-screenshot`
- `capture-viewport`

适合用途：

- 验证材质、UI、关卡对象、特效是否按预期显示
- 跟日志、运行时对象查询搭配做回归检查

## 5.14 Python、构建、热更、重启、性能分析

能做：

- 在 UE 内执行 Python
- 保存、列出、删除本地脚本
- 触发 Live Coding
- 触发构建并等待重启
- 开始 / 停止 Insights 采集
- 列出 trace
- 分析 trace

对应命令：

- `run-python-script`
- `save-script`
- `list-scripts`
- `delete-script`
- `trigger-live-coding`
- `build-and-relaunch`
- `insights-capture`
- `insights-list-traces`
- `insights-analyze`

适合用途：

- 执行一次性的编辑器脚本
- 对大改前后的性能做采样
- 做半自动化重编译和回起

## 6. 按“读 / 写 / 运行时验证”分类汇总

## 6.1 只读很强的板块

- 项目状态与连接
- 关卡对象查询
- 日志
- CVar 读取
- 资产搜索
- 材质参数与图查询
- Blueprint 结构查询
- WidgetBlueprint 树查询
- 运行时 Widget 树查询
- 引用查询
- 项目信息
- 类层级

## 6.2 明确可写的板块

- 运行时 Actor 生成
- 运行时属性设置
- 运行时函数调用
- Blueprint 图编辑
- AnimBlueprint 图编辑
- 材质图节点增删连断
- MPC 读写
- WidgetBlueprint 加控件
- DataTable 加行 / 改行
- 创建 Blueprint / Material / DataTable / WidgetBlueprint / AnimBlueprint
- 编译蓝图
- 保存资产
- Live Coding / 构建重启

## 6.3 当前偏“辅助验证”而不是“深写”的板块

- NiagaraSystem
- NiagaraEmitter
- 特效系统整体联调
- 某些复杂动画资产类型
- 某些复杂材质表达式后期属性编辑

## 7. 当前没有直接专用支持的板块

以下板块当前没有看到明确的专用命令，不能直接承诺“深度可编辑”：

- Niagara Graph / Module Stack / Scratch Pad
- Sequencer / Level Sequence
- Control Rig
- Animation Sequence / Montage / BlendSpace 专项编辑
- Skeletal Mesh / Static Mesh 深度编辑
- Landscape 雕刻 / 绘制
- Foliage 编辑
- 音频资产专项编辑
- Particle System（Cascade）专项编辑
- Physics Asset / Chaos 约束专项编辑
- Behavior Tree 专项编辑

注意：

- “没有专用命令”不等于“完全无法触及”。
- 某些内容仍可通过上层蓝图、运行时对象、日志、截图、Python 等方式间接联调。
- 但不能把这种间接能力误写成“原生深度编辑能力”。

## 8. 对 ProjectR 最有价值的实际使用方向

如果目标是对 `ProjectR` 提效，当前最有价值的方向是：

- Blueprint / AnimBlueprint 图改造
- 材质 / 材质实例 / MPC 分析与联调
- UI 蓝图结构分析与运行时 Widget 排查
- DataTable 配置调整
- Actor 级运行时验证
- 日志 / 截图 / 输入 / PIE 联调
- Build + Live Coding + 性能采样
- Niagara 资产定位、引用分析、运行时验证

## 9. 最后一句话总结

对 `ProjectR` 来说，`soft-ue-cli` 现在最强的是：

- `蓝图图编辑`
- `动画蓝图图编辑`
- `材质与 MPC 分析/局部编辑`
- `UI 结构与运行时排查`
- `运行时 Actor / 日志 / 输入 / PIE 联调`
- `资产搜索、打开、引用分析、预览`

对 `ProjectR` 来说，当前还不应过度承诺的是：

- `Niagara 暂存模块 / Scratch Pad / 模块栈的直接编辑`
- `Sequencer / Control Rig / Animation Sequence 等专项资产的深写`

## 10. 附录：当前命令按板块整理

### 10.1 接入与诊断

- `setup`
- `check-setup`
- `status`
- `project-info`
- `class-hierarchy`

### 10.2 运行时世界

- `spawn-actor`
- `query-level`
- `call-function`
- `set-property`
- `get-property`

### 10.3 日志、输入、会话

- `get-logs`
- `get-console-var`
- `set-console-var`
- `pie-session`
- `trigger-input`

### 10.4 资产与内容浏览

- `query-asset`
- `delete-asset`
- `get-asset-diff`
- `get-asset-preview`
- `open-asset`
- `find-references`

### 10.5 Blueprint / AnimBlueprint / 图编辑

- `query-blueprint`
- `query-blueprint-graph`
- `add-component`
- `set-asset-property`
- `add-graph-node`
- `remove-graph-node`
- `connect-graph-pins`
- `disconnect-graph-pin`
- `insert-graph-node`
- `set-node-position`
- `set-node-property`
- `modify-interface`
- `compile-blueprint`
- `save-asset`
- `create-asset`

### 10.6 材质

- `query-material`
- `query-mpc`
- `add-graph-node`
- `remove-graph-node`
- `connect-graph-pins`
- `disconnect-graph-pin`
- `set-node-position`
- `create-asset`
- `save-asset`

### 10.7 UMG

- `inspect-widget-blueprint`
- `inspect-runtime-widgets`
- `add-widget`

### 10.8 DataTable

- `add-datatable-row`
- `query-asset --asset-path`
- `create-asset`

### 10.9 StateTree

- `query-statetree`
- `add-statetree-state`
- `add-statetree-task`
- `add-statetree-transition`
- `remove-statetree-state`

### 10.10 Python、构建、分析

- `run-python-script`
- `save-script`
- `list-scripts`
- `delete-script`
- `build-and-relaunch`
- `trigger-live-coding`
- `insights-capture`
- `insights-list-traces`
- `insights-analyze`

### 10.11 可视化验证

- `capture-screenshot`
- `capture-viewport`
