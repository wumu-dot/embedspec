#!/bin/bash
# R27 预研三源门禁：检测相对 HEAD 的 .c/.h 改动是否引入项目从未用过的第三方/新 API 符号
# 用法: bash scripts/check_three_source.sh [源码目录]
# 三源: ① 读被调函数源码  ② Issue 区调研  ③ 坑清单交付物
# 设计: 基准定为 HEAD（覆盖 staged+unstaged），提交时拦截"用新 API 但无三源证据"的改动（工具强制 R27，同 SoundDog check_r27_research.sh 思路）
set -eu

SRC_DIR="${1:-firmware}"
VIOLATIONS=0

echo "🔍 R27 预研三源门禁"

# 需要在 git 仓库内才有效；非 git 目录直接跳过（兼容模板刚复制时）
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  ⚠️ 非 git 仓库，跳过三源门禁（提交时经 pre-commit 强制）"
    exit 0
fi

# 基准 = HEAD。无提交时没有基线可比，跳过（空仓库/首次提交）
if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "  ⚠️ 尚无 HEAD 提交，跳过三源门禁（首次提交无基线）"
    exit 0
fi

# 收集相对 HEAD 的非库区 .c/.h 变更（staged+unstaged；排除底层库目录：Core/Drivers/lvgl/Middlewares/components 等）
CHANGED_FILES=$(git diff HEAD --name-only --diff-filter=ACMR \
  | grep -E '\.(c|h)$' \
  | grep -vE '^(Core|Drivers|lvgl|Middlewares|components|managed_components|build|\.reference)/' \
  || true)

# 空 diff 属"未变更"，不是"验证通过"——明示跳过，不冒充通过断言，避免常态假绿
if [ -z "$CHANGED_FILES" ]; then
    echo "  ⊘ 相对 HEAD 无 .c/.h 变更，跳过三源验证（空态不作为通过依据）"
    exit 0
fi

echo "  待检变更文件: $(echo "$CHANGED_FILES" | wc -l | tr -d ' ')"

# 检查每个文件本次改动是否新增"外部 API"特征行（hal_/HAL_ 属标准外设库，已剔除，避免规范误报）的同时缺少三源标记
for f in $CHANGED_FILES; do
    # 本次实际增改的行（排除纯注释/空白）
    NEW_LINES=$(git diff HEAD --unified=0 -- "$f" | grep '^\+' | grep -v '^\+++\|^\+[[:space:]]*//\|^\+[[:space:]]*$' | grep -E 'mbc_|esp_|arm_|xTask|xSemaphore|pubsub|subscribe|publish|mqtt|wifi' || true)

    if [ -n "$NEW_LINES" ]; then
        # 同文件或同改动内须有三源证据标记（代码注释 或 FEAT 文档引用）
        if ! git diff HEAD | grep -qE "三源|R27|source@|Issue|坑清单|坑与预防"; then
            echo "  ❌ $f 引入新 API 调用但无三源证据（①源码/②issue/③坑清单）"
            echo "     请在本文件或 FEAT 文档补 R27 三源标记后再提交。"
            VIOLATIONS=1
        fi
    fi
done

if [ "$VIOLATIONS" -eq 0 ]; then
    echo "  ✅ 三源门禁通过"
else
    echo "  📛 三源门禁失败（逃生口: git commit --no-verify 并登记理由）"
    exit 1
fi
