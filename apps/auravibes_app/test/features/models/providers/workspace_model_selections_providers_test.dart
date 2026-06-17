import 'dart:async';

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeApiModelRepository implements ApiModelRepository {
  const _FakeApiModelRepository({
    this.providers = const [],
    this.models = const [],
  });

  final List<ApiModelProviderEntity> providers;
  final List<ApiModelEntity> models;

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() async => providers;

  @override
  Stream<List<ApiModelProviderEntity>> watchAllProviders() {
    return Stream.value(providers);
  }

  @override
  Future<List<ApiModelEntity>> getAllModels() async => models;

  @override
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  ) async {
    return models.where((model) {
      return model.modelProvider == providerId && model.id == modelId;
    }).firstOrNull;
  }

  @override
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId) async {
    return models.where((model) => model.modelProvider == providerId).toList();
  }

  @override
  Stream<List<ApiModelEntity>> watchModelsByProvider(String providerId) {
    return Stream.value(
      models.where((model) => model.modelProvider == providerId).toList(),
    );
  }

  @override
  Future<List<ApiModelProviderEntity>> getProvidersByType(String type) {
    throw UnimplementedError();
  }

  @override
  Future<List<ApiModelProviderEntity>> batchUpsertProviders(
    List<ApiModelProviderEntity> providers,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<ApiModelEntity>> batchUpsertModels(List<ApiModelEntity> models) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteAllData() {
    throw UnimplementedError();
  }
}

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

WorkspaceModelSelectionWithConnectionEntity _makeSelection({
  required String selectionId,
  required String modelConnectionId,
  required String modelConnectionName,
  required String providerId,
  required String providerName,
  String? modelId,
  String? connectionProviderId,
}) {
  final now = DateTime(2026);

  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: WorkspaceModelSelectionEntity(
      id: selectionId,
      modelId: modelId ?? 'model-$selectionId',
      createdAt: now,
      updatedAt: now,
      modelConnectionId: modelConnectionId,
    ),
    modelConnection: ModelConnectionEntity(
      id: modelConnectionId,
      name: modelConnectionName,
      key: 'key',
      modelId: connectionProviderId ?? modelId ?? 'model-$selectionId',
      createdAt: now,
      updatedAt: now,
      workspaceId: 'ws-1',
    ),
    modelsProvider: ApiModelProviderEntity(
      id: providerId,
      name: providerName,
      type: null,
    ),
  );
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
          apiModelRepositoryProvider.overrideWithValue(
            const _FakeApiModelRepository(),
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
          apiModelRepositoryProvider.overrideWithValue(
            const _FakeApiModelRepository(),
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

    test('filters unsupported Codex selections while loading models', () async {
      final selections = [
        _makeSelection(
          selectionId: 'sel-codex-ok',
          modelConnectionId: 'conn-codex',
          modelConnectionName: 'Codex',
          providerId: 'openai',
          providerName: 'OpenAI',
          modelId: 'gpt-5.5',
          connectionProviderId: openAICodexProviderId,
        ),
        _makeSelection(
          selectionId: 'sel-codex-old',
          modelConnectionId: 'conn-codex',
          modelConnectionName: 'Codex',
          providerId: 'openai',
          providerName: 'OpenAI',
          modelId: 'gpt-3.5-turbo',
          connectionProviderId: openAICodexProviderId,
        ),
      ];
      const openAIProvider = ApiModelProviderEntity(
        id: 'openai',
        name: 'OpenAI',
        type: ModelProvidersType.openai,
      );
      const openAIModels = [
        ApiModelEntity(
          modelProvider: 'openai',
          id: 'gpt-5.5',
          name: 'GPT-5.5',
          limitContext: 1050000,
          limitOutput: 128000,
          modalitiesInput: ['text'],
          modalitiesOuput: ['text'],
          supportsPriorityMode: true,
        ),
        ApiModelEntity(
          modelProvider: 'openai',
          id: 'gpt-3.5-turbo',
          name: 'GPT-3.5 Turbo',
          limitContext: 16385,
          limitOutput: 4096,
          modalitiesInput: ['text'],
          modalitiesOuput: ['text'],
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository(selections),
          ),
          apiModelRepositoryProvider.overrideWithValue(
            const _FakeApiModelRepository(
              providers: [openAIProvider],
              models: openAIModels,
            ),
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

      expect(
        result.map((model) => model.workspaceModelSelection.modelId),
        ['gpt-5.5'],
      );
      expect(result.single.modelsProvider.id, 'openai-codex');
    });
  });

  group('listModelsGroupedByProviderProvider', () {
    test('groups models by model connection id', () async {
      final selections = [
        _makeSelection(
          selectionId: 'sel-1',
          modelConnectionId: 'conn-1',
          modelConnectionName: 'OpenAI Key',
          providerId: 'openai',
          providerName: 'OpenAI',
          modelId: 'gpt-4',
        ),
        _makeSelection(
          selectionId: 'sel-2',
          modelConnectionId: 'conn-2',
          modelConnectionName: 'Anthropic Key',
          providerId: 'anthropic',
          providerName: 'Anthropic',
          modelId: 'claude-3',
        ),
        _makeSelection(
          selectionId: 'sel-3',
          modelConnectionId: 'conn-3',
          modelConnectionName: 'OpenAI Key 2',
          providerId: 'openai',
          providerName: 'OpenAI',
          modelId: 'gpt-4o',
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository(selections),
          ),
          apiModelRepositoryProvider.overrideWithValue(
            const _FakeApiModelRepository(),
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

      expect(result.keys, equals(['conn-2', 'conn-1', 'conn-3']));
      expect(result['conn-1'], hasLength(1));
      expect(result['conn-2'], hasLength(1));
      expect(result['conn-3'], hasLength(1));
    });

    test('keeps multiple credentials for the same provider separate', () async {
      final selections = [
        _makeSelection(
          selectionId: 'sel-1',
          modelConnectionId: 'anthropic-work',
          modelConnectionName: 'Work API Key',
          providerId: 'anthropic',
          providerName: 'Anthropic',
          modelId: 'claude-sonnet-4',
        ),
        _makeSelection(
          selectionId: 'sel-2',
          modelConnectionId: 'anthropic-personal',
          modelConnectionName: 'Personal API Key',
          providerId: 'anthropic',
          providerName: 'Anthropic',
          modelId: 'claude-opus-4',
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository(selections),
          ),
          apiModelRepositoryProvider.overrideWithValue(
            const _FakeApiModelRepository(),
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

      expect(result.keys, equals(['anthropic-personal', 'anthropic-work']));
      expect(
        result['anthropic-personal']?.single.modelConnection.name,
        'Personal API Key',
      );
      expect(
        result['anthropic-work']?.single.modelConnection.name,
        'Work API Key',
      );
    });

    test(
      'keeps duplicate credential names separate by connection id',
      () async {
        final selections = [
          _makeSelection(
            selectionId: 'sel-1',
            modelConnectionId: 'anthropic-a',
            modelConnectionName: 'Default',
            providerId: 'anthropic',
            providerName: 'Anthropic',
          ),
          _makeSelection(
            selectionId: 'sel-2',
            modelConnectionId: 'anthropic-b',
            modelConnectionName: 'Default',
            providerId: 'anthropic',
            providerName: 'Anthropic',
          ),
        ];
        final container = ProviderContainer(
          overrides: [
            workspaceModelSelectionRepositoryProvider.overrideWithValue(
              _FakeWorkspaceModelSelectionRepository(selections),
            ),
            apiModelRepositoryProvider.overrideWithValue(
              const _FakeApiModelRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final provider = listModelsGroupedByProviderProvider(
          workspaceId: 'ws-1',
        );
        final subscription = container.listen(provider, (_, _) {
          final _ = Object();
        });
        addTearDown(subscription.close);

        final result = await container.read(provider.future);

        expect(result.keys, equals(['anthropic-a', 'anthropic-b']));
        expect(
          result['anthropic-a']?.single.workspaceModelSelection.id,
          'sel-1',
        );
        expect(
          result['anthropic-b']?.single.workspaceModelSelection.id,
          'sel-2',
        );
      },
    );

    test(
      'sorts provider groups by provider name then credential name',
      () async {
        final selections = [
          _makeSelection(
            selectionId: 'sel-zebra',
            modelConnectionId: 'conn-z',
            modelConnectionName: 'Zebra Key',
            providerId: 'zebra',
            providerName: 'Zebra',
          ),
          _makeSelection(
            selectionId: 'sel-work',
            modelConnectionId: 'conn-work',
            modelConnectionName: 'Work Key',
            providerId: 'anthropic',
            providerName: 'Anthropic',
          ),
          _makeSelection(
            selectionId: 'sel-personal',
            modelConnectionId: 'conn-personal',
            modelConnectionName: 'Personal Key',
            providerId: 'anthropic',
            providerName: 'Anthropic',
          ),
        ];
        final container = ProviderContainer(
          overrides: [
            workspaceModelSelectionRepositoryProvider.overrideWithValue(
              _FakeWorkspaceModelSelectionRepository(selections),
            ),
            apiModelRepositoryProvider.overrideWithValue(
              const _FakeApiModelRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final provider = listModelsGroupedByProviderProvider(
          workspaceId: 'ws-1',
        );
        final subscription = container.listen(provider, (_, _) {
          final _ = Object();
        });
        addTearDown(subscription.close);

        final result = await container.read(provider.future);

        expect(result.keys, equals(['conn-personal', 'conn-work', 'conn-z']));
        expect(result['conn-personal'], hasLength(1));
        expect(result['conn-work'], hasLength(1));
        expect(result['conn-z'], hasLength(1));
      },
    );

    test('returns empty map when no selections', () async {
      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            _FakeWorkspaceModelSelectionRepository(),
          ),
          apiModelRepositoryProvider.overrideWithValue(
            const _FakeApiModelRepository(),
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
