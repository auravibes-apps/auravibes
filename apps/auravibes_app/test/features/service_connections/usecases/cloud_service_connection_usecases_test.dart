import 'dart:convert';

import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud create keeps plaintext out of resource metadata', () async {
    Map<String, dynamic>? resourceWrite;
    String? submittedSecret;
    final usecases = CloudServiceConnectionUsecases(
      .forTesting(
        patch: ({required requestId, required operations}) async {
          return PatchWorkspaceStateResponse(resources: [], sequence: 1);
        },
        watch: (_) => const Stream.empty(),
        putSecret: (input) async {
          submittedSecret = input.secret;

          return PutWorkspaceSecretResponse(
            configured: true,
            displaySuffix: 'secret',
            revision: 1,
            sequence: 1,
          );
        },
        mutateCredential: (input) async {
          final operation = input.resourceOperation;
          resourceWrite =
              jsonDecode(operation.data ?? '{}') as Map<String, dynamic>;
          submittedSecret = input.secret;

          return MutateWorkspaceCredentialResponse(
            resource: .new(
              workspaceId: 1,
              resourceKind: operation.resourceKind,
              resourceId: operation.resourceId,
              data: operation.data ?? '{}',
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
      secretKind: .skillCredential,
      scope: .user,
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
      .forTesting(
        patch: ({required requestId, required operations}) async {
          final operation = operations.single;
          resourceRevision = operation.expectedRevision;
          metadata = jsonDecode(operation.data ?? '{}') as Map<String, dynamic>;

          return PatchWorkspaceStateResponse(resources: [], sequence: 1);
        },
        watch: (_) => const Stream.empty(),
        putSecret: (input) async {
          secretRevision = input.expectedRevision;

          return PutWorkspaceSecretResponse(
            configured: true,
            displaySuffix: 'secret',
            revision: 8,
            sequence: 2,
          );
        },
        mutateCredential: (input) async {
          final operation = input.resourceOperation;
          resourceRevision = operation.expectedRevision;
          secretRevision = input.expectedSecretRevision;
          metadata = jsonDecode(operation.data ?? '{}') as Map<String, dynamic>;

          return MutateWorkspaceCredentialResponse(
            resource: .new(
              workspaceId: 1,
              resourceKind: operation.resourceKind,
              resourceId: operation.resourceId,
              data: operation.data ?? '{}',
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
        scope: .workspace,
        kind: 'appSkillCredential',
        secretRevision: 7,
      ),
      update: const GenericServiceConnectionUpdate(
        name: 'New',
        secretEdit: .replace,
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
      .forTesting(
        patch: ({required requestId, required operations}) async {
          throw StateError('stale revision');
        },
        watch: (_) => const Stream.empty(),
        putSecret: (_) async {
          throw StateError('secret must not be touched');
        },
        mutateCredential: (_) async {
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
          scope: .workspace,
          kind: 'appSkillCredential',
          secretRevision: 7,
        ),
        update: const GenericServiceConnectionUpdate(
          name: 'New',
          secretEdit: .clear,
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
      .forTesting(
        patch: ({required requestId, required operations}) async {
          return PatchWorkspaceStateResponse(resources: [], sequence: 2);
        },
        watch: (_) => Stream.value([
          WorkspaceResource(
            workspaceId: 1,
            resourceKind: .serviceConnection,
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
        putSecret: (_) async {
          return PutWorkspaceSecretResponse(
            configured: false,
            revision: 4,
            sequence: 3,
          );
        },
        mutateCredential: (input) async {
          final operation = input.resourceOperation;
          mutation = operation;
          expect(input.expectedSecretRevision, 3);
          expect(input.secret, isNull);
          expect(input.clearSecret, isTrue);

          return MutateWorkspaceCredentialResponse(
            resource: .new(
              workspaceId: 1,
              resourceKind: operation.resourceKind,
              resourceId: operation.resourceId,
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
