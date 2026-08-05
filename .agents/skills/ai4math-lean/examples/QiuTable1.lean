-- ═══════════════════════════════════════════════════════════════════
-- Qiu 论文 Section 7 Table 1 的 Lean 形式化验证
-- 论文: Congling Qiu, "Hyperelliptic Shimura curves and L-functions
--       of central vanishing order at least 3"
-- 验证: 2026-08-05 ｜ 环境: Lean 4.33.0-rc2 + mathlib 9fb1099
-- 运行: bash scripts/leanrun.sh mtest/Mtest/QiuTable1.lean
--
-- 【形式化范围（诚实声明）】
-- 已验证（机器可验证）:
--   Level 1: Table 1 的纯数论条件 —— 39 个平方自由 N 中恰有 26 个 N 满足
--       ∃ 素数 p | N, p ≡ 3 (mod 4)  （p 在 ℚ(i) 中惯性）
--       ∃ 素数 q | N, q ≡ 2 (mod 3)  （q 在 ℚ(√-3) 中惯性）
--   Level 2: 惯性条件的可计算形式（x² ≡ -1 (mod p) 无解）整体复核 + ZMod 桥接
--   Level 3: 二次互反律桥接（(-3/q) = (q/3)，q % 3 = 2 ⟺ -3 非平方模 q）
-- 未形式化（超出当前 mathlib 范围，需数代工作）:
--   * "p 惯性 ⟺ p ≡ 3 mod 4" 的完整代数数论证明（二次域素理想分解）；
--   * "X0*(N) 超椭圆 ⟺ N ∈ 39 列表"（Hasegawa 定理）；
--   * L-函数理论：Theorem 7.2 的 ord ≥ 2、定理 1.1 的 ord ≥ 3·4³ 全部解析内容
--     （Gross–Kudla/YZZ 三元积公式、高度配对、Dembélé 亏格 16 曲线计算）。
-- ═══════════════════════════════════════════════════════════════════

import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.NumberTheory.LegendreSymbol.ZModChar
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.Prime

/-! ════════════ Level 1: Table 1 的模条件分类 ════════════
    论文 §7 Lemma 7.1 的条件（可计算形式）:
     HasInertPrimeMod4 N : N 有素数因子 p 且 p ≡ 3 (mod 4)   （p 在 ℚ(i) 中惯性）
     HasInertPrimeMod3 N : N 有素数因子 q 且 q ≡ 2 (mod 3)   （q 在 ℚ(√-3) 中惯性）
    注: 素数因子 p 必满足 p ≤ N，故用 Fin (N+1) 有界化，使命题可判定。 -/

abbrev HasInertPrimeMod4 (N : Nat) : Prop :=
  ∃ p : Fin (N + 1), Nat.Prime p.1 ∧ p.1 ∣ N ∧ p.1 % 4 = 3

abbrev HasInertPrimeMod3 (N : Nat) : Prop :=
  ∃ q : Fin (N + 1), Nat.Prime q.1 ∧ q.1 ∣ N ∧ q.1 % 3 = 2

/-! 论文 (7.1): 39 个使 X0*(N) 超椭圆的平方自由 N（Hasegawa [11] 列表）。 -/

def HyperellipticNList : List Nat :=
  [67, 73, 85, 93, 103, 106, 107, 115, 122, 129, 133, 134, 146, 154, 158, 161,
   165, 166, 167, 170, 177, 186, 191, 205, 206, 209, 213, 215, 221, 230, 255,
   266, 285, 286, 287, 299, 330, 357, 390]

/-! 论文 Table 1 的 26 个 N（两个惯性条件都满足）。 -/

def Table1List : List Nat :=
  [107, 115, 134, 154, 158, 161, 165, 166, 167, 177, 186, 191, 206, 209, 213,
   215, 230, 255, 266, 285, 286, 287, 299, 330, 357, 390]

/-! 剩余 13 个 N（至少一个条件不满足，故不在 Table 1）。 -/

def NotTable1List : List Nat :=
  [67, 73, 85, 93, 103, 106, 122, 129, 133, 146, 170, 205, 221]

/-! 逐个验证: 26 个正例（两个条件都成立）。 -/

theorem table1_107 : HasInertPrimeMod4 107 ∧ HasInertPrimeMod3 107 := by native_decide
theorem table1_115 : HasInertPrimeMod4 115 ∧ HasInertPrimeMod3 115 := by native_decide
theorem table1_134 : HasInertPrimeMod4 134 ∧ HasInertPrimeMod3 134 := by native_decide
theorem table1_154 : HasInertPrimeMod4 154 ∧ HasInertPrimeMod3 154 := by native_decide
theorem table1_158 : HasInertPrimeMod4 158 ∧ HasInertPrimeMod3 158 := by native_decide
theorem table1_161 : HasInertPrimeMod4 161 ∧ HasInertPrimeMod3 161 := by native_decide
theorem table1_165 : HasInertPrimeMod4 165 ∧ HasInertPrimeMod3 165 := by native_decide
theorem table1_166 : HasInertPrimeMod4 166 ∧ HasInertPrimeMod3 166 := by native_decide
theorem table1_167 : HasInertPrimeMod4 167 ∧ HasInertPrimeMod3 167 := by native_decide
theorem table1_177 : HasInertPrimeMod4 177 ∧ HasInertPrimeMod3 177 := by native_decide
theorem table1_186 : HasInertPrimeMod4 186 ∧ HasInertPrimeMod3 186 := by native_decide
theorem table1_191 : HasInertPrimeMod4 191 ∧ HasInertPrimeMod3 191 := by native_decide
theorem table1_206 : HasInertPrimeMod4 206 ∧ HasInertPrimeMod3 206 := by native_decide
theorem table1_209 : HasInertPrimeMod4 209 ∧ HasInertPrimeMod3 209 := by native_decide
theorem table1_213 : HasInertPrimeMod4 213 ∧ HasInertPrimeMod3 213 := by native_decide
theorem table1_215 : HasInertPrimeMod4 215 ∧ HasInertPrimeMod3 215 := by native_decide
theorem table1_230 : HasInertPrimeMod4 230 ∧ HasInertPrimeMod3 230 := by native_decide
theorem table1_255 : HasInertPrimeMod4 255 ∧ HasInertPrimeMod3 255 := by native_decide
theorem table1_266 : HasInertPrimeMod4 266 ∧ HasInertPrimeMod3 266 := by native_decide
theorem table1_285 : HasInertPrimeMod4 285 ∧ HasInertPrimeMod3 285 := by native_decide
theorem table1_286 : HasInertPrimeMod4 286 ∧ HasInertPrimeMod3 286 := by native_decide
theorem table1_287 : HasInertPrimeMod4 287 ∧ HasInertPrimeMod3 287 := by native_decide
theorem table1_299 : HasInertPrimeMod4 299 ∧ HasInertPrimeMod3 299 := by native_decide
theorem table1_330 : HasInertPrimeMod4 330 ∧ HasInertPrimeMod3 330 := by native_decide
theorem table1_357 : HasInertPrimeMod4 357 ∧ HasInertPrimeMod3 357 := by native_decide
theorem table1_390 : HasInertPrimeMod4 390 ∧ HasInertPrimeMod3 390 := by native_decide

/-! 逐个验证: 13 个反例（两个条件不能同时成立）。 -/

theorem not_table1_67 : ¬ (HasInertPrimeMod4 67 ∧ HasInertPrimeMod3 67) := by native_decide
theorem not_table1_73 : ¬ (HasInertPrimeMod4 73 ∧ HasInertPrimeMod3 73) := by native_decide
theorem not_table1_85 : ¬ (HasInertPrimeMod4 85 ∧ HasInertPrimeMod3 85) := by native_decide
theorem not_table1_93 : ¬ (HasInertPrimeMod4 93 ∧ HasInertPrimeMod3 93) := by native_decide
theorem not_table1_103 : ¬ (HasInertPrimeMod4 103 ∧ HasInertPrimeMod3 103) := by native_decide
theorem not_table1_106 : ¬ (HasInertPrimeMod4 106 ∧ HasInertPrimeMod3 106) := by native_decide
theorem not_table1_122 : ¬ (HasInertPrimeMod4 122 ∧ HasInertPrimeMod3 122) := by native_decide
theorem not_table1_129 : ¬ (HasInertPrimeMod4 129 ∧ HasInertPrimeMod3 129) := by native_decide
theorem not_table1_133 : ¬ (HasInertPrimeMod4 133 ∧ HasInertPrimeMod3 133) := by native_decide
theorem not_table1_146 : ¬ (HasInertPrimeMod4 146 ∧ HasInertPrimeMod3 146) := by native_decide
theorem not_table1_170 : ¬ (HasInertPrimeMod4 170 ∧ HasInertPrimeMod3 170) := by native_decide
theorem not_table1_205 : ¬ (HasInertPrimeMod4 205 ∧ HasInertPrimeMod3 205) := by native_decide
theorem not_table1_221 : ¬ (HasInertPrimeMod4 221 ∧ HasInertPrimeMod3 221) := by native_decide

/-! 整体分类定理: Table1List 恰为 39 个超椭圆 N 中满足两个惯性条件的全体。
     (一个 native_decide 同时检查 26 正例 + 13 反例，内核整体验证。) -/

theorem table1_classification :
    (∀ N ∈ Table1List, HasInertPrimeMod4 N ∧ HasInertPrimeMod3 N) ∧
    (∀ N ∈ NotTable1List, ¬ (HasInertPrimeMod4 N ∧ HasInertPrimeMod3 N)) := by
  native_decide

/-! 附带核对: 两个列表都不重复、互不相交、且并集（排列意义下）= 39 个超椭圆 N。 -/

theorem lists_sane :
    Table1List.Nodup ∧ NotTable1List.Nodup ∧
    Table1List ∩ NotTable1List = [] ∧
    List.Perm (Table1List ++ NotTable1List) HyperellipticNList := by
  native_decide

/-! ════════════ Level 2: 惯性的可计算形式与 ZMod 桥接 ════════════
    "p 在 ℚ(i) 中惯性" 的算术核心: x² ≡ -1 (mod p) 无解。
    NoSquareNegOne p 是纯 Nat 的可计算版本（无需 ZMod 环结构，native_decide 可用）:
      ¬ ∃ x : Fin p, x² ≡ p-1 (mod p)。
    ZMod 版本（需 p 素数的类型类实例）:
      inert_in_Q_i_iff : p % 4 = 3 ↔ ¬ IsSquare (-1 : ZMod p)
      （由 mathlib 定理 ZMod.exists_sq_eq_neg_one_iff : IsSquare (-1 : ZMod p) ↔ p % 4 ≠ 3
        直接推出，对所有素数含 p=2 成立） -/

abbrev NoSquareNegOne (p : Nat) : Prop :=
  ¬ ∃ x : Fin p, (x.1 * x.1) % p = (p - 1) % p

theorem inert_in_Q_i_iff (p : ℕ) (hp : Nat.Prime p) :
    p % 4 = 3 ↔ ¬ IsSquare (-1 : ZMod p) := by
  haveI : Fact p.Prime := ⟨hp⟩
  constructor
  · intro h4 hs
    exact (ZMod.exists_sq_eq_neg_one_iff.1 hs) (by simp [h4])
  · intro hns
    by_contra h4
    exact hns (ZMod.exists_sq_eq_neg_one_iff.2 h4)

/-! 以惯性形式（x² ≡ -1 (mod p) 无解）整体复核 Table 1 的 ℚ(i) 侧条件。
     与 Level 1（模 4 条件）交叉验证。
     注意反例方向的正确陈述：NotTable1List 的 N 是"两个惯性条件不能同时成立"
     （如 67：p=67 满足 ℚ(i) 惯性，但无 q ≡ 2 (mod 3) 的因子）。 -/

theorem table1_inertia_Qi :
    ∀ N ∈ Table1List, ∃ p : Fin (N + 1),
      Nat.Prime p.1 ∧ p.1 ∣ N ∧ NoSquareNegOne p.1 := by
  native_decide

theorem not_table1_inertia :
    ∀ N ∈ NotTable1List, ¬ (∃ p : Fin (N + 1),
      Nat.Prime p.1 ∧ p.1 ∣ N ∧ NoSquareNegOne p.1 ∧
      HasInertPrimeMod3 N) := by
  native_decide

/-! ⚠️ 形式化捕获的真实数学陷阱:
   对于 ℚ(√-3) 侧，朴素的 "q 惯性 ⟺ -3 模 q 非平方" 在 q = 2 处**不成立**：
     -3 ≡ 1 ≡ 1² (mod 2)，所以 -3 模 2 是平方；但 2 在 ℚ(√-3) 中确实惯性。
   论文正确使用 "q ≡ 2 (mod 3)"（对 q = 2 也成立：2 % 3 = 2），
   因此 Table 1 中 134 = 2·67、158 = 2·79 等用 q = 2 的情形
   只能用模 3 条件、不能用平方条件刻画。下面的示例记录该现象： -/

abbrev NoSquareNegThree (p : Nat) : Prop :=
  ¬ ∃ x : Fin p, (x.1 * x.1) % p = (p * 3 - 3) % p   -- -3 mod p 的 Nat 形式

example : ¬ NoSquareNegThree 2 := by
  -- 退化情形: -3 ≡ 1 ≡ 1² (mod 2) 是平方，尽管 2 在 ℚ(√-3) 中惯性
  native_decide

example : NoSquareNegThree 5 := by
  -- 奇素数正常: 5 ≡ 2 (mod 3)，-3 模 5 非平方（5 在 ℚ(√-3) 中惯性）
  native_decide

example : ¬ NoSquareNegThree 67 := by
  -- 奇素数正常: 67 ≡ 1 (mod 3)，-3 模 67 是平方（67 分裂）
  native_decide

/-! ════════════ Level 3: ℚ(√-3) 侧的惯性桥接（二次互反律） ════════════
    目标定理（已完成，机器验证）:
      inert_in_Q_sqrt_neg_three_iff q : q % 3 = 2 ↔ ¬ IsSquare (-3 : ZMod q)
    对奇素数 q ≠ 3 成立，即 "q 在 ℚ(√-3) 中惯性 ⟺ q ≡ 2 (mod 3)" 的 Legendre 符号版本。
    证明链:
      ① leg_neg_three: (-3/q) = (q/3)  —— legendreSym.mul + at_neg_one(χ₄)
         + quadratic_reciprocity'(p=3) + χ₄ q = (-1)^(q/2) 相消
      ② leg_three_neg_one_iff: (q/3) = -1 ⟺ q % 3 = 2  —— eq_pow 在 ZMod 3 中求值
         + eq_one_or_neg_one 排除 0/1 + 区间分类
      ③ 组装: eq_neg_one_iff' 把 Legendre 符号 = -1 翻译回 IsSquare 非平方 -/

theorem leg_neg_three (q : ℕ) [Fact q.Prime] (hq2 : q ≠ 2) :
    legendreSym q (-3) = legendreSym 3 q := by
  rw [show (-3 : ℤ) = -1 * (3 : ℤ) by norm_num]
  rw [legendreSym.mul]
  rw [legendreSym.at_neg_one hq2]
  have hqodd : q % 2 = 1 := (Nat.Prime.mod_two_eq_one_iff_ne_two Fact.out).mpr hq2
  have hχ : ZMod.χ₄ q = (-1 : ℤ) ^ (q / 2) := ZMod.χ₄_eq_neg_one_pow hqodd
  rw [hχ]
  change (-1 : ℤ) ^ (q / 2) * legendreSym q ((3 : ℕ) : ℤ) = legendreSym 3 ((q : ℕ) : ℤ)
  have hqr : legendreSym q ((3 : ℕ) : ℤ) =
      (-1) ^ ((3 : ℕ) / 2 * (q / 2)) * legendreSym 3 ((q : ℕ) : ℤ) :=
    legendreSym.quadratic_reciprocity' (by norm_num : 3 ≠ 2) hq2
  rw [hqr]
  have h32 : (3 : ℕ) / 2 * (q / 2) = q / 2 := by
    rw [show (3 : ℕ) / 2 = 1 by norm_num, one_mul]
  rw [h32]
  rw [← mul_assoc]
  have hone : (-1 : ℤ) ^ (q / 2) * (-1 : ℤ) ^ (q / 2) = 1 := by
    rw [← pow_add, ← two_mul (q / 2), pow_mul, neg_one_sq, one_pow]
  rw [hone, one_mul]

theorem leg_three_neg_one_iff (q : ℕ) (hq : Nat.Prime q) (hq3 : q ≠ 3) :
    legendreSym 3 q = -1 ↔ q % 3 = 2 := by
  haveI : Fact q.Prime := ⟨hq⟩
  constructor
  · intro h
    have hlt : q % 3 < 3 := Nat.mod_lt q (by norm_num)
    interval_cases hq3m : q % 3
    · -- q % 3 = 0 → q = 3，与 hq3 矛盾
      have hdvd : 3 ∣ q := by rw [Nat.dvd_iff_mod_eq_zero, hq3m]
      have hqeq : 3 = q := by
        rcases (Nat.dvd_prime hq).mp hdvd with h1 | h3q
        · norm_num at h1
        · exact h3q
      exact (hq3 hqeq.symm).elim
    · -- q % 3 = 1 → (q/3) = 1，与 h 矛盾
      have hz : (legendreSym 3 q : ZMod 3) = (1 : ZMod 3) := by
        rw [legendreSym.eq_pow, show (3 : ℕ) / 2 = 1 by norm_num, pow_one]
        norm_cast
        exact (ZMod.natCast_eq_natCast_iff' q 1 3).mpr (by norm_num [hq3m])
      rw [h] at hz
      have hne' : ((-1 : ℤ) : ZMod 3) ≠ ((1 : ℤ) : ZMod 3) := by decide
      exfalso; exact hne' hz
    · -- q % 3 = 2
      rfl
  · intro hmod
    have hne : ((q : ℤ) : ZMod 3) ≠ 0 := by
      intro hz
      have hdvd : (3 : ℤ) ∣ (q : ℤ) := (ZMod.intCast_zmod_eq_zero_iff_dvd (q : ℤ) 3).mp hz
      have hq3dvd : 3 ∣ q := by exact_mod_cast hdvd
      have hqeq : 3 = q := by
        rcases (Nat.dvd_prime hq).mp hq3dvd with h1 | h3q
        · norm_num at h1
        · exact h3q
      exact hq3 hqeq.symm
    rcases legendreSym.eq_one_or_neg_one 3 hne with h1 | h2
    · -- (q/3) = 1：与 (q : ZMod 3) = 2 矛盾
      have hz : (legendreSym 3 q : ZMod 3) = (2 : ZMod 3) := by
        rw [legendreSym.eq_pow, show (3 : ℕ) / 2 = 1 by norm_num, pow_one]
        norm_cast
        exact (ZMod.natCast_eq_natCast_iff' q 2 3).mpr (by norm_num [hmod])
      rw [h1] at hz
      have hne' : ¬ (1 : ZMod 3) = (2 : ZMod 3) := by decide
      exfalso; exact hne' hz
    · exact h2

/-! 最终桥接: 对奇素数 q ≠ 3，"q ≡ 2 (mod 3) ⟺ q 在 ℚ(√-3) 中惯性"。
     注: 这就是论文 Lemma 7.1 条件 (2) 的 Legendre 符号版本；
         q = 2 的退化情形见上文 NoSquareNegThree 的讨论（模 3 条件仍正确）。 -/

theorem inert_in_Q_sqrt_neg_three_iff (q : ℕ) (hq : Nat.Prime q) (hq2 : q ≠ 2) (hq3 : q ≠ 3) :
    q % 3 = 2 ↔ ¬ IsSquare (-3 : ZMod q) := by
  haveI : Fact q.Prime := ⟨hq⟩
  rw [← leg_three_neg_one_iff q hq hq3]
  rw [← leg_neg_three q hq2]
  simpa using (@legendreSym.eq_neg_one_iff q _ (-3 : ℤ))

/-! 桥接定理的具体实例复核（与 native_decide 交叉验证） -/

example : ¬ IsSquare (-3 : ZMod 5) :=
  (inert_in_Q_sqrt_neg_three_iff 5 (by norm_num : Nat.Prime 5) (by norm_num : 5 ≠ 2)
    (by norm_num : 5 ≠ 3)).mp (by norm_num)

example : IsSquare (-3 : ZMod 67) := by
  by_contra h
  have h' : 67 % 3 = 2 :=
    (inert_in_Q_sqrt_neg_three_iff 67 (by norm_num : Nat.Prime 67) (by norm_num : 67 ≠ 2)
      (by norm_num : 67 ≠ 3)).symm.mp h
  norm_num at h'
