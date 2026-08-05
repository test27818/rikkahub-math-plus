#!/usr/bin/env python3
# ⚠️ 已过时（2026-08-05）：此 patch 已在 src-pdflatex 提交 92b3496 中应用完毕，勿再对 src-pdflatex 运行
"""禁用 workspace 模块的 CMake 原生构建，改为使用预编译的 .so"""
import re

import sys
path = sys.argv[1] + '/workspace/build.gradle.kts'
with open(path) as f:
    content = f.read()

# defaultConfig 内的 externalNativeBuild
content = content.replace(
    '        externalNativeBuild {\n            cmake {\n                cppFlags += ""\n            }\n        }',
    '        // CMake disabled - using pre-built .so from jniLibs'
)

# 独立的 externalNativeBuild 块
content = re.sub(
    r'\n    externalNativeBuild \{\n        cmake \{\n            path = file\("src/main/cpp/CMakeLists.txt"\)\n            version = "3\.22\.1"\n        }\n    }',
    '\n    // CMake disabled - using pre-built .so from jniLibs',
    content
)

with open(path, 'w') as f:
    f.write(content)
print('workspace/build.gradle.kts: CMake 已禁用')
