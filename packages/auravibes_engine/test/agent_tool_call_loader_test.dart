import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('pending is unresolved and every result is resolved', () {
    const pending = AgentMessageToolCall(
      id: 'pending',
      name: 'tool',
      argumentsRaw: '{}',
    );
    const runningProjection = AgentMessageToolCall(
      id: 'running',
      name: 'tool',
      argumentsRaw: '{}',
    );
    const resolved = AgentMessageToolCall(
      id: 'resolved',
      name: 'tool',
      argumentsRaw: '{}',
      lifecycle: AgentToolCallLifecycle.success,
    );

    expect(pending.isPending, isTrue);
    expect(runningProjection.isPending, isTrue);
    expect(resolved.isResolved, isTrue);
  });

  test(
    'returns done shape when latest assistant message has no tool calls',
    () async {
      const usecase = AgentToolCallLoader<String>(
        provider: _FakeAgentToolCallProvider(
          messages: [
            AgentToolMessage(id: 'assistant-1', isUser: false),
          ],
        ),
      );

      final result = await usecase(conversationId: 'conversation-1');

      expect(result.messageId, 'assistant-1');
      expect(result.hasToolCalls, false);
      expect(result.toolsToRun, isEmpty);
    },
  );

  test(
    'partitions runnable, missing, and previously failed tool calls',
    () async {
      const usecase = AgentToolCallLoader<String>(
        provider: _FakeAgentToolCallProvider(
          messages: [
            AgentToolMessage(id: 'user-1', isUser: true),
            AgentToolMessage(
              id: 'assistant-1',
              isUser: false,
              toolCalls: [
                AgentMessageToolCall(
                  id: 'old-failed',
                  name: 'fail_once',
                  argumentsRaw: '{}',
                  lifecycle: AgentToolCallLifecycle.failed,
                ),
              ],
            ),
            AgentToolMessage(id: 'user-2', isUser: true),
            AgentToolMessage(
              id: 'assistant-2',
              isUser: false,
              toolCalls: [
                AgentMessageToolCall(
                  id: 'run-1',
                  name: 'known_tool',
                  argumentsRaw: '{}',
                ),
                AgentMessageToolCall(
                  id: 'missing-1',
                  name: 'missing_tool',
                  argumentsRaw: '{}',
                ),
                AgentMessageToolCall(
                  id: 'failed-1',
                  name: 'fail_once',
                  argumentsRaw: '{}',
                ),
              ],
            ),
          ],
        ),
      );

      final result = await usecase(conversationId: 'conversation-1');

      expect(result.messageId, 'assistant-2');
      expect(result.hasToolCalls, true);
      expect(result.toolsToRun.single.id, 'run-1');
      expect(result.notFoundToolCallIds, ['missing-1']);
      expect(result.previouslyFailedToolCallIds, ['failed-1']);
    },
  );
}

class _FakeAgentToolCallProvider implements AgentToolCallProvider<String> {
  const _FakeAgentToolCallProvider({required this.messages});

  final List<AgentToolMessage> messages;

  @override
  Future<List<AgentToolMessage>> loadMessages(String conversationId) async {
    return messages;
  }

  @override
  String? resolveTool(String toolName) {
    return toolName == 'known_tool' ? 'resolved' : null;
  }
}
