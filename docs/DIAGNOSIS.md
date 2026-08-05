# 渲染问题诊断

## 链路回顾

```
$$...tikz...$$ → MathBlock 检测 → LatexCapability → DiagramRenderer → SVG → Coil
```

## 常见现象

| 现象 | 原因 | 检查 |
|------|------|------|
| 看到原始代码 | isAvailable=false | which pdflatex |
| 半透明卡住 | 编译超时/失败 | 手动 pdflatex |
| 乱码 | 未识别为 tikz | 检测正则 |
| 深色下黑字 | 颜色未注入 | 版本需含 \color 注入 |
| 红字缺包 | 宏包未装 | apt install |

## 手动验证编译管线

```bash
cat > test.tex << 'TEX'
\documentclass[border=8pt]{standalone}
\usepackage{tikz}
\usetikzlibrary{cd}
\begin{document}
\begin{tikzcd}A \ar[r] & B\end{tikzcd}
\end{document}
TEX
pdflatex -interaction=nonstopmode test.tex && pdftocairo -svg test.pdf test.svg
```
