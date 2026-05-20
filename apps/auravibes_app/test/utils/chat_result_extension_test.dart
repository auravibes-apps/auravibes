import 'package:auravibes_app/utils/chat_result_extension.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatResultConcat', () {
    test('appends streaming thinking deltas', () {
      final first = ChatResult<ChatMessage>(
        output: ChatMessage.model('Hello'),
        thinking: 'First ',
      );
      final second = ChatResult<ChatMessage>(
        output: ChatMessage.model('world'),
        thinking: 'second',
      );

      final result = first.concat(second);

      expect(result.output.text, 'Helloworld');
      expect(result.thinking, 'First second');
    });

    test('merges output metadata before concatenating chunks', () {
      final first = ChatResult<ChatMessage>(
        output: ChatMessage.model('Hello'),
      );
      final second = ChatResult<ChatMessage>(
        output: ChatMessage.model(
          ' world',
          metadata: const {'_anthropic_thinking_signature': 'signature'},
        ),
      );

      final result = first.concat(second);

      expect(result.output.text, 'Hello world');
      expect(result.output.metadata, {
        '_anthropic_thinking_signature': 'signature',
      });
    });
  });

  group('ChatResultEntities', () {
    test('persists thinking metadata from ChatResult thinking', () {
      final result = ChatResult<ChatMessage>(
        output: ChatMessage.model('Answer'),
        thinking: 'Reasoned summary',
      );

      expect(result.entityThinking, 'Reasoned summary');
      expect(result.entityMetadata?.thinking, 'Reasoned summary');
    });

    test('persists thinking metadata from ThinkingPart chunks', () {
      final result = ChatResult<ChatMessage>(
        output: ChatMessage.model(
          '',
          parts: const [ThinkingPart('OpenAI reasoning ')],
        ),
        messages: [
          ChatMessage.model(
            '',
            parts: const [ThinkingPart('summary')],
          ),
        ],
      );

      expect(result.entityThinking, 'OpenAI reasoning summary');
      expect(result.entityMetadata?.thinking, 'OpenAI reasoning summary');
    });

    test('persists model metadata for provider continuation', () {
      final result = ChatResult<ChatMessage>(
        output: ChatMessage.model(
          'Answer',
          metadata: const {'_anthropic_thinking_signature': 'signature'},
        ),
      );

      expect(result.entityMetadata?.modelMetadata, {
        '_anthropic_thinking_signature': 'signature',
      });
    });
  });
}
