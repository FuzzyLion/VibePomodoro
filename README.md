# VibePomodoro

Before coding:
1. Summarize current architecture
2. Explain where this feature should live
3. Then implement

## 0. 项目结构

以下结构作为当前 thread 与后续 threads 的统一颗粒度对齐基准；后续讨论默认以这一级别描述页面、共享 UI 和逻辑边界。

```text
VibePomodoro/
├── VibePomodoroApp.swift
├── ContentView.swift
├── PomodoroModels.swift
├── PomodoroStore.swift
├── Screens/
│   ├── Focus/
│   │   └── FocusScreen.swift
│   ├── Productivity/
│   │   └── ProductivityScreen.swift
│   └── Settings/
│       └── SettingsScreen.swift
├── Shared/
│   ├── Theme/
│   │   └── VibeTheme.swift
│   └── UI/
│       ├── SharedShell.swift
│       └── SectionTitle.swift
└── Assets.xcassets/
```

结构约定：

- 每个页面的 UI 设计只归属于自己的页面文件。
- 页面专属子视图默认与页面文件同驻，不放进共享层。
- 共享层只放跨页面复用的主题、背景、面板、标题等通用 UI。
- `Focus` 的 hierarchy 为保护区；后续线程若改设计，必须在不打散当前层级、不改变现有刷新边界的前提下进行。

## 0.1 State & Data Flow

这部分定义当前工程的状态归属、数据流方向与功能落点，后续 threads 默认以此为准，不重新发明一套状态结构。

### 0.1.1 当前架构摘要

- `VibePomodoroApp.swift` 创建单一 `@StateObject PomodoroStore`，并把它注入整个 app。
- `ContentView.swift` 只负责全局背景与 `TabView`，不承载业务状态机。
- `PomodoroModels.swift` 定义核心数据模型、统计结构和 `PomodoroEngine` 状态推进规则。
- `PomodoroStore.swift` 是运行时唯一 source of truth，负责状态持有、持久化、通知、scene phase 协调和副作用触发。
- `Screens/*` 负责页面级 UI 和页面专属子视图，不新增第二套全局状态源。
- `Shared/*` 只承载跨页面复用的主题与通用 UI 外壳。

### 0.1.2 单一状态来源

- 全局状态入口只有 `PomodoroStore`：
  - `selectedTab`
  - `settings`
  - `activeSession`
  - `completedSessions`
  - `productivityCache`
- `SessionSnapshot` 是当前 session 的完整快照：
  - step 列表
  - 当前 step index
  - run state
  - `currentSegmentStartDate`
  - `targetEndDate`
  - 已结算 `segments`
- `CompletedSession` 只表示已完成 session 的归档数据，不反向驱动当前计时状态。
- `ProductivityAggregateCache` 是由已完成 session 派生出的本地聚合缓存：
  - 指标卡总量
  - 按自然日切分的统计汇总
  - 已入账 `sessionID` 集合

### 0.1.3 数据流方向

- 用户交互流：
  - View 按钮点击
  - 调用 `PomodoroStore`
  - `PomodoroStore` 调用 `PomodoroEngine` 或直接更新设置
  - `PomodoroStore` 触发 `persist()` / `syncNotifications()` / `syncIdleTimer()` / `syncStepBoundaryTimer()`
  - `@Published` 状态变化回流到 SwiftUI View
- 时间推进流：
  - 真值来自 `Date` + `targetEndDate`
  - `PomodoroEngine.reconcile` 负责跨 step 补算
  - `TimelineView` 只负责显示刷新，不是状态真值来源
- 恢复流：
  - app 启动时 `PomodoroStore.init()` 先从 `UserDefaults` 读取
  - 然后 `reconcileNow()` 恢复 session
  - `scenePhase` 变回 `.active` 时再次补算并同步副作用
- 统计入账流：
  - `activeSession` 在运行期间只维护自己的 `segments`
  - `Productivity` 正式统计不读取进行中的 session
  - 只有在 `.sessionCompleted` 时，才把该 session 写入 `completedSessions` 并增量更新 `productivityCache`
  - cache 缺失、版本不匹配或 session 集合不一致时，从 `completedSessions` 全量重建

### 0.1.4 页面与状态边界

- `FocusScreen`：
  - 读取 `PomodoroStore`
  - 生成 `FocusRenderState`
  - 页面内只做显示层拆分，不能自建 session 状态机
  - 计时数字按 `1Hz` 刷新，气泡动画按低帧率刷新，仅在 `Focus` tab 可见且 session 运行时激活
- `ProductivityScreen`：
  - 通过 `store.productivitySnapshot(...)` 读取聚合后的统计快照
  - 正式统计只反映已完成 session
  - 范围选择只保留 `Week / Month / Year`
  - 页面本身不持有统计真值，只持有本地 UI 选择态 `selectedRange`
- `SettingsScreen`：
  - 直接绑定 `store.settings`
  - 设置修改只走 store 的 update/set 接口，不直接改 model 副本

### 0.1.5 功能应该放在哪里

- 改页面布局、视觉组件、页面专属子视图：
  - 放对应 `Screens/<Page>/...`
- 改跨页面主题、背景、玻璃容器、共用标题：
  - 放 `Shared/Theme` 或 `Shared/UI`
- 改 session 规则、统计口径、step 推进、时间真值：
  - 放 `PomodoroModels.swift` 内的 model / engine
- 改持久化、通知、scene 恢复、idle timer、副作用协调：
  - 放 `PomodoroStore.swift`
- 新功能开始前，默认先回答三件事：
  - 当前架构是什么
  - 这个功能应该落在哪一层
  - 再开始实现

### 0.1.6 当前禁止项

- 不在页面层复制一份 store 状态。
- 不在 `Shared/*` 中塞只被单页使用的组件。
- 不让 `TimelineView` 成为计时真值。
- 不在未说明原因的情况下打散 `Focus` 现有 hierarchy。

`VibePomodoro` 是一款以“精准计时”和“安静陪伴”为核心的番茄钟 App。

它不是一个强调打卡、刺激和游戏化反馈的效率面板，而是一个在专注前、专注中、专注后都尽量保持平静、可信赖、有温度的工具。

---

## 1. 产品定位

### 1.1 核心目标

- 计时必须精准，尤其是在 App 进入后台、锁屏、甚至后续接入 `Live Activities` 时，计时仍然要以真实时间为准。
- 架构必须可扩展，便于后续接入 `SwiftData`、`iCloud`、统计分析、提醒系统和更多自定义设置。
- 视觉上追求 `Liquid Glass` 气质下的克制高级感，同时保留一点“人味”和陪伴感。
- 玻璃感应尽量优先采用系统官方语义，而不是用传统高斯模糊去模仿“像玻璃”的效果。

### 1.2 产品人格

`VibePomodoro` 的人格被定义为：

- 平静
- 温柔
- 克制
- 可信赖
- 有呼吸感，但不打扰

它更像一个“安静的专注陪伴物”，而不是“冷冰冰的计时仪表盘”。

---

## 2. 冻结后的需求规格

### 2.1 计时真值

- 计时核心必须基于 `Date` / `targetEndDate`。
- 不允许用简单的 `Int` 秒数递减作为系统真值。
- 前台显示可以每秒刷新，但核心状态必须以时间戳推导。

### 2.2 Session 模型

一个 session 由多个 step 构成，step 类型固定为：

- `Focus`
- `Short Break`
- `Long Break`

状态流转规则：

- 默认流转为 `Focus -> Short Break`
- 每完成第 `N` 个 `Focus` 后，进入一次 `Long Break`
- 其中 `N` 等于本次 session 的目标轮次
- `完成最后一个 Long Break` 才算整个 session 完成

特殊情况：

- 当目标轮次为 `1` 时，流程为 `Focus -> Long Break -> Session End`

### 2.3 操作语义

支持的核心操作：

- `Start`
- `Pause`
- `Resume`
- `Reset`
- `Skip`
- `Back to last step`

语义定义如下：

- `Start`：从当前 step 的初始状态开始
- `Pause`：冻结当前 step，保留剩余时长
- `Resume`：基于当前时间和剩余时长重新生成新的 `targetEndDate`
- `Reset`：将当前 step 重置为初始状态，清空当前 step 已发生的有效时长；若当前 step 正在运行，则立即从头继续运行
- `Skip`：进入下一 step 的初始状态；不增加完成轮次，但会记录当前 step 已发生的有效时长
- `Back to last step`：回到上一 step 的初始状态，并回滚刚刚已结算的统计与轮次

### 2.4 后台与恢复策略

- App 进入后台后，恢复时按真实时间自动推进状态
- 如果后台期间跨越多个 step，应逐段补算
- App 被杀后重新打开，应恢复未完成的 session

### 2.5 设置项

MVP 需要支持的配置项：

- `Focus Duration`
- `Short Break Duration`
- `Long Break Duration`
- `Target Rounds`
- `Keep Screen On`
- `Notifications`
- `Sound Enabled`
- `Selected Sound`
- `Haptics Enabled`

规则：

- 运行中的 session 使用“创建时的设置快照”
- 设置修改只影响下一个 session，不影响当前正在进行的 session
- 时间类 stepper 在调节时应伴随带阻尼感的轻触觉反馈，接近“拨动液体”的手感

### 2.6 统计口径

统计只记录“有效运行时长”，不包含暂停时间。
`Productivity` 页的正式统计只在整个 session 完成后统一入账；进行中的 `activeSession` 不参与正式图表和指标卡统计。

统计维度包括：

- `Focus Time`
- `Short Break Time`
- `Long Break Time`
- `Break Time`
- `Session Time`
- `Completed Focus Count`

补充规则：

- `Break Time = Short Break Time + Long Break Time`
- `Session Time = Focus Time + Break Time`
- 跨天时按真实时间切分到自然日
- `Productivity` 的指标卡总量基于已完成 session 的聚合缓存读取
- `Productivity` 只保留 `W / M / Y`
- `Productivity` 的 `W / M` 图按日缓存读取，`Y` 由日缓存卷到月
- `Skip` 记录当前阶段已发生时长，但不计入额外完成轮次
- `Reset` 会清空当前 step 已结算时长
- `Back to last step` 会回滚相关已结算统计

### 2.7 提醒与反馈

- 每个 step 结束时需要提醒
- 每个新 step 开始时也需要提醒
- 提醒形式包括：
  - 声音
  - 震动 / haptics

说明：

- MVP 中先保留音效选择结构和提醒入口
- 真正区分音色的自定义声音素材可以在后续版本继续补充
- 设置中的时间调节需要有柔和但明确的 haptics 耦合

---

## 3. MVP 范围

### 3.1 MVP 必做

- 时间戳驱动的精准计时
- `Focus / Short Break / Long Break` 三阶段流程
- `Start / Pause / Resume / Reset / Skip / Back to last step`
- 后台自动推进
- App 重启后恢复当前 session
- 基础设置与基础统计
- 三页 UI：
  - `Focus`
  - `Productivity`
  - `Settings`
- `Focus` 页必须为单屏，不允许滚动承载核心功能

### 3.2 MVP 暂不做

- 正式 `Live Activities` 接入
- `SwiftData` 完整统计落库
- `iCloud` 数据同步
- 多设备接力 session
- 高级统计图表
- 自定义导入音效
- 复杂提醒策略

### 3.3 MVP 成功标准

- 计时逻辑准确
- `Skip / Reset / Back to last step` 不会造成统计错乱
- session 完成时机正确
- 后台与重启恢复正确
- UI 结构清晰，体验安静，不显得为了设计而设计

---

## 4. UI 方向定稿

### 4.1 UI 设计原则

经过设计讨论，最终冻结的 UI 原则为：

1. 专注优先
2. `Focus` 页一屏完成，不用滚动组织核心交互
3. `Liquid Glass` 优先，能使用系统官方导航与玻璃行为时，不自造一套“伪玻璃”
4. 温度来自透明、流动、触感和节奏，而不是高斯模糊和颜色堆砌
5. 数据页诚实，不装饰化
6. 整套 App 只保留一个强记忆点

### 4.2 总体视觉语言

整体遵循 `Liquid Glass` 气质，但不做过度炫技。

关键词：

- 安静
- 温柔
- 克制
- 高级
- 冥想感
- 透明
- 流动

不做的方向：

- 不做高刺激的效率激励界面
- 不做游戏化打卡 UI
- 不做过度炫耀材质的“玻璃秀场”
- 不用传统高斯模糊去假装官方玻璃
- 不做五颜六色的图标墙
- 不做“为了设计而设计”的装饰型统计页

补充说明：

- 底部导航优先采用系统 `Tab Bar` / `Navigation` 的官方 `Liquid Glass` 样式
- 自定义组件可以做玻璃化表达，但语言必须向系统靠拢

### 4.3 三个页面的角色

#### Focus

这是整个 App 的情绪核心和唯一强记忆点。

定位：

- 冥想对象
- 安静的计时空间
- 用户进入专注前后的情绪缓冲层

设计规则：

- 页面元素尽量少
- 单屏完成所有高频操作
- 气泡是主视觉记忆点
- 时间数字永远是最重要信息
- 时间数字允许带轻微玻璃质感，但任何高光、描边、阴影都不能牺牲浅色模式可读性
- 动效应慢、柔和、有呼吸感
- `Reset` 与 `Skip` 属于次级操作
- `Back to last step` 属于低频回退操作，不应抢主视觉

#### Productivity

这是理性复盘页，不是炫技数据页。

定位：

- 用来帮助用户理解自己的专注节律
- 强调清晰、可信、可读

设计规则：

- 主统计图优先选择柱状图
- 先展示可解释的数据，而不是抽象指标
- 避免为了好看而牺牲数据表达

#### Settings

这是系统控制页，要最稳、最轻、最接近系统原生感。

定位：

- 管理节奏、提醒和显示偏好

设计规则：

- 视觉最克制
- 模块结构要清楚
- 不做复杂装饰

---

## 5. Focus 页的视觉决策

### 5.1 保留气泡，而不是改成传统圆环

最终决定：

- `保留气泡`
- 不以圆环作为主视觉

原因：

- 气泡更符合产品“平静、陪伴、冥想对象”的人格
- 圆环虽然更稳妥，但会让产品更容易落回普通番茄钟范式
- 气泡能成为这款 App 的独特记忆点

### 5.2 气泡的实现边界

MVP 中的气泡不是追求高写实的流体特效，而是：

- 风格化
- 低动态
- 克制
- 可读性优先

它应被定义为：

> 安静的液态计时容器，而不是炫技特效

具体要求：

- 水位变化表达“陪伴式流动”，不是“压力式倒计时”
- 动效尽量慢，避免持续吸引注意力
- `Pause` 时气泡应静止
- step 切换时可以有一次短暂过渡，但平时不要一直晃动
- 液体波动时，气泡底部阴影需要产生随之扩散的光斑
- 玻璃层次应强调透明和流动，而不是厚重模糊
- 浅色模式与深色模式必须属于同一套气泡语言，只允许在亮度、透明度和对比度上做模式适配，不允许做成两种完全不同的材质性格
- 气泡本体应是清晰可辨的透明玻璃球，需要有边缘折射、高光、内阴影和轻微 caustic
- 不使用独立的上浮气泡粒子或螺旋气泡特效，液态存在感仅由液面波浪、折射光和轻微 caustic 提供
- 当官方 `Liquid Glass` 语义不足以复现设计稿时，可以使用 `UltraThinMaterial` 作为基底，再叠加高光、描边、内阴影和底部折射光完成定制玻璃效果
- 倒计时接近结束时，液面在视觉上必须真正灌满球体，不允许最后一秒仍明显留白
- 液面上升节奏需要更克制，不能在结束前数秒就提前灌满；推荐在显示 `00:01` 的最后一秒内完成视觉灌满
- 液体层必须完全贴合球体 mask，不允许在顶部、侧边或底部出现明显缝隙
- 液面默认采用双层波浪结构；浅色模式也必须能读出主液面与次液面的前后关系，不能只剩一条平面水线或一条单独的 crest 线

### 5.3 Focus 页操作层级

- 主操作：气泡内部的 `Start / Pause / Resume`
- 次级操作：`Skip` 与 `Reset`
- 低频操作：`Back to last step`

`Back to last step` 需要保留，但应以更轻的层级出现，而不是与主控制抢同等注意力。

补充规则：

- `Back to last step` 只在计时已经开始后显示
- 当计时尚未开始时，不显示该操作
- 气泡中的 `Start / Pause / Resume` 按钮需要固定在数字正下方的中心区域，而不是因文字阴影或材质层变化而产生明显位移
- 如果时间数字采用玻璃化高光语言，中间控制按钮也应保持同一套克制的玻璃语义
- 当前定稿规则：
  - 暗色模式中央图标保持暖白渐变
  - 浅色模式中央图标与时间数字使用同一套深灰色语言，并保持纯色，不额外叠加特效

### 5.4 Focus 页状态条与 Session 条

- 气泡上方的状态条需要随状态变化显示不同文案和长度
- 当前冻结的状态语义为：`READY / FOCUS / SHORT BREAK / LONG BREAK / COMPLETE`
- 一旦进入 session，状态条优先表达当前 phase，而不是 `RUNNING / PAUSED` 这样的运行态文案
- 状态条不允许出现文字换行，长度应随内容自然变化
- 气泡下方的 session 条不再显示文字，而是只显示当前 session 的 focus 节点
- 由于 session 条仅承载节点，它的高度应收至接近上方状态条的高度
- 每一个 focus round 对应一个节点
- `Focus` 阶段时，当前节点显示为半节点
- 进入 `Short Break / Long Break` 后，对应节点变为实心
- 尚未开始的后续节点保持低对比度未激活态

### 5.5 不采用“拖拽圆环改时长”的原因

这个想法被保留为未来可能性，但不进入 MVP。

原因：

- 它会破坏专注状态中的平静感
- 容易误触
- 会增加统计与 session 语义复杂度
- 不属于番茄钟最核心的高频需求

如果未来要支持时间调整，优先考虑：

- `+5 min`
- `End Early`
- `Adjust Duration`

### 5.6 Focus 页性能约束

- `Focus` 页在真机上不应带来持续明显发热或肉眼可见的卡顿
- 动态刷新频率应遵循“足够顺滑，而非默认满帧”的原则；液面与波动目标约为 `15-20fps` 级别即可
- 非运行态（`idle / paused / completed`）不允许继续维持高频 `TimelineView` 刷新，应显著降频
- 当 `scenePhase` 进入 `inactive / background`，`Focus` 页的液面与波动必须立即冻结或强力降频；系统状态栏、通知中心、控制中心的过场优先级高于 app 自身动画
- 静态玻璃层、描边、高光和不随时间变化的反射层应尽量从逐帧重绘路径中剥离
- 液面、必要的水线高光和极少数真正依赖时间的层才应参与持续动画
- 真机 profiling 若出现 `PaintShapeLayer.draw` / `GraphicsContext.renderingTo` 长时间占优，应优先减少逐帧 `Canvas` 内的静态绘制，而不是先砍掉核心视觉语言
- 工程配置中应显式启用 `CADisableMinimumFrameDurationOnPhone = YES`，避免在支持 `ProMotion` 的 iPhone 上被系统层默认最低帧时长限制住
- 次级玻璃控件应优先使用 `material + tint + 细描边` 的低离屏合成方案，避免为了高光质感叠加过多 `blur / shadow / mask`
- 任何新增动态效果都需要先问一个问题：它是否值得用持续 GPU / CPU 开销来换

而不是在主视觉上直接拖拽修改。

### 5.7 当前 Focus 性能优化策略对齐

以下内容用于和后续 threads 对齐，默认视为当前有效方向：

- 当前性能优化范围优先只覆盖 `Focus` 页及其计时基础设施
- 在 `Productivity / Settings` 即将重做设计的前提下，默认不要先对这两页做大规模性能重构
- `Focus` 页的计时真值必须继续来自 `Date / targetEndDate`
- 高刷逻辑应尽量收敛到气泡内部，外层状态条、session 条和次级按钮不应跟随液面动画一起高频重建
- 时间数字和液面动画拆开刷新：
  - 数字按 `1Hz`
  - 液面与呼吸光保持低帧率即可；当前实现按 `12fps`
- 非 `running` 状态不维持高频动画
- 当 `scenePhase != .active` 或当前 tab 不是 `Focus` 时，`Focus` 页动画直接冻结
- store 层不再依赖“全局每秒 ticker”驱动整棵视图树刷新
- `persist()`、`syncNotifications()`、`syncIdleTimer()` 这类副作用只在状态真实变化时执行

最近一次真机 `30s Activity Monitor` 对比表明，这个方向已经明显降低了 CPU、wakeups 和磁盘读取，且 thermal 仍保持 `Nominal`。

### 5.8 本项目中的玻璃理解与实现原则

这个项目中的“玻璃”不是把 `blur / material / shadow / mask` 一层层堆到最重，而是尽量用更少的层表达更可信的材质。

默认原则：

- 玻璃感不等于重模糊，优先依赖轻材质基底、透明度层次、边缘描边和局部高光
- 如果一个组件已经有了 `material + tint + stroke`，默认先不要继续叠更多 material
- 小玻璃控件优先使用更轻的 `thinMaterial`
- 大气泡优先保持 `1 个 material shell + 普通 gradient / stroke 高光 + 少量必要阴影`
- `drawingGroup()` 只用于稳定且值得合并的静态簇，不默认包裹整颗气泡，也不默认包裹逐帧变化的 `Canvas`
- 静态层和动态层分工明确：
  - 静态层负责外壳、描边、高光、固定反射
  - 动态层只保留液面、水线 glow 和必要的底部呼吸光

后续如果要继续加视觉效果，默认先问两个问题：

- 它是否真的在帮助表达“平静、可信赖、克制”？
- 它是否值得额外的持续 GPU / CPU 开销？

---

## 6. Light / Dark 设计原则

### Light

- 以暖白、雾灰、浅金为主
- 干净但不冰冷
- 重点是柔和和呼吸感
- Focus 气泡中的倒计时数字保持当前字体与排版，但前景可带分层高光，不可牺牲可读性
- Focus 气泡中的中央图标使用与数字一致的深灰纯色
- Focus 液面应是可读的双层波浪，而不是单层水面加装饰线

### Dark

- 以烟灰、墨黑、暖琥珀高光为主
- 避免纯黑硬切
- 重点是沉静和材质层次
- 除倒计时数字外，其余文字在暗色模式下统一使用暖白色，以保证玻璃材质上的可读性
- Focus 液面高光应更柔和、更整片，不做局部刺眼亮斑

### 全局配色原则

- `Focus (25min)`：`Amber Gold`
- `Short Break (5min)`：`Soft Mist`
- `Long Break (15min)`：`Soft Jade`
- 颜色不是主角，明度、透明度、材质和层级才是重点
- 色彩应用应随 phase 微调，而不是做成高饱和主题切换

---

## 7. 图标与素材策略

### 7.1 图标

- 以 `SF Symbols` 风格为主
- 默认单色或近单色
- 强调色只用于当前选中态或关键状态

不追求“更多颜色”，而追求“更稳定的视觉节奏”。

### 7.2 图片素材

MVP 不需要额外寻找开源 PNG 照片素材。

原因：

- 当前方向不是照片拼贴型 UI
- `Liquid Glass` 更依赖材质、透明度、渐变、模糊和光感
- 外部 PNG 照片很容易破坏整体的一致性和克制感

更适合的资源类型：

- `SF Symbols`
- 少量 `SVG`
- 轻微纹理
- 后续自定义音效素材

---

## 8. 当前实现对应关系

当前代码已经开始落地以上方案，主要结构如下：

- [VibePomodoro/PomodoroModels.swift](./VibePomodoro/PomodoroModels.swift)
  - 核心模型、状态机、事件定义、Productivity 日聚合缓存模型
- [VibePomodoro/PomodoroStore.swift](./VibePomodoro/PomodoroStore.swift)
  - 状态管理、持久化、通知调度、session 完成后的统计入账与缓存重建
- [VibePomodoro/Screens/Focus/FocusScreen.swift](./VibePomodoro/Screens/Focus/FocusScreen.swift)
  - Focus 页与专属气泡/控制组件
- [VibePomodoro/Screens/Productivity/ProductivityScreen.swift](./VibePomodoro/Screens/Productivity/ProductivityScreen.swift)
  - Productivity 页与专属指标卡组件；只读取已完成 session 的聚合快照，不做实时统计
- [VibePomodoro/Screens/Settings/SettingsScreen.swift](./VibePomodoro/Screens/Settings/SettingsScreen.swift)
  - Settings 页与专属设置行组件
- [VibePomodoro/Shared/Theme/VibeTheme.swift](./VibePomodoro/Shared/Theme/VibeTheme.swift)
  - 共享主题色板与 phase UI 扩展
- [VibePomodoro/Shared/UI/SharedShell.swift](./VibePomodoro/Shared/UI/SharedShell.swift)
  - 共享背景、玻璃容器与底部导航外壳
- [VibePomodoro/Shared/UI/SectionTitle.swift](./VibePomodoro/Shared/UI/SectionTitle.swift)
  - `Productivity` / `Settings` 共用标题组件

---

## 9. 后续路线

优先级建议：

1. 继续打磨 `Focus` 页气泡与布局细节
2. 接入真正的自定义声音素材
3. 完善本地通知体验
4. 将统计持久化迁移到 `SwiftData`
5. 接入 `Live Activities`
6. 再考虑 `iCloud` 同步

---

## 10. 一句话总结

`VibePomodoro` 的设计目标不是做一个“更花的番茄钟”，而是做一个：

> 计时准确、架构稳健、视觉克制、真正能让人更容易进入专注状态的番茄钟。
