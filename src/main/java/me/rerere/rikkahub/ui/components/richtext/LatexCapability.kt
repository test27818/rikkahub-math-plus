package me.rerere.rikkahub.ui.components.richtext

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.first
import me.rerere.rikkahub.data.repository.WorkspaceRepository
import me.rerere.workspace.WorkspaceShellStatus
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

/**
 * 检测工作区是否安装了 LaTeX 图表渲染所需的工具链。
 * 首次检测后缓存到 SharedPreferences，避免重复 which 调用。
 */
object LatexCapability : KoinComponent {

    private const val PREFS_NAME = "latex_capability"
    private const val KEY_CHECKED = "checked"
    private const val KEY_AVAILABLE = "available"

    private val repo: WorkspaceRepository by inject()

    /** 所需工具清单（缺一不可）。注意：不能把 "kpsewhich tikz.sty" 当单个工具名传给 which，
     *  那会被解释成检查 kpsewhich/tikz/sty 三个命令，tikz/sty 非可执行文件导致检测失真。
     *  正确做法：which 查可执行文件，kpsewhich 查宏包文件。 */
    private val REQUIRED_TOOLS = listOf(
        "pdflatex",
        "pdftocairo",
    )

    suspend fun isAvailable(context: Context): Boolean {
        val prefs: SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        if (!prefs.getBoolean(KEY_CHECKED, false)) {
            val available = checkWorkspace()
            prefs.edit()
                .putBoolean(KEY_CHECKED, true)
                .putBoolean(KEY_AVAILABLE, available)
                .apply()
            return available
        }
        return prefs.getBoolean(KEY_AVAILABLE, false)
    }

    /** 强制重新检测（用户装完 LaTeX 后调用） */
    suspend fun recheck(context: Context): Boolean {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_CHECKED, false).apply()
        return isAvailable(context)
    }

    private suspend fun checkWorkspace(): Boolean {
        return try {
            val workspace = repo.listFlow().first().firstOrNull {
                it.shellStatus == WorkspaceShellStatus.READY.name
            } ?: return false

            // which 查可执行文件
            val binariesOk = REQUIRED_TOOLS.all { tool ->
                val result = repo.executeCommand(
                    id = workspace.id,
                    command = "which " + tool,
                    cwd = "",
                    timeoutMillis = 3_000
                )
                result.stdout.isNotBlank()
            }
            // kpsewhich 查宏包文件（tikz.sty 必须存在）
            val tikzOk = repo.executeCommand(
                id = workspace.id,
                command = "kpsewhich tikz.sty",
                cwd = "",
                timeoutMillis = 3_000
            ).stdout.isNotBlank()
            binariesOk && tikzOk
        } catch (_: Exception) {
            false
        }
    }
}
