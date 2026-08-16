# FEAT 两级体系（父FEAT + 子FEAT）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 embedspec 落地可复用的两级 FEAT 体系：父FEAT（统筹规划+项目表）+ 子FEAT（5阶段实现），模板项目无关、示例独立可删、索引两级、引用同步。

**Architecture:** 新增 `.template-parent.md`，将 `.template.md` 改名 `.template-child.md` 并做最小增量（父引用+回填义务），`INDEX.md` 改两级索引，`examples/` 放 SoundDog 风格演示（标注可删），最后同步 CLAUDE.md / docs/INDEX.md / README.md 三处引用。

**Tech Stack:** Markdown 文档体系，无代码/无脚本。spec 依据：`docs/superpowers/specs/2026-08-16-feat-two-tier-design.md`。

**重要前提**：CLAUDE.md / README.md 工作区有用户未提交改动（DOC-STATE 注释、Quick Start 注释），执行时只做本计划指定的插入/替换，不整文件重写、不 `git add -A` 提交无关文件。

---

### Task 1: 创建父FEAT模板 `.template-parent.md`

**Files:**
- Create: `docs/features/.template-parent.md`

- [ ] **Step 1: 创建文件**

写入以下完整内容（项目无关，仅 `{{占位符}}`）：

```markdown
# FEAT-{A1}-{简短描述}（父FEAT · 统筹规划）

> **AI 执行规则**：父FEAT 只做统筹规划，禁止编写实现代码；实现一律拆成子FEAT。
> 创建/修改项目表后必须停等，输出结果等人类确认方向后才允许创建子FEAT。
> 禁止自审自判完成：父FEAT 置 🟢 仅当项目表全部子FEAT 🟢 且每个都经过 Review。

## 0. 元数据
- **优先级**：P0(阻断) / P1(紧急) / P2(正常) / P3(可缓)
- **预估总耗时**：
- **当前状态**：🔴规划中 / 🟡部分子FEAT完成 / 🟢全部完成

## 1. 总体目标与方向

### 1.1 核心目标（一句话）
> 示例：实现 {{功能域}} 的 {{能力}}，支撑 {{大阶段目标}}。

### 1.2 大方向策略
> 示例：先 {{基础能力}} 后 {{进阶能力}}；优先复用 {{现有模块}}，不重复造轮子。

### 1.3 硬边界（继承 CLAUDE.md）
- [ ] 是否涉及底层库（Core/ Drivers/ lvgl/ Middlewares/）？是 → 暂停，进地基评估
- [ ] 否 → 继续进入项目表规划

## 2. 项目表（子FEAT清单）

| 子FEAT编号 | 功能 | 验收要点 | 优先级 | 依赖 | 状态 | 文件 |
|-----------|------|----------|--------|------|------|------|
| FEAT-{A1}-01 | {{功能}} | {{验收要点}} | P2 | 无 | 🔴未开始 | `FEAT-{A1}-01-{描述}.md` |
| FEAT-{A1}-02 | {{功能}} | {{验收要点}} | P2 | 依赖 01 | 🔴未开始 | `FEAT-{A1}-02-{描述}.md` |

> 子FEAT 完成后回填本行状态与文件链接（🟢已完成 / 🟡阶段X进行中）。

## 3. 依赖与执行顺序

1. {{先做X}} → {{再做Y}}（{{原因}}）
2. {{可并行}}：{{C}} 与 {{D}} 互不依赖

## 4. 阻塞与下一步

- **阻塞**：{{等硬件 / 等决策 / 等外部依赖}}
- **下一步**：{{第一个要开的子FEAT及其原因}}

## 5. 完成定义（DoD）

- [ ] 项目表全部子FEAT 🟢 且每个经 Review
- [ ] 本表状态与 `docs/features/INDEX.md` 一致
- [ ] 经验教训已提炼（如有）

## 6. 执行日志

| 时间 | 动作 | 角色 | 摘要 | 遇阻 |
|------|------|------|------|------|
| | | | | |
```

- [ ] **Step 2: 校验项目无关性**

Run: `grep -nE "STM32|ESP32|做饭|SoundDog|麦克风|RS485|上位机" docs/features/.template-parent.md`
Expected: 无输出（返回非0），文件只有占位符。

- [ ] **Step 3: 提交**

```bash
git add docs/features/.template-parent.md
git commit -m "docs: add parent FEAT template (planner + project table)"
```

---

### Task 2: 子FEAT模板（`.template.md` 改名 + 最小增量）

**Files:**
- Rename: `docs/features/.template.md` → `docs/features/.template-child.md`
- Modify: `docs/features/.template-child.md`（3处增量）

- [ ] **Step 1: 改名**

Run: `git mv docs/features/.template.md docs/features/.template-child.md`

- [ ] **Step 2: 修改标题行（第1行）**

将第 1 行：
```
# FEAT-{YYYYMMDD}-{序号}-{简短描述}
```
替换为：
```
# FEAT-{A1}-{序号}-{简短描述}

> 无父FEAT 的独立功能用：`FEAT-{YYYYMMDD}-{序号}-{简短描述}`。
```

- [ ] **Step 3: 顶部 AI 执行规则追加回填义务**

在文件头引用块（第 3-4 行 `> **AI 执行规则**` 与 `> 阶段间停等…` 两行）之后追加一行：
```
> 阶段5通过后：回填父FEAT项目表该行 + 更新 docs/features/INDEX.md。
```

- [ ] **Step 4: 元数据增加父FEAT字段**

在 `## 0. 元数据` 下 `- **优先级**…` 行之前插入：
```
- **父FEAT**：FEAT-{A1}-{父描述}（独立功能填"无"）
```

- [ ] **Step 5: 校验**

Run: `grep -n "父FEAT" docs/features/.template-child.md`
Expected: 至少 3 处命中（顶部规则、元数据、阶段5/回填相关）。

- [ ] **Step 6: 提交**

```bash
git add docs/features/.template-child.md
git commit -m "docs: rename FEAT template to child template, add parent ref + backfill rule"
```

---

### Task 3: INDEX.md 改为两级索引

**Files:**
- Modify: `docs/features/INDEX.md`（整体重写）

- [ ] **Step 1: 重写文件**

写入以下完整内容（覆盖现有单级索引）：

```markdown
# 功能开发索引（FEAT INDEX）

> 维护规则：父FEAT 用 `.template-parent.md` 创建（统筹规划+项目表）；子FEAT 用 `.template-child.md` 创建（5阶段实现）。
> 子FEAT 阶段5通过后：回填父FEAT项目表该行 + 更新本表子行。
> 父行状态由子行推导（见推导规则）；修改 docs 后同步本表更新日期。

## 状态图例

| 标记 | 子FEAT | 父FEAT |
|------|--------|--------|
| 🔴 未开始 | 已建档未启动 | 规划中，尚未开子FEAT |
| 🟡 进行中 | 阶段X进行中 | 部分子FEAT已完成 |
| 🟢 已完成 | 阶段5 Review 通过 | 全部子FEAT 🟢（DoD达成） |

## 父行状态推导规则

- 全部子 🟢 → 父 🟢
- 有子 🟡 或 🟢 → 父 🟡
- 无子开工 → 父 🔴

## 索引表

| 层级 | FEAT ID | 优先级 | 描述 | 状态 | 创建日期 | 预估耗时 | 实际耗时 | 文件 |
|------|---------|--------|------|------|----------|----------|----------|------|
| 父 | FEAT-A1 | P1 | {{父目标}} | 🔴 | | | | `FEAT-A1-{描述}.md` |
| ├子 | FEAT-A1-01 | P1 | {{步骤}} | 🔴 | | | | `FEAT-A1-01-{描述}.md` |
```

- [ ] **Step 2: 提交**

```bash
git add docs/features/INDEX.md
git commit -m "docs: two-level FEAT index with parent derivation rule"
```

---

### Task 4: examples/ 演示集（标注可删）

**Files:**
- Create: `docs/features/examples/FEAT-A1-麦克风验证.md`（父FEAT演示，🟡含1个已完成子项）
- Create: `docs/features/examples/FEAT-A1-01-接线验证.md`（子FEAT演示，完整5阶段+AC全勾+回填）
- Create: `docs/features/examples/FEAT-A2-RS485通信.md`（父FEAT演示，🔴规划中）
- Create: `docs/features/examples/FEAT-A3-上位机.md`（父FEAT演示，🔴规划中）

每个文件头部第一行必须包含：
```
> **⚠️ 演示示例**：本文件用于演示两级 FEAT 体系（内容基于虚构项目），复制到你的项目后请删除或改写。
```

- [ ] **Step 1: 创建 `FEAT-A1-麦克风验证.md`**

```markdown
# FEAT-A1-麦克风验证（父FEAT · 统筹规划）

> **⚠️ 演示示例**：本文件用于演示两级 FEAT 体系（内容基于虚构项目），复制到你的项目后请删除或改写。

> **AI 执行规则**：父FEAT 只做统筹规划，禁止编写实现代码；实现一律拆成子FEAT。
> 创建/修改项目表后必须停等，等人类确认方向后才允许创建子FEAT。
> 禁止自审自判完成：父FEAT 置 🟢 仅当项目表全部子FEAT 🟢 且每个都经过 Review。

## 0. 元数据
- **优先级**：P1
- **预估总耗时**：12h
- **当前状态**：🟡部分子FEAT完成

## 1. 总体目标与方向

### 1.1 核心目标（一句话）
> 验证麦克风采集链路可用，产出标定参数，支撑后续 FFT 分析。

### 1.2 大方向策略
> 先验证硬件接线与供电，再打通 I2S/PDM 采集，最后做采样率与噪声基准标定。

### 1.3 硬边界（继承 CLAUDE.md）
- [x] 是否涉及底层库（Core/ Drivers/ lvgl/ Middlewares/）？→ 否（仅 App 层 + 配置文件）
- [x] 否 → 继续

## 2. 项目表（子FEAT清单）

| 子FEAT编号 | 功能 | 验收要点 | 优先级 | 依赖 | 状态 | 文件 |
|-----------|------|----------|--------|------|------|------|
| FEAT-A1-01 | 接线与供电验证 | 供电正常、信号线无虚焊，逻辑分析仪抓到时序 | P1 | 无 | 🟢已完成 | `FEAT-A1-01-接线验证.md` |
| FEAT-A1-02 | I2S/PDM 驱动采集 | 持续采集原始PCM，DMA无溢出 | P1 | 依赖 01 | 🔴未开始 | `FEAT-A1-02-采集驱动.md` |
| FEAT-A1-03 | 采样率/数据格式校验 | 已知声源注入，采样率误差<1% | P1 | 依赖 02 | 🔴未开始 | `FEAT-A1-03-采样率校验.md` |
| FEAT-A1-04 | 噪声基准与响应测试 | 静态噪声/动态响应对比基准 | P2 | 依赖 02 | 🔴未开始 | `FEAT-A1-04-噪声基准.md` |
| FEAT-A1-05 | 标定报告输出 | 增益/阈值标定，交付FFT使用 | P1 | 依赖 03,04 | 🔴未开始 | `FEAT-A1-05-标定报告.md` |

> 子FEAT 完成后回填本行状态与文件链接。

## 3. 依赖与执行顺序

1. A1-01 接线验证 → A1-02 采集驱动（硬件不通过则后续无意义）
2. A1-03 采样率校验 与 A1-04 噪声基准 可并行（均依赖 02）
3. A1-05 标定报告 最后做（依赖 03、04）

## 4. 阻塞与下一步

- **阻塞**：新麦克风 / 逻辑分析仪未到货
- **下一步**：硬件到货后开 A1-02 采集驱动

## 5. 完成定义（DoD）

- [ ] 项目表全部子FEAT 🟢 且每个经 Review
- [ ] 本表状态与 `docs/features/INDEX.md` 一致
- [ ] 经验教训已提炼（如有）

## 6. 执行日志

| 时间 | 动作 | 角色 | 摘要 | 遇阻 |
|------|------|------|------|------|
| 2026-08-16 | 创建父FEAT | Planner | 规划A1麦克风验证5个子步骤 | 无 |
```

- [ ] **Step 2: 创建 `FEAT-A1-01-接线验证.md`**

```markdown
# FEAT-A1-01-接线验证（子FEAT）

> **⚠️ 演示示例**：本文件用于演示两级 FEAT 体系（内容基于虚构项目），复制到你的项目后请删除或改写。

> **AI 执行规则**：必须按阶段顺序执行，每个阶段开头声明角色。严禁跳跃、越界、自审自判。
> 阶段间停等：每完成一个阶段，停下来，输出结果，等人说"继续"。
> 阶段5通过后：回填父FEAT项目表该行 + 更新 docs/features/INDEX.md。

## 0. 元数据
- **父FEAT**：FEAT-A1-麦克风验证
- **优先级**：P1
- **预估总耗时**：2h
- **当前状态**：🟢已完成

## 1. 总体目标与硬边界

### 1.1 核心目标（一句话）
> 验证麦克风接线与供电，用逻辑分析仪确认时序。

### 1.2 地基触碰前置自检
- [x] 否 → 继续

### 1.3 任务边界
| 类型 | 具体内容 |
|------|----------|
| 范围内（可改） | App 层接线初始化、测试代码 |
| 超出范围（禁止碰） | Core/ Drivers/ lvgl/ Middlewares/ 底层库 |
| 外部依赖 | 逻辑分析仪、新麦克风 |

## 2. 执行路线图（5 阶段）

### 🟢 阶段 1：准备（角色：Dev Agent）
- [x] 步骤1：定位接线引脚与供电电路
- [x] 步骤2：影响范围：仅测试代码，无接口变化
- **⏸️ 停等 → 已确认**

### 🔵 阶段 2：设计（角色：Dev Agent）
- [x] 步骤1：接线检查清单
- [x] 步骤2：验证步骤与判定标准
- **⏸️ 停等 → 已确认**

### 🟠 阶段 3：实现（角色：Dev Agent）
- [x] 步骤1：编写接线自检代码
- [x] 步骤2：对照 AC 自检
- **⏸️ 停等 → 已确认**

===== 切换至 Test Agent =====

### 🟣 阶段 4：测试（角色：Test Agent）
- [x] 步骤1：按 AC 编写测试用例
- [x] 步骤2：运行 ./scripts/ci_local.sh，通过
- **⏸️ 停等 → 已确认**

===== 切换至 Review Agent =====

### 🔴 阶段 5：审查（角色：Review Agent）
- [x] AC 逐条打勾，全部通过
- [x] 回填：父FEAT 项目表 FEAT-A1-01 行置 🟢 + INDEX.md 子行置 🟢

## 3. 验收标准（12 条）

### 功能验收
- [x] AC-01 功能目标达成
- [x] AC-02 向后兼容
### 代码质量
- [x] AC-03 编译/Lint 通过
- [x] AC-04 无新增警告
- [x] AC-05 文档已更新
### 安全红线
- [x] AC-06 无硬编码密钥
- [x] AC-07 错误处理完善
- [x] AC-08 用户输入已校验
### 测试与边界
- [x] AC-09 新增测试自动运行
- [x] AC-10 全部回归测试通过
- [x] AC-11 测试覆盖率 ≥ 80%
- [x] AC-12 按 FEAT 模板执行

## 4. 执行日志

| 时间 | 阶段 | 角色 | 摘要 | 遇阻 |
|------|------|------|------|------|
| 2026-08-16 | 1-3 | Dev | 接线自检代码完成 | 无 |
| 2026-08-16 | 4 | Test | CI 通过 | 无 |
| 2026-08-16 | 5 | Review | 全部AC通过，回填父表 | 无 |
```

- [ ] **Step 3: 创建 `FEAT-A2-RS485通信.md`（父结构演示，🔴规划中）**

```markdown
# FEAT-A2-RS485通信（父FEAT · 统筹规划）

> **⚠️ 演示示例**：本文件用于演示两级 FEAT 体系（内容基于虚构项目），复制到你的项目后请删除或改写。

> **AI 执行规则**：父FEAT 只做统筹规划，禁止编写实现代码；实现一律拆成子FEAT。
> 创建/修改项目表后必须停等，等人类确认方向后才允许创建子FEAT。
> 禁止自审自判完成：父FEAT 置 🟢 仅当项目表全部子FEAT 🟢 且每个都经过 Review。

## 0. 元数据
- **优先级**：P1
- **预估总耗时**：16h
- **当前状态**：🔴规划中

## 1. 总体目标与方向

### 1.1 核心目标（一句话）
> 打通 RS485 半双工通信链路，协议帧定义双端一致、长线可靠。

### 1.2 大方向策略
> 先硬件接口与回环，再收发状态机，最后协议帧与可靠性测试。

### 1.3 硬边界（继承 CLAUDE.md）
- [x] 是否涉及底层库？→ 否（UART 走 HAL 标准库，App 层状态机）
- [x] 否 → 继续

## 2. 项目表（子FEAT清单）

| 子FEAT编号 | 功能 | 验收要点 | 优先级 | 依赖 | 状态 | 文件 |
|-----------|------|----------|--------|------|------|------|
| FEAT-A2-01 | RS485硬件接口 | 电路检查通过，回环可收发 | P1 | 无 | 🔴未开始 | `FEAT-A2-01-硬件接口.md` |
| FEAT-A2-02 | UART驱动+半双工状态机 | 收发切换无冲突 | P1 | 依赖 01 | 🔴未开始 | `FEAT-A2-02-收发状态机.md` |
| FEAT-A2-03 | 协议帧定义 | 帧头/地址/长度/CRC 文档化，双端一致 | P1 | 依赖 02 | 🔴未开始 | `FEAT-A2-03-协议帧.md` |
| FEAT-A2-04 | 主从应答+超时重试 | 丢帧可重试恢复 | P1 | 依赖 03 | 🔴未开始 | `FEAT-A2-04-应答重试.md` |
| FEAT-A2-05 | 双机回环+长线测试 | 连续1000帧无误码 | P2 | 依赖 04 | 🔴未开始 | `FEAT-A2-05-长线测试.md` |

## 3. 依赖与执行顺序

1. 01 硬件接口 → 02 状态机 → 03 协议帧（串行推进）
2. 04 应答重试 依赖 03；05 长线测试 最后做

## 4. 阻塞与下一步

- **阻塞**：等待 A1 标定完成释放调试资源
- **下一步**：确认硬件后开 A2-01 硬件接口

## 5. 完成定义（DoD）

- [ ] 项目表全部子FEAT 🟢 且每个经 Review
- [ ] 本表状态与 `docs/features/INDEX.md` 一致
- [ ] 经验教训已提炼（如有）

## 6. 执行日志

| 时间 | 动作 | 角色 | 摘要 | 遇阻 |
|------|------|------|------|------|
| 2026-08-16 | 创建父FEAT | Planner | 规划A2 RS485通信5个子步骤 | 无 |
```

- [ ] **Step 4: 创建 `FEAT-A3-上位机.md`（父结构演示，🔴规划中）**

```markdown
# FEAT-A3-上位机（父FEAT · 统筹规划）

> **⚠️ 演示示例**：本文件用于演示两级 FEAT 体系（内容基于虚构项目），复制到你的项目后请删除或改写。

> **AI 执行规则**：父FEAT 只做统筹规划，禁止编写实现代码；实现一律拆成子FEAT。
> 创建/修改项目表后必须停等，等人类确认方向后才允许创建子FEAT。
> 禁止自审自判完成：父FEAT 置 🟢 仅当项目表全部子FEAT 🟢 且每个都经过 Review。

## 0. 元数据
- **优先级**：P2
- **预估总耗时**：20h
- **当前状态**：🔴规划中

## 1. 总体目标与方向

### 1.1 核心目标（一句话）
> 实现上位机：连接下位机、解析协议、实时显示波形、数据记录与回放。

### 1.2 大方向策略
> 先框架与连接，再协议解析，最后波形与记录；协议字段与 A2-03 帧定义逐字段对齐。

### 1.3 硬边界（继承 CLAUDE.md）
- [x] 是否涉及底层库？→ 否（纯上位机应用，不碰固件底层库）
- [x] 否 → 继续

## 2. 项目表（子FEAT清单）

| 子FEAT编号 | 功能 | 验收要点 | 优先级 | 依赖 | 状态 | 文件 |
|-----------|------|----------|--------|------|------|------|
| FEAT-A3-01 | 上位机框架+串口连接 | 枚举/连接/断开正常 | P1 | 无 | 🔴未开始 | `FEAT-A3-01-框架串口.md` |
| FEAT-A3-02 | 协议解析层+数据模型 | 与 A2-03 帧定义逐字段对齐 | P1 | 依赖 01 | 🔴未开始 | `FEAT-A3-02-协议解析.md` |
| FEAT-A3-03 | 实时波形显示 | 采样率内刷新无卡顿 | P1 | 依赖 02 | 🔴未开始 | `FEAT-A3-03-波形显示.md` |
| FEAT-A3-04 | 数据记录/导出/回放 | 数据完整可回放 | P2 | 依赖 02 | 🔴未开始 | `FEAT-A3-04-记录回放.md` |
| FEAT-A3-05 | 下位机联调+验收 | 端到端全链路通过 | P1 | 依赖 A2 | 🔴未开始 | `FEAT-A3-05-联调验收.md` |

## 3. 依赖与执行顺序

1. 01 框架串口 → 02 协议解析 → 03 波形显示（串行）
2. 04 记录回放 与 03 可并行；05 联调依赖整个 A2 完成

## 4. 阻塞与下一步

- **阻塞**：依赖 A2 协议定稿
- **下一步**：A2-03 协议帧通过后开 A3-01

## 5. 完成定义（DoD）

- [ ] 项目表全部子FEAT 🟢 且每个经 Review
- [ ] 本表状态与 `docs/features/INDEX.md` 一致
- [ ] 经验教训已提炼（如有）

## 6. 执行日志

| 时间 | 动作 | 角色 | 摘要 | 遇阻 |
|------|------|------|------|------|
| 2026-08-16 | 创建父FEAT | Planner | 规划A3 上位机5个子步骤 | 无 |
```

- [ ] **Step 5: 提交**

```bash
git add docs/features/examples/
git commit -m "docs: two-tier FEAT demo examples (A1/A2/A3, deletable)"
```

---

### Task 5: 引用同步（CLAUDE.md / docs/INDEX.md / README.md）

**Files:**
- Modify: `CLAUDE.md`（场景导航表加2行）
- Modify: `docs/INDEX.md`（场景表1行替换为2行 + 文档清单2行替换为3行）
- Modify: `README.md`（目录树1行替换为4行 + 核心流程补两级说明）

- [ ] **Step 1: CLAUDE.md 场景导航表**

在 `| 搭建开发环境 | docs/tools/dev-setup.md（CodeGraph + Ponytail + OpenCLI） |` 行之后追加两行：
```
| 规划功能方向（开父FEAT） | `docs/features/.template-parent.md` |
| 实现具体功能（开子FEAT） | `docs/features/.template-child.md` |
```

- [ ] **Step 2: docs/INDEX.md 场景检索地图**

将行 `| 功能开发流程 | docs/features/.template.md（5阶段模板） |` 替换为两行：
```
| 规划功能方向（父FEAT） | `docs/features/.template-parent.md` |
| 实现具体功能（子FEAT，5阶段） | `docs/features/.template-child.md` |
```

- [ ] **Step 3: docs/INDEX.md 文档清单**

将行 `| features/.template.md | FEAT 5阶段开发模板（准备→设计→实现→测试→审查） |` 替换为：
```
| features/.template-parent.md | 父FEAT统筹模板（方向+项目表+依赖+DoD） |
| features/.template-child.md | 子FEAT实现模板（5阶段+12AC+回填） |
| features/examples/ | 两级体系演示示例（复制后删除） |
```
并将行 `| features/INDEX.md | 功能开发索引进度 |` 的描述改为 `两级FEAT索引进度`。

- [ ] **Step 4: README.md 目录树**

将行 `│   ├── features/.template.md     # FEAT 5阶段开发（准备→设计→实现→测试→审查）` 替换为：
```
│   ├── features/.template-parent.md # 父FEAT统筹（方向+项目表+DoD）
│   ├── features/.template-child.md  # 子FEAT实现（5阶段+AC+回填）
│   ├── features/INDEX.md            # 两级FEAT索引
│   └── features/examples/           # 演示示例（复制后删除）
```

- [ ] **Step 5: README.md 核心流程补两级说明**

在 `## Core workflow / 核心流程` 节中，`- 12 条验收标准（AC-01~AC-12），Review 逐条打勾` 行之后追加：
```
**两级 FEAT：父FEAT（A1/A2…）统筹规划 + 项目表；子FEAT（A1-01…）逐个走5阶段。**
子FEAT 阶段5通过 → 回填父项目表 + INDEX；全部 🟢 → 父FEAT 完成。
```

- [ ] **Step 6: 提交**

```bash
git add CLAUDE.md docs/INDEX.md README.md
git commit -m "docs: sync references to two-tier FEAT system"
```

---

### Task 6: 终检

- [ ] **Step 1: 模板项目无关性**

Run: `grep -rnE "STM32|ESP32|做饭|SoundDog|麦克风|RS485|上位机" docs/features/.template-parent.md docs/features/.template-child.md docs/features/INDEX.md`
Expected: 无输出（非0退出）。examples/ 允许包含（演示内容）。

- [ ] **Step 2: 引用一致性**

Run: `grep -rn "features/.template.md" CLAUDE.md docs/ README.md`
Expected: 无输出（旧模板名不再被引用）。

- [ ] **Step 3: 结构核对**

Run: `ls docs/features/ docs/features/examples/`
Expected:
```
.template-child.md
.template-parent.md
INDEX.md
examples/FEAT-A1-01-接线验证.md
examples/FEAT-A1-麦克风验证.md
examples/FEAT-A2-RS485通信.md
examples/FEAT-A3-上位机.md
```

- [ ] **Step 4: git 状态确认**

Run: `git status --short`
Expected: 仅本计划涉及文件 + 用户原有未提交改动（CLAUDE.md/README.md/scripts 的既有修改）。如有意外文件，停下检查再提交。

- [ ] **Step 5: 终检修复如有则提交**

若有 Step 1/2 失败项，修复后 `git commit -m "docs: fix two-tier FEAT verification findings"`。

---

## 自审记录（writing-plans 要求）

- **Spec 覆盖**：D1(文件组织)→Task1/2；D2(命名)→Task2标题；D3(子FEAT 5阶段)→Task2保留原模板；D4(方案A)→Task1/2；D5(项目无关)→Task1/6；D6(示例)→Task4；D7(大阶段不建文档)→无任务（设计决定）；D8(父行推导)→Task3；D9(生命周期)→Task4演示；AI约束9.1-9.5→Task1父模板AI规则、Task2回填规则、Task4示例体现；引用更新→Task5；验收标准→Task6。
- **占位符扫描**：所有代码块为完整文件内容，无 TBD/TODO。
- **类型一致性**：文件名、编号（FEAT-A1-01）、路径在全部任务中一致。
