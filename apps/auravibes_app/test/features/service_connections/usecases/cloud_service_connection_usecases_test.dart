import 'dart:convert';

import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud create keeps plaintext out of resource metadata', () async {
    Map<String, dynamic>? resourceWrite;
    String? submittedSecret;
    final usecases = CloudServiceConnectionUsecases(
      CloudWorkspaceResourceStore.forTesting(
        patch: ({required requestId, required operations}) async {
          return PatchWorkspaceStateResponse(resources: [], sequence: 1);
        },
        watch: (_) => const Stream.empty(),
        putSecret:
            ({
              required requestId,
              required secretKind,
              required scope,
              required resourceId,
              secret,
              expectedRevision,
            }) async {
              submittedSecret = secret;

              return PutWorkspaceSecretResponse(
                configured: true,
                displaySuffix: 'secret',
                revision: 1,
                sequence: 1,
              );
            },
        mutateCredential:
            ({
              required requestId,
              required resourceOperation,
              required secretKind,
              required scope,
              required secret,
              required clearSecret,
              expectedSecretRevision,
            }) async {
              resourceWrite =
                  jsonDecode(resourceOperation.data ?? '{}')
                      as Map<String, dynamic>;
              submittedSecret = secret;

              return MutateWorkspaceCredentialResponse(
                resource: WorkspaceResource(
                  workspaceId: 1,
                  resourceKind: resourceOperation.resourceKind,
                  resourceId: resourceOperation.resourceId,
                  data: resourceOperation.data ?? '{}',
                  revision: 1,
                  createdAt: DateTime.utc(2026),
                  updatedAt: DateTime.utc(2026),
                ),
                configured: true,
                displaySuffix: 'secret',
                secretRevision: 1,
                sequence: 1,
              );
            },
      ),
    );

    await usecases.create(
      id: 'connection',
      name: 'GitHub',
      serviceId: 'github',
      secretKind: WorkspaceSecretKind.skillCredential,
      scope: WorkspaceSecretScope.user,
      secret: 'secret',
    );

    expect(resourceWrite, isNot(contains('keySuffix')));
    expect(jsonEncode(resourceWrite), isNot(contains('"secret":"secret"')));
    expect(submittedSecret, 'secret');
  });

  test('generic edit sends resource and secret expected revisions', () async {
    int? resourceRevision;
    int? secretRevision;
    Map<String, dynamic>? metadata;
    final usecases = CloudServiceConnectionUsecases(
      CloudWorkspaceResourceStore.forTesting(
        patch: ({required requestId, required operations}) async {
          final operation = operations.single;
          resourceRevision = operation.expectedRevision;
          metadata = jsonDecode(operation.data ?? '{}') as Map<String, dynamic>;

          return PatchWorkspaceStateResponse(resources: [], sequence: 1);
        },
        watch: (_) => const Stream.empty(),
        putSecret:
            ({
              required requestId,
              required secretKind,
              required scope,
              required resourceId,
              secret,
              expectedRevision,
            }) async {
              secretRevision = expectedRevision;

              return PutWorkspaceSecretResponse(
                configured: true,
                displaySuffix: 'secret',
                revision: 8,
                sequence: 2,
              );
            },
        mutateCredential:
            ({
              required requestId,
              required resourceOperation,
              required secretKind,
              required scope,
              required secret,
              required clearSecret,
              expectedSecretRevision,
            }) async {
              resourceRevision = resourceOperation.expectedRevision;
              secretRevision = expectedSecretRevision;
              metadata =
                  jsonDecode(resourceOperation.data ?? '{}')
                      as Map<String, dynamic>;

              return MutateWorkspaceCredentialResponse(
                resource: WorkspaceResource(
                  workspaceId: 1,
                  resourceKind: resourceOperation.resourceKind,
                  resourceId: resourceOperation.resourceId,
                  data: resourceOperation.data ?? '{}',
                  revision: 5,
                  createdAt: DateTime.utc(2026),
                  updatedAt: DateTime.utc(2026),
                ),
                configured: true,
                displaySuffix: 'secret',
                secretRevision: 8,
                sequence: 2,
              );
            },
      ),
    );

    await usecases.updateGeneric(
      connection: const CloudServiceConnection(
        id: 'connection',
        revision: 4,
        name: 'Old',
        serviceId: 'github',
        hasSecret: true,
        scope: WorkspaceSecretScope.workspace,
        kind: 'appSkillCredential',
        secretRevision: 7,
      ),
      update: const GenericServiceConnectionUpdate(
        name: 'New',
        secretEdit: ServiceConnectionSecretEdit.replace,
        secret: 'new-secret',
      ),
    );

    expect(resourceRevision, 4);
    expect(secretRevision, 7);
    expect(metadata, containsPair('name', 'New'));
    expect(metadata, isNot(contains('secretRevision')));
    expect(jsonEncode(metadata), isNot(contains('new-secret')));
  });

  test('stale resource revision stops generic secret replacement', () async {
    var mutationTouched = false;
    final usecases = CloudServiceConnectionUsecases(
      CloudWorkspaceResourceStore.forTesting(
        patch: ({required requestId, required operations}) async {
          throw StateError('stale revision');
        },
        watch: (_) => const Stream.empty(),
        putSecret:
            ({
              required requestId,
              required secretKind,
              required scope,
              required resourceId,
              secret,
              expectedRevision,
            }) async {
              throw StateError('secret must not be touched');
            },
        mutateCredential:
            ({
              required requestId,
              required resourceOperation,
              required secretKind,
              required scope,
              required secret,
              required clearSecret,
              expectedSecretRevision,
            }) async {
              mutationTouched = true;
              throw StateError('stale revision');
            },
      ),
    );

    await expectLater(
      usecases.updateGeneric(
        connection: const CloudServiceConnection(
          id: 'connection',
          revision: 4,
          name: 'Old',
          serviceId: 'github',
          hasSecret: true,
          scope: WorkspaceSecretScope.workspace,
          kind: 'appSkillCredential',
          secretRevision: 7,
        ),
        update: const GenericServiceConnectionUpdate(
          name: 'New',
          secretEdit: ServiceConnectionSecretEdit.clear,
        ),
      ),
      throwsStateError,
    );
    expect(mutationTouched, isTrue);
  });

  test('cloud delete atomically removes metadata and secret', () async {
    WorkspacePatchOperation? mutation;
    final now = DateTime(2026);
    final usecases = CloudServiceConnectionUsecases(
      CloudWorkspaceResourceStore.forTesting(
        patch: ({required requestId, required operations}) async {
          return PatchWorkspaceStateResponse(resources: [], sequence: 2);
        },
        watch: (_) => Stream.value([
          WorkspaceResource(
            workspaceId: 1,
            resourceKind: WorkspaceResourceKind.serviceConnection,
            resourceId: 'connection',
            data:
                '{"name":"GitHub","serviceId":"github",'
                '"scope":"workspace","hasSecret":true,'
                '"secretRevision":3}',
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ]),
        putSecret:
            ({
              required requestId,
              required secretKind,
              required scope,
              required resourceId,
              secret,
              expectedRevision,
            }) async {
              return PutWorkspaceSecretResponse(
                configured: false,
                revision: 4,
                sequence: 3,
              );
            },
        mutateCredential:
            ({
              required requestId,
              required resourceOperation,
              required secretKind,
              required scope,
              required secret,
              required clearSecret,
              expectedSecretRevision,
            }) async {
              mutation = resourceOperation;
              expect(expectedSecretRevision, 3);
              expect(secret, isNull);
              expect(clearSecret, isTrue);

              return MutateWorkspaceCredentialResponse(
                resource: WorkspaceResource(
                  workspaceId: 1,
                  resourceKind: resourceOperation.resourceKind,
                  resourceId: resourceOperation.resourceId,
                  data: '{}',
                  revision: 3,
                  createdAt: now,
                  updatedAt: now,
                ),
                configured: false,
                secretRevision: 4,
                sequence: 3,
              );
            },
      ),
    );

    await usecases.deleteById('connection');

    expect(mutation?.operation, WorkspacePatchOperationKind.delete);
    expect(mutation?.expectedRevision, 2);
  });
}
