// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';

void main() {
  group('ChatMessage', () {
    test('constructors work as expected', () {
      final msg = ChatMessage.user('hello');
      expect(msg.role, ChatMessageRole.user);
      expect(msg.content, 'hello');

      final sys = ChatMessage.system('system instruction');
      expect(sys.role, ChatMessageRole.system);
      expect(sys.content, 'system instruction');

      final model = ChatMessage.model('response', metadata: {'foo': 'bar'});
      expect(model.role, ChatMessageRole.model);
      expect(model.content, 'response');
      expect(model.metadata['foo'], 'bar');
    });

    test('copyWith works, including omitting parameters', () {
      final msg = ChatMessage.user('hello');
      final copied = msg.copyWith(content: 'world');
      expect(copied.role, ChatMessageRole.user);
      expect(copied.content, 'world');
      // Verify metadata is empty by default and copyWith doesn't fail
      expect(copied.metadata, isEmpty);

      // Call copyWith without metadata parameter (essential for nullable check)
      final anotherCopy = msg.copyWith(role: ChatMessageRole.model);
      expect(anotherCopy.role, ChatMessageRole.model);
      expect(anotherCopy.metadata, isEmpty);

      // Call copyWith with metadata
      final withMeta = msg.copyWith(metadata: {'key': 'value'});
      expect(withMeta.metadata['key'], 'value');
    });

    test('concatenate appends content and parts', () {
      final msg1 = ChatMessage(
        role: ChatMessageRole.model,
        content: 'hello',
        parts: [TextPart(text: 'hello')],
      );
      final msg2 = ChatMessage(
        role: ChatMessageRole.model,
        content: ' world',
        parts: [TextPart(text: ' world')],
      );

      final combined = msg1.concatenate(msg2);
      expect(combined.content, 'hello world');
      expect(combined.parts.length, 2);
    });
  });

  group('ChatResultConcat', () {
    test('concat merges two results', () {
      final res1 = ChatResult<ChatMessage>(
        output: ChatMessage.model('part1'),
        usage: const LanguageModelUsage(
          promptTokens: 10,
          responseTokens: 5,
          totalTokens: 15,
        ),
      );
      final res2 = ChatResult<ChatMessage>(
        output: ChatMessage.model('part2'),
        usage: const LanguageModelUsage(
          promptTokens: 10,
          responseTokens: 5,
          totalTokens: 15,
        ),
      );

      final merged = res1.concat(res2);
      expect(merged.output.content, 'part1part2');
      expect(merged.usage?.promptTokens, 20);
      expect(merged.usage?.responseTokens, 10);
      expect(merged.usage?.totalTokens, 30);
    });
  });

  group('ChatResultEntities', () {
    test('extracts tool calls correctly', () {
      final toolRequestPart = ToolRequestPart(
        toolRequest: ToolRequest(
          ref: 'call-1',
          name: 'getWeather',
          input: const {'city': 'Boston'},
        ),
      );
      final res = ChatResult<ChatMessage>(
        output: ChatMessage(
          role: ChatMessageRole.model,
          parts: [toolRequestPart],
        ),
      );

      expect(res.entityTools.length, 1);
      expect(res.entityTools.firstOrNull?.id, 'call-1');
      expect(res.entityTools.firstOrNull?.name, 'getWeather');
    });
  });
}
