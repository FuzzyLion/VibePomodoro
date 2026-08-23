# Product Vision

`VibePomodoro` 是一款以“精准计时”和“安静陪伴”为核心的番茄钟 App。

它不是一个强调打卡、刺激和游戏化反馈的效率面板，而是一个在专注前、专注中、专注后都尽量保持平静、可信赖、有温度的工具。

## Product Philosophy

### 核心目标

- 计时必须精准，尤其是在 App 进入后台、锁屏或重新启动后，计时仍然要以真实时间为准。
- 架构必须可扩展，便于后续接入 `SwiftData`、`iCloud`、统计分析、提醒系统和更多自定义设置。
- 视觉上追求 `Liquid Glass` 气质下的克制高级感，同时保留一点“人味”和陪伴感。
- 玻璃感应尽量优先采用系统官方语义，而不是用传统高斯模糊去模仿“像玻璃”的效果。

### Product Personality

`VibePomodoro` 的人格被定义为：

- 平静
- 温柔
- 克制
- 可信赖
- 有呼吸感，但不打扰

它更像一个“安静的专注陪伴物”，而不是“冷冰冰的计时仪表盘”。

## Design Principles

经过设计讨论，最终冻结的 UI 原则为：

1. 专注优先
2. `Focus` 页一屏完成，不用滚动组织核心交互
3. `Liquid Glass` 优先，能使用系统官方导航与玻璃行为时，不自造一套“伪玻璃”
4. 温度来自透明、流动、触感和节奏，而不是高斯模糊和颜色堆砌
5. 数据页诚实，不装饰化
6. 整套 App 只保留一个强记忆点

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
- `Focus` 沉浸模式下，底部导航允许通过共享壳层对系统 `Tab Bar` 做协调显隐，但语义上仍应保持“系统导航栏”的感觉，而不是改造成独立页面组件
- 自定义组件可以做玻璃化表达，但语言必须向系统靠拢

## MVP Scope

### 计时真值

- 计时核心必须基于 `Date` / `targetEndDate`。
- 不允许用简单的 `Int` 秒数递减作为系统真值。
- 前台显示可以每秒刷新，但核心状态必须以时间戳推导。

### Session 模型

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

### 操作语义

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

### 后台与恢复策略

- App 进入后台后，恢复时按真实时间自动推进状态
- 如果后台期间跨越多个 step，应逐段补算
- App 被杀后重新打开，应恢复未完成的 session

### 设置项

MVP 需要支持的配置项：

- `Focus Duration`
- `Short Break Duration`
- `Long Break Duration`
- `Target Rounds`
- `Keep Screen On`
- `Notifications`
- `Sound`
- `Haptics`

规则：

- 运行中的 session 使用“创建时的设置快照”
- 设置修改只影响下一个 session，不影响当前正在进行的 session
- 时间类 stepper 在调节时应伴随带阻尼感的轻触觉反馈，接近“拨动液体”的手感

### 统计口径

统计只记录“有效运行时长”，不包含暂停时间。`Productivity` 页的正式统计只在整个 session 完成后统一入账；进行中的 `activeSession` 不参与正式图表和指标卡统计。

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
- `Clear Productivity History` 会同时清空已完成 session 归档与 Productivity 聚合缓存
- 清空历史后，`Productivity` 应立即回到 empty state；后续新完成的 session 会从零重新累计
- `Skip` 记录当前阶段已发生时长，但不计入额外完成轮次
- `Reset` 会清空当前 step 已结算时长
- `Back to last step` 会回滚相关已结算统计

### 提醒与反馈

- 每个 step 结束时需要提醒
- 每个新 step 开始时也需要提醒
- 提醒形式包括：
  - 声音
  - 震动 / haptics

说明：

- 事件声音固定映射为 `forward phase boundary = next-phase-whoosh.caf`、`back to last step = phase-complete-pop.caf`、`reset current step = phase-reset-notification.caf`、`session complete = session-complete-thud.caf`
- 前台普通自动 step boundary 和 `Skip` 正向推进只播放 Whoosh；`Back to last step` 只播放 Pop；`Reset current step` 只播放 reset 音效；session complete 只播放 Thud
- 前台 haptics 语义为 `forward = soft impact`、`back = rigid impact`、`reset = soft impact`、`session complete = success`
- 后台和锁屏由 local notification 表达声音：普通边界用 Whoosh，最终完成用 Thud；不做 app-controlled haptics
- 设置中的时间调节需要有柔和但明确的 haptics 耦合

### MVP 必做

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

### MVP 暂不做

- `SwiftData` 完整统计落库
- `iCloud` 数据同步
- 多设备接力 session
- 高级统计图表
- 自定义导入音效
- 复杂提醒策略

### MVP 成功标准

- 计时逻辑准确
- `Skip / Reset / Back to last step` 不会造成统计错乱
- session 完成时机正确
- 后台与重启恢复正确
- UI 结构清晰，体验安静，不显得为了设计而设计

## UI Direction

The screen-specific design rationale sections below are the current baseline when they conflict with older directional notes in this section.

### Focus

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

### Productivity

这是理性复盘页，不是炫技数据页。

定位：

- 用来帮助用户理解自己的专注节律
- 强调清晰、可信、可读

设计规则：

- 主统计图优先选择柱状图
- 先展示可解释的数据，而不是抽象指标
- 避免为了好看而牺牲数据表达
- 顶部导航保持系统 `large title + topBarTrailing` 结构，不为了迁就右上角控件而上提标题
- 右上角范围选择保持 icon-only 的系统 toolbar 行为，弱化存在感，但不自造一层伪 toolbar glass
- 标题下方保留一条轻量 summary strip，文案为 `All Time`
- summary strip 只展示全量累计的 `Session Time / Avg / Day / Streak`，不展示当前 range 内临时总量
- `Session Time` 不再单独占一张图表卡；图表主区只保留 `Focus Sessions / Focus Time / Break Time`
- 三张图表卡顶部主数值展示当前 `Week / Month / Year` 范围内的合计，而不是全量累计
- summary strip 内三组信息必须采用硬栅格：
  - 第一组 `Session Time` 的左边界，要与下方图表卡左上角的小方块图标左边界落在同一条垂直线上
  - 三组信息之间的横向空隙必须完全一致，不能出现左右宽、中间窄的视觉误差
  - divider 只允许落在组间空隙的中点，不能贴字，也不能参与“挤压文字”来凑布局
- 图表 `x` 轴必须使用等宽 bucket 轴，label 与柱体共用同一组 slot 中心；不允许出现右端省略、错位或视觉不等距
- 浅色模式下，summary strip 的三项小标题可以保持语义色，但必须使用更深的同系色保证可读性；不能为了玻璃感把对比度降到发虚
- 这一页的重点是诚实、清楚、可信，而不是把统计做成装饰性面板

### Settings

这是系统控制页，要最稳、最轻、最接近系统原生感。

定位：

- 管理节奏、提醒和显示偏好

设计规则：

- 视觉最克制
- 模块结构要清楚
- 不做复杂装饰
- 不做成分析面板或 dashboard 式卡片堆栈
- `Session Rhythm` 可以作为主设置锚点，但次级设置区默认保持更安静
- Settings 专属视觉 chrome 默认留在 `Screens/Settings/*` 内维护，不再复用 `Productivity` 命名的卡片壳

## Focus Design Rationale

### 保留气泡，而不是改成传统圆环

最终决定：

- `保留气泡`
- 不以圆环作为主视觉

原因：

- 气泡更符合产品“平静、陪伴、冥想对象”的人格
- 圆环虽然更稳妥，但会让产品更容易落回普通番茄钟范式
- 气泡能成为这款 App 的独特记忆点

### 气泡的实现边界

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
- `Focus` 主气泡可以带一点 rounded-squircle 的几何特征来建立识别度，但整体仍应被读作“稳定的计时容器”，不是会持续表演的 blob
- `Short Break / Long Break` 的轮廓允许比 `Focus` 更放松，但三态差异必须克制，优先守住倒计时数字的居中、稳定与可读性
- 不使用独立的上浮气泡粒子或螺旋气泡特效，液态存在感仅由液面波浪、折射光和轻微 caustic 提供
- 当官方 `Liquid Glass` 语义不足以复现设计稿时，可以使用 `UltraThinMaterial` 作为基底，再叠加高光、描边、内阴影和底部折射光完成定制玻璃效果
- 倒计时接近结束时，液面在视觉上必须真正灌满球体，不允许最后一秒仍明显留白
- 液面上升节奏需要更克制，不能在结束前数秒就提前灌满；推荐在显示 `00:01` 的最后一秒内完成视觉灌满
- 液体层必须完全贴合球体 mask，不允许在顶部、侧边或底部出现明显缝隙
- 液面默认采用双层波浪结构；浅色模式也必须能读出主液面与次液面的前后关系，不能只剩一条平面水线或一条单独的 crest 线

### Focus 页操作层级

- 主操作：气泡下方主控制区内的 `Start / Pause / Resume`
- 次级操作：`Reset`、`Skip`
- 低频操作：`Back to last step`

`Back to last step` 需要保留，但应以更轻的层级出现，而不是与主控制抢同等注意力。

补充规则：

- `Back to last step` 只在计时已经开始后显示
- 当计时尚未开始时，不显示该操作
- 主控制区默认与气泡共轴放置，并保持“贴气泡但拉开”的关系：
  - 它属于同一组构图
  - 但不应紧贴气泡下沿，避免页面显得头重脚轻
  - 当前定稿基线允许这组 controls 保持“悬浮但更低”，更接近底部 tab bar 上缘，但仍不贴底部系统栏
- `Reset / 状态灯 + 标题 / Finish early` 顶部 chrome 只承担辅助导航语义，不得做成厚重横条：
  - 按钮视觉尺寸应向系统 toolbar item 靠拢
  - 标题与状态灯应明显轻于倒计时数字
  - 顶部整体应更接近 safe area 顶部，读起来像页面 chrome，而不是第二主视觉
- 如果时间数字采用玻璃化高光语言，主控制按钮也应保持同一套克制的玻璃语义，但不能比时间本身更抢眼
- `Pause` 与 `Resume / Start / Start Again` 需要保留明确的视觉语气差异：
  - `Pause` 更中性、更安静
  - `Resume / Start / Start Again` 可以略亮或略 tinted，但不能浓到像促销 CTA
- 主控制按钮的宽度应按较长文案预留，不允许 `Resume` 因共享宽度而显得比 `Pause` 更挤
- 底部 `Back / Skip` 图标的粗细、重量和顶部低频按钮必须属于同一套语言，不允许出现“上方轻、下方硬”的冲突
- 当前定稿规则：
  - 深色模式主控制区文字与图标保持暖白系，可接受轻微分层
  - 浅色模式主控制区文字与图标保持更克制的深色系，不额外叠加炫技特效
- `Reset / Finish early` 与底部 `Back / Skip` 的 `.glass` 实现必须遵循同一条结构规则：
  - 按钮本体只承载可视玻璃圆
  - 外层 slot 单独承接 hit area 与对位
  - 不在 glass 本体上额外叠加会和系统交互态打架的 pressed / opacity 动画
- 底部 `Back / Pause-Resume / Skip` 三按钮需要维持明确分离：
  - 允许共享 glass sampling region，以减少 pressed 时的采样跳变
  - 但不允许在点击时出现流体“吸附”或视觉粘连
  - 如果使用 `GlassEffectContainer`，必须显式压低其 merge 行为，不能让相邻按钮在交互时自动融合成连续胶囊
- 已验证的经验结论：
  - 底部按钮此前的闪烁主要来自相邻独立 glass 的采样不一致
  - 后续若要继续优化，优先调整 glass 宿主结构或 container 策略，不要退回自绘假玻璃

### Focus 页状态条与 Session 条

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
- session 条同时承担“连接气泡与底部 controls”的过渡角色：
  - 它不应做成独立的重材质装饰条
  - 也不应弱到只剩散点点缀
  - 它应帮助页面从主视觉自然过渡到控制区，而不是再制造一个新的视觉中心

### Focus 完成总结页

- `Session complete / Session finished` 需要被视为独立确认层，而不是盖在完整 Focus 页面上的普通 overlay
- 完成总结出现时，背景只保留极淡的气泡轮廓作为情绪延续，不再保留 back、status badge、skip、reset 与底部 tab bar
- `COMPLETE` 仍保留为内部状态语义，但完成总结出现后不再继续占据顶部可见层级
- 正常完成时，标题下方默认不再追加解释性副文案；提前结束时才保留一条简短说明
- 完成卡片采用上紧下松的非对称留白，避免顶部空隙过大
- `Done` 必须是居中的窄胶囊确认动作，而不是通栏底部条
- `Done` 的当前定稿方向：
  - 不加图标，只保留文字动作
  - 材质与 `Pause / Resume` 属于同一家族的系统 glass 语义，而不是单独一套自绘 material
  - tint 保持 calm，不做高饱和完成态强调
  - 文字密度要明显高于早期试验稿：按钮略窄、字号略大，避免“字太小而按钮太空”
- 完成总结的动效以 calm choreography 为原则：
  - badge 先确认
  - 标题与卡片随后进入
  - `Done` 最后进入
- 离开完成总结时，动作顺序应保持同一套克制层级，但不允许出现只剩黑遮罩和背景气泡停留过久的空档
- 仅文字组适合使用 reveal mask；带圆角的卡片和按钮在进出场中不应再被 mask 切掉边角
- `Reduce Motion` 下取消分段 choreography，退化为简单显隐

### 不采用“拖拽圆环改时长”的原因

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

而不是在主视觉上直接拖拽修改。

## Productivity Design Rationale

- `Productivity` 顶部摘要区当前已对齐为单独主卡，不再按旧版三等分摘要条作为后续设计基线。
- 该主卡当前确认的标题文案为 `ALL TIME COMPLETED SESSIONS`。
- 当前确认版本不使用 `Finished sessions only` 解释型副标题。
- 主卡信息层级固定为：
  - 主指标：`Session Time`
  - 辅助指标：`Daily Focus Avg`
  - 辅助指标：`Streak`
  - 底部元信息：已完成 session 数与 focus block 数
- 主卡与下方 3 张趋势卡采用“同语法、微区分”的玻璃语言：
  - 主卡是页面第一视觉锚点
  - 趋势卡应更低调，属于分析层
  - 但四张卡仍需保持同一家族感，不能做成两套独立视觉系统
- 右上角 range 选择当前基线是 icon-only `Menu`：
  - 菜单内显式列出 `Week / Month / Year`
  - 当前项在右侧显示 checkmark
  - 默认不要回退到 `Menu` 内嵌 `Picker` 的实现
- 若点击 range menu 时控制台仍出现 `Called -[UIContextMenuInteraction updateVisibleMenuWithBlock:] while no context menu is visible.`，当前按系统层噪音处理：
  - 只要没有伴随交互异常、状态不同步或崩溃，就不作为当前线程的优先修复项
  - 后续只有在确认出现真实行为问题时，才重新打开这条线
- 如果后续 thread 继续打磨 `Productivity`：
  - 以上述主卡版本为当前基线
  - 默认不要回到 `Finished sessions only` 副标题方案
  - 默认不要采用“更紧上半区 + 手动两行标题断句 + 明显收窄主卡与趋势卡间距”的那一版试验稿，除非线程内重新确认

## Settings Design Rationale

- `Settings` 当前信息架构固定为：
  - `Session Rhythm`
  - `Alerts`
  - `Display`
  - `Other`
- 当前视觉层级为：
  - `Session Rhythm` 作为主设置卡
  - `Alerts / Display / Other` 作为同一家族下的次级设置卡
- `Session Rhythm` 使用离散档位，不提供自由输入：
  - `Focus`：正式档位为 `15...90`、每 `5` 分钟一档
  - `Short Break`：`5 / 10`
  - `Long Break`：`15 / 20 / 30`
  - `Rounds`：`1...10`
- `Session Rhythm` 标题上的 `Next session only` 必须保留；默认语义是：
  - 设置变更只影响下一次新 session
  - 不回写正在进行中的 session
- 页面出现时，历史持久化的非标准时长与轮数会由 `PomodoroStore` 吸附到最近合法值；该 normalization 不触发反馈。
- `Alerts` 内部当前存在明确依赖关系：
  - `Sound` 依赖 `Notifications`
  - 事件声音固定映射，不提供逐项选择入口
- `Display` 当前只承载 `Keep Screen On`，语义限定为 `Active sessions only`
- `Other` 当前包含占位项与维护动作：
  - `Send Feedback`
  - `Share App`
  - 两者状态都为 `Soon`
  - `Clear Productivity History`
- `Clear Productivity History` 的默认语义是：
  - 只清空已完成历史统计，不影响当前进行中的 session
  - 删除对象为 `completedSessions` 与 `productivityCache`
  - 行入口常驻，但在没有历史数据时禁用并显示 `No history yet`
  - 点击后直接进入最终 destructive `alert`，不再经过中间确认菜单
  - 该行标题可保留危险语义，但辅助副标题应维持普通次级灰，避免整行过度发红

## Light / Dark Direction

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
- 即使 `Focus` 气泡几何参考了更有性格的 Figma 轮廓，也不引入紫色主题；几何可以借鉴，phase 配色语义不能漂移
- 颜色不是主角，明度、透明度、材质和层级才是重点
- 色彩应用应随 phase 微调，而不是做成高饱和主题切换

## Icon and Asset Strategy

### 图标

- 以 `SF Symbols` 风格为主
- 默认单色或近单色
- 强调色只用于当前选中态或关键状态

不追求“更多颜色”，而追求“更稳定的视觉节奏”。

### 图片素材

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

## Future Vision

优先级建议：

1. 继续打磨 `Focus` 页气泡与布局细节
2. 接入真正的自定义声音素材
3. 完善本地通知体验
4. 将统计持久化迁移到 `SwiftData`
5. 继续完善无障碍体验与边界场景
6. 再考虑 `iCloud` 同步

`VibePomodoro` 的设计目标不是做一个“更花的番茄钟”，而是做一个：

> 计时准确、架构稳健、视觉克制、真正能让人更容易进入专注状态的番茄钟。
