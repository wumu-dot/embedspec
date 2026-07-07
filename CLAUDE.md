# 项目全局上下文（会话自动继承）
<!-- 新项目初始化时填写实际芯片/RTOS/构建参数，不确定则留空并询问 -->

## 硬件平台
主控：{{CHIP_MODEL}} | {{CLOCK_SOURCE}} | 调试接口 {{DEBUG_IF}}
外设：{{PERIPHERALS}}

## 软件环境
RTOS：{{RTOS_NAME}} {{RTOS_VERSION}} 抢占式，共 {{TASK_COUNT}} 个业务任务
驱动库：{{HAL_NAME}} {{HAL_VERSION}}
编译构建：{{BUILD_SYSTEM}} + {{TOOLCHAIN}}

## 固定全局宏（禁止随意修改）
{{CRITICAL_MACROS}}

## 场景导航（做X前先读Y）
| 你要做什么 | 先读这个 |
|-----------|---------|
| {{SCENE_1_TRIGGER}} | {{SCENE_1_FILE}} |
| {{SCENE_2_TRIGGER}} | {{SCENE_2_FILE}} |
| {{SCENE_3_TRIGGER}} | {{SCENE_3_FILE}} |
| 编译或烧录失败 | `scripts/ci_local.sh` |
| 搭建开发环境 | `docs/tools/dev-setup.md`（CodeGraph + Ponytail + OpenCLI） |

## 开发硬性边界
1. {{BOUNDARY_1}}
2. {{BOUNDARY_2}}

---
## 芯片预设（检测到对应平台时自动填入）

### STM32 系列
| 字段 | 值 |
|------|-----|
| 调试接口 | ST-Link SWD |
| RTOS | FreeRTOS {{从FreeRTOSConfig.h读取}} |
| 驱动库 | STM32 HAL |
| 编译构建 | Makefile + arm-none-eabi-gcc |
| 固定宏 | HSE_VALUE={{从board.h读取}}；configMINIMAL_STACK_SIZE=128，业务任务堆栈最低256字 |
| 硬性边界 | 禁止修改 src/core/、hal/ 底层库文件；中断优先级固定分组4 |

### ESP32 系列
| 字段 | 值 |
|------|-----|
| 调试接口 | USB-UART JTAG |
| RTOS | FreeRTOS（ESP-IDF 内置） |
| 驱动库 | ESP-IDF |
| 编译构建 | CMake + ESP-IDF + xtensa-esp32-elf-gcc |
| 固定宏 | configMINIMAL_STACK_SIZE={{从sdkconfig读取}} |
| 硬性边界 | 禁止修改 components/ 下 framework 文件；WiFi/BLE 栈任务优先级不做修改 |

### 其他芯片
上面没有则逐项询问用户填写。

### 其他芯片适配检查清单

使用非 STM32/ESP32 芯片时，逐项确认并修改：

**不受影响（直接可用）：**

| 功能 | 说明 |
|------|------|
| DOC-STATE 校验 | SRC_CHIP=UNKNOWN，子串匹配仍工作 |
| ci_local.sh 门禁 | HSE检查自动跳过，其余不变 |
| FEAT 5阶段模板 | 芯片无关 |
| Bug 模板 + 故障库 | 芯片无关 |
| R0-R20 硬规则 | 芯片无关 |
| docs/ 文档体系 | 芯片无关 |

**需手动修改（3个文件）：**

| 检查项 | 文件位置 | 当前值（STM32示例） | 改为 |
|--------|----------|-------------------|------|
| 调试器配置 | `firmware/openocd.cfg` | `source [find target/stm32f4x.cfg]` | 目标芯片配置，如 `nrf52.cfg`、`rp2040.cfg` |
| 烧录命令 | `.skills/flash.sh` | `openocd -f openocd.cfg -c "program ..."` | 确认烧录方式，可能需要 pyocd、JLink |
| GDB 调试 | `.skills/debug.sh` | `arm-none-eabi-gdb` | RISC-V用 `riscv-elf-gdb`，xtensa用 `xtensa-esp32-elf-gdb` |
| RTOS | `DOC-STATE` | `FreeRTOS/CMSIS-RTOS_v2` | 改为 `Zephyr` / `RT-Thread` / `None` |
| 构建系统 | `DOC-STATE` | `Makefile+arm-none-eabi-gcc` | 改为实际工具链 |
| 时钟源 | `DOC-STATE` | `HSE=8000000` | 填主时钟频率，无HSE填 `N/A` |

> 操作流程：按上表逐项改完 → 运行 `scripts/check-doc-drift.sh` 校验 → 通过则适配完成。
