#!/bin/bash
# 嵌入式项目本地CI门禁：编译→故障匹配→规范检查→文档漂移
# 用法: bash scripts/ci_local.sh [源码目录] [CLAUDE.md]
set -eu

# P0-2: 根目录用绝对路径，后续全流程不依赖相对 cd
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SRC_DIR="${1:-firmware}"
DOC_FILE="${2:-CLAUDE.md}"

echo "🔨 编译校验"

# 自动检测构建系统（构建放进子 shell，不污染主 shell 的 cwd）
# make 前置：未安装 make/cmake 时明示警告并跳过，避免被误报成"编译失败"
if [ -f "$SRC_DIR/Makefile" ]; then
    if command -v make >/dev/null 2>&1; then
        ( cd "$SRC_DIR" && make clean && make -j6 all ) && BUILD_OK=0 || BUILD_OK=$?
    else
        echo "  ⚠️ 检测到 Makefile 但未安装 make，跳过命令行构建"
        BUILD_OK=0
    fi
elif [ -f "$SRC_DIR/CMakeLists.txt" ]; then
    if command -v cmake >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
        ( cd "$SRC_DIR" && mkdir -p build && cd build && cmake .. && make -j6 ) && BUILD_OK=0 || BUILD_OK=$?
    else
        echo "  ⚠️ 检测到 CMakeLists.txt 但未安装 cmake/make，跳过命令行构建"
        BUILD_OK=0
    fi
elif [ -f "$SRC_DIR/.project" ] || [ -f "$SRC_DIR/.cproject" ]; then
    echo "  STM32CubeIDE 项目 — 请在 IDE 中编译，跳过命令行构建"
    BUILD_OK=0
else
    echo "  ⚠️ 未检测到构建系统 (Makefile/CMakeLists.txt/.project)，跳过编译"
    BUILD_OK=0
fi

if [ ${BUILD_OK:-0} -ne 0 ]; then
    echo "❌ 编译失败，检索故障库"
    # P1-1: 从编译错误行提取"实质符号关键词"，避免拿整行头 N 字符匹配必落空。
    #        "error: undefined reference to foo_bar_sym" → KEYWORD=foo_bar_sym
    KEYWORD=$( { cd "$SRC_DIR" && { make 2>&1 || true; } | \
        grep -E "error|undefined|fault" | head -1 || echo ""; } | \
        sed -E 's/^.*(error|undefined reference|fault)[ :]+//I' | tr -d "\r" | tr -s ' ' | awk 'NF{print $NF}' )
    if [ -n "$KEYWORD" ] && grep -qiF "$KEYWORD" "$ROOT/docs/troubleshooting/bug_shturl" 2>/dev/null; then
        echo "  命中历史故障记录:"
        grep -iF "$KEYWORD" "$ROOT/docs/troubleshooting/bug_shturl" | head -3
    else
        echo "  无匹配历史故障记录 (错误关键词: ${KEYWORD:-unknown})"
    fi
    exit 1
fi
echo "✅ 编译通过"

echo "📋 规范检查"
PASS=1

# FreeRTOS 最小任务堆栈
FREERTOS_CONFIG=$(find "$SRC_DIR" -name "FreeRTOSConfig.h" 2>/dev/null | head -1)
if [ -n "$FREERTOS_CONFIG" ]; then
    STACK_MIN=$(grep "configMINIMAL_STACK_SIZE" "$FREERTOS_CONFIG" | grep -o '[0-9]\+' | tail -1)
    if [ -n "$STACK_MIN" ] && [ "$STACK_MIN" -lt 128 ]; then
        echo "❌ configMINIMAL_STACK_SIZE 最小128字，当前: $STACK_MIN"
        PASS=0
    fi
fi

# HSE 晶振范围 (仅 STM32)
HSE_FILE=$(find "$SRC_DIR" -name "stm32f4xx_hal_conf.h" 2>/dev/null | grep -v TEMPLATE | head -1)
if [ -n "$HSE_FILE" ]; then
    HSE_VAL=$(grep '#define\s*HSE_VALUE' "$HSE_FILE" | grep -v '^\s*//\|^\s*#if' | grep -o '[0-9]\+' | head -1)
    if [ -n "$HSE_VAL" ] && { [ "$HSE_VAL" -lt 4000000 ] || [ "$HSE_VAL" -gt 25000000 ]; }; then
        echo "❌ HSE_VALUE 需在 4M~25M 区间，当前: $HSE_VAL"
        PASS=0
    fi
fi

[ "$PASS" -eq 0 ] && { echo "❌ 规范检查失败"; exit 1; }
echo "✅ 规范检查通过"

echo "📋 文档漂移检查"
bash "$ROOT/scripts/check-doc-drift.sh" "$SRC_DIR" "$DOC_FILE" || { echo "❌ 请更新 CLAUDE.md DOC-STATE"; exit 1; }

echo "📋 FEAT 文档门禁"
bash "$ROOT/scripts/check-feat-docs.sh" || { echo "❌ FEAT 文档门禁失败"; exit 1; }
bash "$ROOT/scripts/check_three_source.sh" || { echo "❌ R27 三源门禁失败"; exit 1; }

echo "✅ 全量CI通过"
