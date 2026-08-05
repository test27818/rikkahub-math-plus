# ARM64 构建指南

## 前置

- ARM64 Linux + Android SDK 37 + NDK 28
- qemu-user-static（SDK 工具 x86_64 模拟）

## 关键步骤

1. SDK build-tools 的 aapt2 用 qemu 包装（`aapt2FromMavenOverride`）
2. native 库用预编译 .so（官方版 libtermux 266KB + libc++_shared 兜底 + proot 库）
3. workspace/web 模块 patch（禁用 CMake / 恢复 web-ui 构建）
4. `./gradlew assembleDebug -PtargetAbis=arm64-v8a`

## web-ui

```bash
cd web-ui && pnpm install --frozen-lockfile
```

## .so 来源（重要）

**libtermux.so / libworkspace.so 不要手动编译**——极简版与 Termux JNI 调用约定不匹配导致终端闪退。从官方 APK 提取完整版。

## 常见问题

- AAPT2 Daemon 失败 → aapt2FromMavenOverride
- targetAbis 未解析 → 声明必须在 android{} 顶部
- libc++_shared 缺失 → 从 NDK 提取部署 jniLibs
