#!/usr/bin/env python3
# ⚠️ 已过时（2026-08-05）：此 patch 已在 src-pdflatex 提交 92b3496 中应用完毕，勿再对 src-pdflatex 运行
"""跳过 web-ui 的 pnpm 构建（ARM64 CI 环境无完整 node 工具链）"""
import sys
path = sys.argv[1] + '/web/build.gradle.kts'
with open(path) as f:
    content = f.read()

# 注释掉 preBuild 对 buildWebUi 的依赖
content = content.replace(
    'tasks.named("preBuild") {\n    dependsOn(buildWebUi)\n}',
    '// Web UI build skipped for ARM64 build\n// tasks.named("preBuild") {\n//     dependsOn(buildWebUi)\n// }'
)

with open(path, 'w') as f:
    f.write(content)
print('web/build.gradle.kts: web-ui 构建已跳过')
