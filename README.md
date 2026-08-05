# RikkaHub TikZ Renderer — 二改增强版

> 为 [RikkaHub](https://github.com/rikkahub/rikkahub)（Android 多模型 AI 聊天客户端）添加 **TikZ 图表自动渲染** 能力。
> 基线：上游 2.4.3 · 许可证：AGPL-3.0（跟随上游）

## ✨ 这个项目是什么

RikkaHub 原版只能渲染普通 LaTeX 公式（jlatexmath），**无法渲染 TikZ 图表**——AI 输出的交换图、流程图、函数图全都是一团乱码。

本项目在客户端内建了一条 **pdflatex 工作区渲染管线**：

```
AI 输出 $$...\begin{tikzcd}...$$
  → 自动检测 TikZ 代码（前缀通配，覆盖 tikzpicture/tikzcd/tikztiming 全家族）
  → 动态生成 preamble（自动提取用户代码里的 \usepackage / \usetikzlibrary）
  → 工作区 pdflatex 编译 → pdftocairo 转 SVG
  → 三层缓存（内存 LRU → 磁盘 → 重编译）
  → 深色模式自动适配（LaTeX 源头注入 \color{white}）
  → 内嵌矢量图显示
```

## 🎯 核心亮点

| 能力 | 说明 |
|------|------|
| **零改动公式渲染** | 普通公式仍走 jlatexmath，互不干扰 |
| **深色模式正确** | LaTeX 源头注入颜色，彻底告别黑字隐形 |
| **宏包即声明即用** | 用户代码写 `\usepackage{pgfplots}` 自动加载，无需改客户端 |
| **缺包可诊断** | 编译失败读 `.log`，红字提示"缺少宏包: xxx.sty" |
| **三层缓存** | 同图再次出现 <1ms，历史图滚动秒回 |
| **智能尺寸** | 小图原尺寸、大图限宽 320dp，不再撑满屏幕 |
| **失败可视化** | 渲染失败显示错误原因，而非静默乱码 |

## 📦 与上游的差异（二改内容）

本项目是**补丁集 + 完整文档**，不是 fork 整个代码库：

- **新增 3 文件**：`DiagramRenderer.kt`（编译管线）、`LatexCapability.kt`（环境检测）、`LatexRenderCache.kt`（LRU 缓存）
- **修改 4 文件**：`MathBlock.kt`（检测+调度+状态机）、`PreferencesStore.kt`（开关）、`SettingPreferencesUIPage.kt`（设置 UI）、`GenerationHandler.kt`（AI 提示词）
- **完整实现文档**：`docs/` 下 9 份，含双路线战略、代码审查、诊断指南、构建指南

### 合并到新版本

```bash
# 新建文件直接复制（零冲突）
cp DiagramRenderer.kt LatexCapability.kt LatexRenderCache.kt <新版本>/.../richtext/
# 修改文件按 docs/ROUTE_A.md 的 diff 说明应用
```

## 🔧 构建

```bash
# 前置：Android SDK 37 + JDK 17 + Node 18 + pnpm 8
cd web-ui && pnpm install --frozen-lockfile   # web 界面
cd .. && ./gradlew assembleRelease -PtargetAbis=arm64-v8a
```

> ARM64 交叉构建见 `docs/BUILD.md`（qemu + 预编译 .so + patch 脚本）。

## 🧭 路线规划

本项目同时探索了两条渲染路线（详见 `docs/STRATEGY.md`）：

- **路线 A（本仓库）**：pdflatex 工作区编译 —— 原生 TeX 质量，当前主线 ✅
- **路线 B（TikZJax WASM）**：客户端内置引擎，零安装 —— 作为降级方案保留

## 📚 文档导航

| 文档 | 内容 |
|------|------|
| `docs/ROUTE_A.md` | 路线 A 实现指南（可无上下文复现） |
| `docs/ROUTE_B.md` | 路线 B 架构与踩坑记录 |
| `docs/STRATEGY.md` | 双路线战略思考 |
| `docs/REVIEW.md` | 代码审查与全部 bug 记录 |
| `docs/BUILD.md` | ARM64 构建指南 |
| `docs/DIAGNOSIS.md` | 渲染问题诊断 |

## ⚠️ 说明

- 本仓库为**二改补丁集**，完整源码请 clone 上游 `rikkahub/rikkahub` 后按 `docs/ROUTE_A.md` 应用
- 不含任何密钥/私钥（`google-services.json`、签名 keystore 均已 gitignore）
- 仅用于学习与展示，遵循上游 AGPL-3.0
