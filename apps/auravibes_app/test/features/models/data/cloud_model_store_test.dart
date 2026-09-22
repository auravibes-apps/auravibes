import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/data/cloud_model_store.dart';
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
}

class _FakeModelProviderServices extends ModelProviderServices {
  bool wasCalled = false;

  @override
  Future<List<WorkspaceModelSelectionToCreate>?> getWorkspaceModelSelections(
    ModelProvider provider,
  ) async {
    wasCalled = true;

    return null;
  }
}

CloudWorkspaceStateGateway _stateGateway({WorkspaceStateRead? readState}) =>
    CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'workspace',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
      readState: readState ?? (_) => throw UnimplementedError(),
      subscribe: (_) => const Stream.empty(),
    );
