import 'dart:convert';
import 'dart:io';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Synthetic workspace capacity', (sessionBuilder, endpoints) {
    test(
      'measures table writes and page reads',
      () async {
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
              name: 'Synthetic capacity',
              ownerUserId: userId,
              now: DateTime.now().toUtc(),
            );

        Future<PatchWorkspaceStateResponse> patch(
          List<WorkspacePatchOperation> operations,
        ) => endpoints.workspaceState.patch(
          authenticated,
          PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: operations,
          ),
        );
        final columns = [
          for (var i = 0; i < 20; i++)
            {'id': 'column-$i', 'name': 'Column $i', 'type': 'text'},
        ];
        final watch = Stopwatch()..start();
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'benchmark-table',
            fieldMask: const [],
            data: jsonEncode({
              'name': 'Benchmark',
              'labelColumnId': 'column-0',
              'schemaRevision': 1,
              'columns': columns,
            }),
          ),
        ]);
        final tableMs = watch.elapsedMilliseconds;
        for (var batch = 0; batch < 4; batch++) {
          await patch([
            for (var i = 0; i < 25; i++)
              WorkspacePatchOperation(
                operation: .create,
                resourceKind: .tableRecord,
                resourceId: 'record-${batch * 25 + i}',
                fieldMask: const [],
                data: jsonEncode({
                  'tableId': 'benchmark-table',
                  'schemaRevision': 1,
                  'values': {'column-0': 'Record ${batch * 25 + i}'},
                }),
              ),
          ]);
        }
        final writesMs = watch.elapsedMilliseconds - tableMs;
        final readStart = watch.elapsedMilliseconds;
        final response = await endpoints.workspaceState.read(
          authenticated,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: .tableRecord,
                limit: 100,
              ),
            ],
            eventLimit: 0,
          ),
        );
        final readMs = watch.elapsedMilliseconds - readStart;
        expect(response.pages.single.resources, hasLength(100));
        final querySamples = <int>[];
        for (var sample = 0; sample < 10; sample++) {
          final queryTimer = Stopwatch()..start();
          final rows = await endpoints.workspaceState.queryRecords(
            authenticated,
            workspace.id!,
            'benchmark-table',
            jsonEncode({'limit': 100, 'search': 'Record'}),
          );
          queryTimer.stop();
          expect(rows, hasLength(100));
          querySamples.add(queryTimer.elapsedMicroseconds);
        }
        querySamples.sort();
        final queryMedianUs = (querySamples[4] + querySamples[5]) ~/ 2;
        final queryMaxUs = querySamples.last;
        final validationError = isA<CloudWorkspaceException>().having(
          (error) => error.code,
          'code',
          CloudWorkspaceErrorCode.validationFailed,
        );
        await expectLater(
          endpoints.workspaceState.read(
            authenticated,
            ReadWorkspaceStateRequest(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(
                  resourceKind: .tableRecord,
                  limit: 101,
                ),
              ],
              eventLimit: 0,
            ),
          ),
          throwsA(validationError),
        );
        await expectLater(
          endpoints.workspaceState.queryRecords(
            authenticated,
            workspace.id!,
            'benchmark-table',
            jsonEncode({'limit': 101}),
          ),
          throwsA(validationError),
        );
        await expectLater(
          patch([
            for (var i = 0; i < 51; i++)
              WorkspacePatchOperation(
                operation: .create,
                resourceKind: .tableRecord,
                resourceId: 'over-limit-$i',
                fieldMask: const [],
                data: jsonEncode({
                  'tableId': 'benchmark-table',
                  'schemaRevision': 1,
                  'values': <String, Object?>{},
                }),
              ),
          ]),
          throwsA(validationError),
        );
        stdout.writeln(
          'synthetic capacity: columns=20 records=100 batches=4 batchSize=25 page=100 tableMs=$tableMs writesMs=$writesMs readMs=$readMs querySamples=10 queryMedianUs=$queryMedianUs queryMaxUs=$queryMaxUs',
        );
      },
      skip: Platform.environment['AURAVIBES_RUN_CAPACITY_BENCHMARK'] != '1'
          ? 'Opt in to the synthetic capacity benchmark'
          : false,
    );
  });
}
