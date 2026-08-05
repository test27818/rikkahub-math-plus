# 路线 B：TikZJax 客户端渲染（暂停）

> 源码：`src-tikzjax/`（基于上游 2.4.3）· 包名 `me.rerere.rikkahub.tikzjax`

## 定位

TikZJax WASM 引擎，零安装。当前**暂停维护**，保留为路线 A 的降级方案。

## 架构（v2 SVG+Coil）

```
MathBlock 检测 TikZ → TikZJaxView（debounce 300ms）
  → TikZJaxEngine（128LRU）→ WebView JS bridge
    → WASM 编译 → SVG 字符串 → Coil 显示（max 320dp）
```

## 踩坑记录

1. tikzjax 处理挂在 window.onload，需手动触发
2. fetch() 不支持 file://，XHR 拦截
3. v1 core dump 缺 tikz-cd/pgfplots
4. @JavascriptInterface 参数无转义
5. 并发渲染需 Mutex 串行
6. warmUp 需 Mutex 单飞；引擎就绪需 stateFlow 驱动重渲染
