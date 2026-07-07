# EmbedSpec

> CLAUDE.md standard for embedded firmware projects. Auto-detects STM32/ESP32, catches doc-vs-code drift in CI.
>
> 嵌入式固件项目 CLAUDE.md 规范标准。自动识别 STM32/ESP32 平台，CI 校验文档与源码一致性。

---

## Why / 为什么需要

### The problem / 问题场景

Embedded projects have a unique documentation problem. Your `CLAUDE.md` is the first thing the coding agent reads every session — it tells the agent what chip, what RTOS, what pins, what not to touch. But embedded code changes:

- MCU gets swapped (STM32F407 → STM32F407ZGT6 → ESP32-C3)
- HSE crystal changes (12MHz → 8MHz)
- FreeRTOS upgrades (v10.3.1 → v10.4.1)
- Tasks get added or removed
- Stack sizes get tuned

**Nobody updates the doc.** The agent reads stale hardware info and hallucinates wrong pin configs, wrong clock trees, wrong HAL calls.

嵌入式项目的 CLAUDE.md 是 agent 每次会话第一个读的文件——告诉它什么芯片、什么RTOS、什么引脚、不能碰什么。但硬件变更频繁，文档很快腐烂。**Agent 读着过时的硬件信息，生成的代码引脚、时钟树、HAL调用全是错的。**

### The fix / 解决方案

EmbedSpec does two things:

1. **CLAUDE.md template** — layered design: ~400 Token at session load, deep docs on `Read()` demand. Chip presets for STM32 and ESP32 so the agent auto-fills your hardware info instead of guessing.
2. **`check-doc-drift.sh`** — runs in CI. Extracts real values from your source code (chip type, build system, task count, HSE frequency, stack size) and diffs them against the machine-readable `DOC-STATE` marker. Mismatch → build fails.

两层解法：**模板**规范结构 + 芯片预设自动填入；**CI 脚本**从源码提取实际值对比 DOC-STATE，漂移即拦截。

### Real damage example / 真实翻车现场

```
CLAUDE.md:           STM32F407VET6, HSE 12MHz, FreeRTOS v10.4.1
Actual source:       ESP32-C3, no HSE, ESP-IDF FreeRTOS
Agent generates:     HAL_Init(), SystemClock_Config(12MHz), arm-none-eabi Makefile
Result:              300 lines of dead code, zero lines that compile
```

---

## Design / 设计理念

### Layered CLAUDE.md / 分层结构

Traditional CLAUDE.md dumps everything into one file — hardware specs, pin tables, debug guides, build instructions. The agent loads it all every session, burning context window on info it doesn't need yet.

传统做法把所有信息堆在一个文件——硬件参数、引脚表、调试指南、构建说明。Agent 每次全量加载，浪费 Token。

EmbedSpec layers it:

EmbedSpec 分层：

```
CLAUDE.md (~400 Token, loaded every session / 每次会话自动加载)
├── DOC-STATE                # Machine-readable / 机器可读
├── 1-line HW+SW summary     # 一行摘要
├── Scene navigation table   # 场景导航表
├── Directory map            # 目录速查
├── Hard boundaries          # 开发边界
└── Link to docs/INDEX.md    # 深层文档入口

docs/ (loaded on demand / 按需 Read)
├── INDEX.md                 # All docs index / 文档总索引
├── tools/gdb_debug.md       # Debug guide / 调试教程
├── tools/skills.md          # Build/flash commands / 编译烧录命令
├── features/FEAT-*.md       # Feature specs / 功能设计文档
├── bugs/.template.md        # Bug report template / Bug 登记模板
└── troubleshooting/         # Historical bug fixes / 历史故障库
```

**Result / 效果**: Agent reads 400 Token to understand the project, then `Read()` specific docs only when the task needs them. Context window stays clean for actual code.

Agent 进来只需 400 Token 就知道边界和导航，具体操作时按场景索引 `Read()` 对应文档。上下文窗口留给真正的代码。

### Scene navigation / 场景导航

Instead of "read everything before you start," CLAUDE.md gives the agent a lookup table:

不是"先读完所有文档再动手"，而是一张速查表：

| You're asked to / 你要 | Read this first / 先读 |
|-----------------------|----------------------|
| Change a pin | `pin_config.h` + `hal_msp.c` |
| Modify UI | `lv_conf.h` + `lv_port_disp.c` |
| Add a FreeRTOS task | `freertos.c` + `tasks.h` |
| Debug a HardFault | `docs/tools/gdb_debug.md` |
| Fix build failure | `docs/tools/skills.md` + `ci_local.sh` |
| Change ESP32 bridge | `weather_bridge.c` |
| Implement a feature | `docs/features/.template.md` |

The agent knows exactly which file to `Read()` before touching code. No guessing, no shotgun-reading.

---

## Install / 安装

### Minimum setup / 最小安装

Two files / 两个文件:

```bash
git clone https://github.com/wumu-dot/embedspec.git
cp embedspec/CLAUDE.md embedspec/scripts/check-doc-drift.sh your-project/
```

Requirements: `bash`, `grep`, `sed`, `find`, `awk` — all standard on macOS/Linux/WSL/MSYS2. No npm, no pip, no Docker.

依赖: `bash` + 标准 Unix 工具（macOS/Linux/WSL/MSYS2 自带）。零额外依赖。

### Full setup / 完整安装

Recommended project structure after adopting EmbedSpec:

建议的项目结构：

```
your-project/
├── CLAUDE.md                   # From template, customized / 从模板定制
├── scripts/
│   ├── check-doc-drift.sh      # Drift checker / 漂移检查
│   └── ci_local.sh             # Local CI (build + drift + lint)
├── docs/
│   ├── INDEX.md                # Doc index / 文档索引
│   ├── tools/                  # Debug, flash, skill guides
│   ├── features/               # Feature specs
│   └── troubleshooting/        # Bug history
├── firmware/                   # Your source code
├── .github/workflows/
│   └── ci.yml                  # CI with doc-drift job
└── .gitignore
```

---

## Quick Start / 快速开始

### Step 1: Fill DOC-STATE / 填写 DOC-STATE

Edit line 1 of `CLAUDE.md`. Replace placeholders with your project's actual values:

编辑 `CLAUDE.md` 首行，替换为项目实际值：

```markdown
<!-- DOC-STATE: CHIP=STM32F407VET6, RTOS=FreeRTOS_v10.4.1, BUILD=Makefile+arm-none-eabi-gcc, TASKS=5, HSE=12000000, MIN_STACK=128 -->
```

| Field | Meaning | Example |
|-------|---------|---------|
| `CHIP` | MCU model / 主控型号 | `STM32F407ZGT6`, `ESP32-C3` |
| `RTOS` | RTOS name + version | `FreeRTOS/CMSIS-RTOS_v2`, `FreeRTOS_v10.4.1` |
| `BUILD` | Build system + toolchain | `Makefile+arm-none-eabi-gcc`, `CMake+ESP-IDF` |
| `TASKS` | Number of business tasks / 业务任务数 | `4`, `5` |
| `HSE` | External crystal frequency (Hz) / 外部晶振频率 | `8000000`, `12000000`, `N/A` |
| `MIN_STACK` | `configMINIMAL_STACK_SIZE` | `128`, `256` |

### Step 2: Fill the template / 填入模板信息

Replace `{{PLACEHOLDER}}` values in CLAUDE.md. If your MCU is STM32 or ESP32, the agent auto-fills most fields from the chip preset table. You only need to add project-specific details (peripherals, pin assignments, custom boundaries).

替换 CLAUDE.md 中的 `{{占位符}}`。如果芯片是 STM32 或 ESP32，agent 会从预设表自动填入大部分字段，只需补充项目特有信息（外设、引脚、边界）。

### Step 3: Run the check / 运行检查

```bash
bash scripts/check-doc-drift.sh firmware/ CLAUDE.md
```

### Step 4: Expected output / 预期结果

**Pass / 通过:**
```
======== 文档 vs 源码 一致性检查 ========

✅ MCU主控: 文档=STM32F407ZGT6  源码=STM32F4
✅ 构建系统: 文档=Makefile+arm-none-eabi-gcc  源码=Makefile+arm-none-eabi-gcc
✅ 业务任务数: 文档=4  源码=4
✅ HSE_VALUE: 文档=8000000  源码=8000000
✅ 最小堆栈: 文档=128  源码=128

✅ 文档与源码一致。
```

**Drift / 漂移:**
```
❌ MCU主控: 文档=STM32F407VET6  源码=ESP32
❌ 构建系统: 文档=Makefile+arm-none-eabi-gcc  源码=CMake+ESP-IDF
⊘  HSE_VALUE: 跳过

📛 文档漂移！更新 CLAUDE.md 的 DOC-STATE 行。
exit 1
```

---

## How `check-doc-drift.sh` Works / 脚本原理

### Extraction logic / 提取逻辑

The script scans your source tree (excluding third-party libs like `lvgl/`, `Drivers/`, `Middlewares/`) and extracts:

脚本扫描源码树（排除第三方库目录），提取：

**Chip detection / 芯片识别:**
1. Check for ESP32 patterns (`esp_err`, `ESP_LOGI`, `idf_component_register`) → `ESP32`
2. Check for STM32 HAL patterns (`stm32f4xx_hal`, `HAL_Init`) → `STM32F4`
3. Check for generic STM32 patterns (`stm32`) → `STM32`
4. Otherwise → `UNKNOWN`

**Build system / 构建系统:**
1. Find `Makefile` with `arm-none-eabi` → `Makefile+arm-none-eabi-gcc`
2. Find `CMakeLists.txt` with `idf_component` → `CMake+ESP-IDF`
3. Find generic `CMakeLists.txt` → `CMake+gcc`

**Task count / 任务数:**
- Count `xTaskCreate(` calls (bare FreeRTOS) + `osThreadNew(` calls (CMSIS-RTOS v2)
- Exclude third-party lib directories

**HSE frequency / 晶振频率:**
- Parse `#define HSE_VALUE` from `stm32f4xx_hal_conf.h` (skip template files)
- Strip `U`, `L`, parentheses, comments → pure number
- Return `NOT_FOUND` for non-STM32 platforms (skips automatically)

**Min stack / 最小堆栈:**
- Parse `#define configMINIMAL_STACK_SIZE` from `FreeRTOSConfig.h`
- Handle `((uint16_t)128)` wrapper → extract last number (128)
- Handles bare `128` format too

### Skipping third-party code / 跳过第三方库

The script automatically excludes: `lvgl/`, `Drivers/`, `Middlewares/`, `components/`, `node_modules/`

This prevents false positives from ESP32 compatibility code bundled inside LVGL on STM32 projects.

脚本自动排除第三方库目录，防止 STM32 项目的 LVGL 库里包含的 ESP32 兼容代码造成误判。

### Substring matching / 子串匹配

The comparison uses substring matching, not exact string comparison. `STM32F4` matches `STM32F407ZGT6`. This means you can be more specific in DOC-STATE without worrying about the exact format the script detects.

比对使用子串匹配而非精确匹配。`STM32F4` 能匹配到 `STM32F407ZGT6`，DOC-STATE 可以比脚本检测结果更具体。

---

## Customizing / 自定义

### Adding new fields to DOC-STATE / 增加校验字段

Edit `check-doc-drift.sh` and add three things:

在 `check-doc-drift.sh` 中加三处：

```bash
# 1. Extract from DOC-STATE
DOC_MYFIELD=$(doc_field "MYFIELD")

# 2. Extract from source
SRC_MYFIELD=$(...your extraction logic...)

# 3. Add comparison
compare "我的字段" "$DOC_MYFIELD" "$SRC_MYFIELD"
```

### Adding new chip preset / 增加芯片预设

Edit `CLAUDE.md` chip presets section:

编辑 `CLAUDE.md` 芯片预设部分：

```markdown
### nRF52 系列
| 字段 | 值 |
|------|-----|
| 调试接口 | J-Link SWD |
| RTOS | FreeRTOS (nRF5 SDK) |
| 驱动库 | nRF5 SDK |
| 编译构建 | Makefile + arm-none-eabi-gcc |
| 固定宏 | configMINIMAL_STACK_SIZE=128 |
| 硬性边界 | 禁止修改 components/libraries/ |
```

### Skipping additional directories / 排除更多目录

Edit the `SKIP_DIRS` variable in `check-doc-drift.sh`:

```bash
SKIP_DIRS="lvgl|Drivers|Middlewares|components|node_modules|your_lib"
```

---

## CI Integration / CI 集成

### GitHub Actions (full example)

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: Install toolchain
        run: sudo apt-get install -y gcc-arm-none-eabi
      - name: Build
        run: cd firmware && make -j$(nproc) all

  doc-drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check CLAUDE.md vs source
        run: bash scripts/check-doc-drift.sh firmware/ CLAUDE.md

  static-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: cppcheck
        run: |
          sudo apt-get install -y cppcheck
          cppcheck --enable=warning,performance firmware/Core/ firmware/App/
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - check

doc-drift:
  stage: check
  script:
    - bash scripts/check-doc-drift.sh firmware/ CLAUDE.md
```

### Local pre-commit / 本地提交前

Add to `scripts/ci_local.sh`:

```bash
#!/bin/bash
set -eu

echo "Building..."
cd firmware && make clean && make -j6 all

echo "Checking doc drift..."
cd ..
bash scripts/check-doc-drift.sh firmware/ CLAUDE.md || {
    echo "❌ Update CLAUDE.md DOC-STATE to match source"
    exit 1
}

echo "✅ All checks passed"
```

---

## Design Philosophy & Constraints / 设计约束

### What EmbedSpec is NOT / 不是

- **Not a code generator** — won't write pin configs or clock trees. It validates that your doc matches your code.
- **不是代码生成器** — 不写引脚配置、时钟树，只校验文档与代码一致。
- **Not an LLM-based tool** — deterministic bash script, zero API calls, zero hallucinations.
- **不是 LLM 工具** — 确定性 bash 脚本，零 API 调用，零幻觉。
- **Not a generic documentation framework** — deliberately scoped to embedded C/FreeRTOS projects.
- **不是通用文档框架** — 刻意限定在嵌入式 C/FreeRTOS 项目。

### Why not OpenWiki? / 为什么不用 OpenWiki？

| | EmbedSpec | OpenWiki |
|---|----------|----------|
| Approach / 方式 | Template + validation / 模板+校验 | LLM generates docs / LLM生成文档 |
| Determinism / 确定性 | 100% (bash script) | ~90% (LLM hallucination risk) |
| Embedded awareness / 嵌入式感知 | HSE, stack sizes, CMSIS-RTOS | None / 无 |
| Cost / 成本 | Free, runs in CI / 免费 | LLM API cost per run / 每次运行API费用 |
| Drift detection / 漂移检测 | Exact value comparison / 精确值对比 | Semantic understanding / 语义理解 |

EmbedSpec and OpenWiki are complementary, not competitors. OpenWiki is great for high-level architecture docs; EmbedSpec is for the hardware-specific ground truth that must never drift.

EmbedSpec 和 OpenWiki 互补而非竞争。OpenWiki 适合高层架构文档；EmbedSpec 负责硬件精确参数——这些不容漂移。

---

## FAQ / 常见问题

**Q: What if my chip isn't STM32 or ESP32? / 不是 STM32 或 ESP32 怎么办？**
A: The template uses `{{PLACEHOLDERS}}` and the agent asks you to fill them in. `check-doc-drift.sh` returns `UNKNOWN` for CHIP and the comparison still works — any non-empty value in DOC-STATE passes substring matching.
模板使用 `{{占位符}}`，agent 逐项询问。`check-doc-drift.sh` 返回 `UNKNOWN`，比对逻辑仍工作。

**Q: Can I skip a field? / 能跳过某个字段吗？**
A: Yes. Leave the field out of DOC-STATE, or set it to `N/A`. The script skips it.
可以从 DOC-STATE 中去掉该字段，或设为 `N/A`。

**Q: Does this work with bare-metal / no RTOS? / 裸机无RTOS能用吗？**
A: Yes. Set `RTOS=BareMetal`, `TASKS=1` (for main loop). MIN_STACK check will skip automatically if no `FreeRTOSConfig.h` exists.
可以。`RTOS=BareMetal`, `TASKS=1`（主循环）。没有 `FreeRTOSConfig.h` 则 MIN_STACK 自动跳过。

**Q: What about Zephyr / NuttX / RT-Thread? / 其他 RTOS 呢？**
A: The current chip presets cover FreeRTOS. Other RTOS require manual DOC-STATE setup. PRs welcome to add preset tables.
目前预设表覆盖 FreeRTOS。其他 RTOS 需手动配置 DOC-STATE。欢迎 PR 贡献预设表。

**Q: Does the script modify my files? / 脚本会修改我的文件吗？**
A: No. Read-only. Only `exit 0` or `exit 1`.
不。只读。只返回 `exit 0` 或 `exit 1`。

**Q: Can I run this on Windows without WSL? / 不用WSL能在Windows跑吗？**
A: Yes — Git Bash or MSYS2. Both ship `bash`, `grep`, `sed`, `find`, `awk`.
可以 — Git Bash 或 MSYS2 自带全部依赖。

---

## Real-world Example / 实际案例

### ov-watch — STM32F407ZGT6 Smartwatch

[ov-watch](https://github.com/wumu-dot/ov-watch) is a STM32F407ZGT6 smartwatch with FreeRTOS CMSIS-RTOS v2, LVGL v9.x, SHT30 temp sensor, and ESP32 weather bridge.

[ov-watch](https://github.com/wumu-dot/ov-watch) 是基于 STM32F407ZGT6 + FreeRTOS + LVGL v9.x 的开源智能手表。

**EmbedSpec integration / 集成效果:**

```
Before / 之前: 79-line flat CLAUDE.md, all info loaded every session
After / 之后:  25-line layered CLAUDE.md + docs/INDEX.md, 400 Token load

DOC-STATE: CHIP=STM32F407ZGT6, RTOS=FreeRTOS/CMSIS-RTOS_v2,
           BUILD=Makefile+arm-none-eabi-gcc, TASKS=4,
           HSE=8000000, MIN_STACK=128

CI: 5/5 fields passing on every push
CI: 每次 push 5/5 字段全绿
```

See the full CLAUDE.md and CI config in the [ov-watch repo](https://github.com/wumu-dot/ov-watch).

---

## Roadmap / 路线图

- [ ] More chip presets: nRF52, MSP430, RP2040, GD32
- [ ] CMSIS-RTOS v2 API detection (beyond `osThreadNew` count)
- [ ] `--fix` flag: auto-update DOC-STATE from source values
- [ ] Pre-commit hook setup script
- [ ] JSON output mode for CI dashboards
- [ ] I2C/SPI/UART peripheral count extraction

---

## Contributing / 贡献

PRs welcome for:
- New chip preset tables
- New extraction fields (peripheral count, toolchain version, etc.)
- Bug fixes in extraction logic
- Documentation improvements / 文档改进

Keep PRs focused on one change. Please test against both STM32 and ESP32 projects before submitting.

---

## License

MIT
