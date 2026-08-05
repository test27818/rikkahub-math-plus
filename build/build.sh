#!/bin/bash
# ==============================================================
# RikkaHub ARM64 构建脚本（2026-08-05 重写）
# 用法:
#   ./build.sh                        # debug, 仅 arm64-v8a
#   ./build.sh release                # release, 仅 arm64-v8a
#   TARGET_ABIS=arm64-v8a,x86_64 ./build.sh  # 两个 ABI + universal
#   产物: output/ 目录 + 本次构建日志
#
# 变更记录:
#   2026-08-05 重写:
#   - 源码目录自动定位到 ../src-pdflatex（不再使用废弃的 /root/rikkahub）
#   - 删除 git checkout（src-pdflatex 的 master 分支即工作分支）
#   - 删除 web 占位步骤（web-ui 已由 preBuild→buildWebUi 真实构建）
#   - 改用源码自带 gradlew（替代 GRADLE_HOME 硬编码）
#   - 增量构建默认 ~1-2min；需全量时在 gradle 参数加 --no-build-cache
# ==============================================================
set -euo pipefail

BUILD_TYPE="${1:-debug}"
TARGET_ABIS="${TARGET_ABIS:-arm64-v8a}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/../src-pdflatex" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
PREBUILT_DIR="$SCRIPT_DIR/prebuilt"
SDK_DIR="/opt/android-sdk"
LOG_FILE="$SCRIPT_DIR/build_$(date +%Y%m%d_%H%M%S).log"

export ANDROID_SDK_ROOT="$SDK_DIR"
export ANDROID_HOME="$SDK_DIR"

echo "=== RikkaHub 构建 ==="
echo "类型:      $BUILD_TYPE"
echo "目标 ABI:  $TARGET_ABIS"
echo "源码:      $SOURCE_DIR"
echo "产物:      $OUTPUT_DIR"
echo "日志:      $LOG_FILE"
echo ""

# ---- 校验源码存在 ----
[ -d "$SOURCE_DIR" ] || { echo "错误: 源码目录不存在 $SOURCE_DIR"; exit 1; }
[ -f "$SOURCE_DIR/gradlew" ] || { echo "错误: $SOURCE_DIR/gradlew 不存在"; exit 1; }

# ---- 部署预编译 .so（幂等；官方 libtermux 266KB + libc++_shared 兜底）----
JNILIBS="$SOURCE_DIR/workspace/src/main/jniLibs"
mkdir -p "$JNILIBS/arm64-v8a"
cp -f "$PREBUILT_DIR/arm64-v8a/"*.so "$JNILIBS/arm64-v8a/"

# ---- Gradle 构建（tee 日志；前台运行，后台 nohup 会被沙箱清理）----
cd "$SOURCE_DIR"
TASK=":app:assemble${BUILD_TYPE^}"
echo "=== Gradle 构建中 ($TASK) ... ==="
./gradlew "$TASK" -PtargetAbis="$TARGET_ABIS" --console=plain 2>&1 | tee "$LOG_FILE" | tail -30

# ---- 收集产物 ----
echo ""
echo "=== 收集 APK ==="
rm -f "$OUTPUT_DIR"/*.apk
find app/build/outputs/apk -name "*.apk" -exec cp {} "$OUTPUT_DIR/" \;
ls -lh "$OUTPUT_DIR/"*.apk

echo ""
echo "=== 构建完成 ==="
