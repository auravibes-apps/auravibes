import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

QueryExecutor _testConnection() {
  return DatabaseConnection.delayed(
    Future(
      () => DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      ),
    ),
  );
}

@Dependencies([
  mcpServersRepository,
  workspaceSession,
  cloudWorkspaceStateGateway,
])
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
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'workspace'),
          ),
        ),
      ],
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
