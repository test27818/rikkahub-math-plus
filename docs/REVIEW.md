# 代码审查报告

## 一、A 系列（pdflatex）编译 bug（已全部修复）

| # | 级别 | 文件 | 描述 |
|---|:---:|------|------|
| C1 | 🔴 编译 | DiagramRenderer.kt | `listFlow().value` → `.first()` |
| C2 | 🔴 编译 | DiagramRenderer.kt | `fileSize` 缺 WorkspaceStorageArea 参数 |
| C3 | 🔴 编译 | LatexCapability.kt | 同上 |
| C4 | 🔴 编译 | LatexCapability.kt | 非 suspend 调 suspend |
| C5 | 🔴 编译 | MathBlock.kt | LaunchedEffect 花括号缺失 |
| R1 | 🔴 运行 | DiagramRenderer.kt | cwd 路径错误 |

## 二、B 系列（TikZJax）编译 bug（已修复）

| # | 级别 | 描述 |
|---|:---:|------|
| B-C1 | 🔴 | inner class 在 object 内 |
| B-C2 | 🔴 | Gradle val 声明顺序 |
| B-C3 | 🔴 | @Composable 在 LazyListScope 外 |
| B-C4 | 🔴 | 同上复发 |
| B-C5 | 🔴 | val(a,b,c) by flow 非法 |
| B-C6 | 🔴 | WebView setInitialScale 无 getter |

## 三、2.4.3 迁移发现

### GenerationHandler 回退新功能（已修复）

上游 2.4.1→2.4.3 唯一改动：移除 `limitContext`（上下文消息上限）。直接拷贝 2.4.1 文件会回退该功能。**迁移时必须逐文件验证上游差异。**

### 终端闪退根因（已修复）

libtermux.so 手动编译极简版与 Termux JNI 调用约定不匹配。修复：换官方完整版(266KB) + libc++_shared.so 兜底。

## 四、通用教训

1. sealed class when 不能混用 object 和 class
2. Compose by remember 阻断 smart-cast
3. object 内不能有 inner class
4. Gradle DSL 变量先声明后使用
5. @Composable 必须在 item{} 内
6. val(a,b,c) by flow 非法
7. 表达式体 withLock 内不能 return
8. catch(_) { throw _ } 不绑定
9. **改完必须实际编译**
10. **迁移时逐文件验证上游差异**
