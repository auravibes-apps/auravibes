import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';
import '../database/drift/database_test_utils.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('WorkspaceModelSelectionRepository', () {
    final mockDao = MockWorkspaceModelSelectionsDao();
    final database = _TestAppDatabase(mockDao);
    final repository = WorkspaceModelSelectionRepository(database);

    setUp(() async {
      reset(mockDao);
      await clearAppDatabase(database);
    });

    tearDownAll(() async {
      await database.close();
    });

    final now = DateTime(2026);

    test(
      'projects persisted flags only for official Anthropic transport',
      () async {
        for (final scenario in [
          (
            connectionUrl: null,
            providerUrl: 'https://api.anthropic.com/v1',
            allowed: true,
          ),
          (
            connectionUrl: 'https://custom.example/v1',
            providerUrl: 'https://api.anthropic.com/v1',
            allowed: false,
          ),
          (
            connectionUrl: null,
            providerUrl: 'https://custom.example/v1',
            allowed: false,
          ),
        ]) {
          for (var index = 0; index < 4; index++) {
            final source = WorkspaceModelSelectionWithConnection(
              model: .new(
                id: 'sel',
                createdAt: now,
                updatedAt: now,
                modelId: 'claude-sonnet-5',
                modelConnectionId: 'conn',
              ),
              modelConnection: .new(
                id: 'conn',
                createdAt: now,
                updatedAt: now,
                name: 'Connection',
                serviceId: 'anthropic',
                kind: ServiceConnectionKindTable.modelProvider,
                authenticationType: ServiceAuthenticationTypeTable.apiKey,
                workspaceId: 'ws',
                isEnabled: true,
                url: scenario.connectionUrl,
              ),
              modelProvider: .new(
                id: 'anthropic',
                name: 'Anthropic',
                type: .anthropic,
                url: scenario.providerUrl,
              ),
              apiModel: .new(
                modelProvider: 'anthropic',
                id: 'claude-sonnet-5',
                name: 'Sonnet',
                supportsReasoning: false,
                isCanonical: true,
                supportsPriorityMode: false,
                supportsToolCalls: true,
                supportsPromptCacheMarkers: index == 0,
                supportsMidConversationSystemMessages: index == 1,
                supportsToolDeltas: index == 2,
                supportsDeferredTools: index == 3,
                limitContext: 1000,
                limitOutput: 100,
              ),
            );
            when(() => mockDao.getWorkspaceModelSelectionById('sel'))
                .thenAnswer((_) async => source);
            final result = await repository.getWorkspaceModelSelectionById(
              'sel',
            );
            final selection = result?.workspaceModelSelection;
            expect(
              selection?.supportsPromptCacheMarkers,
              scenario.allowed && index == 0,
            );
            expect(
              selection?.supportsMidConversationSystemMessages,
              scenario.allowed && index == 1,
            );
            expect(
              selection?.supportsToolDeltas,
              scenario.allowed && index == 2,
            );
            expect(
              selection?.supportsDeferredTools,
              scenario.allowed && index == 3,
            );
          }
        }
      },
    );

    group('createWorkspaceModelSelections', () {
      test('delegates to dao with companions', () async {
        when(() => mockDao.insertWorkspaceModelSelections(any()))
            .thenAnswer((_) async {
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

        expect(
          () =>
              verify(() => mockDao.insertWorkspaceModelSelections(any()))
                  .called(1),
          returnsNormally,
        );
      });

      test('handles empty list', () async {
        when(() => mockDao.insertWorkspaceModelSelections(any()))
            .thenAnswer((_) async {
              return;
            });

        await repository.createWorkspaceModelSelections([]);

        expect(
          () =>
              verify(() => mockDao.insertWorkspaceModelSelections(any()))
                  .called(1),
          returnsNormally,
        );
      });
    });

    group('getWorkspaceModelSelections', () {
      test('returns mapped entities with connections', () async {
        final withConnection = WorkspaceModelSelectionWithConnection(
          model: .new(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'openai',
            modelConnectionId: 'conn-1',
            toolSamplingPolicy: 'prefer',
          ),
          modelConnection: .new(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'My Connection',
            serviceId: 'openai',
            kind: ServiceConnectionKindTable.modelProvider,
            authenticationType: ServiceAuthenticationTypeTable.apiKey,
            encryptedAuthValue: 'encrypted-key',
            keySuffix: 'abc123',
            workspaceId: 'ws-1',
            isEnabled: true,
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'openai',
            name: 'OpenAI',
            type: .openai,
          ),
          apiModel: const ApiModelsTable(
            modelProvider: 'openai',
            id: 'openai',
            name: 'GPT-4',
            supportsReasoning: false,
            isCanonical: true,
            supportsPriorityMode: false,
            supportsToolCalls: false,
            supportsPromptCacheMarkers: false,
            supportsMidConversationSystemMessages: false,
            supportsToolDeltas: false,
            supportsDeferredTools: false,

            limitContext: 128000,
            limitOutput: 4096,
          ),
        );

        when(
          () => mockDao.getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: any(named: 'workspaceIds'),
          ),
        ).thenAnswer((_) async => [withConnection]);

        const filter = WorkspaceModelSelectionFilter(workspaces: ['ws-1']);
        final result = await repository.getWorkspaceModelSelections(filter);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.workspaceModelSelection.id, 'sel-1');
        expect(result.firstOrNull?.workspaceModelSelection.modelId, 'openai');
        expect(result.firstOrNull?.workspaceModelSelection.modelName, 'GPT-4');
        expect(
          result.firstOrNull?.workspaceModelSelection.toolSamplingPolicy,
          ToolSamplingPolicy.prefer,
        );
        expect(
          result.firstOrNull?.workspaceModelSelection.supportsToolCalls,
          false,
        );
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
          () => mockDao.getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: any(named: 'workspaceIds'),
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
          model: .new(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'openai',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: .new(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'My Connection',
            serviceId: 'openai',
            kind: ServiceConnectionKindTable.modelProvider,
            authenticationType: ServiceAuthenticationTypeTable.apiKey,
            encryptedAuthValue: 'key',
            workspaceId: 'ws-1',
            isEnabled: true,
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'openai',
            name: 'OpenAI',
          ),
        );

        when(() => mockDao.getWorkspaceModelSelectionById('sel-1'))
            .thenAnswer((_) async => withConnection);

        final result = await repository.getWorkspaceModelSelectionById('sel-1');

        expect(result, isNotNull);
        expect(
          (result ?? fail('Expected result to be non-null'))
              .workspaceModelSelection
              .id,
          'sel-1',
        );
        expect(result.modelConnection.id, 'conn-1');
        expect(
          result.workspaceModelSelection.supportsPromptCacheMarkers,
          isFalse,
        );
        expect(
          result.workspaceModelSelection.supportsMidConversationSystemMessages,
          isFalse,
        );
        expect(result.workspaceModelSelection.supportsToolDeltas, isFalse);
        expect(result.workspaceModelSelection.supportsDeferredTools, isFalse);
      });

      test('returns null when not found', () async {
        when(() => mockDao.getWorkspaceModelSelectionById('nonexistent'))
            .thenAnswer((_) async => null);

        final result = await repository.getWorkspaceModelSelectionById(
          'nonexistent',
        );

        expect(result, isNull);
      });

      test('updates policy for a selection', () async {
        when(() => mockDao.updateToolSamplingPolicy('sel-1', 'require'))
            .thenAnswer((_) async => 1);

        await repository.updateToolSamplingPolicy('sel-1', .require);

        verify(() => mockDao.updateToolSamplingPolicy('sel-1', 'require'))
            .called(1);
      });
    });

    group('type mapping', () {
      test('maps null provider type correctly', () async {
        final withConnection = WorkspaceModelSelectionWithConnection(
          model: .new(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'test',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: .new(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'Conn',
            serviceId: 'test',
            kind: ServiceConnectionKindTable.modelProvider,
            authenticationType: ServiceAuthenticationTypeTable.apiKey,
            encryptedAuthValue: 'key',
            workspaceId: 'ws-1',
            isEnabled: true,
          ),
          modelProvider: const ApiModelProvidersTable(id: 'test', name: 'Test'),
        );

        when(() => mockDao.getWorkspaceModelSelectionById('sel-1'))
            .thenAnswer((_) async => withConnection);

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
          model: .new(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'anthropic',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: .new(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'Conn',
            serviceId: 'anthropic',
            kind: ServiceConnectionKindTable.modelProvider,
            authenticationType: ServiceAuthenticationTypeTable.apiKey,
            encryptedAuthValue: 'key',
            workspaceId: 'ws-1',
            isEnabled: true,
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'anthropic',
            name: 'Anthropic',
            type: .anthropic,
          ),
        );

        when(() => mockDao.getWorkspaceModelSelectionById('sel-1'))
            .thenAnswer((_) async => withConnection);

        final result = await repository.getWorkspaceModelSelectionById('sel-1');

        expect(
          (result ?? fail('Expected result to be non-null'))
              .modelsProvider
              .type,
          ModelProvidersType.anthropic,
        );
      });

      test('maps openrouter type correctly', () async {
        final withConnection = WorkspaceModelSelectionWithConnection(
          model: .new(
            id: 'sel-1',
            createdAt: now,
            updatedAt: now,
            modelId: 'anthropic/claude-sonnet-4',
            modelConnectionId: 'conn-1',
          ),
          modelConnection: .new(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'Conn',
            serviceId: 'openrouter',
            kind: ServiceConnectionKindTable.modelProvider,
            authenticationType: ServiceAuthenticationTypeTable.apiKey,
            encryptedAuthValue: 'key',
            workspaceId: 'ws-1',
            isEnabled: true,
          ),
          modelProvider: const ApiModelProvidersTable(
            id: 'openrouter',
            name: 'OpenRouter',
            type: .openrouter,
          ),
        );

        when(() => mockDao.getWorkspaceModelSelectionById('sel-1'))
            .thenAnswer((_) async => withConnection);

        final result = await repository.getWorkspaceModelSelectionById('sel-1');

        expect(
          (result ?? fail('Expected result to be non-null'))
              .modelsProvider
              .type,
          ModelProvidersType.openrouter,
        );
      });
    });
  });
}

class _TestAppDatabase(final WorkspaceModelSelectionsDao _selectionsDao)
    extends AppDatabase {
  this : super(connection: DatabaseConnection(NativeDatabase.memory()));

  @override
  WorkspaceModelSelectionsDao get workspaceModelSelectionsDao => _selectionsDao;
}
