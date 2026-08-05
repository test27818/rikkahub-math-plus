#!/bin/bash
# ⚠️ 已过时（2026-08-05）：libtermux/libworkspace 勿手动编译（见 docs/BUILD.md §5），用 build/prebuilt 官方版
# ==============================================================
# 用系统 clang + NDK sysroot 编译 workspace 原生库
# 产物输出到 ../prebuilt/ 目录
# ==============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREBUILT_DIR="$SCRIPT_DIR/../prebuilt"
SOURCE_DIR="/root/rikkahub"
SRC="$SOURCE_DIR/workspace/src/main/cpp"

SYSROOT="/opt/android-sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
CLANG_RT="/opt/android-sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/19"
NDK_LIB="$SYSROOT/usr/lib/aarch64-linux-android/26"

TARGET="aarch64-linux-android26"
CXX_FLAGS="-target $TARGET --sysroot=$SYSROOT -resource-dir $CLANG_RT -rtlib=compiler-rt"
LINK_FLAGS="-shared -fPIC -L$NDK_LIB -landroid -llog -std=c++17"

echo "=== 编译原生库 (ARM64) ==="

mkdir -p "$PREBUILT_DIR/arm64-v8a"

for lib in workspace termux; do
    echo "编译 lib${lib}.so..."
    clang++ $CXX_FLAGS $LINK_FLAGS \
        -o "$PREBUILT_DIR/arm64-v8a/lib${lib}.so" \
        "$SRC/${lib}.cpp" 2>&1
done

# 为 x86_64 也放一份（通用 APK 需要）
mkdir -p "$PREBUILT_DIR/x86_64"
cp "$PREBUILT_DIR/arm64-v8a"/*.so "$PREBUILT_DIR/x86_64/" 2>/dev/null || true

echo ""
echo "=== 编译完成 ==="
ls -lh "$PREBUILT_DIR/arm64-v8a/"
file "$PREBUILT_DIR/arm64-v8a/"*.so | head -2
