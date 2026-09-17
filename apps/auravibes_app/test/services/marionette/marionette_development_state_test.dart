import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/services/marionette/marionette_development_state.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  var database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  var selectionRepository = _SelectionRepository();
  String? lastLocation;
  var modelSelectionCalls = 0;
  MarionetteDevelopmentState createState() => MarionetteDevelopmentState(
    database: database,
    workspaceRepository: .new(database),
    selectWorkspaceUsecase: .new(selectionRepository: selectionRepository),
    modelSelectionRepository: .new(database),
    preferences: SharedPreferences.getInstance(),
    navigateTo: (location) => lastLocation = location,
    setNewChatModel: (_, _) => modelSelectionCalls++,
  );
  var state = createState();

  setUp(() async {
    await database.close();
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    selectionRepository = _SelectionRepository();
    lastLocation = null;
    modelSelectionCalls = 0;
    state = createState();
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds deterministic credential-free data idempotently', () async {
    final firstSeed = await state.seedDemoData();
    final secondSeed = await state.seedDemoData();
    expect(secondSeed, firstSeed);

    final workspaces =
        await (database.select(database.workspaces)..where(
              (table) =>
                  table.id.equals(MarionetteDevelopmentState.demoWorkspaceId),
            ))
            .get();
    final connections =
        await (database.select(database.serviceConnections)..where(
              (table) =>
                  table.id.equals(MarionetteDevelopmentState.demoConnectionId),
            ))
            .get();
    final selections =
        await (database.select(database.workspaceModelSelections)..where(
              (table) => table.id.equals(
                MarionetteDevelopmentState.demoModelSelectionId,
              ),
            ))
            .get();
    final conversations =
        await (database.select(database.conversations)..where(
              (table) => table.id.equals(
                MarionetteDevelopmentState.demoConversationId,
              ),
            ))
            .get();
    final messages =
        await (database.select(database.messages)..where(
              (table) =>
                  table.id.equals(MarionetteDevelopmentState.demoMessageId),
            ))
            .get();

    expect(workspaces, hasLength(1));
    expect(workspaces.single.type, WorkspaceType.local);
    expect(workspaces.single.createdAt.toUtc(), DateTime.utc(2026));
    expect(connections, hasLength(1));
    expect(
      connections.single.authenticationType,
      ServiceAuthenticationTypeTable.none,
    );
    expect(connections.single.url, isNull);
    expect(connections.single.encryptedAuthValue, isNull);
    expect(selections, hasLength(1));
    expect(selections.single.modelId, 'marionette-demo-model');
    expect(conversations, hasLength(1));
    expect(
      conversations.single.modelId,
      MarionetteDevelopmentState.demoModelSelectionId,
    );
    expect(messages, hasLength(1));
    expect(messages.single.content, 'Deterministic Marionette demo message.');
    expect(messages.single.messageType, MessagesTableType.text);
  });

  test(
    'selects only local workspace models and applies intended state',
    () async {
      final _ = await state.seedDemoData();

      final workspaceResult = await state.selectWorkspace(
        workspaceId: MarionetteDevelopmentState.demoWorkspaceId,
      );
      final modelResult = await state.selectModel(
        workspaceId: MarionetteDevelopmentState.demoWorkspaceId,
        modelSelectionId: MarionetteDevelopmentState.demoModelSelectionId,
      );

      expect(
        selectionRepository.selectedWorkspaceId,
        MarionetteDevelopmentState.demoWorkspaceId,
      );
      expect(workspaceResult['location'], lastLocation);
      expect(modelResult['location'], lastLocation);
      expect(modelSelectionCalls, 1);
      expect(
        await database.recentModelSelectionsDao.getSelectionIds(
          MarionetteDevelopmentState.demoWorkspaceId,
        ),
        [MarionetteDevelopmentState.demoModelSelectionId],
      );
    },
  );

  test('rejects remote navigation and mismatched model selection', () async {
    final _ = await database.workspaceDao.insertWorkspace(
      .insert(
        id: const Value('remote-workspace'),
        name: 'Remote workspace',
        type: .remote,
        url: const Value('https://example.invalid'),
      ),
    );

    expect(
      () => state.navigate(route: 'new_chat', workspaceId: 'remote-workspace'),
      throwsA(isA<ArgumentError>()),
    );
    expect(lastLocation, isNull);

    final _ = await state.seedDemoData();
    final _ = await database.workspaceDao.insertWorkspace(
      .insert(
        id: const Value('other-workspace'),
        name: 'Other workspace',
        type: .local,
      ),
    );
    final _ = await database.modelConnectionsDao.insertModelConnection(
      .insert(
        id: const Value('other-connection'),
        name: 'Other connection',
        serviceId: 'other',
        kind: .modelProvider,
        authenticationType: .none,
        workspaceId: 'other-workspace',
      ),
    );
    await database.workspaceModelSelectionsDao.insertWorkspaceModelSelections([
      .insert(
        id: const Value('other-model-selection'),
        modelId: 'other-model',
        modelConnectionId: 'other-connection',
      ),
    ]);

    expect(
      () => state.selectModel(
        workspaceId: MarionetteDevelopmentState.demoWorkspaceId,
        modelSelectionId: 'other-model-selection',
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(modelSelectionCalls, 0);
  });

  test('clears only Marionette development state', () async {
    final _ = await database.workspaceDao.insertWorkspace(
      .insert(
        id: const Value('keep-workspace'),
        name: 'Keep workspace',
        type: .local,
      ),
    );
    final _ = await state.seedDemoData();
    await database.recentModelSelectionsDao.recordSelection(
      MarionetteDevelopmentState.demoWorkspaceId,
      MarionetteDevelopmentState.demoModelSelectionId,
    );
    final preferences = await SharedPreferences.getInstance();
    final _ = await preferences.setBool(
      'auravibes.marionette.feature.a2ui',
      true,
    );
    final _ = await preferences.setBool('unrelated.preference', true);

    final result = await state.clearDevelopmentState();

    expect(result['deletedWorkspace'], isTrue);
    expect(result['deletedRecentSelections'], 1);
    expect(result['clearedFeatureFlags'], 1);
    final repository = WorkspaceRepository(database);
    expect(
      await repository.getWorkspaceById(
        MarionetteDevelopmentState.demoWorkspaceId,
      ),
      isNull,
    );
    expect(
      await database.recentModelSelectionsDao.getSelectionIds(
        MarionetteDevelopmentState.demoWorkspaceId,
      ),
      isEmpty,
    );
    expect(await repository.getWorkspaceById('keep-workspace'), isNotNull);
    expect(preferences.getBool('auravibes.marionette.feature.a2ui'), isNull);
    expect(preferences.getBool('unrelated.preference'), isTrue);
  });
}

final class _SelectionRepository implements WorkspaceSelectionRepository {
  String? selectedWorkspaceId;

  @override
  Future<void> clearIfMatches(String workspaceId) async {
    if (selectedWorkspaceId == workspaceId) selectedWorkspaceId = null;
  }

  @override
  Future<String?> read() async => selectedWorkspaceId;

  @override
  Future<void> save(String workspaceId) async {
    selectedWorkspaceId = workspaceId;
  }
}
