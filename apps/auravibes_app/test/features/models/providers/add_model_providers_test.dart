import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/features/models/providers/add_model_providers.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeModelConnectionRepository implements ModelConnectionRepository {
  ModelConnectionEntity? created;

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate toCreate,
  ) async {
    created = ModelConnectionEntity(
      id: 'new-id',
      name: toCreate.name,
      key: toCreate.key,
      modelId: toCreate.modelId,
      workspaceId: toCreate.workspaceId,
      url: toCreate.url,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    return created!;
  }

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async => const [];

  @override
  Future<ModelConnectionEntity?> getModelConnectionById(String id) async =>
      null;

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToCreate update,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteModelConnection(String id) {
    throw UnimplementedError();
  }
}

void main() {
  group('AddModelProviderState', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(
            _FakeModelConnectionRepository(),
          ),
          apiModelProvidersProvider.overrideWith((ref) async => []),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('build returns default state', () {
      final state = container.read(addModelProviderStateProvider('ws1'));
      expect(state.name, isNull);
      expect(state.modelId, isNull);
      expect(state.key, isNull);
      expect(state.url, isNull);
    });

    test('setName updates name', () {
      container
          .read(addModelProviderStateProvider('ws1').notifier)
          .setName('GPT-4');
      expect(
        container.read(addModelProviderStateProvider('ws1')).name,
        'GPT-4',
      );
    });

    test('setKey updates key', () {
      container
          .read(addModelProviderStateProvider('ws1').notifier)
          .setKey('sk-123');
      expect(
        container.read(addModelProviderStateProvider('ws1')).key,
        'sk-123',
      );
    });

    test('setUrl updates url', () {
      container
          .read(addModelProviderStateProvider('ws1').notifier)
          .setUrl('https://api.example.com');
      expect(
        container.read(addModelProviderStateProvider('ws1')).url,
        'https://api.example.com',
      );
    });

    test('addModelProvider returns null when invalid', () async {
      final result = await container
          .read(addModelProviderStateProvider('ws1').notifier)
          .addModelProvider();
      expect(result, isNull);
    });

    test('addModelProvider creates entity when valid', () async {
      final repo = _FakeModelConnectionRepository();
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          apiModelProvidersProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );
      notifier
        ..setName('GPT-4')
        ..setKey('sk-12345')
        ..setModel(null);

      final result = await notifier.addModelProvider();
      expect(result, isNull);
    });

    test('setModel updates modelId and name from api models', () async {
      final providers = [
        const ApiModelProviderEntity(
          id: 'openai',
          name: 'OpenAI',
          type: null,
        ),
      ];
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(
            _FakeModelConnectionRepository(),
          ),
          apiModelProvidersProvider.overrideWith((ref) async => providers),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );

      await container2.read(apiModelProvidersProvider.future);
      notifier.setModel('openai');

      final state = container2.read(addModelProviderStateProvider('ws1'));
      expect(state.modelId, 'openai');
      expect(state.name, 'OpenAI');
    });

    test('setModel with non-matching id sets modelId without name', () async {
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(
            _FakeModelConnectionRepository(),
          ),
          apiModelProvidersProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );

      await container2.read(apiModelProvidersProvider.future);
      notifier.setModel('nonexistent');

      final state = container2.read(addModelProviderStateProvider('ws1'));
      expect(state.modelId, 'nonexistent');
      expect(state.name, isNull);
    });

    test('setUrl with null clears url', () async {
      final notifier = container.read(
        addModelProviderStateProvider('ws1').notifier,
      );
      notifier
        ..setUrl('https://api.example.com')
        ..setUrl(null);

      expect(
        container.read(addModelProviderStateProvider('ws1')).url,
        isNull,
      );
    });

    test('addModelProvider returns entity on success', () async {
      final repo = _FakeModelConnectionRepository();
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          apiModelProvidersProvider.overrideWith(
            (ref) async => [
              const ApiModelProviderEntity(
                id: 'gpt-4',
                name: 'GPT-4',
                type: null,
              ),
            ],
          ),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );

      await container2.read(apiModelProvidersProvider.future);
      notifier
        ..setKey('sk-valid-key-12345')
        ..setModel('gpt-4');

      final result = await notifier.addModelProvider();
      expect(result, isNotNull);
      expect(result!.modelId, 'gpt-4');
      expect(result.workspaceId, 'ws1');
    });

    test('addModelProvider rethrows repository exception', () async {
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(
            _ThrowingModelConnectionRepository(),
          ),
          apiModelProvidersProvider.overrideWith(
            (ref) async => [
              const ApiModelProviderEntity(
                id: 'gpt-4',
                name: 'GPT-4',
                type: null,
              ),
            ],
          ),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );

      await container2.read(apiModelProvidersProvider.future);
      notifier
        ..setKey('sk-valid-key-12345')
        ..setModel('gpt-4');

      expect(
        notifier.addModelProvider,
        throwsA(isA<Exception>()),
      );
    });

    test('build with different workspaceIds are independent', () async {
      final state1 = container.read(addModelProviderStateProvider('ws1'));
      final state2 = container.read(addModelProviderStateProvider('ws2'));

      container
          .read(addModelProviderStateProvider('ws1').notifier)
          .setName('A');
      container
          .read(addModelProviderStateProvider('ws2').notifier)
          .setName('B');

      expect(container.read(addModelProviderStateProvider('ws1')).name, 'A');
      expect(container.read(addModelProviderStateProvider('ws2')).name, 'B');

      expect(state1.name, isNull);
      expect(state2.name, isNull);
    });
  });
}

class _ThrowingModelConnectionRepository implements ModelConnectionRepository {
  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate toCreate,
  ) async {
    throw Exception('db connection failed');
  }

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async => const [];

  @override
  Future<ModelConnectionEntity?> getModelConnectionById(String id) async =>
      null;

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToCreate update,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteModelConnection(String id) {
    throw UnimplementedError();
  }
}
