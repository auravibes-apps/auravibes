import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/background_work_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/background_work_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/background_work_coordinator.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

QueryExecutor _testConnection() => DatabaseConnection.delayed(
  Future(
    () => DatabaseConnection(LazyDatabase(() async => NativeDatabase.memory())),
  ),
);

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(connection: _testConnection());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('wires the local work repository and coordinator', () {
    expect(
      container.read(backgroundWorkRepositoryProvider),
      isA<BackgroundWorkRepository>(),
    );
    expect(
      container.read(backgroundWorkCoordinatorProvider),
      isA<BackgroundWorkCoordinator>(),
    );
    expect(
      container.read(agentCancellationRuntimeProvider),
      isA<AgentCancellationRuntime>(),
    );
  });
}
