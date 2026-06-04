# Agent Context

This document is the engineering and AI-assistant context for `VibePomodoro`. Product philosophy, visual rationale, and MVP behavior scope live in [PRODUCT_VISION.md](./PRODUCT_VISION.md). This file defines where code should live, what owns state, and which architecture rules future work must preserve.

Before coding:

1. Summarize current architecture
2. Explain where this feature should live
3. Then implement

## Architecture Overview

- `VibePomodoroApp.swift` creates a single `@StateObject PomodoroStore` and injects it through the app.
- `ContentView.swift` owns the global background, `TabView`, and cross-page bottom navigation visibility coordination. It does not own the business state machine.
- `Core/Models/*` defines core data models, session snapshots, completed sessions, and productivity aggregate structures.
- `Core/Engine/PomodoroEngine.swift` defines session state advancement rules and emitted events.
- `Core/LiveActivity/*` defines the ActivityKit contract, maps session snapshots into Live Activity snapshots, and adapts ActivityKit side effects.
- `Core/Store/*` is still the runtime source of truth, split by main state, settings, lifecycle, notifications, persistence, testing fixtures, reminders, and productivity.
- `Screens/*` owns page-level UI and page-specific subviews. It must not introduce a second global state source.
- `Screens/Focus/*` is split by page skeleton, render state, layout support, page support, chrome composition, page-specific controls, bubble timer implementation, frame state, and completion summary pieces. It remains one page boundary.
- `Screens/Productivity/*` is split by page skeleton, card glass shell, summary section, trend chart section, and chart support logic. It remains one page boundary.
- `Screens/Settings/*` is split by page skeleton, support logic, card chrome, session rhythm section, and preference sections. It remains one page boundary.
- `Shared/*` only carries cross-page theme and shared UI shell pieces. The global background, glass container, primary action menu button, shared section title, and system tab bar visibility bridge belong here.

## Full Repository Tree

The tree intentionally excludes `.git` and `.DS_Store`.

```text
.
├── .agents/
│   └── plugins/
│       └── marketplace.json
├── .impeccable.md
├── AGENT_CONTEXT.md
├── PRODUCT_VISION.md
├── README.md
├── VibePomodoro.xcodeproj/
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata/
│   │   │   └── swiftpm/
│   │   │       └── configuration
│   │   └── xcuserdata/
│   │       └── qi.xcuserdatad/
│   │           └── UserInterfaceState.xcuserstate
│   ├── xcshareddata/
│   │   └── xcschemes/
│   │       └── VibePomodoro.xcscheme
│   └── xcuserdata/
│       └── qi.xcuserdatad/
│           └── xcschemes/
│               └── xcschememanagement.plist
├── VibePomodoro/
│   ├── Assets.xcassets/
│   │   ├── AccentColor.colorset/
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset/
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── ContentView.swift
│   ├── Core/
│   │   ├── Engine/
│   │   │   └── PomodoroEngine.swift
│   │   ├── LiveActivity/
│   │   │   ├── LiveActivityCoordinator.swift
│   │   │   ├── PomodoroActivityAttributes.swift
│   │   │   └── PomodoroLiveActivitySnapshot.swift
│   │   ├── Models/
│   │   │   ├── PomodoroTypes.swift
│   │   │   ├── ProductivityModels.swift
│   │   │   └── SessionModels.swift
│   │   └── Store/
│   │       ├── PomodoroStore+Lifecycle.swift
│   │       ├── PomodoroStore+Notifications.swift
│   │       ├── PomodoroStore+Persistence.swift
│   │       ├── PomodoroStore+Productivity.swift
│   │       ├── PomodoroStore+Settings.swift
│   │       ├── PomodoroStore+UITestingFixtures.swift
│   │       ├── PomodoroStore.swift
│   │       └── ReminderFeedbackPlayer.swift
│   ├── Resources/
│   │   └── Sounds/
│   │       ├── next-phase-whoosh.caf
│   │       ├── phase-complete-pop.caf
│   │       ├── phase-reset-notification.caf
│   │       └── session-complete-thud.caf
│   ├── Screens/
│   │   ├── Focus/
│   │   │   ├── FocusBubbleTimer.swift
│   │   │   ├── FocusBubbleTimerDigits.swift
│   │   │   ├── FocusBubbleTimerGeometry.swift
│   │   │   ├── FocusBubbleTimerGlass.swift
│   │   │   ├── FocusBubbleTimerSurface.swift
│   │   │   ├── FocusChrome.swift
│   │   │   ├── FocusCompletionFormatting.swift
│   │   │   ├── FocusCompletionSummary.swift
│   │   │   ├── FocusCompletionSummaryCard.swift
│   │   │   ├── FocusCompletionSummaryComponents.swift
│   │   │   ├── FocusControls.swift
│   │   │   ├── FocusLayout.swift
│   │   │   ├── FocusRenderState.swift
│   │   │   ├── FocusScreen.swift
│   │   │   ├── FocusScreenFrameState.swift
│   │   │   └── FocusScreenSupport.swift
│   │   ├── Productivity/
│   │   │   ├── ProductivityCardChrome.swift
│   │   │   ├── ProductivityChartSupport.swift
│   │   │   ├── ProductivityScreen.swift
│   │   │   ├── ProductivitySummarySection.swift
│   │   │   └── ProductivityTrendSection.swift
│   │   └── Settings/
│   │       ├── SettingsCardChrome.swift
│   │       ├── SettingsPreferenceSections.swift
│   │       ├── SettingsScreen.swift
│   │       ├── SettingsSessionRhythmSection.swift
│   │       └── SettingsSupport.swift
│   ├── Shared/
│   │   ├── Theme/
│   │   │   └── VibeTheme.swift
│   │   └── UI/
│   │       ├── PrimaryActionMenuButton.swift
│   │       ├── SectionTitle.swift
│   │       └── SharedShell.swift
│   ├── VibePomodoro.entitlements
│   └── VibePomodoroApp.swift
├── VibePomodoroLiveActivity-Info.plist
├── VibePomodoroLiveActivity/
│   ├── PomodoroActivityAttributes.swift
│   ├── PomodoroLiveActivityBundle.swift
│   ├── PomodoroLiveActivityWidget.swift
│   ├── Preview/
│   │   └── PomodoroLiveActivityPreview.swift
│   ├── Style/
│   │   └── PomodoroLiveActivityStyle.swift
│   └── Views/
│       ├── PomodoroDynamicIslandViews.swift
│       ├── PomodoroLiveActivityComponents.swift
│       └── PomodoroLockScreenLiveActivityView.swift
├── VibePomodoroTests/
│   └── VibePomodoroTests.swift
└── VibePomodoroUITests/
    ├── VibePomodoroUITests.swift
    └── VibePomodoroUITestsLaunchTests.swift
```

## State and Data Flow

### Source of Truth

全局状态入口只有 `PomodoroStore`：

- `selectedTab`
- `settings`
- `activeSession`
- `completedSessions`
- `productivityCache`

`SessionSnapshot` 是当前 session 的完整快照：

- step 列表
- 当前 step index
- run state
- `currentSegmentStartDate`
- `targetEndDate`
- 已结算 `segments`

`CompletedSession` 只表示已完成 session 的归档数据，不反向驱动当前计时状态。

`ProductivityAggregateCache` 是由已完成 session 派生出的本地聚合缓存：

- 指标卡总量
- 按自然日切分的统计汇总
- 已入账 `sessionID` 集合

计时真值必须继续来自 `Date / targetEndDate`。`TimelineView` 只负责显示刷新，不是状态真值来源。

### 用户交互流

- View 按钮点击
- 调用 `PomodoroStore`
- `PomodoroStore` 调用 `PomodoroEngine` 或直接更新设置
- `PomodoroStore` 触发 `persist()` / `syncNotifications()` / `syncIdleTimer()` / `syncStepBoundaryTimer()`
- `@Published` 状态变化回流到 SwiftUI View

### 时间推进流

- 真值来自 `Date` + `targetEndDate`
- `PomodoroEngine.reconcile` 负责跨 step 补算
- `TimelineView` 只负责显示刷新，不是状态真值来源

### 恢复流

- app 启动时 `PomodoroStore.init()` 先从 `UserDefaults` 读取
- 然后 `reconcileNow()` 恢复 session
- `scenePhase` 变回 `.active` 时再次补算并同步副作用

### 统计入账流

- `activeSession` 在运行期间只维护自己的 `segments`
- `Productivity` 正式统计不读取进行中的 session
- 只有在 `.sessionCompleted` 时，才把该 session 写入 `completedSessions` 并增量更新 `productivityCache`
- cache 缺失、版本不匹配或 session 集合不一致时，从 `completedSessions` 全量重建

### Focus 沉浸模式视觉流

- `FocusScreen` 在页面内维护 `isImmersive / isRestoringImmersiveLayout / immersiveVisualsHidden`
- 页面内 chrome 与气泡内主按钮的淡入淡出由同一个 SwiftUI 动画驱动
- `FocusScreen` 通过父层 binding 向 `ContentView` 发出底部导航显隐信号
- `ContentView` 把该信号交给 `Shared/UI/SharedShell.swift` 中的系统 `Tab Bar` 可见性桥接层
- 状态栏 / system overlays 仍由 `FocusScreen` 直接控制，底部导航的全局显隐则属于父层协作

## Module Responsibilities

### App Shell

- `VibePomodoroApp.swift`：app entry point, creates the single `PomodoroStore`, and injects it into the environment.
- `ContentView.swift`：global background, tab structure, and bottom navigation visibility coordination.

### Core Models

- `VibePomodoro/Core/Models/PomodoroTypes.swift`：全局 tab、session phase、run state 与 settings 基础类型。
- `VibePomodoro/Core/Models/SessionModels.swift`：session step、segment、snapshot、completed session 与运行期统计。
- `VibePomodoro/Core/Models/ProductivityModels.swift`：Productivity 日聚合缓存、自然日 summary 与 range 类型。

### Core Engine

- `VibePomodoro/Core/Engine/PomodoroEngine.swift`：状态机推进、step 切换、reconcile 与事件定义。

### Core Live Activity

- `VibePomodoro/Core/LiveActivity/PomodoroActivityAttributes.swift`：Live Activity 的 ActivityKit attributes、content state、phase 与 run state contract。
- `VibePomodoro/Core/LiveActivity/PomodoroLiveActivitySnapshot.swift`：从 `SessionSnapshot` 推导 Live Activity 展示快照，保持计时真值来自 `Date / targetEndDate`。
- `VibePomodoro/Core/LiveActivity/LiveActivityCoordinator.swift`：ActivityKit 创建、更新、结束与测试替身协议；由 `PomodoroStore` 作为 runtime 副作用触发。

### Core Store

- `VibePomodoro/Core/Store/PomodoroStore.swift`：store 主状态、对外动作入口与页面读取的派生属性。
- `VibePomodoro/Core/Store/PomodoroStore+Settings.swift`：设置更新、离散档位 normalization、提醒开关与调节 haptics。
- `VibePomodoro/Core/Store/PomodoroStore+Lifecycle.swift`：scene phase 协调、runtime 副作用刷新、step 边界 timer、前台反馈触发与 session 完成入账。
- `VibePomodoro/Core/Store/PomodoroStore+Notifications.swift`：本地通知权限、未来 step 边界提醒计划与自定义通知声音调度。
- `VibePomodoro/Core/Store/ReminderFeedbackPlayer.swift`：固定提醒声音资源、前台声音播放、前台 haptics 与事件反馈计划。
- `VibePomodoro/Core/Store/PomodoroStore+Persistence.swift`：UserDefaults 持久化、cache 修复与编解码辅助。
- `VibePomodoro/Core/Store/PomodoroStore+Productivity.swift`：Productivity snapshot、图表桶映射、streak 计算、统计查询与历史清空动作。
- `VibePomodoro/Core/Store/PomodoroStore+UITestingFixtures.swift`：UI testing fixture entry points.

### Focus Screen

- `VibePomodoro/Screens/Focus/FocusScreen.swift`：Focus 页页面骨架、沉浸模式状态同步事件接线与系统显隐协作。
- `VibePomodoro/Screens/Focus/FocusRenderState.swift`：Focus 页 render state、时间显示态与操作可用性推导。
- `VibePomodoro/Screens/Focus/FocusLayout.swift`：Focus 页布局常量、safe area 适配与气泡 anchor support。
- `VibePomodoro/Screens/Focus/FocusScreenSupport.swift`：Focus 页 bubble 几何计算、chrome 可见性与沉浸模式辅助规则。
- `VibePomodoro/Screens/Focus/FocusScreenFrameState.swift`：Focus 页 frame-level state helpers.
- `VibePomodoro/Screens/Focus/FocusChrome.swift`：Focus 页 page content、top/bottom chrome 组合与操作层装配。
- `VibePomodoro/Screens/Focus/FocusControls.swift`：Focus 页状态条、session 条、次级按钮与胶囊玻璃控件。
- `VibePomodoro/Screens/Focus/FocusBubbleTimer.swift`：Focus 气泡主入口、phase morph 与液体视觉态过渡编排。
- `VibePomodoro/Screens/Focus/FocusBubbleTimerDigits.swift`：Focus 气泡倒计时数字刷新与前景内容绘制。
- `VibePomodoro/Screens/Focus/FocusBubbleTimerGeometry.swift`：Focus 气泡 shell profile、shape geometry 与插值支撑。
- `VibePomodoro/Screens/Focus/FocusBubbleTimerGlass.swift`：Focus 气泡玻璃背板与 rim overlay 绘制。
- `VibePomodoro/Screens/Focus/FocusBubbleTimerSurface.swift`：Focus 气泡液面动画、glow、Canvas 绘制与波形路径。
- `VibePomodoro/Screens/Focus/FocusCompletionSummary.swift`：Focus 完成总结独立确认层与完成态确认 UI。
- `VibePomodoro/Screens/Focus/FocusCompletionSummaryCard.swift`：Focus 完成总结卡片布局。
- `VibePomodoro/Screens/Focus/FocusCompletionSummaryComponents.swift`：Focus 完成总结子组件。
- `VibePomodoro/Screens/Focus/FocusCompletionFormatting.swift`：Focus 完成总结文案格式化。

### Productivity Screen

- `VibePomodoro/Screens/Productivity/ProductivityScreen.swift`：Productivity 页页面骨架、布局常量、本地 range 选择态、icon-only range menu 与 render state。
- `VibePomodoro/Screens/Productivity/ProductivityCardChrome.swift`：Productivity 专属玻璃卡片壳与卡片 chrome modifier。
- `VibePomodoro/Screens/Productivity/ProductivitySummarySection.swift`：Productivity 顶部摘要卡、辅助指标排布与 empty note。
- `VibePomodoro/Screens/Productivity/ProductivityTrendSection.swift`：Productivity 趋势卡、指标枚举与自定义等宽 `x` 轴。
- `VibePomodoro/Screens/Productivity/ProductivityChartSupport.swift`：Productivity 图表格式化、桶映射与数值轴计算。

### Settings Screen

- `VibePomodoro/Screens/Settings/SettingsScreen.swift`：Settings 页页面骨架、section 排列与 store normalization 触发。
- `VibePomodoro/Screens/Settings/SettingsSupport.swift`：Settings 布局常量、色彩映射、离散档位规则与辅助逻辑。
- `VibePomodoro/Screens/Settings/SettingsCardChrome.swift`：Settings 专属卡片壳、header、divider 与 card chrome modifier。
- `VibePomodoro/Screens/Settings/SettingsSessionRhythmSection.swift`：`Session Rhythm` 主设置卡、stepper row 与时长更新映射。
- `VibePomodoro/Screens/Settings/SettingsPreferenceSections.swift`：`Alerts / Display / Other` 次级设置卡、共用设置行组件与清空 Productivity 历史确认入口。

### Shared UI

- `VibePomodoro/Shared/Theme/VibeTheme.swift`：共享主题色板与 phase UI 扩展。
- `VibePomodoro/Shared/UI/SharedShell.swift`：共享背景、玻璃容器与底部导航外壳。
- `VibePomodoro/Shared/UI/SectionTitle.swift`：`Productivity` / `Settings` 共用标题组件。
- `VibePomodoro/Shared/UI/PrimaryActionMenuButton.swift`：shared primary action menu button UI.

### Resources

- `VibePomodoro/Resources/Sounds`：`phase-complete-pop.caf`、`next-phase-whoosh.caf`、`phase-reset-notification.caf`、`session-complete-thud.caf` 四个固定提醒声音素材。

### Live Activity Extension

- `VibePomodoroLiveActivity`：Live Activity extension target。
- `VibePomodoroLiveActivity/PomodoroActivityAttributes.swift`：extension-side ActivityKit attributes mirror.
- `VibePomodoroLiveActivity/PomodoroLiveActivityBundle.swift`：Widget bundle entry.
- `VibePomodoroLiveActivity/PomodoroLiveActivityWidget.swift`：Live Activity configuration assembly.
- `VibePomodoroLiveActivity/Views/*`：锁屏、Dynamic Island、和 Live Activity shared components UI。
- `VibePomodoroLiveActivity/Style/*`：Activity 专用色彩与 style。
- `VibePomodoroLiveActivity/Preview/*`：预览状态。

## Feature Ownership Boundaries

- 改页面布局、视觉组件、页面专属子视图：放对应 `Screens/<Page>/...`
- 改跨页面主题、背景、玻璃容器、共用标题、共用菜单按钮：放 `Shared/Theme` 或 `Shared/UI`
- 改全局底部导航的显隐协作、系统 `Tab Bar` 动画桥接：放 `ContentView.swift` 或 `Shared/UI/*`
- 具体页面只负责发出“是否应隐藏全局 chrome”的视觉信号
- 改 session 规则、统计口径、step 推进、时间真值：放 `Core/Models/*` 或 `Core/Engine/PomodoroEngine.swift`
- 改持久化、通知、scene 恢复、idle timer、副作用协调：放 `Core/Store/*`
- 改 `Live Activities` 的数据 contract、session 快照映射或 ActivityKit 创建/更新/结束适配：放 `Core/LiveActivity/*`
- 改锁屏 Live Activity 或 Dynamic Island UI：放 `VibePomodoroLiveActivity/*`
- 新功能开始前，默认先回答三件事：当前架构是什么、这个功能应该落在哪一层、再开始实现

## Page and State Boundaries

### FocusScreen

- 读取 `PomodoroStore`
- 生成 `FocusRenderState`
- 页面内只做显示层拆分，不能自建 session 状态机
- 计时数字按 `1Hz` 刷新，气泡动画按低帧率刷新，仅在 `Focus` tab 可见且 session 运行时激活

当前目录内拆分为：

- `FocusScreen.swift`：页面骨架、沉浸模式状态同步与系统显隐协作
- `FocusRenderState.swift`：`FocusRenderState / BubbleRenderState` 与 Focus 页显示态推导
- `FocusLayout.swift`：布局常量、safe area 适配与气泡 anchor support
- `FocusScreenSupport.swift`：bubble 几何计算、chrome 可见性与沉浸模式辅助规则
- `FocusScreenFrameState.swift`：frame-level state helpers
- `FocusChrome.swift`：Focus 页面 chrome 组合、操作层装配与 page content 骨架
- `FocusControls.swift`：状态条、session 条、次级按钮与胶囊玻璃壳
- `FocusBubbleTimer.swift`：气泡主入口、phase morph 与液体视觉态过渡编排
- `FocusBubbleTimerDigits.swift`：倒计时数字与前景内容绘制
- `FocusBubbleTimerGeometry.swift`：气泡 shell profile、shape geometry 与插值支撑
- `FocusBubbleTimerGlass.swift`：玻璃背板与 rim overlay 绘制
- `FocusBubbleTimerSurface.swift`：液面动画、glow、Canvas 绘制与波形路径
- `FocusCompletionSummary.swift`：session 完成总结 overlay 与确认 UI
- `FocusCompletionSummaryCard.swift`：完成总结卡片布局
- `FocusCompletionSummaryComponents.swift`：完成总结子组件
- `FocusCompletionFormatting.swift`：完成总结格式化显示

### ProductivityScreen

- 通过 `store.productivitySnapshot(...)` 读取聚合后的统计快照
- 正式统计只反映已完成 session
- 范围选择只保留 `Week / Month / Year`
- 页面本身不持有统计真值，只持有本地 UI 选择态 `selectedRange`

当前目录内拆分为：

- `ProductivityScreen.swift`：页面骨架、布局常量、icon-only range toolbar menu 与页面 render state
- `ProductivityCardChrome.swift`：Productivity 专属玻璃卡片壳
- `ProductivitySummarySection.swift`：顶部摘要卡与 empty note
- `ProductivityTrendSection.swift`：趋势卡、指标枚举与自定义 `x` 轴
- `ProductivityChartSupport.swift`：格式化、桶映射与图表轴计算

### SettingsScreen

- 直接绑定 `store.settings`
- 设置修改只走 store 的 update/set 接口，不直接改 model 副本
- 设置页出现时只负责触发 store 侧 normalization，不在页面内重复维护离散档位吸附逻辑
- `Settings` 当前保持页面内拆分，不把其专属卡片 chrome 和设置行上提到 `Shared/*`

当前目录内拆分为：

- `SettingsScreen.swift`：页面骨架、section 排列与 store normalization 触发
- `SettingsSupport.swift`：布局常量、色彩映射、`SettingsTimerField` 离散档位与辅助规则
- `SettingsCardChrome.swift`：Settings 专属卡片壳、header 与 divider
- `SettingsSessionRhythmSection.swift`：`Session Rhythm` 主设置卡与 stepper row
- `SettingsPreferenceSections.swift`：`Alerts / Display / Other` 次级卡与共用 row 组件

## Engineering Constraints

- 不在页面层复制一份 store 状态。
- 不在 `Shared/*` 中塞只被单页使用的组件。
- 不让 `TimelineView` 成为计时真值。
- 不在未说明原因的情况下打散 `Focus` 现有 hierarchy。
- `Focus` hierarchy 为保护区；后续线程若改设计，必须在不打散当前层级、不改变现有刷新边界的前提下进行。
- `Focus` 页当前允许在 `Screens/Focus/` 内按职责拆文件，但这只属于页面内整理，不代表可以把其专属组件上提到 `Shared/*`。
- 每个页面的 UI 设计只归属于自己的页面目录。
- 页面专属子视图默认与页面目录同驻，不放进共享层。
- 共享层只放跨页面复用的主题、背景、面板、标题等通用 UI。

### Focus Performance Constraints

- `Focus` 页在真机上不应带来持续明显发热或肉眼可见的卡顿。
- 动态刷新频率应遵循“足够顺滑，而非默认满帧”的原则；液面与波动目标约为 `15-20fps` 级别即可。
- 非运行态（`idle / paused / completed`）不允许继续维持高频 `TimelineView` 刷新，应显著降频。
- 当 `scenePhase` 进入 `inactive / background`，`Focus` 页的液面与波动必须立即冻结或强力降频；系统状态栏、通知中心、控制中心的过场优先级高于 app 自身动画。
- 静态玻璃层、描边、高光和不随时间变化的反射层应尽量从逐帧重绘路径中剥离。
- 液面、必要的水线高光和极少数真正依赖时间的层才应参与持续动画。
- 真机 profiling 若出现 `PaintShapeLayer.draw` / `GraphicsContext.renderingTo` 长时间占优，应优先减少逐帧 `Canvas` 内的静态绘制，而不是先砍掉核心视觉语言。
- 工程配置中应显式启用 `CADisableMinimumFrameDurationOnPhone = YES`，避免在支持 `ProMotion` 的 iPhone 上被系统层默认最低帧时长限制住。
- 次级玻璃控件应优先使用 `material + tint + 细描边` 的低离屏合成方案，避免为了高光质感叠加过多 `blur / shadow / mask`。
- 任何新增动态效果都需要先问一个问题：它是否值得用持续 GPU / CPU 开销来换。

### Current Focus Optimization Direction

- 当前性能优化范围优先只覆盖 `Focus` 页及其计时基础设施。
- 在 `Productivity / Settings` 即将重做设计的前提下，默认不要先对这两页做大规模性能重构。
- `Focus` 页的计时真值必须继续来自 `Date / targetEndDate`。
- 高刷逻辑应尽量收敛到气泡内部，外层状态条、session 条和次级按钮不应跟随液面动画一起高频重建。
- 时间数字和液面动画拆开刷新：
  - 数字按 `1Hz`
  - 液面与呼吸光保持低帧率即可；当前实现按 `12fps`
- 非 `running` 状态不维持高频动画。
- 当 `scenePhase != .active` 或当前 tab 不是 `Focus` 时，`Focus` 页动画直接冻结。
- store 层不再依赖“全局每秒 ticker”驱动整棵视图树刷新。
- `persist()`、`syncNotifications()`、`syncIdleTimer()` 这类副作用只在状态真实变化时执行。

最近一次真机 `30s Activity Monitor` 对比表明，这个方向已经明显降低了 CPU、wakeups 和磁盘读取，且 thermal 仍保持 `Nominal`。

## Known Implementation Decisions

### Focus Bubble Timer

- `FocusBubbleTimer*.swift` 是当前 Focus 气泡、液面、倒计时数字和玻璃球绘制的页面内落点；后续继续打磨主气泡时，默认不要把页面专属子组件上提到 `Shared/*`
- 气泡视觉必须继续由 `BubbleRenderState` + `Date / targetEndDate` 推导；`TimelineView` 只负责刷新显示，不成为新的计时真值
- phase morph 需要由单一 `BubblePhaseMorph` 同步驱动外壳形状、shell profile、rim、glow、liquid tint 与外层 mask；不要让液面先切到新 phase、外壳后切到新 phase
- phase 切换时，液体视觉态应通过 `BubbleLiquidVisualState` 从旧 render state 连续插值到新 render state；不要直接读取新 phase 的液面进度来绘制第一帧
- 液体层只保留外层 `.mask(phaseMorph.shape)` 作为最终裁剪；不要在 `Canvas` 内部再用另一份 shape path 做二次 clip，避免 mask 与液面使用不同动画时钟导致边缘错位
- 液面终段填充当前基线是：结束前常规液面最多到 `0.94`，最后约 `2.8s` 基于 `remainingDuration(at:)` 用 smoothstep 连续插值到 `1.08`，让 `00:01 -> 00:00` 看起来接近灌满但不突然跳变
- 不要恢复早期 `terminalBoost` 或 `timeText == "00:00"` 的离散填充方案；前者会导致最后几秒提前灌满，后者会导致 `00:01` 仍留大洞而 `00:00` 突然全满
- 当前时间文案使用 rounded seconds，因此显示 `00:01` 并不等价于真实剩余时间正好 `1.0s`；液面终段动画应优先依赖连续 remaining duration，而不是依赖文案字符串
- 终段 cue 可以收束 glow 和底部深度池，但不应把波幅压到接近静止；最后几秒水面仍应保留轻微运动
- 深色模式下不要恢复大面积内部白雾或横向白光；暗色气泡应依靠柔和水线、边缘折射、底部 glow 与低透明度层次表达材质

### Glass Implementation Principles

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

## Current Architecture Rules

- 全局 runtime state 只从 `PomodoroStore` 出口读写。
- Session progression, reconciliation, and event production belong in `PomodoroEngine`.
- Persistence, notification scheduling, lifecycle reconciliation, idle timer behavior, reminder feedback, and productivity aggregation are store-side responsibilities.
- Page views may derive render state and own local UI-only selection state, but they may not become business state machines.
- `Focus` render state and bubble rendering must remain derived from the current session snapshot and real dates.
- `Productivity` charts read completed-session aggregate state only; active sessions do not feed formal metrics.
- Settings changes affect the next new session only and should go through store update methods.
- Shared UI may contain cross-page shell, theme, title, and button primitives only.
- Live Activity data contracts and ActivityKit side-effect coordination remain in `Core/LiveActivity`; extension UI remains in `VibePomodoroLiveActivity`.
- Screen-specific visual baselines and rationale live in `PRODUCT_VISION.md`; do not silently overwrite them during implementation.

