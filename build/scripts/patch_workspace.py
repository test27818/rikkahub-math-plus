#!/usr/bin/env python3
"""禁用 workspace 模块的 CMake 原生构建，改为使用预编译的 .so"""
import sys
path = sys.argv[1] + '/workspace/build.gradle.kts'
with open(path) as f:
    content = f.read()

content = content.replace(
    '        externalNativeBuild {\n            cmake {\n                cppFlags += ""\n            }\n        }',
    '        // CMake disabled - using pre-built .so from jniLibs'
)

import re
content = re.sub(
    r'\n    externalNativeBuild \{\n        cmake \{\n            path = file\("src/main/cpp/CMakeLists.txt"\)\n            version = "3\.22\.1"\n        }\n    }',
    '\n    // CMake disabled - using pre-built .so from jniLibs',
    content
)

with open(path, 'w') as f:
    f.write(content)
print('workspace/build.gradle.kts: CMake 已禁用')
