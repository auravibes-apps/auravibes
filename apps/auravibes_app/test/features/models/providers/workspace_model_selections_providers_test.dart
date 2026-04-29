import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeWorkspaceModelSelectionRepository
    implements WorkspaceModelSelectionRepository {
  _FakeWorkspaceModelSelectionRepository([this.selections = const []]);
  final List<WorkspaceModelSelectionWithConnectionEntity> selections;

  @override
  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(WorkspaceModelSelectionFilter filter) async {
    return selections;
  }

  @override
  Future<void> createWorkspaceModelSelections(
    List<WorkspaceModelSelectionToCreate> selections,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(String id) {
    throw UnimplementedError();
  }
}

void main() {
  group('listWorkspaceModelSelectionsProvider', () {
    test('returns selections for given workspace', () async {
      final now = DateTime(2026);
      final selections = [
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-1',
            modelId: 'gpt-4',
            modelConnectionId: 'conn-1',
            createdAt: now,
            updatedAt: now,
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-1',
            name: 'OpenAI',
            key: 'key',
            modelId: 'gpt-4',
            workspaceId: 'ws-1',
            createdAt: now,
            updatedAt: now,
          ),
          modelsProvider: const ApiModelProviderEntity(
            id: 'openai',
            name: 'OpenAI',
            type: null,
          ),
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository(selections),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        listWorkspaceModelSelectionsProvider(workspaceId: 'ws-1').future,
      );
      expect(result, hasLength(1));
      expect(
        result.first.workspaceModelSelection.id,
        'sel-1',
      );
    });
  });

  group('listModelsGroupedByProviderProvider', () {
    test('groups models by provider name', () async {
      final now = DateTime(2026);
      final selections = [
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-1',
            modelId: 'gpt-4',
            modelConnectionId: 'conn-1',
            createdAt: now,
            updatedAt: now,
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-1',
            name: 'OpenAI Key',
            key: 'key',
            modelId: 'gpt-4',
            workspaceId: 'ws-1',
            createdAt: now,
            updatedAt: now,
          ),
          modelsProvider: const ApiModelProviderEntity(
            id: 'openai',
            name: 'OpenAI',
            type: null,
          ),
        ),
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-2',
            modelId: 'claude-3',
            modelConnectionId: 'conn-2',
            createdAt: now,
            updatedAt: now,
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-2',
            name: 'Anthropic Key',
            key: 'key',
            modelId: 'claude-3',
            workspaceId: 'ws-1',
            createdAt: now,
            updatedAt: now,
          ),
          modelsProvider: const ApiModelProviderEntity(
            id: 'anthropic',
            name: 'Anthropic',
            type: null,
          ),
        ),
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-3',
            modelId: 'gpt-4o',
            modelConnectionId: 'conn-3',
            createdAt: now,
            updatedAt: now,
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-3',
            name: 'OpenAI Key 2',
            key: 'key',
            modelId: 'gpt-4o',
            workspaceId: 'ws-1',
            createdAt: now,
            updatedAt: now,
          ),
          modelsProvider: const ApiModelProviderEntity(
            id: 'openai',
            name: 'OpenAI',
            type: null,
          ),
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository(selections),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        listModelsGroupedByProviderProvider(workspaceId: 'ws-1').future,
      );

      expect(result.keys, equals(['Anthropic', 'OpenAI']));
      expect(result['OpenAI'], hasLength(2));
      expect(result['Anthropic'], hasLength(1));
    });

    test('returns empty map when no selections', () async {
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        listModelsGroupedByProviderProvider(workspaceId: 'ws-1').future,
      );
      expect(result, isEmpty);
    });
  });
}
