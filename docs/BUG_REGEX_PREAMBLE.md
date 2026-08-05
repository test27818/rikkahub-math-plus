# Bug：TikZ 渲染全部失败（动态 preamble 正则）

> 交接文档 · 2026-08-05 · 请新接手者先读此文档再动代码

## 现象

2.4.3 修复版 APK 实测：**所有 TikZ 图都渲染不出来**。
logcat 报错：

```
Unrecognized backslash escape sequence in pattern near index 2
\usepackage(?:\[[^]]*\])?\{([^}]+)\}
  ^
```

## 根因

`DiagramRenderer.kt` 动态 preamble 用了两个正则提取用户代码的 `\usepackage` / `\usetikzlibrary`。
Kotlin 正则底层是 **java.util.regex**，其中 **`\u` 是 Unicode 转义**（必须跟 4 位十六进制）。
正则字符串里出现 `\u` + 非十六进制（如 `\us`）→ PatternSyntaxException。

同时 `\{` `\[` 在 Java regex 里是**字面字符**（1 个反斜杠即可），写成 `\\{`（2 反斜杠）会匹配 `\{`（要求多余反斜杠）→ 永远匹配不上。

## 正确写法（已在工作区源码修复）

Kotlin 三引号字符串（raw string，原样保留字符）：

```kotlin
// ✅ 正确：\\u = 2 反斜杠（匹配字面 \），\{ = 1 反斜杠（匹配字面 {）
Regex("""\\usepackage(?:\[[^]]*\])?\{([^}]+)\}""")
Regex("""\\usetikzlibrary\{([^}]+)\}""")
```

- `\\u`（2 反斜杠 + u）→ Java 正则 `\\` 匹配字面 `\` → 匹配 `\u` ✅
- `\{`（1 反斜杠 + {）→ Java 正则 `\{` 匹配字面 `{` ✅
- `\[` `\]` `\}` 同理

对照 MathBlock.kt 的正确写法（已验证）：
```kotlin
Regex("""\\begin\{tikz\w*\}""")   // \{ 1 反斜杠 = 字面 {
```

## 修复历史（踩坑记录）

| 版本 | 写法 | 结果 |
|------|------|------|
| v1（打包进 APK） | `\usepackage`（单反斜杠） | ❌ Java `\u` Unicode 转义崩溃 |
| v2 | `\\usepackage(?:\\[[^]]*\\])?\\{...\\}`（全 2 反斜杠） | ❌ 编译过但 `\\{` 匹配 `\{` → 提取不到宏包 |
| **v3（当前工作区）** | `\\u`(2) + `\[` `\{`(1) | ✅ Python/Java 编译 + 匹配全部通过 |

## 当前状态（2026-08-05 10:38）

- **工作区源码** `src-pdflatex/.../DiagramRenderer.kt` 75/84 行 = v3 正确写法，已提交 `ab2a108`
- **Java 编译验证**：6 个正则全部编译通过
- **匹配验证**（Python re，语义与 Java 一致）：`\usepackage{pgfplots}` / `\usepackage[utf8]{inputenc}` / `\usepackage{tikz-cd}` / `\usetikzlibrary{shapes}` 全部匹配 + 捕获正确
- **APK**：`app/build/outputs/apk/debug/app-arm64-v8a-debug.apk`（10:38 重新打包，`--no-build-cache`）
- ⚠️ **dex 字节验证有矛盾**：class 文件（javap）显示 `\\u`，dex 字节 hexdump 显示 `0x5c 0x5c`（2 反斜杠）——**疑似已正确**，但需在真实设备/运行时最终确认

## 新接手者第一步

1. 确认工作区源码 DiagramRenderer.kt 75/84 行是 v3 写法（`\\u` 2 反斜杠 + `\{` 1 反斜杠）
2. 用 kotlinc 编译一个小文件确认 raw string 行为：
   ```kotlin
   fun main() {
       val s = """\\usepackage(?:\[[^]]*\])?\{([^}]+)\}"""
       println(s.count { it == '\\' })  // 应打印 6（u前2 + [前1 + ]前1 + {前1 + }前1）
       val r = java.util.regex.Pattern.compile(s)  // 不抛异常即语法正确
       println(r.matcher("\\usepackage{pgfplots}").find())  // true
   }
   ```
3. 若通过 → 用 `--no-build-cache` 重新打包（删除 build cache 防旧 dex 混入）→ 实机测试
4. 实机确认渲染成功后，上传 APK 到仓库

## 其他背景

- 仓库：`test27818/rikkahub-math-plus`（2.4.1 APK 已在根目录）
- PAT：用户提供（在对话里，未写入本文件）
- 打包耗时：全量 ~5min，增量 ~2min（勿信"半小时"——那是全量+多次失败）
- 相关文件：`MathBlock.kt`（检测正则，已是 v3 正确写法）、`DiagramRenderer.kt`（动态 preamble，v3 已修复）
