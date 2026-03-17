# VibePomodoro

`VibePomodoro` 是一款以“精准计时”和“安静陪伴”为核心的番茄钟 App。

它不是一个强调打卡、刺激和游戏化反馈的效率面板，而是一个在专注前、专注中、专注后都尽量保持平静、可信赖、有温度的工具。

---

## 1. 产品定位

### 1.1 核心目标

- 计时必须精准，尤其是在 App 进入后台、锁屏、甚至后续接入 `Live Activities` 时，计时仍然要以真实时间为准。
- 架构必须可扩展，便于后续接入 `SwiftData`、`iCloud`、统计分析、提醒系统和更多自定义设置。
- 视觉上追求 `Liquid Glass` 气质下的克制高级感，同时保留一点“人味”和陪伴感。

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
- `Skip`
- `Back`

语义定义如下：

- `Start`：从当前 step 的初始状态开始
- `Pause`：冻结当前 step，保留剩余时长
- `Resume`：基于当前时间和剩余时长重新生成新的 `targetEndDate`
- `Skip`：进入下一 step 的初始状态；不增加完成轮次，但会记录当前 step 已发生的有效时长
- `Back`：回到上一 step 的初始状态，并回滚刚刚已结算的统计与轮次

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

### 2.6 统计口径

统计只记录“有效运行时长”，不包含暂停时间。

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
- `Skip` 记录当前阶段已发生时长，但不计入额外完成轮次
- `Back` 会回滚相关已结算统计

### 2.7 提醒与反馈

- 每个 step 结束时需要提醒
- 每个新 step 开始时也需要提醒
- 提醒形式包括：
  - 声音
  - 震动 / haptics

说明：

- MVP 中先保留音效选择结构和提醒入口
- 真正区分音色的自定义声音素材可以在后续版本继续补充

---

## 3. MVP 范围

### 3.1 MVP 必做

- 时间戳驱动的精准计时
- `Focus / Short Break / Long Break` 三阶段流程
- `Start / Pause / Resume / Skip / Back`
- 后台自动推进
- App 重启后恢复当前 session
- 基础设置与基础统计
- 三页 UI：
  - `Focus`
  - `Productivity`
  - `Settings`

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
- `Skip` 和 `Back` 不会造成统计错乱
- session 完成时机正确
- 后台与重启恢复正确
- UI 结构清晰，体验安静，不显得为了设计而设计

---

## 4. UI 方向定稿

### 4.1 UI 设计原则

经过设计讨论，最终冻结的 UI 原则为：

1. 专注优先
2. 温度来自材质和节奏，而不是颜色堆砌
3. 数据页诚实，不装饰化
4. 整套 App 只保留一个强记忆点

### 4.2 总体视觉语言

整体遵循 `Liquid Glass` 气质，但不做过度炫技。

关键词：

- 安静
- 温柔
- 克制
- 高级
- 冥想感

不做的方向：

- 不做高刺激的效率激励界面
- 不做游戏化打卡 UI
- 不做过度炫耀材质的“玻璃秀场”
- 不做五颜六色的图标墙
- 不做“为了设计而设计”的装饰型统计页

### 4.3 三个页面的角色

#### Focus

这是整个 App 的情绪核心和唯一强记忆点。

定位：

- 冥想对象
- 安静的计时空间
- 用户进入专注前后的情绪缓冲层

设计规则：

- 页面元素尽量少
- 气泡是主视觉记忆点
- 时间数字永远是最重要信息
- 动效应慢、柔和、有呼吸感

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

### 5.3 不采用“拖拽圆环改时长”的原因

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

---

## 6. Light / Dark 设计原则

### Light

- 以暖白、雾灰、浅金为主
- 干净但不冰冷
- 重点是柔和和呼吸感

### Dark

- 以烟灰、墨黑、暖琥珀高光为主
- 避免纯黑硬切
- 重点是沉静和材质层次

### 全局配色原则

- 只保留一条主强调色，当前方向为暖金色系
- 颜色不是主角，明度、透明度、材质和层级才是重点

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
  - 核心模型、状态机、事件定义
- [VibePomodoro/PomodoroStore.swift](./VibePomodoro/PomodoroStore.swift)
  - 状态管理、持久化、通知调度、聚合统计
- [VibePomodoro/FocusScreen.swift](./VibePomodoro/FocusScreen.swift)
  - Focus 页
- [VibePomodoro/ProductivityScreen.swift](./VibePomodoro/ProductivityScreen.swift)
  - Productivity 页
- [VibePomodoro/SettingsScreen.swift](./VibePomodoro/SettingsScreen.swift)
  - Settings 页
- [VibePomodoro/UIComponents.swift](./VibePomodoro/UIComponents.swift)
  - 玻璃材质组件、气泡组件、底部导航等

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

