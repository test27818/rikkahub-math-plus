# 双路线战略思考

## 两条路线的本质区别

```
路线 A（pdflatex）:  真正的外部 TeX → 质量天花板最高
  依赖: 工作区 PRoot + apt 装 TeX Live
  强: 原生 TeX 渲染质量、字体完整、成熟稳定
  弱: 用户需装 30MB+、首次 ~1s

路线 B（TikZJax）:   内置 WASM TeX → 零安装但受限
  强: 零安装、理论上全宏包
  弱: v1 core dump 缺宏包、SVG 字体限制、架构复杂
```

## 终局架构：双引擎分层

```
渲染入口（MathBlock）
  ├─ 有工作区 TeX？ → 路线 A（pdflatex）→ 高质量 SVG
  ├─ 无但需要图？   → 路线 B（TikZJax）→ 降级渲染
  └─ 都不是（普通公式）→ jlatexmath（补字体后够用）
```

## 待解决

| 问题 | 方向 |
|------|------|
| jlatexmath 字体（\otimes 等） | fork 修 ch=173→200（\Omega 先例） |
| 路线 B 宏包不全 | 自编译含 pgfplots 的 core dump |
| install-tl TeX Live 不在 PATH | 绝对路径探测 |
