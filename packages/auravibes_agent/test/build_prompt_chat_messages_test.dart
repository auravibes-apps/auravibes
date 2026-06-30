import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:test/test.dart';

void main() {
  test('maps resolved tool calls to model and tool messages', () {
    const usecase = BuildPromptChatMessages();

    final result = usecase([
      const AgentPromptMessage(
        content: 'What is 2 + 2?',
        isUser: true,
      ),
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
}
