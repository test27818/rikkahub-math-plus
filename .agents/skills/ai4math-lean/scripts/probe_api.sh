#!/usr/bin/env bash
# API 探测工具 —— 写 mathlib 代码前必须先跑（AI4Math skill 铁律）
# 用法: bash probe_api.sh <关键词>
# 功能: ① 找模块路径 ② 找定理定义+命名空间 ③ 提示生成最小 #check 探测文件
# 依赖: MATHLIB_DIR（同 leanrun.sh，未设置时自动探测）
set -u
MB="${MATHLIB_DIR:-}"
if [ -z "$MB" ]; then
  for cand in "$(pwd)/.lake/packages/mathlib" "$(pwd)/mtest/.lake/packages/mathlib"; do
    if [ -d "$cand" ]; then MB="$cand"; break; fi
  done
fi
KW="$1"
if [ -z "$KW" ]; then echo "用法: bash probe_api.sh <关键词>"; exit 1; fi
if [ -z "$MB" ]; then echo "错误: 找不到 mathlib 包目录（设置 MATHLIB_DIR）"; exit 2; fi

echo "═══ ① 模块路径（find）═══"
find "$MB/Mathlib" -name "*.lean" 2>/dev/null | grep -i "$KW" | head -8
echo "═══ ② 定理/定义位置 + 命名空间 ═══"
grep -rn "theorem $KW\|lemma $KW\|def $KW" "$MB/Mathlib/" 2>/dev/null | head -4
echo "═══ ③ 生成探测文件（检查后跑 leanrun.sh）═══"
cat > /tmp/probe_api.lean <<EOF
import Mathlib
#check $KW
EOF
echo "已生成 /tmp/probe_api.lean，运行: bash leanrun.sh /tmp/probe_api.lean"
echo "（若 #check 失败，先按 ①② 修正模块路径，用精准 import 重试）"
