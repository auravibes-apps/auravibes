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

  group('mcpServersRepositoryProvider', () {
    test('returns a McpServersRepository instance', () {
      final repo = container.read(mcpServersRepositoryProvider);
      expect(repo, isA<McpServersRepository>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final first = container.read(mcpServersRepositoryProvider);
      final second = container.read(mcpServersRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
