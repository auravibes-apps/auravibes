// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
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

  group('mcpServersRepositoryProvider', () {
    test('returns a McpServersRepository instance', () {
      final repo = readContainer().read(mcpServersRepositoryProvider);
      expect(repo, isA<McpServersRepository>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final first = readContainer().read(mcpServersRepositoryProvider);
      final second = readContainer().read(mcpServersRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
