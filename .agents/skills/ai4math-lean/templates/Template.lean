-- ═══════════════════════════════════════════════════════════
-- 已验证写法先例库（写新证明文件前先照抄这里，不要凭记忆）
-- 验证环境：Lean 4.33.0-rc2 + mathlib 9fb1099（2026-08-04 全过）
-- 运行：bash scripts/leanrun.sh mtest/Mtest/Template.lean
-- ═══════════════════════════════════════════════════════════

-- 【import 清单】按需取用（少一个就报错，多一个无害）
import Mathlib.Data.Nat.Prime.Basic          -- Nat.Prime, dvd_mul
import Mathlib.Data.Nat.Prime.Infinite       -- exists_infinite_primes
import Mathlib.Algebra.Group.Nat.Even        -- Even, Nat.even_*, grind 规则
import Mathlib.Algebra.Ring.Parity           -- even_iff_two_dvd
import Mathlib.Algebra.EuclideanDomain.Basic -- EuclideanDomain.gcd_eq_gcd_ab（贝祖）
import Mathlib.Data.Nat.Choose.Sum           -- sum_range_choose, sum_range_succ
import Mathlib.Tactic.Abel                   -- abel（必须显式 import！）
import Mathlib.Tactic.Ring                   -- ring, ring_nf
import Mathlib.Tactic.NormNum                -- norm_num
import Mathlib.Tactic.NormNum.Prime          -- norm_num 的素数扩展
import Mathlib.Tactic.NormNum.NatFactorial   -- norm_num 的阶乘扩展

open scoped BigOperators                     -- ∑ ∈ 记号必需

-- 【写法 1】∑ ∈ 语法（不是 ∑ in！）
example (n : Nat) : ∑ k ∈ Finset.range (n + 1), Nat.choose n k = 2 ^ n := by
  simpa using Nat.sum_range_choose n

-- 【写法 2】grind 自动证明（奇偶/模运算）
example : ¬ Even 1 := by grind
example (n : Nat) : Even n ↔ n % 2 = 0 := by grind

-- 【写法 3】lia（线性算术；omega 已边缘化，社区用 lia）
example (a b : Nat) (h : a + 1 ≤ b) : a < b := by lia

-- 【写法 4】二次整除：不要硬用 omega，用现成定理
example (n : Nat) : 2 ∣ n * (n + 1) := by
  exact even_iff_two_dvd.mp (Nat.even_mul_succ_self n)

-- 【写法 5】ring + Nat cast：先 norm_num 再 ring（直接 ring 不认识 ↑(1+n)）
example (n : Nat) : ∑ k ∈ Finset.range (n + 1), (k : ℚ)^2 = n * (n + 1) * (2 * n + 1) / 6 := by
  induction n with
  | zero => norm_num
  | succ n ih =>
      rw [Finset.sum_range_succ, ih]
      norm_num      -- 关键：展开 Nat cast
      ring

-- 【写法 6】abel（交换群，ℤ）
example (a b c : ℤ) : a + b + c = c + b + a := by abel

-- 【写法 7】namespace 前缀：mathlib 定理常在 namespace 里（探测：sed 看源文件）
-- EuclideanDomain.gcd_eq_gcd_ab / Nat.even_add / Complex.continuous_exp
#check EuclideanDomain.gcd_eq_gcd_ab
#check Nat.even_add

-- 【写法 8】norm_num 扩展按需 import（Prime/NatFactorial 是独立模块）
example : Nat.factorial 5 = 120 := by norm_num
example : Nat.Prime 3 := by norm_num
