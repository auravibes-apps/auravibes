import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('maps resolved tool calls to model and tool messages', () {
    const usecase = BuildPromptChatMessages();

    final result = usecase([
      const AgentPromptMessage(content: 'What is 2 + 2?', isUser: true),
      const AgentPromptMessage(
        content: '',
        isUser: false,
        toolCalls: [
          AgentPromptToolCall(
            id: 'tool-1',
            name: 'calculator',
            arguments: {'input': '2+2'},
            isResolved: true,
            response: '4',
          ),
        ],
      ),
    ]);

    expect(result, hasLength(3));
    expect(result[0].role, AgentChatMessageRole.user);
    expect(result[1].role, AgentChatMessageRole.model);
    expect(result[1].toolCalls.single.ref, 'tool-1');
    expect(result[2].role, AgentChatMessageRole.tool);
    expect(result[2].parts.single.toolResponse?.output, '4');
  });

  test('groups resolved tool responses in one tool message', () {
    const usecase = BuildPromptChatMessages();

    final result = usecase([
      const AgentPromptMessage(
        content: '',
        isUser: false,
        toolCalls: [
          AgentPromptToolCall(
            id: 'tool-1',
            name: 'first_tool',
            arguments: {},
            isResolved: true,
            response: 'first result',
          ),
          AgentPromptToolCall(
            id: 'tool-2',
            name: 'second_tool',
            arguments: {},
            isResolved: true,
            response: 'second result',
          ),
        ],
      ),
    ]);

    expect(result, hasLength(2));
    expect(result.first.role, AgentChatMessageRole.model);
    expect(result.first.toolCalls.map((toolCall) => toolCall.ref), [
      'tool-1',
      'tool-2',
    ]);

    final resultMessage = result.last;
    expect(resultMessage.role, AgentChatMessageRole.tool);
    expect(resultMessage.parts.map((part) => part.toolResponse?.ref), [
      'tool-1',
      'tool-2',
    ]);
  });

  test('maps only compaction summaries to system messages', () {
    const usecase = BuildPromptChatMessages();

    final result = usecase([
      const AgentPromptMessage(
        content: 'skip',
        isUser: false,
        type: AgentPromptMessageType.system,
      ),
      const AgentPromptMessage(
        content: ' keep ',
        isUser: false,
        type: AgentPromptMessageType.system,
        isCompactionSummary: true,
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.role, AgentChatMessageRole.system);
    expect(result.single.text, 'keep');
  });

  test('maps assistant thinking and model metadata to model message', () {
    const usecase = BuildPromptChatMessages();

    final result = usecase([
      const AgentPromptMessage(
        content: 'Final answer',
        isUser: false,
        thinking: 'Reasoning summary',
        modelMetadata: {'_anthropic_thinking_signature': 'signature'},
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.text, 'Final answer');
    expect(result.single.parts.first.reasoning, 'Reasoning summary');
    expect(result.single.metadata, {
      '_anthropic_thinking_signature': 'signature',
    });
  });
}
