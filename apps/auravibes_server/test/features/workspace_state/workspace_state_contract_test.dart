import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'workspace state contracts stay closed and secret responses are redacted',
    () {
      final operation = WorkspacePatchOperation(
        operation: WorkspacePatchOperationKind.update,
        resourceKind: WorkspaceResourceKind.agent,
        resourceId: 'agent-1',
        data: '{"name":"Agent"}',
        fieldMask: ['name'],
        expectedRevision: 2,
      );
      final secretResponse = PutWorkspaceSecretResponse(
        configured: true,
        displaySuffix: '1234',
        revision: 3,
        sequence: 4,
      );

      expect(operation.toJson()['resourceKind'], 'agent');
      expect(operation.toJson()['operation'], 'update');
      expect(secretResponse.toJson(), isNot(contains('secret')));
      expect(secretResponse.toJson(), isNot(contains('ciphertext')));
      final credentialResponse = MutateWorkspaceCredentialResponse(
        resource: WorkspaceResource(
          workspaceId: 1,
          resourceKind: WorkspaceResourceKind.serviceConnection,
          resourceId: 'connection-1',
          data: '{"name":"GitHub"}',
          revision: 1,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        configured: true,
        displaySuffix: '1234',
        secretRevision: 1,
        sequence: 2,
      );
      expect(credentialResponse.toJson(), isNot(contains('secret')));
      expect(credentialResponse.toJson(), isNot(contains('ciphertext')));
    },
  );
}
