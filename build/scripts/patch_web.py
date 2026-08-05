#!/usr/bin/env python3
"""控制 web-ui 构建（可跳过或恢复）"""
import sys
path = sys.argv[1] + '/web/build.gradle.kts'
with open(path) as f:
    content = f.read()

if '--skip' in sys.argv:
    content = content.replace(
        'tasks.named("preBuild") {\n    dependsOn(buildWebUi)\n}',
        '// Web UI build skipped\n// tasks.named("preBuild") {\n//     dependsOn(buildWebUi)\n// }'
    )
    print('web/build.gradle.kts: web-ui 构建已跳过')
else:
    content = content.replace(
        '// Web UI build skipped\n// tasks.named("preBuild") {\n//     dependsOn(buildWebUi)\n// }',
        'tasks.named("preBuild") {\n    dependsOn(buildWebUi)\n}'
    )
    print('web/build.gradle.kts: web-ui 构建已恢复')

with open(path, 'w') as f:
    f.write(content)
