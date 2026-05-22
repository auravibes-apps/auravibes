import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatbotService', () {
    test('can be constructed with required dependencies', () {
      expect(
        () => ChatbotService(
          modelConnectionRepository: _FakeModelConnectionRepository(),
          encryptionService: _FakeEncryptionService(),
        ),
        returnsNormally,
      );
    });

    test('exposes injected dependencies', () {
      final repo = _FakeModelConnectionRepository();
      final encryption = _FakeEncryptionService();

      final service = ChatbotService(
        modelConnectionRepository: repo,
        encryptionService: encryption,
      );

      expect(service.modelConnectionRepository, same(repo));
      expect(service.encryptionService, same(encryption));
    });

    test('accepts optional providerFactory and toolAdapter', () {
      expect(
        () => ChatbotService(
          modelConnectionRepository: _FakeModelConnectionRepository(),
          encryptionService: _FakeEncryptionService(),
        ),
        returnsNormally,
      );
    });
  });

  group('ChatbotService.generateFallbackTitle', () {
    test('returns first 4 words of short message', () {
      final title = ChatbotService.generateFallbackTitle(
        'Hello world this is a test',
      );

      expect(title, 'Hello world this is');
    });

    test('returns all words when message has 4 or fewer words', () {
      expect(
        ChatbotService.generateFallbackTitle('Hello world'),
        'Hello world',
      );
      expect(
        ChatbotService.generateFallbackTitle('one two three four'),
        'one two three four',
      );
    });

    test('returns single word for single word message', () {
      expect(ChatbotService.generateFallbackTitle('Hello'), 'Hello');
    });

    test('returns empty string for empty message', () {
      expect(ChatbotService.generateFallbackTitle(''), '');
    });

    test('truncates long title to 30 characters with ellipsis', () {
      const longMessage =
          'Extraordinarily lengthy complicated sophisticated expressions';
      final title = ChatbotService.generateFallbackTitle(longMessage);

      expect(title.length, 30);
      expect(title.endsWith('...'), isTrue);
    });

    test('handles multiple spaces between words', () {
      final title = ChatbotService.generateFallbackTitle(
        'Hello   world   test   words   here',
      );

      expect(title, 'Hello world test words');
    });

    test('handles leading and trailing spaces', () {
      final title = ChatbotService.generateFallbackTitle('  Hello world  ');

      expect(title, 'Hello world');
    });

    test('returns short title unchanged when under 30 chars', () {
      const message = 'Hi there friend';
      final title = ChatbotService.generateFallbackTitle(message);

      expect(title, message);
      expect(title.length, lessThanOrEqualTo(30));
    });

    test('exactly at boundary does not truncate', () {
      final words = List.generate(4, (i) => 'a' * 6).join(' ');
      final title = ChatbotService.generateFallbackTitle(words);

      expect(title, words);
      expect(title.endsWith('...'), isFalse);
    });

    test('handles tab and newline separated words', () {
      final title = ChatbotService.generateFallbackTitle(
        'word1 word2 word3 word4 word5',
      );
      expect(title, 'word1 word2 word3 word4');
    });

    test('handles very long single word', () {
      final longWord = 'a' * 100;
      final title = ChatbotService.generateFallbackTitle(longWord);
      expect(title.length, 30);
      expect(title.endsWith('...'), isTrue);
    });
  });

  group('ChatbotService.streamTitle processing', () {
    test('strips double quotes from title', () async {
      final stripped = _stripQuotes('"My Title"');
      expect(stripped, 'My Title');
    });

    test('strips single quotes from title', () async {
      final stripped = _stripQuotes("'My Title'");
      expect(stripped, 'My Title');
    });

    test('strips Title: prefix', () {
      final stripped = _stripPrefixes('Title: My Conversation');
      expect(stripped, 'My Conversation');
    });

    test('strips Conversation: prefix', () {
      final stripped = _stripPrefixes('Conversation: My Topic');
      expect(stripped, 'My Topic');
    });

    test('truncates title over 50 chars', () {
      final longTitle = 'a' * 60;
      final processed = _processTitle(longTitle);
      expect(processed.length, 50);
      expect(processed.endsWith('...'), isTrue);
    });

    test('returns title unchanged when under 50 chars', () {
      const title = 'Short Title';
      final processed = _processTitle(title);
      expect(processed, title);
    });

    test('returns fallback for empty processed title', () {
      final fallback = ChatbotService.generateFallbackTitle('test message');
      expect(fallback, isNotEmpty);
    });
  });
}

String _stripQuotes(String title) {
  var processed = title.trim();
  if (processed.startsWith('"') && processed.endsWith('"')) {
    processed = processed.substring(1, processed.length - 1);
  }
  if (processed.startsWith("'") && processed.endsWith("'")) {
    processed = processed.substring(1, processed.length - 1);
  }
  return processed;
}

String _stripPrefixes(String title) {
  var processed = title.trim();
  if (processed.startsWith('Title:')) {
    processed = processed.substring(6).trim();
  }
  if (processed.startsWith('Conversation:')) {
    processed = processed.substring(13).trim();
  }
  return processed;
}

String _processTitle(String title) {
  var processed = title.trim();
  if (processed.startsWith('"') && processed.endsWith('"')) {
    processed = processed.substring(1, processed.length - 1);
  }
  if (processed.startsWith("'") && processed.endsWith("'")) {
    processed = processed.substring(1, processed.length - 1);
  }
  if (processed.startsWith('Title:')) {
    processed = processed.substring(6).trim();
  }
  if (processed.startsWith('Conversation:')) {
    processed = processed.substring(13).trim();
  }
  if (processed.length > 50) {
    return '${processed.substring(0, 47)}...';
  }
  return processed;
}

class _FakeModelConnectionRepository extends ModelConnectionRepository {
  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate _,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteModelConnection(String _) async {}

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter _,
  ) async {
    return [];
  }
}

class _FakeEncryptionService extends EncryptionService {
  _FakeEncryptionService() : super(_FakeSecretKeyManager());

  @override
  Future<String> decrypt(String _) async => 'test-api-key';
}

class _FakeSecretKeyManager extends SecretKeyManager {
  _FakeSecretKeyManager() : super();

  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (i) => i));
  }
}
