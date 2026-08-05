# build/ 目录说明

| 路径 | 职责 |
|------|------|
| `prebuilt/arm64-v8a/` | 预编译原生 .so（官方 libtermux.so 266KB + libc++_shared.so 等，构建必需，勿删） |
| `output/` | APK 备份（最新：`app-arm64-v8a-debug.apk`，SHA256 1fba97e5...） |
| `scripts/` | ⚠️ 已过时的 ARM64 patch 脚本（patch_workspace/patch_web/patch_abi/compile_native）——patch 均已应用进 src-pdflatex，勿再运行 |
| `build.sh` | ✅ 构建脚本（2026-08-05 重写：自动定位 ../src-pdflatex，增量 ~1-2min） |

## 用法

```bash
cd /workspace/rikkahub/build
./build.sh                 # debug, arm64-v8a → output/app-arm64-v8a-debug.apk
./build.sh release         # release（需签名配置）
TARGET_ABIS=arm64-v8a,x86_64 ./build.sh
```

等价手写命令（不经脚本）：

```bash
cd /workspace/rikkahub/src-pdflatex
export ANDROID_SDK_ROOT=/opt/android-sdk ANDROID_HOME=/opt/android-sdk
./gradlew :app:assembleDebug -PtargetAbis=arm64-v8a --console=plain
# 产物: src-pdflatex/app/build/outputs/apk/debug/app-arm64-v8a-debug.apk
```
