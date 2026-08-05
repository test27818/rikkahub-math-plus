#!/usr/bin/env python3
# ⚠️ 已过时（2026-08-05）：此 patch 已在 src-pdflatex 提交 92b3496 中应用完毕，勿再对 src-pdflatex 运行
"""
将 app/build.gradle.kts 的 ABI 选择改为可配置。
用法: gradle assembleDebug -PtargetAbis=arm64-v8a
      不传则默认 arm64-v8a,x86_64（上游原始行为）

⚠️ B-C2 教训：targetAbis/isBuildingBundle 声明必须在 android{} 块最顶部，
   defaultConfig 和 splits 都会引用它们。放在任何引用者之后会 Unresolved reference。
"""
import sys

path = sys.argv[1] + '/app/build.gradle.kts'
with open(path) as f:
    content = f.read()

VAR_DECL = '''    // ---- ABI 选择（可通过 -PtargetAbis=arm64-v8a,x86_64 覆盖） ----
    // 注意：必须在 android{} 块最顶部声明，defaultConfig/splits 都引用它们（B-C2）
    val targetAbis = (project.findProperty("targetAbis") as? String)
        ?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() }
        ?: listOf("arm64-v8a", "x86_64")
    val isBuildingBundle = gradle.startParameter.taskNames.any { it.lowercase().contains("bundle") }

'''

def patch(content):
    # 1. 删除任何已存在的声明块（幂等）
    import re
    content = re.sub(
        r'\n    // ---- ABI 选择[^\n]*\n(?:    val targetAbis[^\n]*\n)(?:        \?\.split[^\n]*\n)?(?:        \?\.map[^\n]*\n)?(?:        \?: listOf[^\n]*\n)?(?:    val isBuildingBundle[^\n]*\n)?',
        '\n', content
    )

    # 2. 确保 android{ 块顶部插入声明（在第一个 namespace 之前）
    if 'val targetAbis' not in content:
        # 找 android { 后的第一个属性
        m = re.search(r'android \{\n', content)
        assert m, "android {} not found"
        # 插在 android { 之后的第一个非空行前（即 namespace 前）
        insert_at = m.end()
        content = content[:insert_at] + VAR_DECL + content[insert_at:]

    # 3. defaultConfig 内引用 targetAbis/isBuildingBundle
    if 'if (isBuildingBundle) {' not in content:
        old_ndk = '''        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }'''
        new_ndk = '''        // ndk abiFilters 仅在 AppBundle 构建时生效（否则与 splits 冲突）
        if (isBuildingBundle) {
            ndk {
                abiFilters += targetAbis
            }
        }'''
        if old_ndk in content:
            content = content.replace(old_ndk, new_ndk)
        else:
            print("  WARNING: ndk 块未找到，跳过")

    # 4. splits 块
    old_splits = '''    splits {
        abi {
            // AppBundle tasks usually contain "bundle" in their name
            //noinspection WrongGradleMethod
            val isBuildingBundle = gradle.startParameter.taskNames.any { it.lowercase().contains("bundle") }
            isEnable = !isBuildingBundle
            reset()
            include("arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }'''
    new_splits = '''    splits {
        abi {
            isEnable = !isBuildingBundle
            reset()
            include(*targetAbis.toTypedArray())
            isUniversalApk = targetAbis.size > 1
        }
    }'''
    if old_splits in content:
        content = content.replace(old_splits, new_splits)
    else:
        print("  WARNING: splits 块未找到（可能已被修改），跳过")

    return content

content = patch(content)
with open(path, 'w') as f:
    f.write(content)
print('app/build.gradle.kts: ABI 已改为 -PtargetAbis 可控（声明在 android 顶部）')
