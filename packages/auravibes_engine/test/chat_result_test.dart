import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';
import 'package:test/test.dart';

void main() {
  group('ChatMessage', () {
    test('constructors set roles and content', () {
      final user = ChatMessage.user('hello');
      expect(user.role, ChatMessageRole.user);
      expect(user.content, 'hello');

      final system = ChatMessage.system('system instruction');
      expect(system.role, ChatMessageRole.system);
      expect(system.content, 'system instruction');

      final model = ChatMessage.model('response', metadata: {'foo': 'bar'});
      expect(model.role, ChatMessageRole.model);
      expect(model.content, 'response');
      expect(model.metadata['foo'], 'bar');
    });

    test('extracts tool calls from parts', () {
      final message = ChatMessage(
        role: ChatMessageRole.model,
        parts: [
          ToolRequestPart(
            toolRequest: ToolRequest(
              ref: 'call-1',
              name: 'getWeather',
              input: const {'city': 'Boston'},
            ),
          ),
        ],
      );

      expect(message.toolCalls.single.callId, 'call-1');
      expect(message.toolCalls.single.toolName, 'getWeather');
      expect(message.toolCalls.single.argumentsRaw, '{"city":"Boston"}');
    });
  });

  group('ChatResultConcat', () {
    test('merges output, usage, metadata, and thinking deltas', () {
      final first = ChatResult<ChatMessage>(
        output: ChatMessage.model('Hello'),
        usage: const LanguageModelUsage(
          promptTokens: 10,
          responseTokens: 5,
          totalTokens: 15,
        ),
        thinking: 'First',
      );
      final second = ChatResult<ChatMessage>(
        output: ChatMessage.model(
          ' world',
          metadata: const {'signature': 'value'},
        ),
        finishReason: ChatFinishReason.stop,
        usage: const LanguageModelUsage(
          promptTokens: 2,
          responseTokens: 3,
          totalTokens: 5,
        ),
        metadata: const {'provider': 'test'},
        thinking: 'second',
      );

      final merged = first.concat(second);

      expect(merged.output.text, 'Hello world');
      expect(merged.output.metadata, {'signature': 'value'});
      expect(merged.finishReason, ChatFinishReason.stop);
      expect(merged.usage?.promptTokens, 12);
      expect(merged.usage?.responseTokens, 8);
      expect(merged.usage?.totalTokens, 20);
      expect(merged.metadata, {'provider': 'test'});
      expect(merged.thinking, 'First second');
    });
  });
}
