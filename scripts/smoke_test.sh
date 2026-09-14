#!/bin/bash
# 回归护栏 smoke_test.sh：对 gate 脚本做可复现的行为断言。
# 只读项目代码，夹具全部建在 mktemp 临时沙箱内，跑完自动清理，绝不污染任何真实仓库。
# 用法: bash scripts/smoke_test.sh
# 依赖: bash + 标准 Unix 工具 + git（与 scripts 下其它 gate 一致）
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m  %s\n' "$1"; }

# doc-drift 夹具：src 只放 stm32f4xx_hal_conf.h(HSE=8000000)，doc 带 DOC-STATE
mk_doc_src(){ mkdir -p "$1"; printf '#define HSE_VALUE 8000000\n' > "$1/stm32f4xx_hal_conf.h"; }
mk_doc(){ printf '# top marker\n<!-- DOC-STATE: CHIP=STM32, RTOS=None, BUILD=UNKNOWN, TASKS=0, HSE=%s, MIN_STACK=NOT_FOUND -->\n# bottom marker\n' "$1"; }

# git 夹具：一个 base.c 的空提交仓库
mk_repo(){ mkdir -p "$1"; ( cd "$1" && git init -q && git config user.email t@t && git config user.name t && printf 'int main(void){return 0;}\n' > base.c && git add base.c && git commit -qm init ); }
add_c(){ ( cd "$1" && printf '%s' "$2" > "$3" && git add "$3" ); }

echo "===== doc-drift ====="

# T01 一致(无漂移) → exit 0
S="$SANDBOX/t01"; mk_doc_src "$S/src"; mk_doc 8000000 > "$S/doc.md"
if bash "$SCRIPTS/check-doc-drift.sh" "$S/src" "$S/doc.md" >/dev/null 2>&1; then ok "T01 doc-drift 一致→exit 0"; else no "T01 doc-drift 一致应 exit 0"; fi

# T02 漂移 + --fix → exit 0，DOC-STATE 被改写且首/尾标记保留
S="$SANDBOX/t02"; mk_doc_src "$S/src"; mk_doc 80000000 > "$S/doc.md"   # HSE 漂移
if bash "$SCRIPTS/check-doc-drift.sh" --fix "$S/src" "$S/doc.md" >/dev/null 2>&1 &&
   grep -q 'HSE=8000000' "$S/doc.md" && grep -q '^# top marker' "$S/doc.md" && grep -q '^# bottom marker' "$S/doc.md"; then
  ok "T02 doc-drift --fix 改写并保首尾"; else no "T02 doc-drift --fix 失败"; fi

# T03 漂移但不 --fix → exit 1
S="$SANDBOX/t03"; mk_doc_src "$S/src"; mk_doc 80000000 > "$S/doc.md"
if bash "$SCRIPTS/check-doc-drift.sh" "$S/src" "$S/doc.md" >/dev/null 2>&1; then no "T03 漂移(无--fix)应 exit 1"; else ok "T03 doc-drift 漂移→exit 1"; fi

echo "===== three-source ====="

# T04 相对HEAD空diff → exit 0 且输出"跳过三源验证"(不再假绿为通过)
R="$SANDBOX/t04"; mk_repo "$R"
out=$( cd "$R" && bash "$SCRIPTS/check_three_source.sh" 2>&1 ); rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '跳过三源验证'; then ok "T04 three-source 空态显式跳过"; else no "T04 three-source 空态 rc=$rc"; fi

# T05 新增 esp_ 外部API 无三源标记 → exit 1
R="$SANDBOX/t05"; mk_repo "$R"; add_c "$R" 'void f(void){ esp_wifi_start(); }\n' newcall.c
if ( cd "$R" && bash "$SCRIPTS/check_three_source.sh" >/dev/null 2>&1 ); then no "T05 esp_无标记应拦截"; else ok "T05 three-source esp_无标记→exit 1"; fi

# T06 外部API 带三源标记 → exit 0
R="$SANDBOX/t06"; mk_repo "$R"; add_c "$R" '// R27 三源: ①源码 ②issue ③坑清单\nvoid h(void){ mqtt_publish(); }\n' mark.c
if ( cd "$R" && bash "$SCRIPTS/check_three_source.sh" >/dev/null 2>&1 ); then ok "T06 three-source 带标记放行"; else no "T06 three-source 带标记应 exit 0"; fi

# T07 仅 HAL_ 标准库调用(已剔除) → exit 0
R="$SANDBOX/t07"; mk_repo "$R"; add_c "$R" '#include "main.h"\nvoid g(void){ HAL_GPIO_Init(0,0); }\n' halonly.c
if ( cd "$R" && bash "$SCRIPTS/check_three_source.sh" >/dev/null 2>&1 ); then ok "T07 three-source 仅HAL_不触发"; else no "T07 three-source 仅HAL_应通过"; fi

echo "===== 脚本卫生 (LF + 语法) ====="
for f in "$SCRIPTS"/*.sh; do
  cr=$(tr -cd '\r' < "$f" | wc -c)
  if [ "$cr" -gt 0 ]; then no "CRLF: $(basename "$f")"
  elif bash -n "$f" 2>/dev/null; then ok "语法+LF: $(basename "$f")"
  else no "语法错误: $(basename "$f")"; fi
done

echo ""
printf '结果: PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && [ "$PASS" -gt 0 ]
