import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

void main() {
  group('WorkspaceModelSelectionsDao', () {
    late AppDatabase database;
    late String workspaceId;

    setUp(() async {
      database = AppDatabase(connection: createTestConnection());
      final ws = await database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await database.close();
    });

    test('insertWorkspaceModelSelections inserts records', () async {
      await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await database.modelConnectionsDao.insertModelConnection(
        ModelConnectionsCompanion.insert(
          name: 'Conn',
          modelId: 'openai',
          keyValue: 'key',
          workspaceId: workspaceId,
        ),
      );
      await database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
        [
          WorkspaceModelSelectionsCompanion.insert(
            modelId: 'openai',
            modelConnectionId: conn.id,
          ),
        ],
      );
      final results = await database.workspaceModelSelectionsDao
          .getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      expect(results.length, equals(1));
    });

    test('watchAllWorkspaceModelSelectionsByWorkspace emits inserts', () async {
      await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await database.modelConnectionsDao.insertModelConnection(
        ModelConnectionsCompanion.insert(
          name: 'Conn',
          modelId: 'openai',
          keyValue: 'key',
          workspaceId: workspaceId,
        ),
      );

      final initial = await database.workspaceModelSelectionsDao
          .watchAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          )
          .first;
      expect(initial, isEmpty);

      final expectation = expectLater(
        database.workspaceModelSelectionsDao
            .watchAllWorkspaceModelSelectionsByWorkspace(
              workspaceIds: [workspaceId],
            ),
        emitsThrough(hasLength(1)),
      );

      await database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
        [
          WorkspaceModelSelectionsCompanion.insert(
            modelId: 'openai',
            modelConnectionId: conn.id,
          ),
        ],
      );

      await expectation;
    });

    test(
      'getAllWorkspaceModelSelectionsByWorkspace returns empty for no match',
      () async {
        final results = await database.workspaceModelSelectionsDao
            .getAllWorkspaceModelSelectionsByWorkspace(
              workspaceIds: [workspaceId],
            );
        expect(results, isEmpty);
      },
    );

    test('getWorkspaceModelSelectionById returns selection', () async {
      await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await database.modelConnectionsDao.insertModelConnection(
        ModelConnectionsCompanion.insert(
          name: 'Conn',
          modelId: 'openai',
          keyValue: 'key',
          workspaceId: workspaceId,
        ),
      );
      await database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
        [
          WorkspaceModelSelectionsCompanion.insert(
            modelId: 'openai',
            modelConnectionId: conn.id,
          ),
        ],
      );
      final all = await database.workspaceModelSelectionsDao
          .getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      final found = await database.workspaceModelSelectionsDao
          .getWorkspaceModelSelectionById(all.first.model.id);
      expect(found, isNotNull);
      expect(found!.model.modelId, equals('openai'));
    });

    test(
      'getWorkspaceModelSelectionById returns null for nonexistent',
      () async {
        final found = await database.workspaceModelSelectionsDao
            .getWorkspaceModelSelectionById('missing');
        expect(found, isNull);
      },
    );
  });
}
