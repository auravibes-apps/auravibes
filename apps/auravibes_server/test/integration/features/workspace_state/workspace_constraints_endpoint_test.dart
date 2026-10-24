import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace constraints', (sessionBuilder, endpoints) {
    test('concurrent unique defaults persist once and rejected schema preserves data', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Constraints',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final tableId = const Uuid().v4().toString();
      final schema = <String, Object?>{
        'name': 'Items',
        'labelColumnId': 'label',
        'schemaRevision': 1,
        'columns': [
          {'id': 'label', 'name': 'Title', 'type': 'text'},
          {
            'id': 'contact',
            'name': 'Contact',
            'type': 'text',
            'defaultValue': 'person@example.com',
          },
          {
            'id': 'value',
            'name': 'Value',
            'type': 'number',
            'required': true,
            'unique': true,
            'defaultValue': 5,
          },
        ],
      };
      Future<PatchWorkspaceStateResponse> patch(
        WorkspacePatchOperation operation,
      ) => endpoints.workspaceState.patch(
        authenticated,
        PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: const Uuid().v4().toString(),
          operations: [operation],
        ),
      );
      await patch(
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .table,
          resourceId: tableId,
          data: jsonEncode(schema),
          fieldMask: const [],
        ),
      );
      final successful = <PatchWorkspaceStateRequest>[];
      Future<bool> create() async {
        try {
          final request = PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: [
              WorkspacePatchOperation(
                operation: .create,
                resourceKind: .tableRecord,
                resourceId: const Uuid().v4().toString(),
                data: jsonEncode({
                  'tableId': tableId,
                  'schemaRevision': 1,
                  'values': <String, Object?>{},
                }),
                fieldMask: const [],
              ),
            ],
          );
          final response = await endpoints.workspaceState.patch(
            authenticated,
            request,
          );
          successful.add(request);
          expect(
            (jsonDecode(response.resources.single.data) as Map)['values'],
            {'value': 5, 'contact': 'person@example.com'},
          );

          return true;
        } on CloudWorkspaceException catch (error) {
          expect(error.code, CloudWorkspaceErrorCode.validationFailed);

          return false;
        }
      }

      final results = await Future.wait([create(), create()]);
      expect(results.where((result) => result).length, 1);
      await expectLater(
        patch(
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: const Uuid().v4().toString(),
            data: jsonEncode({
              'tableId': tableId,
              'schemaRevision': 1,
              'values': {'value': 5.0},
            }),
            fieldMask: const [],
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );
      final replay = await endpoints.workspaceState.patch(
        authenticated,
        successful.single,
      );
      final record = replay.resources.single;
      await expectLater(
        patch(
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: record.resourceId,
            expectedRevision: 1,
            data: jsonEncode({
              'tableId': tableId,
              'schemaRevision': 1,
              'values': <String, Object?>{},
            }),
            fieldMask: const [],
          ),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );

      final safe = {
        ...schema,
        'schemaRevision': 2,
        'columns': [
          {'id': 'label', 'name': 'Title', 'type': 'text'},
          {
            'id': 'value',
            'name': 'Value',
            'type': 'number',
            'required': true,
            'unique': true,
            'defaultValue': 5,
          },
          {
            'id': 'contact',
            'name': 'Contact',
            'type': 'email',
            'defaultValue': 'person@example.com',
          },
        ],
      };
      final converted = await patch(
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .table,
          resourceId: tableId,
          expectedRevision: 1,
          data: jsonEncode(safe),
          fieldMask: const [],
        ),
      );
      expect(converted.resources.single.revision, 2);
      final incompatible = {
        ...schema,
        'schemaRevision': 3,
        'columns': [
          {'id': 'label', 'name': 'Title', 'type': 'text'},
          {'id': 'value', 'name': 'Value', 'type': 'checkbox'},
          {'id': 'contact', 'name': 'Contact', 'type': 'email'},
        ],
      };
      await expectLater(
        patch(
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: tableId,
            expectedRevision: 2,
            data: jsonEncode(incompatible),
            fieldMask: const [],
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );
      final state = await endpoints.workspaceState.read(
        authenticated,
        ReadWorkspaceStateRequest(
          workspaceId: workspace.id!,
          eventLimit: 100,
          pages: [
            WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
          ],
        ),
      );
      final saved = state.pages.single.resources.firstWhere(
        (row) => row.resourceId == tableId,
      );
      expect(saved.revision, 2);
      expect((jsonDecode(saved.data) as Map)['schemaRevision'], 2);
    });
  }, rollbackDatabase: RollbackDatabase.disabled);
}
