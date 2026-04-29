import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

QueryExecutor _testConnection() {
  return DatabaseConnection.delayed(
    Future(
      () => DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDatabase;
  late ProviderContainer container;

  setUp(() {
    testDatabase = AppDatabase(connection: _testConnection());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(testDatabase)],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  group('conversationRepositoryProvider', () {
    test('returns a ConversationRepository instance', () {
      final repo = container.read(conversationRepositoryProvider);
      expect(repo, isA<ConversationRepository>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final first = container.read(conversationRepositoryProvider);
      final second = container.read(conversationRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });

  group('messageRepositoryProvider', () {
    test('returns a MessageRepository instance', () {
      final repo = container.read(messageRepositoryProvider);
      expect(repo, isA<MessageRepository>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final first = container.read(messageRepositoryProvider);
      final second = container.read(messageRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
