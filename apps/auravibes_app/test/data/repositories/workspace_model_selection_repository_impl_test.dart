// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: missing-test-assertion
// Required: Repository tests verify side effects through database state.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository_impl.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'workspace_model_selection_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WorkspaceModelSelectionsDao>()])
void main() {
  group('WorkspaceModelSelectionRepositoryImpl', () {
    late MockWorkspaceModelSelectionsDao mockDao;
    late _TestAppDatabase database;
    late WorkspaceModelSelectionRepositoryImpl repository;

    setUp(() {
      mockDao = MockWorkspaceModelSelectionsDao();
      database = _TestAppDatabase(mockDao);
      repository = WorkspaceModelSelectionRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    final now = DateTime(2026);

    group('createWorkspaceModelSelections', () {
      test('delegates to dao with companions', () async {
        when(mockDao.insertWorkspaceModelSelections(any)).thenAnswer((_) async {
          return;
        });

        final selections = [
          const WorkspaceModelSelectionToCreate(
            modelId: 'gpt-4',
            modelConnectionId: 'conn-1',
          ),
          const WorkspaceModelSelectionToCreate(
            modelId: 'gpt-3.5',
            modelConnectionId: 'conn-1',
          ),
        ];

        await repository.createWorkspaceModelSelections(selections);

        verify(mockDao.insertWorkspaceModelSelections(any)).called(1);
      });

      test('handles empty list', () async {
        when(mockDao.insertWorkspaceModelSelections(any)).thenAnswer((_) async {
          return;
        });

        await repository.createWorkspaceModelSelections([]);

        verify(mockDao.insertWorkspaceModelSelections(any)).called(1);
      });
    });

    group('getWorkspaceModelSelections', () {
      test('returns mapped entities with connections', () async {
        final withConnection = WorkspaceModelSelectionWithConnection(
          model: WorkspaceModelSelectionTable(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'openai',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: ModelConnectionTable(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'My Connection',
            modelId: 'openai',
            keyValue: 'encrypted-key',
            keySuffix: 'abc123',
            workspaceId: 'ws-1',
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'openai',
            name: 'OpenAI',
            type: ModelProvidersTableType.openai,
          ),
        );

        when(
          mockDao.getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: anyNamed('workspaceIds'),
          ),
        ).thenAnswer((_) async => [withConnection]);

        const filter = WorkspaceModelSelectionFilter(workspaces: ['ws-1']);
        final result = await repository.getWorkspaceModelSelections(filter);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.workspaceModelSelection.id, 'sel-1');
        expect(result.firstOrNull?.workspaceModelSelection.modelId, 'openai');
        expect(result.firstOrNull?.modelConnection.id, 'conn-1');
        expect(result.firstOrNull?.modelConnection.name, 'My Connection');
        expect(result.firstOrNull?.modelsProvider.id, 'openai');
        expect(
          result.firstOrNull?.modelsProvider.type,
          ModelProvidersType.openai,
        );
      });

      test('handles null workspaces filter', () async {
        when(
          mockDao.getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: anyNamed('workspaceIds'),
          ),
        ).thenAnswer((_) async => []);

        const filter = WorkspaceModelSelectionFilter();
        final result = await repository.getWorkspaceModelSelections(filter);

        expect(result, isEmpty);
      });
    });

    group('getWorkspaceModelSelectionById', () {
      test('returns entity when found', () async {
        final withConnection = WorkspaceModelSelectionWithConnection(
          model: WorkspaceModelSelectionTable(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'openai',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: ModelConnectionTable(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'My Connection',
            modelId: 'openai',
            keyValue: 'key',
            workspaceId: 'ws-1',
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'openai',
            name: 'OpenAI',
          ),
        );

        when(
          mockDao.getWorkspaceModelSelectionById('sel-1'),
        ).thenAnswer((_) async => withConnection);

        final result = await repository.getWorkspaceModelSelectionById('sel-1');

        expect(result, isNotNull);
        expect(
          (result ?? fail('Expected result to be non-null'))
              .workspaceModelSelection
              .id,
          'sel-1',
        );
        expect(result.modelConnection.id, 'conn-1');
      });

      test('returns null when not found', () async {
        when(
          mockDao.getWorkspaceModelSelectionById('nonexistent'),
        ).thenAnswer((_) async => null);

        final result = await repository.getWorkspaceModelSelectionById(
          'nonexistent',
        );

        expect(result, isNull);
      });
    });

    group('type mapping', () {
      test('maps null provider type correctly', () async {
        final withConnection = WorkspaceModelSelectionWithConnection(
          model: WorkspaceModelSelectionTable(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'test',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: ModelConnectionTable(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'Conn',
            modelId: 'test',
            keyValue: 'key',
            workspaceId: 'ws-1',
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'test',
            name: 'Test',
          ),
        );

        when(
          mockDao.getWorkspaceModelSelectionById('sel-1'),
        ).thenAnswer((_) async => withConnection);

        final result = await repository.getWorkspaceModelSelectionById('sel-1');

        expect(
          (result ?? fail('Expected result to be non-null'))
              .modelsProvider
              .type,
          isNull,
        );
      });

      test('maps anthropic type correctly', () async {
        final withConnection = WorkspaceModelSelectionWithConnection(
          model: WorkspaceModelSelectionTable(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'anthropic',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: ModelConnectionTable(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'Conn',
            modelId: 'anthropic',
            keyValue: 'key',
            workspaceId: 'ws-1',
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'anthropic',
            name: 'Anthropic',
            type: ModelProvidersTableType.anthropic,
          ),
        );

        when(
          mockDao.getWorkspaceModelSelectionById('sel-1'),
        ).thenAnswer((_) async => withConnection);

        final result = await repository.getWorkspaceModelSelectionById('sel-1');

        expect(
          (result ?? fail('Expected result to be non-null'))
              .modelsProvider
              .type,
          ModelProvidersType.anthropic,
        );
      });
    });
  });
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(this._selectionsDao)
    : super(connection: DatabaseConnection(NativeDatabase.memory()));
  final WorkspaceModelSelectionsDao _selectionsDao;

  @override
  WorkspaceModelSelectionsDao get workspaceModelSelectionsDao => _selectionsDao;
}
