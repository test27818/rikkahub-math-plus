---
name: ai4math-lean
description: 在 RikkaHub 的 proot 工作区中配置 Lean 证明助手环境（elan + Lean + mathlib），并用 Lean 对数学命题做形式化验证。当用户需要配置 Lean、验证数学证明、把数学命题/论文内容形式化为 Lean 定理、或讨论 AI 数学研究时使用。包含环境配置步骤、形式化工作流、API 探测协议与验证规范。
---

# AI4Math：Lean 环境配置与数学形式化

> 来源：AI4Math 数学研究工作区（Lean 4.33 + mathlib 9fb1099 实测，2026-08 验证）。
> 核心理念：**LLM 负责想，Lean 负责判**——"编译通过 = 正确"是唯一标准；报错是搜索过程的正常反馈，不是失败。

## 何时使用

- 用户要求配置 Lean 环境 / 安装 mathlib / 搭建证明工程
- 用户给出一道数学题/一条定理，要求机器验证或形式化
- 用户有一篇数学论文/LaTeX 内容，想翻译成 Lean 可编译的定理
- 用户在讨论 AI 数学研究（搜索+验证闭环、反例搜索等）

## 1. 配置 Lean 环境（proot 工作区，约 20-40 分钟）

> 手机端 RikkaHub 工作区是 proot 沙箱：有 600 秒单命令上限、git 对象读取可能 EPERM。下面配方已针对此优化。

### 1.1 安装 elan（Lean 版本管理器）

```bash
curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
export PATH="$HOME/.elan/bin:$PATH"
elan --version        # 验证
```

### 1.2 创建工程 + 声明 toolchain

```bash
mkdir lean-project && cd lean-project
echo "leanprover/lean4:v4.33.0-rc2" > lean-toolchain   # 项目自动切换该版本
```

### 1.3 拉取 mathlib（数学库，含数论/代数/分析已验证定理）

**首选（git 方式，网络好时）**：
```bash
# 在工程根目录写 lakefile.lean：
#   import Lake; open Lake DSL
#   package lean_project
#   require mathlib from git "https://github.com/leanprover-community/mathlib4.git"
lake update mathlib
lake exe cache get    # ★关键：拉预编译 olean 缓存，避免本地编译数小时
```

**备选（沙箱 git EPERM 时，codeload tarball 法）**：
```bash
# 1) 下载 mathlib 源码 tarball（断点续传；120MB）
curl -fL -C - -o /tmp/mathlib4.tar.gz \
  https://codeload.github.com/leanprover-community/mathlib4/tar.gz/<commit-sha>
# 2) 解压到 .lake/packages/mathlib，git init 伪造本地 HEAD 供 lake 校验
# 3) 改 lake-manifest.json 的 rev 为本地 HEAD
# 4) 在 mathlib 包目录内执行（cache 工具以 CWD 为准，超时重跑可续传）：
cd .lake/packages/mathlib && lake exe cache get
```

### 1.4 健康检查（必须通过才算配置完成）

```bash
cat > Smoke.lean <<'EOF'
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
example : 2 ^ 10 = 1024 := by norm_num
example (n : Nat) : n * (n + 1) % 2 = 0 := by omega
EOF
# 在 mathlib 包目录内运行（LEAN_PATH 才正确）：
cd .lake/packages/mathlib && lake env lean /path/to/Smoke.lean
```

**运行铁律**：永远在 `mathlib/.lake/packages/mathlib` 目录内用 `lake env lean <文件>` 运行；**禁止**在工程根直接 `lean`（会用错 toolchain / 找不到 mathlib）。

## 2. Lean 形式化工作流（写证明的方法）

### 2.1 五步流程（铁律顺序）

```
① 先例库 → ② 探测 API → ③ 写证明 → ④ 验证 → ⑤ 记录
```

1. **先例库照抄**：维护一个 `Template.lean`（已验证写法库：import 清单、∑∈ 语法、grind/lia、ring+norm_num 套路）。写任何新证明先打开它照抄，不要凭记忆重写。
2. **探测 API（禁止凭记忆）**：2026 版 mathlib API 大改过。写代码前：
   ```bash
   # ① 定理完整签名（★最重要，30 秒省多次编译）
   #check @定理名
   #check 定理名
   #check @legendreSym.eq_neg_one_iff   -- 例：看清参数是显式还是隐式
   #check ZMod.exists_sq_eq_neg_one_iff -- 例：注意命名空间前缀
   #check Nat.dvd_prime                 -- 例：Nat 专用 vs 泛代数版本
   #check Nat.Prime.dvd_mul
   #check even_iff_two_dvd

   # ② 模块路径 / 命名空间（mathlib 源码就是权威教材）
   cd mtest/.lake/packages/mathlib
   find Mathlib -name "*.lean" | grep -i "<关键词>"
   grep -rn "theorem <名>\|lemma <名>" Mathlib/ | head -3
   sed -n '1,120p' <文件> | grep -n "namespace\|^end"
   ```
3. **写证明**：先例库写法 + 数学直觉；复杂证明拆子目标（引理），逐个击破。
4. **验证（唯一通过标准）**：`REAL_EXIT=0 且 error 计数=0`，缺一不可。用输出文件法：
   ```bash
   timeout 400 lake env lean X.lean > /tmp/out.txt 2>&1
   echo "REAL_EXIT=$?"          # 这才是 lean 的退出码
   grep -c "error" /tmp/out.txt
   # ❌ 禁止：cmd | tail; echo $?  ——  $? 是 tail 的，永远 0
   ```
5. **记录**：新踩的 API 坑追加进 STANDARDS 速查表；新定理进先例库。

### 2.2 精准 import（性能铁律）

- ❌ **禁止 `import Mathlib` 全量**：5-7 分钟加载 / 8300+ olean。
- ✅ 只 import 需要的模块：`import Mathlib.Data.Nat.Prime.Basic` 等，精准 import 30 秒-1 分钟。
- ⚠️ 目录模块必须写全：`Prime`（目录）→ `Mathlib.Data.Nat.Prime.Basic`。
- ⚠️ tactic 扩展按需 import：`Mathlib.Tactic.Ring` / `Mathlib.Tactic.NormNum` / `Mathlib.Tactic.NormNum.Prime`（素数）/ `Mathlib.Tactic.NormNum.NatFactorial`（阶乘）/ `Mathlib.Tactic.Abel`。

### 2.3 2026 版 API 速查（已踩过的坑，先查再写）

| 过时写法（训练知识） | 2026-07 正确写法 |
|---|---|
| `∑ i in s, f i` | `∑ i ∈ s, f i`（需 `open scoped BigOperators`） |
| `omega` 证整除/模 | `lia`（线性算术主流）、`grind`（自动证明器：奇偶/模/归纳） |
| `Continuous.exp` | `Complex.continuous_exp`（namespace Complex） |
| `Even.two_dvd` | `even_iff_two_dvd` + `Nat.even_mul_succ_self` |
| `Mathlib.Topology.Instances.Real` | `Mathlib.Topology.Instances.Real.Lemmas` |
| `Mathlib.Data.Nat.Prime` | `Mathlib.Data.Nat.Prime.Basic` |
| `Mathlib.Data.Nat.Factorial` | `Mathlib.Data.Nat.Factorial.Basic` |
| `prime_dvd_prime_iff_eq`（当 Nat 用） | 实为**泛环版**（代数 Prime）；Nat 用 `Nat.dvd_prime` |
| `legendreSym.eq_neg_one_iff` 命名参数 | `p` 是显式参数：`legendreSym.eq_neg_one_iff q` 或 `@名字 q _ a` |
| ZMod 中 `(-1 : ZMod 3) ≠ 1` | `by decide`（norm_num 判不了 ZMod 的 ≠） |
| `def` 作可判定谓词 | 用 `abbrev`（类型类合成才能还原） |

### 2.4 可判定命题 / 计算验证技巧

- `native_decide` 直接算：`example : 2 ^ 10 = 1024 := by native_decide`
- **Fin 有界化**：`∃ p : Nat, ...` 不可判定 → 素因子 p | N 必有 p ≤ N → `∃ p : Fin (N+1), ...` 可判定 → `by native_decide`。
- **纯数据表述**：`¬ IsSquare (-1 : ZMod p.1)`（p.1 是变量）Decidable 合成失败（ZMod 环结构需 `NeZero p.1`）→ 改用 `¬ ∃ x : Fin p, (x.1*x.1) % p = (p-1) % p`。
- 定理应用前先 `#check @名字` 确认参数：显式/隐式、命名空间、Nat 专用还是泛代数版。

### 2.5 验证金字塔（配置/修改环境后重跑）

| 层 | 内容 | 命令 |
|---|---|---|
| L1 冒烟 | 核心 tactic + 基础定理 | `lake env lean Smoke.lean` |
| L2 深测 | 跨领域 import + 高级定理 | `lake env lean Deep.lean` |
| L3 金标准 | 全部 olean 哈希匹配 | `cd .lake/packages/mathlib && lake build Mathlib` |

## 3. 数学研究方法论（来自 AI4Math 工作区）

- **搜索 + 验证闭环**：生成候选（直觉/搜索）→ 外部裁判过滤（Lean/精确算术）→ 迭代 → 通过入库。AI 数学突破几乎从不"一次写对"。
- **不退缩信念**："难"经常是被贴出来的标签。把问题拆到最小可验证单位（一个引理/一个计算），大而模糊的挫败感 → 具体小任务。
- **被验证器打回 = 正常反馈**：读报错（缺假设/符号错/子目标顺序），修完重试。
- **先找反例再证明**：证明卡住 → 先检查命题本身是否成立（数值/启发式扫描）。
- **形式化是终局裁判**：结论能形式化（Lean 证书）= 结论可信。自动形式化（文章 → Lean 骨架）见 `ai4math/autoformal` 流水线思路。

## 4. 命令速查

```bash
# 探测
#check @定理名                              # 完整签名
find Mathlib -name "*.lean" | grep -i 关键词  # 模块路径
grep -rn "theorem 名\|lemma 名" Mathlib/     # 定理位置

# 运行（在 mathlib 包目录内）
cd <工程>/.lake/packages/mathlib && lake env lean <绝对路径>/X.lean

# 构建/缓存
lake exe cache get                            # 拉预编译 olean（增量）
cd .lake/packages/mathlib && lake build Mathlib  # L3 金标准（哈希校验）

# 一次性验证（输出文件法）
timeout 400 lake env lean X.lean > /tmp/o.txt 2>&1; echo "EXIT=$?"; grep -c error /tmp/o.txt
```

## 5. 约束（务必遵守）

1. **一次只编译一个目标**：`lake build` 多目标 = 多进程 × 2-3GB = 内存爆炸卡死。串行编译。
2. **不凭记忆写 mathlib API**：先 `#check` / grep / 先例库，再写进文件。
3. **不用管道退出码判断成败**：`cmd | tail; echo $?` 的 `$?` 是 tail 的。用输出文件法。
4. **不 import Mathlib 全量**（除非研究型全量验证且注明）。
5. **600 秒单命令上限**：大证明（>5MB Lean）编译 10-30 分钟超上限且无断点——沙箱内编译不完的，如实记录，建议用户本地跑。
6. **诚实原则**：证明不完整就说明（`sorry` 标记未完成部分），绝不藏 gap 或伪造"编译通过"。
7. 不提交任何密钥 / `google-services.json` / 签名 keystore。

## 6. 本技能自带文件

- `scripts/leanrun.sh`：Lean 运行封装（自动进 mathlib 目录 + 真实退出码 + 错误计数）
- `scripts/probe_api.sh`：API 探测工具（找模块路径/定理/命名空间）
- `scripts/setup_mathlib.sh`：mathlib 一键部署（elan + 工程 + 源码 + olean 缓存 + 冒烟测试）
- `templates/Template.lean`：**先例库**（已验证写法：import 清单、∑∈、grind/lia、ring+norm_num——写新证明先照抄）
- `examples/QiuTable1.lean`：成果示例（47 定理：超椭圆模曲线 Table 1 分类 + 二次互反律惯性桥接，`native_decide` + 形式化证明的完整示范）
