#!/usr/bin/env bash
# Lean 运行封装 —— 唯一推荐的运行方式（AI4Math skill）
# 用法: bash leanrun.sh <file.lean> [timeout秒=400]
# 特性: ① 自动进入 mathlib 包目录（LEAN_PATH 正确）② 输出文件法（真实退出码）③ 错误计数
# 依赖: 环境变量 MATHLIB_DIR 指向 mathlib 包目录（含 .lake/build 的 olean）；
#        未设置时自动探测常见位置（<工程>/.lake/packages/mathlib）
set -u
export PATH="$HOME/.elan/bin:$PATH"

FILE="$(realpath "$1")"
TIMEOUT="${2:-400}"

# 探测 mathlib 目录
MB="${MATHLIB_DIR:-}"
if [ -z "$MB" ]; then
  for cand in \
    "$(dirname "$FILE")/.lake/packages/mathlib" \
    "$(pwd)/.lake/packages/mathlib" \
    "$(pwd)/mtest/.lake/packages/mathlib" \
    "$HOME/lean-project/.lake/packages/mathlib"; do
    if [ -d "$cand" ]; then MB="$cand"; break; fi
  done
fi
if [ -z "$MB" ] || [ ! -d "$MB" ]; then
  echo "错误: 找不到 mathlib 包目录。请设置 MATHLIB_DIR 或在工程内运行。"
  exit 2
fi

cd "$MB"
OUT="$(mktemp /tmp/leanrun.XXXXXX)"
timeout "$TIMEOUT" lake env lean "$FILE" > "$OUT" 2>&1
EC=$?
ERRS=$(grep -c "error" "$OUT" || true)
if [ $EC -eq 0 ] && [ "$ERRS" = "0" ]; then
  echo "── leanrun ── REAL_EXIT=0 errors=0 ✅PASS"
else
  echo "── leanrun ── REAL_EXIT=$EC errors=$ERRS ❌FAIL"
fi
tail -12 "$OUT"
rm -f "$OUT"
exit $EC
