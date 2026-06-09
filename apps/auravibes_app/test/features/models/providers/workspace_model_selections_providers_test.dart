// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.

import 'dart:async';

import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeWorkspaceModelSelectionRepository
    implements WorkspaceModelSelectionRepository {
  _FakeWorkspaceModelSelectionRepository([
    this.selections = const [],
    this.workspaceModelSelectionStream,
  ]);

  final List<WorkspaceModelSelectionWithConnectionEntity> selections;
  final Stream<List<WorkspaceModelSelectionWithConnectionEntity>>?
  workspaceModelSelectionStream;

  @override
  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(WorkspaceModelSelectionFilter filter) async {
    return selections;
  }

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
  watchWorkspaceModelSelections(WorkspaceModelSelectionFilter filter) {
    return workspaceModelSelectionStream ?? Stream.value(selections);
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
      final now = DateTime(2024);
      final selections = [
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-1',
            modelId: 'gpt-4',
            createdAt: now,
            updatedAt: now,
            modelConnectionId: 'conn-1',
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-1',
            name: 'OpenAI',
            key: 'key',
            modelId: 'gpt-4',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
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

      final provider = listWorkspaceModelSelectionsProvider(
        workspaceId: 'ws-1',
      );
      final subscription = container.listen(provider, (_, _) {
        final _ = Object();
      });
      addTearDown(subscription.close);

      final result = await container.read(provider.future);
      expect(result, hasLength(1));
      expect(
        result.firstOrNull?.workspaceModelSelection.id,
        'sel-1',
      );
    });

    test('emits updated selections after initial value', () async {
      final now = DateTime(2026);
      final initialSelection = WorkspaceModelSelectionWithConnectionEntity(
        workspaceModelSelection: WorkspaceModelSelectionEntity(
          id: 'sel-1',
          modelId: 'gpt-4',
          createdAt: now,
          updatedAt: now,
          modelConnectionId: 'conn-1',
        ),
        modelConnection: ModelConnectionEntity(
          id: 'conn-1',
          name: 'OpenAI',
          key: 'key',
          modelId: 'gpt-4',
          createdAt: now,
          updatedAt: now,
          workspaceId: 'ws-1',
        ),
        modelsProvider: const ApiModelProviderEntity(
          id: 'openai',
          name: 'OpenAI',
          type: null,
        ),
      );
      final updatedSelection = WorkspaceModelSelectionWithConnectionEntity(
        workspaceModelSelection: WorkspaceModelSelectionEntity(
          id: 'sel-2',
          modelId: 'claude-3',
          createdAt: now,
          updatedAt: now,
          modelConnectionId: 'conn-2',
        ),
        modelConnection: ModelConnectionEntity(
          id: 'conn-2',
          name: 'Anthropic',
          key: 'key',
          modelId: 'claude-3',
          createdAt: now,
          updatedAt: now,
          workspaceId: 'ws-1',
        ),
        modelsProvider: const ApiModelProviderEntity(
          id: 'anthropic',
          name: 'Anthropic',
          type: null,
        ),
      );
      final controller =
          StreamController<List<WorkspaceModelSelectionWithConnectionEntity>>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository([], controller.stream),
          ),
        ],
      );
      addTearDown(container.dispose);

      final provider = listWorkspaceModelSelectionsProvider(
        workspaceId: 'ws-1',
      );
      final secondEmission =
          Completer<List<WorkspaceModelSelectionWithConnectionEntity>>();
      var emissionCount = 0;
      final subscription = container.listen(provider, (_, next) {
        switch (next) {
          case AsyncData(:final value):
            emissionCount++;
            if (emissionCount == 2) {
              secondEmission.complete(value);
            }
          case AsyncError() || AsyncLoading():
        }
      });
      addTearDown(subscription.close);

      final firstEmission = container.read(provider.future);
      controller.add([initialSelection]);
      expect(await firstEmission, hasLength(1));

      controller.add([initialSelection, updatedSelection]);
      expect(await secondEmission.future, hasLength(2));
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
            createdAt: now,
            updatedAt: now,
            modelConnectionId: 'conn-1',
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-1',
            name: 'OpenAI Key',
            key: 'key',
            modelId: 'gpt-4',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
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
            createdAt: now,
            updatedAt: now,
            modelConnectionId: 'conn-2',
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-2',
            name: 'Anthropic Key',
            key: 'key',
            modelId: 'claude-3',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
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
            createdAt: now,
            updatedAt: now,
            modelConnectionId: 'conn-3',
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-3',
            name: 'OpenAI Key 2',
            key: 'key',
            modelId: 'gpt-4o',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
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

      final provider = listModelsGroupedByProviderProvider(workspaceId: 'ws-1');
      final subscription = container.listen(provider, (_, _) {
        final _ = Object();
      });
      addTearDown(subscription.close);

      final result = await container.read(provider.future);

      expect(result.keys, equals(['Anthropic', 'OpenAI']));
      expect(result['OpenAI'], hasLength(2));
      expect(result['Anthropic'], hasLength(1));
    });

    test('sorts provider groups alphabetically by provider name', () async {
      final now = DateTime(2026);
      final selections = [
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-zebra',
            modelId: 'model-z',
            createdAt: now,
            updatedAt: now,
            modelConnectionId: 'conn-z',
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-z',
            name: 'Zebra Key',
            key: 'key',
            modelId: 'model-z',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
          ),
          modelsProvider: const ApiModelProviderEntity(
            id: 'zebra',
            name: 'Zebra',
            type: null,
          ),
        ),
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-apple',
            modelId: 'model-a',
            createdAt: now,
            updatedAt: now,
            modelConnectionId: 'conn-a',
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-a',
            name: 'Apple Key',
            key: 'key',
            modelId: 'model-a',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
          ),
          modelsProvider: const ApiModelProviderEntity(
            id: 'apple',
            name: 'Apple',
            type: null,
          ),
        ),
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: WorkspaceModelSelectionEntity(
            id: 'sel-microsoft',
            modelId: 'model-m',
            createdAt: now,
            updatedAt: now,
            modelConnectionId: 'conn-m',
          ),
          modelConnection: ModelConnectionEntity(
            id: 'conn-m',
            name: 'Microsoft Key',
            key: 'key',
            modelId: 'model-m',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
          ),
          modelsProvider: const ApiModelProviderEntity(
            id: 'microsoft',
            name: 'Microsoft',
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

      final provider = listModelsGroupedByProviderProvider(workspaceId: 'ws-1');
      final subscription = container.listen(provider, (_, _) {
        final _ = Object();
      });
      addTearDown(subscription.close);

      final result = await container.read(provider.future);

      expect(result.keys, equals(['Apple', 'Microsoft', 'Zebra']));
      expect(result['Apple'], hasLength(1));
      expect(result['Microsoft'], hasLength(1));
      expect(result['Zebra'], hasLength(1));
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

      final provider = listModelsGroupedByProviderProvider(workspaceId: 'ws-1');
      final subscription = container.listen(provider, (_, _) {
        final _ = Object();
      });
      addTearDown(subscription.close);

      final result = await container.read(provider.future);
      expect(result, isEmpty);
    });
  });
}
