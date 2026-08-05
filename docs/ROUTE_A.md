# 路线 A：pdflatex 工作区编译

> 源码：`src-pdflatex/`（基于上游 2.4.3）· 包名 `me.rerere.rikkahub.debug`

## 核心架构

```
AI 输出 $$...\begin{tikzcd}...$$
  → MathBlock 检测（前缀通配：\begin{tikz\w*} / \begin{axis} / \xymatrix / \begin{CD}）
    → LatexCapability 检测工作区 pdflatex/pdftocairo/tikz.sty
      → DiagramRenderer 编译
        → 动态 preamble（提取用户 \usepackage / \usetikzlibrary）
        → pdflatex → pdftocairo -svg → 读回 SVG
        → 三层缓存（内存LRU 128条 → 磁盘 → 重编译）
      → Coil AsyncImage 显示（宽高比自然尺寸，上限 320dp）
```

## 改动文件

### 新增（3）
| 文件 | 作用 |
|------|------|
| `DiagramRenderer.kt` | pdflatex 编译管线 + .log 错误解析 |
| `LatexCapability.kt` | 环境检测（which 二进制 + kpsewhich 宏包） |
| `LatexRenderCache.kt` | 128 条 LRU 内存缓存 |

### 修改（4）
| 文件 | 改动 |
|------|------|
| `MathBlock.kt` | 前缀通配检测 + 三层缓存 + 状态机 UI + Failed 红字 + 剥 $$ |
| `PreferencesStore.kt` | DisplaySetting 加 `enableDiagramRendering` |
| `SettingPreferencesUIPage.kt` | 开关 UI + recheck |
| `GenerationHandler.kt` | AI 提示词注入（保留 2.4.3 的 addAll(messages)） |

## 深色模式方案

LaTeX 源头注入 `\color{white}`/`\color{black}`（buildPreamble + xcolor），缓存按亮/暗分键（d_/l_ 前缀）。彻底摆脱 SVG 字符串替换。

## 已知限制

- `\boxed{\begin{tikzcd}}` 水平模式冲突必失败（可剥外层 box）
- 完整文档（含 \documentclass）会被双重包裹（待支持）
- install-tl 安装的 TeX Live 不在硬编码 PATH（待绝对路径探测）
