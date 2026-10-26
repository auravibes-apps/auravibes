import 'dart:async';
import 'dart:convert';

import 'package:auravibes_server/src/features/objects/object_scanner.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:auravibes_server/src/features/objects/object_use_cases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/auth_services_test_helper.dart';
import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Shared read erasure fencing',
    (builder, endpoints) {
      test(
        'shared workspace readers wait for account deletion',
        () async {
          final fixture = await _createFixture(builder, ownerIsActor: false);
          initializeTestAuthServices(fixture.session.serverpod);
          final lockSession = builder.build();
          final acquired = Completer<void>();
          final release = Completer<void>();
          final holding = lockSession.db.transaction((transaction) async {
            final user = await AuthUser.db.findById(
              lockSession,
              UuidValue.fromString(fixture.userId),
              transaction: transaction,
              lockMode: LockMode.forUpdate,
            );
            expect(user, isNotNull);
            acquired.complete();
            await release.future;
          });
          await acquired.future.timeout(const Duration(seconds: 5));

          final finishedReads = <String>{};
          final readers = _readers(endpoints, fixture);
          final readFutures = [
            for (final entry in readers.entries)
              entry.value().then<void>(
                (_) {
                  finishedReads.add(entry.key);
                },
                onError: (Object _, StackTrace _) {
                  finishedReads.add(entry.key);
                },
              ),
          ];
          Object? deletionError;
          var deletionFinished = false;
          final deletion = endpoints.account
              .deleteCurrentUser(fixture.authenticated)
              .then<void>(
                (_) => deletionFinished = true,
                onError: (Object error, StackTrace _) {
                  deletionError = error;
                  deletionFinished = true;
                },
              );

          try {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            expect(finishedReads, isEmpty);
            expect(deletionFinished, isFalse);
          } finally {
            release.complete();
          }
          await holding.timeout(const Duration(seconds: 10));
          await Future.wait([deletion, ...readFutures]).timeout(
            const Duration(seconds: 20),
          );

          expect(deletionError, isNull);
          expect(
            await AuthUser.db.findById(
              fixture.session,
              UuidValue.fromString(fixture.userId),
            ),
            isNull,
          );
          expect(finishedReads, readers.keys.toSet());
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test(
        'shared workspace readers wait for workspace erasure',
        () async {
          final fixture = await _createFixture(builder, includeObject: false);
          final lockSession = builder.build();
          final acquired = Completer<void>();
          final release = Completer<void>();
          final holding = lockSession.db.transaction((transaction) async {
            final workspace = await CloudWorkspace.db.findFirstRow(
              lockSession,
              where: (row) =>
                  row.id.equals(fixture.workspace.id!) &
                  row.deletedAt.equals(null) &
                  row.erasureRequestedAt.equals(null),
              transaction: transaction,
              lockMode: LockMode.forUpdate,
            );
            expect(workspace, isNotNull);
            acquired.complete();
            await release.future;
          });
          await acquired.future.timeout(const Duration(seconds: 5));

          final finishedReads = <String>{};
          final readers = _readers(endpoints, fixture);
          final readFutures = [
            for (final entry in readers.entries)
              entry.value().then<void>(
                (_) {
                  finishedReads.add(entry.key);
                },
                onError: (Object _, StackTrace _) {
                  finishedReads.add(entry.key);
                },
              ),
          ];
          Object? erasureError;
          var erasureFinished = false;
          final erasure = endpoints.cloudWorkspace
              .eraseWorkspace(
                fixture.authenticated,
                EraseCloudWorkspaceRequest(
                  workspaceId: fixture.workspace.id!,
                  confirmationName: fixture.workspace.name,
                  requestId: const Uuid().v4().toString(),
                  expectedWorkspaceRevision: fixture.workspace.revision,
                ),
              )
              .then<void>(
                (_) => erasureFinished = true,
                onError: (Object error, StackTrace _) {
                  erasureError = error;
                  erasureFinished = true;
                },
              );

          try {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            expect(finishedReads, isEmpty);
            expect(erasureFinished, isFalse);
          } finally {
            release.complete();
          }
          await holding.timeout(const Duration(seconds: 10));
          await Future.wait([erasure, ...readFutures]).timeout(
            const Duration(seconds: 30),
          );

          expect(erasureError, isNull);
          expect(erasureFinished, isTrue);
          expect(finishedReads, readers.keys.toSet());
        },
        timeout: const Timeout(Duration(seconds: 45)),
      );

      test(
        'download signing releases its transaction before remote completion',
        () async {
          final fixture = await _createFixture(builder, ownerIsActor: false);
          initializeTestAuthServices(fixture.session.serverpod);
          final store = _BlockingSigner();
          final objects = ObjectUseCases(
            store: store,
            scanner: const UnconfiguredObjectScanner(),
          );
          final download = objects.getDownload(
            fixture.session,
            userId: fixture.userId,
            request: GetDownloadRequest(
              workspaceId: fixture.workspace.id!,
              objectId: fixture.objectId,
            ),
          );
          await store.started.future.timeout(const Duration(seconds: 5));

          try {
            await endpoints.account
                .deleteCurrentUser(fixture.authenticated)
                .timeout(const Duration(seconds: 10));
          } finally {
            store.release.complete();
          }
          expect((await download).downloadUrl, 'https://example.invalid/read');
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

Map<String, Future<void> Function()> _readers(
  TestEndpoints endpoints,
  _Fixture fixture,
) {
  final workspaceId = fixture.workspace.id!;
  final target = jsonEncode({
    'kind': 'table',
    'id': 'read-table',
    'revision': 1,
  });
  return {
    'object describe': () async {
      await endpoints.object.describe(
        fixture.authenticated,
        GetDownloadRequest(
          workspaceId: workspaceId,
          objectId: fixture.objectId,
        ),
      );
    },
    'agent list': () async {
      await endpoints.agentCatalog.list(
        fixture.authenticated,
        ListAgentsRequest(workspaceId: workspaceId, search: '', limit: 20),
      );
    },
    'agent resources': () async {
      await endpoints.agentCatalog.getResources(
        fixture.authenticated,
        GetAgentResourcesRequest(
          workspaceId: workspaceId,
          agentId: 'read-agent',
        ),
      );
    },
    'workspace list': () async {
      await endpoints.cloudWorkspace.listAuthorizedWorkspaces(
        fixture.authenticated,
      );
    },
    'pending invites': () async {
      await endpoints.cloudWorkspace.listPendingInvites(fixture.authenticated);
    },
    'workspace detail': () async {
      await endpoints.cloudWorkspace.getWorkspaceDetail(
        fixture.authenticated,
        GetCloudWorkspaceDetailRequest(workspaceId: workspaceId),
      );
    },
    'workspace members': () async {
      await endpoints.cloudWorkspace.listMembers(
        fixture.authenticated,
        ListWorkspaceMembersRequest(workspaceId: workspaceId),
      );
    },
    'workspace invites': () async {
      await endpoints.cloudWorkspace.listWorkspaceInvites(
        fixture.authenticated,
        ListCloudWorkspaceInvitesRequest(workspaceId: workspaceId),
      );
    },
    'workspace stream': () async {
      await endpoints.workspaceStream
          .subscribe(
            fixture.authenticated,
            WorkspaceSubscribeRequest(
              workspaceId: workspaceId,
              afterSequence: 0,
              activeTurnIds: const [],
            ),
          )
          .first;
    },
    'record query': () async {
      await endpoints.workspaceState.queryRecords(
        fixture.authenticated,
        workspaceId,
        'read-table',
        '{}',
      );
    },
    'reference targets': () async {
      await endpoints.workspaceReference.tableTargets(
        fixture.authenticated,
        WorkspaceReferenceTableRequest(
          workspaceId: workspaceId,
          tableId: 'read-table',
        ),
      );
    },
    'trash list': () async {
      await endpoints.workspaceTrash.list(fixture.authenticated, workspaceId);
    },
    'deleted reference': () async {
      await endpoints.workspaceTrash.deletedReference(
        fixture.authenticated,
        workspaceId,
        'read-table',
        'read-record',
      );
    },
    'history policy': () async {
      await endpoints.workspaceHistory.policy(
        fixture.authenticated,
        workspaceId,
      );
    },
    'history': () async {
      await endpoints.workspaceHistory.history(
        fixture.authenticated,
        workspaceId,
        target,
      );
    },
    'content reports': () async {
      await endpoints.workspaceContentReport.list(
        fixture.authenticated,
        workspaceId,
      );
    },
  };
}

Future<_Fixture> _createFixture(
  TestSessionBuilder builder, {
  bool includeObject = true,
  bool ownerIsActor = true,
}) async {
  final userId = const Uuid().v4().toString();
  final email = '$userId@example.invalid';
  final authenticated = builder.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(userId, const {}),
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
      email: email,
      passwordHash: 'unused',
    ),
  );
  final workspace = await workspace_repo.CloudWorkspaceRepository()
      .createWorkspace(
        session,
        name: 'Read fencing',
        ownerUserId: ownerIsActor ? userId : const Uuid().v4().toString(),
        now: DateTime.now().toUtc(),
      );
  final now = DateTime.now().toUtc();
  if (!ownerIsActor) {
    await WorkspaceMember.db.insertRow(
      session,
      WorkspaceMember(
        workspaceId: workspace.id!,
        userId: userId,
        role: 'member',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  final object = includeObject
      ? await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/read-fence/$userId',
            purpose: 'workspace_asset',
            displayName: 'read.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'a' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        )
      : null;
  final tableData = jsonEncode({
    'name': 'Read table',
    'labelColumnId': 'label',
    'schemaRevision': 1,
    'columns': [
      {'id': 'label', 'name': 'Name', 'type': 'text'},
    ],
  });
  await WorkspaceResource.db.insert(
    session,
    [
      if (object != null)
        WorkspaceResource(
          workspaceId: workspace.id!,
          resourceKind: WorkspaceResourceKind.file,
          resourceId: 'read-file',
          data: jsonEncode({'name': 'read.txt', 'assetId': '${object.id}'}),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      WorkspaceResource(
        workspaceId: workspace.id!,
        resourceKind: WorkspaceResourceKind.agent,
        resourceId: 'read-agent',
        data: jsonEncode({
          'name': 'Read agent',
          'description': 'Synthetic fixture',
          'isEnabled': true,
          'visibility': 'both',
        }),
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      WorkspaceResource(
        workspaceId: workspace.id!,
        resourceKind: WorkspaceResourceKind.table,
        resourceId: 'read-table',
        data: tableData,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      WorkspaceResource(
        workspaceId: workspace.id!,
        resourceKind: WorkspaceResourceKind.tableRecord,
        resourceId: 'read-record',
        data: jsonEncode({
          'tableId': 'read-table',
          'schemaRevision': 1,
          'values': {'label': 'Synthetic record'},
        }),
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
  await WorkspaceRevision.db.insertRow(
    session,
    WorkspaceRevision(
      workspaceId: workspace.id!,
      resourceKind: WorkspaceResourceKind.table,
      resourceId: 'read-table',
      revision: 1,
      data: tableData,
      capturedAt: now,
      actorUserId: userId,
      aiInvolved: false,
      operation: 'create',
    ),
  );
  await WorkspaceEvent.db.insertRow(
    session,
    WorkspaceEvent(
      eventId: const Uuid().v4().toString(),
      workspaceId: workspace.id!,
      sequence: 1,
      actorUserId: userId,
      kind: 'resourceUpdated',
      resourceKind: 'workspace',
      createdAt: now,
    ),
  );
  await WorkspaceInvite.db.insertRow(
    session,
    WorkspaceInvite(
      workspaceId: workspace.id!,
      email: email,
      normalizedEmail: email.toLowerCase(),
      role: 'member',
      invitedByUserId: userId,
      revision: 1,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(const Duration(days: 1)),
      pendingKey: '${workspace.id}:${email.toLowerCase()}',
    ),
  );
  return _Fixture(
    authenticated: authenticated,
    session: session,
    userId: userId,
    workspace: workspace,
    objectId: object?.id ?? -1,
  );
}

class _Fixture {
  const _Fixture({
    required this.authenticated,
    required this.session,
    required this.userId,
    required this.workspace,
    required this.objectId,
  });

  final TestSessionBuilder authenticated;
  final Session session;
  final String userId;
  final CloudWorkspace workspace;
  final int objectId;
}

class _BlockingSigner implements ObjectStore {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  }) async {
    started.complete();
    await release.future;
    return SignedObjectRequest(
      url: Uri.parse('https://example.invalid/read'),
      headers: const {},
      expiresAt: DateTime.now().toUtc().add(expiresIn),
    );
  }

  @override
  Future<void> delete(String key) async {}

  @override
  Future<ObjectMetadata?> head(String key) async => null;

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required Duration expiresIn,
  }) async => throw UnimplementedError();
}
