import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/data/cloud_model_store.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'does not save a cloud connection when its provider test fails',
    () async {
      var createCalled = false;
      final gateway = CloudModelGateway.forTesting(
        stateGateway: _stateGateway(),
        create: (_) async {
          createCalled = true;

          return throw UnimplementedError();
        },
      );
      final providerServices = _FakeModelProviderServices();
      final store = CloudModelStore(
        'workspace',
        .new(gateway),
        modelProviderServices: providerServices,
      );

      await expectLater(
        store.createModelConnection(
          const ModelConnectionToCreate(
            name: 'OpenAI',
            workspaceId: 'workspace',
            modelId: 'openai',
            key: 'invalid-key',
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(providerServices.wasCalled, isTrue);
      expect(createCalled, isFalse);
    },
  );

  test('saves a cloud connection after its provider test succeeds', () async {
    var createCalled = false;
    String? savedKey;
    final now = DateTime.utc(2026);
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(
        putSecret: (input) async {
          savedKey = input.secret;

          return PutWorkspaceSecretResponse(
            configured: true,
            displaySuffix: '4321',
            revision: 1,
            sequence: 1,
          );
        },
      ),
      create: (request) async {
        createCalled = true;

        return ModelConnectionView(
          id: request.connectionId,
          name: request.name,
          providerId: request.providerId,
          hasSecret: false,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        );
      },
    );
    final providerServices = _FakeModelProviderServices(result: const []);
    final store = CloudModelStore(
      'workspace',
      .new(gateway),
      modelProviderServices: providerServices,
    );

    final result = await store.createModelConnection(
      const ModelConnectionToCreate(
        name: 'OpenAI',
        workspaceId: 'workspace',
        modelId: 'openai',
        key: ' valid-key ',
      ),
    );

    expect(providerServices.lastProvider?.key, 'valid-key');
    expect(savedKey, 'valid-key');
    expect(createCalled, isTrue);
    expect(result.hasKey, isTrue);
  });

  test('verified cloud create skips the duplicate provider request', () async {
    var createCalled = false;
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(
        putSecret: (_) async => PutWorkspaceSecretResponse(
          configured: true,
          displaySuffix: '4321',
          revision: 1,
          sequence: 1,
        ),
      ),
      create: (request) async {
        createCalled = true;
        final now = DateTime.utc(2026);

        return ModelConnectionView(
          id: request.connectionId,
          name: request.name,
          providerId: request.providerId,
          hasSecret: false,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        );
      },
    );
    final providerServices = _FakeModelProviderServices();
    final store = CloudModelStore(
      'workspace',
      .new(gateway),
      modelProviderServices: providerServices,
    );
    const connection = ModelConnectionToCreate(
      name: 'OpenAI',
      workspaceId: 'workspace',
      modelId: 'openai',
      key: 'valid-key',
    );
    final verification = createModelProviderVerification(
      request: const ModelProviderVerificationRequest(
        workspaceId: 'workspace',
        providerId: 'openai',
        connectionId: null,
        expectedRevision: null,
        url: null,
        key: 'valid-key',
      ),
      modelIds: const ['gpt-4o'],
    );

    final _ = await store.createModelConnection(
      connection,
      verification: verification,
    );

    expect(createCalled, isTrue);
    expect(providerServices.wasCalled, isFalse);
  });

  test(
    'does not update a cloud connection when its provider test fails',
    () async {
      var updateCalled = false;
      final now = DateTime.utc(2026);
      final gateway = CloudModelGateway.forTesting(
        stateGateway: _stateGateway(
          readState: (_) async => ReadWorkspaceStateResponse(
            pages: [],
            currentSequence: 1,
            events: [],
            requiresSnapshot: false,
          ),
        ),
        list: (_) async => [
          ModelConnectionView(
            id: 'connection',
            name: 'OpenAI',
            providerId: 'openai',
            hasSecret: true,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        update: (_) async {
          updateCalled = true;

          return throw UnimplementedError();
        },
      );
      final providerServices = _FakeModelProviderServices();
      final store = CloudModelStore(
        'workspace',
        .new(gateway),
        modelProviderServices: providerServices,
      );

      await expectLater(
        store.updateModelConnection(
          'connection',
          const ModelConnectionToUpdate(key: 'invalid-key'),
        ),
        throwsA(isA<StateError>()),
      );

      expect(providerServices.wasCalled, isTrue);
      expect(updateCalled, isFalse);
    },
  );

  test('updates a cloud connection after its provider test succeeds', () async {
    var updateCalled = false;
    String? savedKey;
    final now = DateTime.utc(2026);
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(
        readState: (_) async => ReadWorkspaceStateResponse(
          pages: [],
          currentSequence: 1,
          events: [],
          requiresSnapshot: false,
        ),
        putSecret: (input) async {
          savedKey = input.secret;

          return PutWorkspaceSecretResponse(
            configured: true,
            displaySuffix: '9876',
            revision: 2,
            sequence: 2,
          );
        },
      ),
      list: (_) async => [
        ModelConnectionView(
          id: 'connection',
          name: 'OpenAI',
          providerId: 'openai',
          hasSecret: true,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      update: (request) async {
        updateCalled = true;

        return ModelConnectionView(
          id: request.connectionId,
          name: request.name,
          providerId: 'openai',
          hasSecret: false,
          revision: 2,
          createdAt: now,
          updatedAt: now,
        );
      },
    );
    final providerServices = _FakeModelProviderServices(result: const []);
    final store = CloudModelStore(
      'workspace',
      .new(gateway),
      modelProviderServices: providerServices,
    );

    final result = await store.updateModelConnection(
      'connection',
      const ModelConnectionToUpdate(name: 'Renamed', key: ' new-key '),
    );

    expect(providerServices.lastProvider?.key, 'new-key');
    expect(savedKey, 'new-key');
    expect(updateCalled, isTrue);
    expect(result.name, 'Renamed');
    expect(result.hasKey, isTrue);
  });

  test('verified cloud URL update sends its draft receipt', () async {
    UpdateModelConnectionRequest? updateRequest;
    var draftVerificationCalled = false;
    final now = DateTime.utc(2026);
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(
        readState: (_) async => ReadWorkspaceStateResponse(
          pages: [],
          currentSequence: 1,
          events: [],
          requiresSnapshot: false,
        ),
      ),
      verifyDraft:
          ({required connectionId, required expectedRevision, url}) async {
            draftVerificationCalled = true;
            expect(connectionId, 'connection');
            expect(expectedRevision, 7);
            expect(url, 'https://new.example.com');

            return VerifyModelConnectionResult(
              providerId: 'openai',
              modelIds: const ['gpt-4o'],
              verificationReceipt: 'receipt',
              expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
            );
          },
      list: (_) async => [
        ModelConnectionView(
          id: 'connection',
          name: 'OpenAI',
          providerId: 'openai',
          hasSecret: true,
          revision: 7,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      update: (request) async {
        updateRequest = request;

        return ModelConnectionView(
          id: request.connectionId,
          name: request.name,
          providerId: 'openai',
          hasSecret: true,
          revision: 8,
          createdAt: now,
          updatedAt: now,
        );
      },
    );
    final providerServices = _FakeModelProviderServices();
    final store = CloudModelStore(
      'workspace',
      .new(gateway),
      modelProviderServices: providerServices,
    );
    final verification = await store.verifyModelConnection(
      const ModelProviderVerificationRequest(
        workspaceId: 'workspace',
        providerId: 'openai',
        connectionId: 'connection',
        expectedRevision: 7,
        url: 'https://new.example.com',
        key: null,
      ),
    );

    final _ = await store.updateModelConnection(
      'connection',
      const ModelConnectionToUpdate(
        name: 'Renamed',
        url: 'https://new.example.com',
      ),
      verification: verification,
    );

    expect(draftVerificationCalled, isTrue);
    expect(updateRequest?.verificationReceipt, 'receipt');
    expect(providerServices.wasCalled, isFalse);
  });
}

class _FakeModelProviderServices extends ModelProviderServices {
  new({this.result});

  final List<WorkspaceModelSelectionToCreate>? result;
  bool wasCalled = false;
  ModelProvider? lastProvider;

  @override
  Future<List<WorkspaceModelSelectionToCreate>?> getWorkspaceModelSelections(
    ModelProvider provider,
  ) async {
    wasCalled = true;
    lastProvider = provider;

    return result;
  }
}

CloudWorkspaceStateGateway _stateGateway({
  WorkspaceStateRead? readState,
  WorkspaceSecretPut? putSecret,
}) => CloudWorkspaceStateGateway.forTesting(
  workspace: const CloudWorkspaceRef(
    localWorkspaceId: 'workspace',
    serverUrl: 'https://example.com',
    accountId: 'account',
    cloudWorkspaceId: 1,
  ),
  readState: readState ?? (_) => throw UnimplementedError(),
  subscribe: (_) => const Stream.empty(),
  putSecret: putSecret,
);
