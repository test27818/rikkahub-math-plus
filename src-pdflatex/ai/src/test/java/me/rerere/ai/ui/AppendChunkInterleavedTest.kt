package me.rerere.ai.ui

import me.rerere.ai.core.MessageRole
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 回归测试：thinking/content 交错流不得把一条思维链拆成多个 part。
 *
 * 对应 2026-08-07 修复：UIMessage.appendChunk 中 Text/Reasoning 合并由
 * "仅检查 acc.lastOrNull()" 改为 "合并到列表中最后一个同类 part (indexOfLast)"。
 * 修复前交错流会生成 reason,text,reason,text 多个 part，groupMessageParts
 * 只对连续 Reasoning/Tool 分组，导致渲染出多张思考卡片夹在正文中间
 * （现象：思维链写到一半从上面/中间继续写）。
 */
class AppendChunkInterleavedTest {

    private fun chunk(vararg parts: UIMessagePart) = MessageChunk(
        id = "test-chunk",
        model = "test-model",
        choices = listOf(
            UIMessageChoice(
                index = 0,
                delta = UIMessage(
                    role = MessageRole.ASSISTANT,
                    parts = parts.toList()
                ),
                message = null,
                finishReason = null
            )
        )
    )

    /** 模拟 DeepSeek/Qwen/OpenRouter 网关：reasoning_content 与 content 跨 chunk 交错 */
    @Test
    fun `interleaved reasoning and text deltas keep single reasoning and single text part`() {
        var messages = listOf(UIMessage(role = MessageRole.ASSISTANT, parts = emptyList()))

        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "思考A1")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "思考A2")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Text("回答B1")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "补充思考C1")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "补充思考C2")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Text("回答B2")))

        val parts = messages.single().parts
        assertEquals("交错流不应拆出 4 个 part（reason,text,reason,text）", 2, parts.size)
        val reasoning = parts[0] as UIMessagePart.Reasoning
        val text = parts[1] as UIMessagePart.Text
        assertEquals("思考A1思考A2补充思考C1补充思考C2", reasoning.reasoning)
        assertEquals("回答B1回答B2", text.text)
    }

    /** 模拟 ChatCompletionsAPI.parseMessage：同一 delta 同时携带 reasoning_content + content */
    @Test
    fun `same chunk carrying reasoning and text keeps parts merged`() {
        var messages = listOf(UIMessage(role = MessageRole.ASSISTANT, parts = emptyList()))

        messages = messages.handleMessageChunk(
            chunk(
                UIMessagePart.Reasoning(reasoning = "r1"),
                UIMessagePart.Text("t1")
            )
        )
        messages = messages.handleMessageChunk(
            chunk(
                UIMessagePart.Reasoning(reasoning = "r2"),
                UIMessagePart.Text("t2")
            )
        )

        val parts = messages.single().parts
        assertEquals(2, parts.size)
        assertEquals("r1r2", (parts[0] as UIMessagePart.Reasoning).reasoning)
        assertEquals("t1t2", (parts[1] as UIMessagePart.Text).text)
    }

    /** 常规顺序流（先思考后正文）行为不变 */
    @Test
    fun `sequential reasoning then text still merges correctly`() {
        var messages = listOf(UIMessage(role = MessageRole.ASSISTANT, parts = emptyList()))

        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "r1")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "r2")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Text("t1")))
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Text("t2")))

        val parts = messages.single().parts
        assertEquals(2, parts.size)
        assertEquals("r1r2", (parts[0] as UIMessagePart.Reasoning).reasoning)
        assertEquals("t1t2", (parts[1] as UIMessagePart.Text).text)
    }

    /** 思考→工具调用→再思考：思维链合并为单个 Reasoning part，工具 part 保持独立 */
    @Test
    fun `reasoning around tool call merges into single reasoning part`() {
        var messages = listOf(UIMessage(role = MessageRole.ASSISTANT, parts = emptyList()))

        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "think1")))
        messages = messages.handleMessageChunk(
            chunk(
                UIMessagePart.Tool(
                    toolCallId = "call1",
                    toolName = "search_web",
                    input = """{"q":"test"}"""
                )
            )
        )
        messages = messages.handleMessageChunk(chunk(UIMessagePart.Reasoning(reasoning = "think2")))

        val parts = messages.single().parts
        assertEquals(2, parts.size)
        assertTrue(parts[0] is UIMessagePart.Reasoning)
        assertEquals("think1think2", (parts[0] as UIMessagePart.Reasoning).reasoning)
        assertTrue(parts[1] is UIMessagePart.Tool)
        assertEquals("call1", (parts[1] as UIMessagePart.Tool).toolCallId)
    }
}
