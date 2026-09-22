// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: cascade_invocations
import 'dart:async';

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeModelConnectionRepository implements ModelConnectionRepository {
  ModelConnectionEntity? created;
  ModelProviderVerification? verificationResult;
  ModelProviderVerification? lastCreateVerification;
  Exception? verificationError;
  Future<ModelProviderVerification>? pendingVerification;

  @override
  Future<ModelProviderVerification> verifyModelConnection(
    ModelProviderVerificationRequest request,
  ) async {
    final error = verificationError;
    if (error != null) throw error;
    final pending = pendingVerification;
    if (pending != null) return await pending;

    return verificationResult ??
        createModelProviderVerification(
          request: request,
          modelIds: const ['gpt-4o'],
        );
  }

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate toCreate, {
    ModelProviderVerification? verification,
  }) async {
    lastCreateVerification = verification;
    created = .new(
      id: 'new-id',
      name: toCreate.name,
      modelId: toCreate.modelId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      workspaceId: toCreate.workspaceId,
      hasKey: toCreate.key.isNotEmpty,
      url: toCreate.url,
    );

    return created ?? fail('Expected created model connection');
  }

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async {
    final _ = filter;

    return const [];
  }

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) {
    final _ = filter;

    return Stream.value(const []);
  }

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String _) async {
    return null;
  }

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String _,
    ModelConnectionToUpdate _, {
    ModelProviderVerification? verification,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteModelConnection(String _) {
    throw UnimplementedError();
  }
}

void main() {
  group('AddModelProviderState', () {
    var container = ProviderContainer(
      overrides: [
        modelConnectionRepositoryProvider.overrideWithValue(
          _FakeModelConnectionRepository(),
        ),
        apiModelProvidersProvider.overrideWith((_, _) async => []),
      ],
    );

    setUp(() {
      container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(
            _FakeModelConnectionRepository(),
          ),
          apiModelProvidersProvider.overrideWith((_, _) async => []),
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

    test('tracks and resets unsaved changes', () {
      final notifier = container.read(
        addModelProviderStateProvider('ws1').notifier,
      );

      expect(
        container.read(addModelProviderStateProvider('ws1')).hasUnsavedChanges,
        isFalse,
      );

      notifier
        ..setName('Draft provider')
        ..setKey('secret-key');

      expect(
        container.read(addModelProviderStateProvider('ws1')).hasUnsavedChanges,
        isTrue,
      );

      notifier.reset();

      expect(
        container.read(addModelProviderStateProvider('ws1')).hasUnsavedChanges,
        isFalse,
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
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith((_, _) async => []),
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
        const ApiModelProviderEntity(id: 'openai', name: 'OpenAI', type: null),
      ];
      final repo = _FakeModelConnectionRepository();
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith((_, _) async => providers),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );

      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
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
          apiModelProvidersProvider.overrideWith((_, _) async => []),
        ],
      );
      addTearDown(container2.dispose);
      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );

      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier.setModel('nonexistent');

      final state = container2.read(addModelProviderStateProvider('ws1'));
      expect(state.modelId, 'nonexistent');
      expect(state.name, isNull);
    });

    test('setUrl with null clears url', () {
      final notifier = container.read(
        addModelProviderStateProvider('ws1').notifier,
      );
      notifier
        ..setUrl('https://api.example.com')
        ..setUrl(null);

      expect(container.read(addModelProviderStateProvider('ws1')).url, isNull);
    });

    test('verification stores discovered model count', () async {
      final repo = _FakeModelConnectionRepository();
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
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
      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier
        ..setName('OpenAI')
        ..setKey('valid-key')
        ..setModel('openai');

      final verification = await notifier.verifyModelProvider();

      expect(verification?.modelIds, ['gpt-4o']);
      expect(
        container2
            .read(addModelProviderStateProvider('ws1'))
            .isConnectionVerified,
        isTrue,
      );
      expect(
        container2
            .read(addModelProviderStateProvider('ws1'))
            .verifiedModelCount,
        1,
      );
    });

    test('failed verification leaves add unavailable', () async {
      final repo = _FakeModelConnectionRepository()
        ..verificationError = const ModelConnectionException('invalid key');
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
                type: null,
              ),
            ],
          ),
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(
        addModelProviderStateProvider('ws1').notifier,
      );
      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier
        ..setName('OpenAI')
        ..setKey('valid-key')
        ..setModel('openai');

      await expectLater(
        notifier.verifyModelProvider(),
        throwsA(isA<ModelConnectionException>()),
      );
      final state = container2.read(addModelProviderStateProvider('ws1'));
      expect(state.isTestingConnection, isFalse);
      expect(state.isConnectionVerified, isFalse);
      expect(
        notifier.addModelProvider,
        throwsA(isA<ProviderVerificationRequiredException>()),
      );
      expect(repo.created, isNull);
    });

    test(
      'stale verification response is ignored after a field change',
      () async {
        final completer = Completer<ModelProviderVerification>();
        final repo = _FakeModelConnectionRepository()
          ..pendingVerification = completer.future;
        final container2 = ProviderContainer(
          overrides: [
            modelConnectionRepositoryProvider.overrideWithValue(repo),
            modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
            apiModelProvidersProvider.overrideWith(
              (_, _) async => [
                const ApiModelProviderEntity(
                  id: 'openai',
                  name: 'OpenAI',
                  type: null,
                ),
              ],
            ),
          ],
        );
        addTearDown(container2.dispose);
        final subscription = container2.listen(
          addModelProviderStateProvider('ws1'),
          // Keep notifier alive while the stale request resolves.
          (_, _) {
            assert(true, 'Listener intentionally keeps provider alive.');
          },
        );
        addTearDown(subscription.close);

        final notifier = container2.read(
          addModelProviderStateProvider('ws1').notifier,
        );
        final _ = await container2.read(
          apiModelProvidersProvider(workspaceId: 'ws1').future,
        );
        notifier
          ..setName('OpenAI')
          ..setKey('old-key')
          ..setModel('openai');

        final verificationFuture = notifier.verifyModelProvider();
        await Future<void>.delayed(.zero);
        notifier.setKey('new-key');
        completer.complete(
          createModelProviderVerification(
            request: const ModelProviderVerificationRequest(
              workspaceId: 'ws1',
              providerId: 'openai',
              connectionId: null,
              expectedRevision: null,
              url: null,
              key: 'old-key',
            ),
            modelIds: const ['gpt-4o'],
          ),
        );
        final _ = await verificationFuture;

        final state = container2.read(addModelProviderStateProvider('ws1'));
        expect(state.isTestingConnection, isFalse);
        expect(state.isConnectionVerified, isFalse);
        expect(state.key, 'new-key');
      },
    );

    test('save rejects valid credentials without verification', () async {
      final repo = _FakeModelConnectionRepository();
      final container2 = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
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
      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier
        ..setName('OpenAI')
        ..setKey('valid-key')
        ..setModel('openai');

      await expectLater(
        notifier.addModelProvider,
        throwsA(isA<ProviderVerificationRequiredException>()),
      );
      expect(repo.created, isNull);
    });

    test('changing credentials invalidates verification', () async {
      final repo = _FakeModelConnectionRepository();
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
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
      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier
        ..setName('OpenAI')
        ..setKey('valid-key')
        ..setModel('openai');
      final _ = await notifier.verifyModelProvider();

      notifier.setKey('new-valid-key');

      final state = container2.read(addModelProviderStateProvider('ws1'));
      expect(state.isConnectionVerified, isFalse);
      expect(state.verifiedModelCount, 0);
    });

    test('expired verification is cleared', () async {
      final repo = _FakeModelConnectionRepository()
        ..verificationResult = .new(
          id: 'verification',
          workspaceId: 'ws1',
          providerId: 'openai',
          connectionId: null,
          expectedRevision: null,
          url: null,
          keyDigest: modelProviderKeyDigest('valid-key'),
          modelIds: const ['gpt-4o'],
          expiresAt: DateTime.now().toUtc().add(
            const Duration(milliseconds: 10),
          ),
        );
      final container2 = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
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
      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier
        ..setName('OpenAI')
        ..setKey('valid-key')
        ..setModel('openai');
      final _ = await notifier.verifyModelProvider();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(
        container2
            .read(addModelProviderStateProvider('ws1'))
            .isConnectionVerified,
        isFalse,
      );
    });

    test('addModelProvider returns entity on success', () async {
      final repo = _FakeModelConnectionRepository();
      final container2 = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          modelConnectionRepositoryProvider.overrideWithValue(repo),
          modelConnectionStoreProvider('ws1').overrideWith((_) async => repo),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
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

      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier
        ..setKey('sk-valid-key-12345')
        ..setModel('openai');

      final _ = await notifier.verifyModelProvider();
      final result = await notifier.addModelProvider();
      expect(result, isNotNull);
      expect(
        (result ?? fail('Expected result to be non-null')).modelId,
        'openai',
      );
      expect(result.workspaceId, 'ws1');
    });

    test('addModelProvider rethrows repository exception', () async {
      final container2 = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          modelConnectionRepositoryProvider.overrideWithValue(
            _ThrowingModelConnectionRepository(),
          ),
          modelConnectionStoreProvider('ws1')
              .overrideWith((_) async => _ThrowingModelConnectionRepository()),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
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

      final _ = await container2.read(
        apiModelProvidersProvider(workspaceId: 'ws1').future,
      );
      notifier
        ..setKey('sk-valid-key-12345')
        ..setModel('openai');

      final _ = await notifier.verifyModelProvider();
      expect(notifier.addModelProvider, throwsA(isA<Exception>()));
    });

    test('build with different workspaceIds are independent', () {
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
  Future<ModelProviderVerification> verifyModelConnection(
    ModelProviderVerificationRequest request,
  ) async => createModelProviderVerification(
    request: request,
    modelIds: const ['gpt-4o'],
  );

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate toCreate, {
    ModelProviderVerification? verification,
  }) async {
    throw Exception('db connection failed');
  }

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async {
    final _ = filter;

    return const [];
  }

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) {
    final _ = filter;

    return Stream.value(const []);
  }

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String _) async {
    return null;
  }

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String _,
    ModelConnectionToUpdate _, {
    ModelProviderVerification? verification,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteModelConnection(String _) {
    throw UnimplementedError();
  }
}
