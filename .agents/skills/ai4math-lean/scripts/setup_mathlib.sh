#!/usr/bin/env bash
# mathlib 一键部署（AI4Math skill —— proot 沙箱优化版）
# 用法: bash setup_mathlib.sh [工程目录]
# 流程: elan → 工程 + toolchain → mathlib 源码（git 优先，失败回退 codeload tarball）→ olean 缓存 → 冒烟测试
# 注意: 沙箱单命令 600s 上限，本脚本各步骤可单独重跑（幂等/断点续传）。
set -euo pipefail
export PATH="$HOME/.elan/bin:$PATH"
PROJ="${1:-lean-project}"

echo "═══ ① elan（Lean 版本管理器）═══"
if ! command -v elan >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
  export PATH="$HOME/.elan/bin:$PATH"
fi
elan --version

echo "═══ ② 工程 + toolchain ═══"
mkdir -p "$PROJ" && cd "$PROJ"
echo "leanprover/lean4:v4.33.0-rc2" > lean-toolchain
if [ ! -f lakefile.lean ]; then
  cat > lakefile.lean <<'EOF'
import Lake
open Lake DSL
package lean_project

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"
EOF
fi

echo "═══ ③ mathlib 源码 ═══"
if ! lake update mathlib; then
  echo "→ git 方式失败（沙箱 EPERM?），改用 codeload tarball 法："
  SHA=$(curl -s https://api.github.com/repos/leanprover-community/mathlib4/commits/master | grep -m1 '"sha"' | cut -d'"' -f4)
  mkdir -p .lake/packages
  curl -fL -C - -o /tmp/mathlib4.tar.gz "https://codeload.github.com/leanprover-community/mathlib4/tar.gz/$SHA"
  mkdir -p /tmp/mathlib4-src
  tar xzf /tmp/mathlib4.tar.gz --strip-components=1 -C /tmp/mathlib4-src
  mv /tmp/mathlib4-src .lake/packages/mathlib
  cd .lake/packages/mathlib && git init -q && git add -A && git commit -qm "mathlib @ $SHA"
  cd ../..
  python3 - "$SHA" <<'PY'
import json,sys,subprocess
sha = subprocess.check_output(["git","rev-parse","HEAD"],cwd=".lake/packages/mathlib").decode().strip()
m = json.load(open("lake-manifest.json"))
for p in m["packages"]:
    if p["name"] == "mathlib":
        p["rev"] = sha
json.dump(m, open("lake-manifest.json","w"), indent=2)
PY
fi

echo "═══ ④ olean 预编译缓存（★关键，断点续传：超时重跑即可）═══"
cd .lake/packages/mathlib && lake exe cache get || echo "cache get 中断，重跑本脚本继续"

echo "═══ ⑤ 冒烟测试 ═══"
cat > /tmp/Smoke.lean <<'EOF'
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
example : 2 ^ 10 = 1024 := by norm_num
example (n : Nat) : n * (n + 1) % 2 = 0 := by omega
EOF
timeout 400 lake env lean /tmp/Smoke.lean && echo "✅ MATHLIB-OK"

echo "═══ 完成 ═══"
echo "运行任意 Lean 文件: 进入 $PROJ/.lake/packages/mathlib 后: lake env lean <文件.lean>"
echo "或使用 skill 自带的 scripts/leanrun.sh"
