# EmbedSpec

> Embedded firmware project foundation. CLAUDE.md standard, CI guardrails, FEAT workflow, debug tooling — everything a new embedded project needs before writing its first line of code.
>
> 嵌入式固件项目地基。CLAUDE.md 规范、CI 门禁、FEAT 开发流程、调试工具链——新项目开箱即用。

---

## What's inside / 地基清单

```
embedspec/
├── CLAUDE.md                     # 芯片预设模板（STM32/ESP32自动填入）
├── .claude/rules.md              # R0-R20 AI硬规则
├── .skills/
│   ├── flash.sh                  # 一键编译+烧录
│   ├── debug.sh                  # 一键OpenOCD+GDB调试
│   └── check_style.sh            # cppcheck静态检查
├── scripts/
│   ├── ci_local.sh               # 编译→故障匹配→规范检查→文档漂移
│   └── check-doc-drift.sh        # DOC-STATE vs 源码一致性校验
├── docs/
│   ├── INDEX.md                  # 场景检索地图
│   ├── features/.template.md     # FEAT 5阶段开发（准备→设计→实现→测试→审查）
│   ├── bugs/.template.md         # Bug登记模板
│   ├── summary/lessons_summary.md
│   ├── tools/gdb_debug.md        # CodeGraph→OpenOCD→GDB 调试流程
│   ├── tools/skills.md           # /flash /debug /check /style 技能表
│   └── troubleshooting/bug_shturl
└── firmware/
    ├── .gdbinit                  # GDB初始化配置
    └── openocd.cfg               # STM32F4 OpenOCD配置
```

## Core workflow / 核心流程

**一个大目标，不碰地基：**

```
FEAT目标 → 阶段1准备(Dev)→⏸️ → 阶段2设计(Dev)→⏸️ → 阶段3实现(Dev)→⏸️ → 阶段4测试(Test)→⏸️ → 阶段5审查(Review)→✅
```

- 每阶段结束停等，人确认后才推进
- 阶段1 地基触碰自检：涉及 Core/Drivers/lvgl → 暂停
- R0-R20 硬规则全链路约束
- 12 条验收标准（AC-01~AC-12），Review 逐条打勾

## Why / 为什么

嵌入式 CLAUDE.md 容易腐烂。芯片换了、晶振改了、FreeRTOS 升级了——没人记得更新文档。Agent 读着过时信息，生成的代码全是错的。

EmbedSpec 两层解法：
1. **模板**：芯片预设自动填入 + 分层加载（外层400 Token，深层按需 Read）
2. **CI 脚本**：每次提交从源码提取 CHIP/BUILD/TASKS/HSE/MIN_STACK，与 DOC-STATE 比对，漂移 → 构建失败

## Install / 安装

```bash
git clone https://github.com/wumu-dot/embedspec.git
cp -r embedspec/{CLAUDE.md,.claude,.skills,scripts,docs,firmware} your-project/
```

零依赖。需要 `bash` + 标准 Unix 工具（macOS/Linux/WSL/MSYS2 自带）。

## Quick Start / 快速开始

```bash
# 1. 编辑 CLAUDE.md 首行 DOC-STATE
# 2. 替换模板中的 {{PLACEHOLDER}}（芯片预设自动填入绝大部分）
# 3. 运行校验
bash scripts/check-doc-drift.sh firmware/ CLAUDE.md
bash scripts/ci_local.sh firmware/ CLAUDE.md
```

## Comparison / 对比 OpenWiki

| | EmbedSpec | OpenWiki |
|---|----------|----------|
| 定位 | 嵌入式项目完整地基 | 通用代码文档生成 |
| 硬件感知 | STM32/ESP32 预设 | 无 |
| 确定性 | 100%（bash脚本，零幻觉） | ~90%（LLM语义理解） |
| 开发流程 | FEAT 5阶段 + 12条验收 | 无 |
| Bug/故障体系 | 模板 + 故障库 + CI自动检索 | 无 |
| 调试工具链 | CodeGraph→OpenOCD→GDB + 一键脚本 | 无 |
| CI 集成 | 编译→规范→漂移 四道门禁 | 文档更新CI |
| API依赖 | 零 | LLM API按次付费 |
| 可移植性 | STM32/ESP32，其他手动 | 任何语言/框架 |

OpenWiki 管"怎么写文档"，EmbedSpec 管"怎么建嵌入式项目地基"。互补，不替代。

## License

MIT
