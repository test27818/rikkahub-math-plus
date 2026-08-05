# TikZ 渲染问题诊断指南

> 适用：命令行能编译但聊天界面不渲染、或渲染完全没触发的场景。

## 渲染链路回顾

```
消息中出现 $$...tikzcd...$$
  → MathBlock.isDiagramLatex() 检测到图表代码
    → LatexCapability.isAvailable() 检查环境（缓存到 SharedPreferences）
      → 环境 OK → DiagramRenderer.render() 编译
        → 聊天中显示 SVG
      → 环境缺失 → 回退显示原始 LaTeX 代码（jlatexmath）

关键：如果 isAvailable() 返回 false → 永远不触发渲染。
```

## 步骤 1：验证开关存在

打开 设置 → 显示，确认能看到 **"启用 TikZ 渲染"** 开关。如果看不到，说明 APK 不含我们的改动，需重新构建。

## 步骤 2：确认工作区 Shell 可找到 TeX

在 RikkaHub 聊天中对 AI 说：

```
执行 which pdflatex && which pdftocairo && kpsewhich tikz.sty
```

三项都返回路径 → 工具链就绪。任一项为空 → TeX 未安装或路径不对。

如果未安装，让 AI 执行：

```bash
apt update && apt install -y texlive-latex-extra lmodern poppler-utils
```

然后在设置中**关闭再开启**"启用 TikZ 渲染"开关（触发 recheck）。

## 步骤 3：手动模拟客户端编译管线

以下命令完整模拟 DiagramRenderer 的行为。在 RikkaHub 工作区执行：

```bash
# 1. 写 .tex 文件（和客户端完全相同的 preamble）
cat > /workspace/_rikka_diagram.tex << 'TEX'
\documentclass[border=8pt]{standalone}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage{tikz}
\usetikzlibrary{cd,arrows.meta}
\usepackage{amsmath,amssymb}
\usepackage[all]{xy}
\usepackage{amscd}
\tikzcdset{
  every arrow/.append style={/tikz/line width=0.35pt},
  every label/.append style={font=\footnotesize}
}
\begin{document}
\begin{tikzcd}
X \ar[r,"f"] \ar[d,"q"] & Y \ar[d,"\exists!h"] \\
X/{\sim} \ar[r,equals] & X/{\sim}
\end{tikzcd}
\end{document}
TEX

# 2. 编译
cd /workspace
pdflatex -interaction=nonstopmode _rikka_diagram.tex
ls -la _rikka_diagram.pdf || echo "PDF 未生成!"

# 3. 转换 SVG
pdftocairo -svg _rikka_diagram.pdf _rikka_diagram
ls -la _rikka_diagram.svg || echo "SVG 未生成!"

# 4. 清理
rm -f _rikka_diagram.*
```

- 4 步全部通过 → 工作区交互没问题，断点在客户端逻辑
- 某步失败 → 对应修复（缺 pdflatex、缺宏包、缺字体等）

## 步骤 4：检查 latex.fmt 格式文件

tikz-cd 内部使用 LaTeX 格式（不是 pdfLaTeX 格式）。确认：

```bash
kpsewhich latex.fmt
kpsewhich pdflatex.fmt
```

两项都应有输出。如果 `latex.fmt` 缺失：

```bash
pdftex -ini -etex -jobname=latex -progname=latex "latex.ltx"
```

## 步骤 5：强制清除能力检测缓存

> ⚠️ 旧版 APK：检测结果**永久缓存**，装完包后必须「关闭再开启」开关或清除应用数据才会重检（90% 的"装完还报错"都在这）。
> **新版 APK（≥2026-08-05 15:13，SHA256 248a464a...）：false 结果只缓存 60 秒，装完包后最多等 1 分钟自动恢复，无需任何手动操作。**

如果环境就绪但开关已开启仍不渲染，可能是 SharedPreferences 缓存了旧的 `false`（旧版 APK）：

```
设置 → 应用 → RikkaHub → 存储 → 清除数据
```

然后重新配置，重新开启"启用 TikZ 渲染"开关。

## 步骤 6：让 AI 输出测试图

在聊天中输入：

> 请用 tikz-cd 语法画一个简单的交换图：A 映射到 B，B 映射到 C，A 映射到 C

观察输出：
- 看到 **渲染好的 SVG 图** → 全链路通
- 看到**半透明原始代码** → 编译卡住了
- 看到**普通原始代码** → isAvailable() 返回 false

## 快速对照表

| 现象 | 可能原因 | 检查 |
|------|---------|------|
| 看到原始代码 | `isAvailable()` 返回 false | 步骤 2, 5 |
| 半透明原始代码（"渲染中"卡住） | 编译超时/失败 | 步骤 3 |
| jlatexmath 乱码（非图片） | `isDiagramLatex()` 没识别 | AI 未用 tikz-cd 语法 |
| 渲染出来但字体丑 | 缺 lmodern | `kpsewhich lmodern.sty` |

## 最可能的原因（按概率排序）

1. **能力检测缓存了 false，开关没触发 recheck**（90%）——旧版 APK 永久缓存；新版已改为 60s TTL 自动重检（2026-08-05 修复）
2. **latex.fmt 缺失**，tikz-cd 的 latex 格式文件不存在（5%）
3. **工作区 Shell 看不到 pdflatex**，路径不对（3%）
4. **AI 没输出 tikz-cd 语法**，P2 提示词问题（2%）

> 版本确认：`texlive-latex-extra 2023.20240207` + `lmodern 2.005` + `poppler-utils 24.02` 即 Ubuntu 24.04 正确版本（实测可完整编译 tikzcd）。若版本/位置都对仍报错，优先怀疑缓存（见步骤 5）。
