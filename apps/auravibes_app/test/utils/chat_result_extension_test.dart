import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatResult Concat', () {
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

      expect(result.entityText, 'Helloworld');
      expect(result.thinking, 'First second');
    });

    test('separates streaming thinking deltas without whitespace', () {
      const first = ChatResult<ChatMessage>(
        output: ChatMessage(role: ChatMessageRole.model),
        thinking: 'First',
      );
      const second = ChatResult<ChatMessage>(
        output: ChatMessage(role: ChatMessageRole.model),
        thinking: 'second',
      );

      final result = first.concat(second);

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

      expect(result.entityText, 'Hello world');
      expect(result.entityModelMetadata, {
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

    test('persists final result metadata for provider continuation', () {
      const result = ChatResult<ChatMessage>(
        output: ChatMessage(role: ChatMessageRole.model),
        metadata: {'_anthropic_thinking_signature': 'signature'},
      );

      expect(result.entityMetadata?.modelMetadata, {
        '_anthropic_thinking_signature': 'signature',
      });
    });
  });
}
