# 项目文档索引

> 单次会话只读1次。做X前先查对应的Y。

## 场景检索地图

| 你要做什么 | 先读 |
|-----------|------|
| 改引脚/外设配置 | `firmware/Core/Inc/pin_config.h` + `firmware/Core/Src/stm32f4xx_hal_msp.c` |
| 改UI界面 | `firmware/lv_conf.h` + `firmware/lv_port_disp.c` |
| 加/改FreeRTOS任务 | `firmware/Core/Src/freertos.c` + `firmware/App/tasks/tasks.h` |
| 调试HardFault死机 | `docs/tools/gdb_debug.md` |
| 编译构建报错 | `docs/tools/skills.md` → `/check` |
| 功能开发流程 | `docs/features/.template.md`（5阶段模板） |
| Bug登记 | `docs/bugs/.template.md` |
| 历史故障查询 | `docs/troubleshooting/bug_shturl` |
| 经验教训提炼 | `docs/summary/lessons_summary.md` |
| 功能开发索引进度 | `docs/features/INDEX.md` |

## 文档清单

| 文件 | 摘要 |
|------|------|
| `tools/gdb_debug.md` | CodeGraph → OpenOCD → GDB 硬件调试教程 |
| `tools/skills.md` | `/flash` `/debug` `/check` `/style` 技能速查 |
| `features/.template.md` | FEAT 5阶段开发模板（准备→设计→实现→测试→审查） |
| `features/INDEX.md` | 功能开发索引进度 |
| `bugs/.template.md` | Bug 登记模板 |
| `summary/lessons_summary.md` | 从故障记录提炼的通用规范 |
| `troubleshooting/bug_shturl` | 历史故障复现、根因与修复记录 |

## 维护规则

新增文档才补充条目。空目录、占位文件不录入。修改文档同步更新对应条目。
