// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

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
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  AppDatabase? testDatabase;
  ProviderContainer? container;
  ProviderContainer readContainer() =>
      container ?? fail('ProviderContainer not initialized');

  setUp(() {
    final database = AppDatabase(connection: _testConnection());
    testDatabase = database;
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container?.dispose();
    await testDatabase?.close();
  });

  group('conversationRepositoryProvider', () {
    test('returns a ConversationRepository instance', () {
      final repo = readContainer().read(conversationRepositoryProvider);
      expect(repo, isA<ConversationRepository>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final first = readContainer().read(conversationRepositoryProvider);
      final second = readContainer().read(conversationRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });

  group('messageRepositoryProvider', () {
    test('returns a MessageRepository instance', () {
      final repo = readContainer().read(messageRepositoryProvider);
      expect(repo, isA<MessageRepository>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final first = readContainer().read(messageRepositoryProvider);
      final second = readContainer().read(messageRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
