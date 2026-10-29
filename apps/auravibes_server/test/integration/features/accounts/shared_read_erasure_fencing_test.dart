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

          final readers = _readers(endpoints, fixture);
          final finishedReads = <String>{};
          final readAttempts = <String, _ReadAttempt>{};
          final readFutures = [
            for (final entry in readers.entries)
              _attemptRead(entry.value).then<void>((attempt) {
                readAttempts[entry.key] = attempt;
                finishedReads.add(entry.key);
              }),
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
          _expectRaceReadAttempts(
            readAttempts,
            expectedNames: readers.keys.toSet(),
            allowedErrorCodes: {
              CloudWorkspaceErrorCode.authenticationRequired,
              CloudWorkspaceErrorCode.emailAccountRequired,
              CloudWorkspaceErrorCode.permissionDenied,
            },
          );
          for (final entry in readers.entries) {
            await _expectAccountReadDenied(entry.key, entry.value);
          }
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

          final readers = _readers(endpoints, fixture);
          final finishedReads = <String>{};
          final readAttempts = <String, _ReadAttempt>{};
          final readFutures = [
            for (final entry in readers.entries)
              _attemptRead(entry.value).then<void>((attempt) {
                readAttempts[entry.key] = attempt;
                finishedReads.add(entry.key);
              }),
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
          _expectRaceReadAttempts(
            readAttempts,
            expectedNames: readers.keys.toSet(),
            allowedErrorCodes: {
              CloudWorkspaceErrorCode.authenticationRequired,
              CloudWorkspaceErrorCode.emailAccountRequired,
              CloudWorkspaceErrorCode.workspaceNotFound,
              CloudWorkspaceErrorCode.membershipRequired,
              CloudWorkspaceErrorCode.permissionDenied,
            },
          );
          for (final entry in readers.entries) {
            if (entry.key == 'workspace list' ||
                entry.key == 'pending invites') {
              continue;
            }
            await _expectWorkspaceReadDenied(entry.key, entry.value);
          }
          final remainingWorkspaces =
              await readers['workspace list']!() as List<CloudWorkspaceSummary>;
          expect(
            remainingWorkspaces.map((workspace) => workspace.id),
            isNot(contains(fixture.workspace.id)),
          );
          final remainingInvites =
              await readers['pending invites']!()
                  as List<PendingWorkspaceInviteSummary>;
          expect(
            remainingInvites.map((invite) => invite.workspaceId),
            isNot(contains(fixture.workspace.id)),
          );
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

Map<String, Future<Object?> Function()> _readers(
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
    'object describe': () => endpoints.object.describe(
      fixture.authenticated,
      GetDownloadRequest(
        workspaceId: workspaceId,
        objectId: fixture.objectId,
      ),
    ),
    'agent list': () => endpoints.agentCatalog.list(
      fixture.authenticated,
      ListAgentsRequest(workspaceId: workspaceId, search: '', limit: 20),
    ),
    'agent resources': () => endpoints.agentCatalog.getResources(
      fixture.authenticated,
      GetAgentResourcesRequest(
        workspaceId: workspaceId,
        agentId: 'read-agent',
      ),
    ),
    'workspace list': () => endpoints.cloudWorkspace.listAuthorizedWorkspaces(
      fixture.authenticated,
    ),
    'pending invites': () =>
        endpoints.cloudWorkspace.listPendingInvites(fixture.authenticated),
    'workspace detail': () => endpoints.cloudWorkspace.getWorkspaceDetail(
      fixture.authenticated,
      GetCloudWorkspaceDetailRequest(workspaceId: workspaceId),
    ),
    'workspace members': () => endpoints.cloudWorkspace.listMembers(
      fixture.authenticated,
      ListWorkspaceMembersRequest(workspaceId: workspaceId),
    ),
    'workspace invites': () => endpoints.cloudWorkspace.listWorkspaceInvites(
      fixture.authenticated,
      ListCloudWorkspaceInvitesRequest(workspaceId: workspaceId),
    ),
    'workspace stream': () => _firstWorkspaceEvent(
      endpoints.workspaceStream.subscribe(
        fixture.authenticated,
        WorkspaceSubscribeRequest(
          workspaceId: workspaceId,
          afterSequence: 0,
          activeTurnIds: const [],
        ),
      ),
    ),
    'record query': () => endpoints.workspaceState.queryRecords(
      fixture.authenticated,
      workspaceId,
      'read-table',
      '{}',
    ),
    'reference targets': () => endpoints.workspaceReference.tableTargets(
      fixture.authenticated,
      WorkspaceReferenceTableRequest(
        workspaceId: workspaceId,
        tableId: 'read-table',
      ),
    ),
    'trash list': () =>
        endpoints.workspaceTrash.list(fixture.authenticated, workspaceId),
    'deleted reference': () => endpoints.workspaceTrash.deletedReference(
      fixture.authenticated,
      workspaceId,
      'read-table',
      'read-record',
    ),
    'history policy': () => endpoints.workspaceHistory.policy(
      fixture.authenticated,
      workspaceId,
    ),
    'history': () => endpoints.workspaceHistory.history(
      fixture.authenticated,
      workspaceId,
      target,
    ),
    'content reports': () => endpoints.workspaceContentReport.list(
      fixture.authenticated,
      workspaceId,
    ),
  };
}

Future<Object?> _firstWorkspaceEvent(
  Stream<WorkspaceStreamEnvelope> stream,
) async {
  final first = Completer<Object?>();
  final ended = Completer<void>();
  final errors = <Object>[];
  StackTrace? firstStack;
  late StreamSubscription<WorkspaceStreamEnvelope> subscription;
  subscription = stream.listen(
    (value) {
      if (!first.isCompleted) first.complete(value);
    },
    onError: (Object error, StackTrace stack) {
      errors.add(error);
      firstStack ??= stack;
      if (!first.isCompleted) first.complete(null);
    },
    onDone: ended.complete,
  );
  final result = await first.future;
  if (errors.isNotEmpty) {
    await ended.future.timeout(const Duration(seconds: 5));
  } else {
    await subscription.cancel();
  }
  if (errors.isNotEmpty) {
    // The generated test transport emits a close error after the source error.
    expect(errors.skip(1), everyElement(isA<ConnectionClosedException>()));
    Error.throwWithStackTrace(errors.first, firstStack!);
  }
  return result;
}

typedef _Reader = Future<Object?> Function();

Future<_ReadAttempt> _attemptRead(_Reader reader) async {
  try {
    return _ReadAttempt.success(await reader());
  } catch (error) {
    return _ReadAttempt.failure(error);
  }
}

void _expectRaceReadAttempts(
  Map<String, _ReadAttempt> attempts, {
  required Set<String> expectedNames,
  required Set<CloudWorkspaceErrorCode> allowedErrorCodes,
}) {
  expect(attempts.keys, expectedNames);
  for (final entry in attempts.entries) {
    final error = entry.value.error;
    if (error == null) {
      expect(entry.value.result, isNotNull, reason: entry.key);
      continue;
    }
    if (entry.key == 'object describe' && error is ObjectException) {
      expect(error.code, ObjectErrorCode.objectNotFound, reason: entry.key);
      continue;
    }
    expect(
      error,
      isA<CloudWorkspaceException>().having(
        (exception) => exception.code,
        'code',
        predicate(allowedErrorCodes.contains),
      ),
      reason: '${entry.key} completed with an unexpected error',
    );
  }
}

Future<void> _expectAccountReadDenied(String name, _Reader reader) async {
  await expectLater(
    reader(),
    throwsA(
      isA<CloudWorkspaceException>().having(
        (exception) => exception.code,
        'code',
        anyOf(
          CloudWorkspaceErrorCode.authenticationRequired,
          CloudWorkspaceErrorCode.emailAccountRequired,
        ),
      ),
    ),
    reason: '$name remained readable after account deletion',
  );
}

Future<void> _expectWorkspaceReadDenied(String name, _Reader reader) async {
  final workspaceDenied = isA<CloudWorkspaceException>().having(
    (exception) => exception.code,
    'code',
    anyOf(
      CloudWorkspaceErrorCode.workspaceNotFound,
      CloudWorkspaceErrorCode.membershipRequired,
      CloudWorkspaceErrorCode.permissionDenied,
    ),
  );
  final expectedError = name == 'object describe'
      ? anyOf(
          workspaceDenied,
          isA<ObjectException>().having(
            (exception) => exception.code,
            'code',
            ObjectErrorCode.objectNotFound,
          ),
        )
      : workspaceDenied;
  await expectLater(
    reader(),
    throwsA(expectedError),
    reason: '$name remained readable after workspace erasure',
  );
}

class _ReadAttempt {
  const _ReadAttempt.success(this.result) : error = null;

  const _ReadAttempt.failure(this.error) : result = null;

  final Object? result;
  final Object? error;
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
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  }) async {}

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
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
  Future<void> delete(String key, {String? registrationId}) async {}

  @override
  Future<ObjectMetadata?> head(String key, {String? registrationId}) async =>
      null;

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async => throw UnimplementedError();

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async => false;
}
