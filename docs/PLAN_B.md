# B 系列：工作区文件预览（未开始）

## 目标

- PDF（PDF.js）/ LaTeX .tex / Markdown / SVG 内嵌预览

## 入口

- 工作区文件列表点击
- 聊天文件引用点击

## 方案

复用 Screen.WebView + PDF.js，FilePreviewPage 统一分发。见上游 PLAN_B 文档细节。
