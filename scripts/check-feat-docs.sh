#!/bin/bash
# FEAT 文档门禁：校验两级 FEAT 体系的模板/索引/维护地图
# 用法: bash scripts/check-feat-docs.sh
# 检查: ① 项目无关性 ② 章节编号 ③ 引用闭环 ④ 旧名残留 ⑤ 必填字段
set -eu

RED="\033[31m"; GREEN="\033[32m"; RESET="\033[0m"
FAIL=0

die() { echo -e "${RED}❌ $1${RESET}"; FAIL=1; }
ok()  { echo -e "${GREEN}✅ $1${RESET}"; }

FEAT_DIR="docs/features"
FORBIDDEN="STM32|ESP32|做饭|SoundDog|麦克风|RS485|上位机"
OLD_NAME="features/\.template\.md"

echo "======== FEAT 文档门禁 ========"

# ① 项目无关性（模板/索引/地图；examples 演示目录除外）
for f in "$FEAT_DIR/.template-parent.md" "$FEAT_DIR/.template-child.md" "$FEAT_DIR/INDEX.md" "$FEAT_DIR/维护地图.md"; do
  if [ ! -f "$f" ]; then
    die "缺少文件: $f"
    continue
  fi
  hit=$(grep -nE "$FORBIDDEN" "$f" || true)
  if [ -n "$hit" ]; then
    die "项目无关性: $f 含具体项目词"
    echo "$hit"
  else
    ok "项目无关性: $f"
  fi
done

# ② 章节编号连续性
check_sections() {
  local f="$1" exp="$2" label="$3"
  local got
  got=$(grep -oE '^## [0-9]+\.' "$f" 2>/dev/null | grep -oE '[0-9]+' | tr '\n' ' ')
  if [ "$got" = "$exp " ]; then
    ok "章节编号: $label [$got]"
  else
    die "章节编号: $label 期望 [$exp]，实际 [$got]"
  fi
}
check_sections "$FEAT_DIR/.template-parent.md" "0 1 2 3 4 5 6" "父模板"
check_sections "$FEAT_DIR/.template-child.md"  "0 1 2 3 4 5"    "子模板"

# ③ 引用闭环（维护地图应在导航/清单/模板中被引用）
for f in CLAUDE.md docs/INDEX.md README.md "$FEAT_DIR/INDEX.md" "$FEAT_DIR/.template-child.md"; do
  if grep -q "维护地图" "$f" 2>/dev/null; then
    ok "引用闭环: $f"
  else
    die "引用闭环: $f 缺少「维护地图」引用"
  fi
done

# ④ 旧名残留（.template.md 已被 .template-child.md 取代）
for f in CLAUDE.md docs/INDEX.md README.md "$FEAT_DIR/INDEX.md" "$FEAT_DIR/.template-parent.md" "$FEAT_DIR/.template-child.md"; do
  hit=$(grep -nE "$OLD_NAME" "$f" 2>/dev/null || true)
  if [ -n "$hit" ]; then
    die "旧名残留: $f"
    echo "$hit"
  else
    ok "旧名残留: $f 无"
  fi
done

# ⑤ 必填字段
grep -q "父FEAT" "$FEAT_DIR/.template-child.md"          && ok "子模板: 父FEAT字段"     || die "子模板缺「父FEAT」字段"
grep -qE "AC-12" "$FEAT_DIR/.template-child.md"          && ok "子模板: 12条AC"        || die "子模板缺 AC-12"
grep -q "维护与调试" "$FEAT_DIR/.template-child.md"       && ok "子模板: 维护与调试章节" || die "子模板缺「维护与调试」章节"
grep -q "项目表" "$FEAT_DIR/.template-parent.md"          && ok "父模板: 项目表"         || die "父模板缺「项目表」"
grep -q "完成定义" "$FEAT_DIR/.template-parent.md"        && ok "父模板: 完成定义(DoD)"  || die "父模板缺「完成定义」"
if grep -q "历史记录只更新状态字段" "$FEAT_DIR/.template-parent.md" && grep -q "历史记录只更新状态字段" "$FEAT_DIR/.template-child.md"; then
  ok "模板: 历史只追加规则"
else
  die "模板缺「历史只追加」规则"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}✅ FEAT 文档门禁全部通过。${RESET}"
else
  echo -e "${RED}📛 FEAT 文档门禁失败，请修复后重试。${RESET}"
  exit 1
fi
