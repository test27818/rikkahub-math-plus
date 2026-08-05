# RikkaHub Math+ —— 数学增强二改版

> 为 [RikkaHub](https://github.com/rikkahub/rikkahub)（Android 多模型 AI 聊天客户端）注入两项数学能力：
>
> **① TikZ 图表自动渲染** —— 让 AI 画的数学图表（交换图/流程图/函数图）真正可读
> **② ai4math-lean 数学形式化技能** —— 让 AI 的数学证明可被 Lean 机器验证
>
> 基线：上游 2.4.3 · 许可证：AGPL-3.0（跟随上游）

---

## 一、TikZ 图表自动渲染

### 实现方法（pdflatex 工作区管线）

RikkaHub 原版只能渲染普通 LaTeX 公式（jlatexmath），无法渲染 TikZ 图表——AI 输出的交换图、流程图、函数图全是一团乱码。本项目在客户端内建一条渲染管线：

```
AI 输出 $$...\begin{tikzcd}...$$   （前缀通配：tikzpicture / tikzcd / tikztiming 全家族）
  → 自动检测 TikZ 代码
  → 动态生成 preamble（自动提取用户代码里的 \usepackage / \usetikzlibrary）
  → 工作区 pdflatex 编译 → pdftocairo 转 SVG
  → 三层缓存（内存 LRU → 磁盘 → 重编译）
  → 深色模式自动适配（LaTeX 源头注入 \color{white}）
  → 内嵌矢量图显示
```

### 效果

| 能力 | 说明 |
|------|------|
| 零改动公式渲染 | 普通公式仍走 jlatexmath，互不干扰 |
| 深色模式正确 | LaTeX 源头注入颜色，彻底告别黑字隐形 |
| 宏包即声明即用 | 用户代码写 `\usepackage{pgfplots}` 自动加载，无需改客户端 |
| 缺包可诊断 | 编译失败读 `.log`，红字提示"缺少宏包: xxx.sty" |
| 三层缓存 | 同图再次出现 <1ms，历史图滚动秒回 |
| 智能尺寸 | 小图原尺寸、大图限宽 320dp，不再撑满屏幕 |
| 失败可视化 | 渲染失败显示错误原因，而非静默乱码 |

### 与上游的差异（二改内容）

- **新增 3 文件**：`DiagramRenderer.kt`（编译管线）、`LatexCapability.kt`（环境检测）、`LatexRenderCache.kt`（LRU 缓存）
- **修改 4 文件**：`MathBlock.kt`（检测+调度+状态机）、`PreferencesStore.kt`（开关）、`SettingPreferencesUIPage.kt`（设置 UI）、`GenerationHandler.kt`（AI 提示词）

---

## 二、ai4math-lean 技能：Lean 数学形式化

让 RikkaHub 的 AI 具备「机器可验证的数学证明」能力：**配置 Lean 环境、把数学命题/论文形式化为 Lean 定理、以"编译通过 = 正确"为唯一标准**。

- **位置**：`.agents/skills/ai4math-lean/`（Agent Skills 标准格式，RikkaHub 加载即可用）
- **作用**：
  - **环境配置**：在 proot 工作区一键部署 Lean（elan + mathlib + olean 缓存；含沙箱 git EPERM 的 codeload tarball 备选方案与断点续传）
  - **形式化方法**：教会 AI 完整工作流——先例库照抄 → API 探测（`#check @名字`）→ 精准 import → 真实退出码验证 → 验证金字塔
  - **知识沉淀**：2026 版 mathlib API 速查表（10 条已踩过的坑）、可判定命题技巧（`native_decide`/Fin 有界化）、数学研究方法论（搜索+验证闭环、不退缩信念）
- **自带文件**：`leanrun.sh` / `probe_api.sh` / `setup_mathlib.sh` 三个脚本 + `Template.lean` 先例库 + `QiuTable1.lean` 成果示例（47 定理：超椭圆模曲线 Table 1 分类 + 二次互反律惯性桥接，全部机器验证）

> 一句话：**TikZ 让 AI 画的图能看，Lean 让 AI 证的题能信。**

---

## 三、构建

```bash
# 前置：Android SDK 37 + JDK 17 + Node 18 + pnpm 8
cd web-ui && pnpm install --frozen-lockfile   # web 界面
cd .. && ./gradlew assembleRelease -PtargetAbis=arm64-v8a
```

> ARM64 交叉构建见 `docs/BUILD.md`（qemu + 预编译 .so + patch 脚本）。

## 四、文档导航

| 文档 | 内容 |
|------|------|
| `docs/ROUTE_A.md` | 路线 A（pdflatex）实现指南（可无上下文复现） |
| `docs/ROUTE_B.md` | 路线 B（TikZJax WASM）架构与踩坑记录 |
| `docs/STRATEGY.md` | 双路线战略思考 |
| `docs/REVIEW.md` | 代码审查与全部 bug 记录 |
| `docs/BUILD.md` | ARM64 构建指南 |
| `docs/DIAGNOSIS.md` | 渲染问题诊断 |
| `.agents/skills/ai4math-lean/SKILL.md` | Lean 形式化技能（环境配置 + 工作流 + API 速查） |

## ⚠️ 说明

- 本仓库为**二改补丁集 + 技能包**：TikZ 部分不包含完整源码，请 clone 上游 `rikkahub/rikkahub` 后按 `docs/ROUTE_A.md` 应用；`ai4math-lean` 技能自包含可直接使用
- 不含任何密钥/私钥（`google-services.json`、签名 keystore 均已 gitignore）
- 仅用于学习与展示，遵循上游 AGPL-3.0
