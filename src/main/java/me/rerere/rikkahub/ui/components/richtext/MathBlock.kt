package me.rerere.rikkahub.ui.components.richtext

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.takeOrElse
import coil3.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import me.rerere.rikkahub.data.repository.WorkspaceRepository
import me.rerere.rikkahub.ui.context.LocalSettings
import org.koin.compose.koinInject
import java.io.File
import java.security.MessageDigest

private val DIAGRAM_PATTERNS = listOf(
    Regex("""\\begin\{tikz\w*\}"""),   // 前缀通配：tikzpicture/tikzcd/tikztiming...
    Regex("""\\begin\{axis\}"""),          // pgfplots
    Regex("""\\xymatrix\{"""),
    Regex("""\\begin\{CD\}"""),
)

private fun isDiagramLatex(latex: String): Boolean =
    DIAGRAM_PATTERNS.any { it.containsMatchIn(latex) }

/** 去掉 Markdown 块公式的 $$ / \[...\] 外层包裹（对齐 LatexText.processLatex 行为） */
private fun stripDollarWrappers(latex: String): String {
    val t = latex.trim()
    return when {
        t.startsWith("$$") && t.endsWith("$$") && t.length > 4 -> t.substring(2, t.length - 2).trim()
        t.startsWith("\\[") && t.endsWith("\\]") && t.length > 4 -> t.substring(2, t.length - 2).trim()
        else -> t
    }
}

private fun latexKey(latex: String): String =
    MessageDigest.getInstance("SHA-256")
        .digest(latex.toByteArray())
        .joinToString("") { "%02x".format(it) }

private sealed class DiagramRenderState {
    data object Idle : DiagramRenderState()
    data object Rendering : DiagramRenderState()
    data class Ready(val svg: String) : DiagramRenderState()
    data class Failed(val reason: String) : DiagramRenderState()
}

private val renderCache = LatexRenderCache()

@Composable
fun MathInline(
    latex: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = TextUnit.Unspecified
) {
    LatexText(
        latex = latex,
        color = LocalContentColor.current,
        fontSize = fontSize.takeOrElse { LocalTextStyle.current.fontSize },
        modifier = modifier,
    )
}

@Composable
fun MathBlock(
    latex: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = TextUnit.Unspecified
) {
    val settings = LocalSettings.current.displaySetting
    val context = LocalContext.current
    val repo: WorkspaceRepository = koinInject()
    val isDark = isSystemInDarkTheme()

    val enableRendering = settings.enableDiagramRendering
    val isDiagram = remember(latex) { isDiagramLatex(latex) }
    // 颜色在 LaTeX 源头注入（\color{white}/\color{black}），亮/暗模式各存一份缓存
    val key = remember(latex, isDark) { "${if (isDark) "d" else "l"}_${latexKey(latex)}" }

    var renderState by remember { mutableStateOf<DiagramRenderState>(DiagramRenderState.Idle) }
    val latestLatex by rememberUpdatedState(latex)

    LaunchedEffect(enableRendering, isDiagram, latex) {
        if (!enableRendering || !isDiagram) {
            renderState = DiagramRenderState.Idle
            return@LaunchedEffect
        }

        // 1. 内存缓存
        renderCache.get(key)?.let {
            renderState = DiagramRenderState.Ready(it)
            return@LaunchedEffect
        }

        // 2. 磁盘缓存（IO 线程，避免主线程磁盘读）
        val diskFile = File(context.filesDir, "latex_renders/$key.svg")
        val cached = withContext(Dispatchers.IO) {
            if (diskFile.exists()) diskFile.readText() else null
        }
        if (cached != null) {
            renderCache.put(key, cached)
            renderState = DiagramRenderState.Ready(cached)
            return@LaunchedEffect
        }

        renderState = DiagramRenderState.Rendering

        try {
            kotlinx.coroutines.delay(100)
            val current = latestLatex

            val svg = withContext(Dispatchers.IO) {
                if (!LatexCapability.isAvailable(context)) {
                    throw IllegalStateException("LaTeX 未安装")
                }
                DiagramRenderer.render(repo, stripDollarWrappers(current), isDark)
            }

            // 存磁盘
            withContext(Dispatchers.IO) {
                diskFile.parentFile?.mkdirs()
                diskFile.writeText(svg)
            }

            renderCache.put(key, svg)
            renderState = DiagramRenderState.Ready(svg)
        } catch (ce: kotlinx.coroutines.CancellationException) {
            throw ce
        } catch (e: Exception) {
            renderState = DiagramRenderState.Failed(e.message ?: "未知错误")
        }
    }

    val state = renderState
    when (state) {
        DiagramRenderState.Idle -> {
            Box(modifier = modifier.padding(8.dp)) {
                LatexText(
                    latex = latex,
                    color = LocalContentColor.current,
                    fontSize = fontSize.takeOrElse { LocalTextStyle.current.fontSize },
                    modifier = Modifier
                        .align(Alignment.Center)
                        .horizontalScroll(rememberScrollState()),
                )
            }
        }

        is DiagramRenderState.Failed -> {
            Column(modifier = modifier.padding(8.dp)) {
                LatexText(
                    latex = latex,
                    color = LocalContentColor.current.copy(alpha = 0.5f),
                    fontSize = fontSize.takeOrElse { LocalTextStyle.current.fontSize },
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                )
                Text(
                    text = state.reason,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.padding(top = 4.dp),
                )
            }
        }

        DiagramRenderState.Rendering -> {
            Box(modifier = modifier.padding(8.dp)) {
                LatexText(
                    latex = latex,
                    color = LocalContentColor.current.copy(alpha = 0.4f),
                    fontSize = fontSize.takeOrElse { LocalTextStyle.current.fontSize },
                    modifier = Modifier
                        .align(Alignment.Center)
                        .horizontalScroll(rememberScrollState()),
                )
            }
        }

        is DiagramRenderState.Ready -> {
            // SVG 颜色已在 LaTeX 源头按 isDark 注入（\color{white}/\color{black}），无需字符串替换
            DiagramImage(
                svg = state.svg,
                key = key,
                modifier = modifier
            )
        }
    }
}

@Composable
private fun DiagramImage(svg: String, key: String, modifier: Modifier) {
    val context = LocalContext.current
    var svgFile by remember { mutableStateOf<File?>(null) }

    // IO 线程写文件，组合期不做磁盘 IO
    LaunchedEffect(svg) {
        svgFile = withContext(Dispatchers.IO) {
            val dir = File(context.cacheDir, "latex_svg")
            dir.mkdirs()
            File(dir, "$key.svg").apply { writeText(svg) }
        }
    }

    val file = svgFile
    if (file != null) {
        AsyncImage(
            model = file,
            contentDescription = "交换图",
            modifier = modifier
                .widthIn(max = 320.dp)
                .wrapContentWidth()
                .wrapContentHeight()
                .padding(vertical = 4.dp),
            contentScale = ContentScale.Fit,
        )
    }
}
