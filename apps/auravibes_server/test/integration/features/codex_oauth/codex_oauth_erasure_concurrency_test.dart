import 'dart:async';

import 'package:auravibes_server/src/features/codex_oauth/repositories/codex_oauth_repository.dart';
import 'package:auravibes_server/src/features/codex_oauth/usecases/codex_oauth_usecases.dart';
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
    'Codex OAuth workspace erasure fencing',
    (builder, endpoints) {
      test('erasure waits for an in-flight OAuth token write', () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        session.passwords['workspaceSecretKey'] =
            'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        session.passwords['openAICodexOAuthClientId'] = 'synthetic-client-id';
        session.passwords['openAICodexOAuthRedirectUri'] =
            'http://localhost/callback';
        await _insertAccount(session, userId);
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'OAuth erasure race',
              ownerUserId: userId,
              now: now,
            );
        const connectionId = 'synthetic-codex-connection';
        final started =
            await CodexOAuthUseCases(
              CodexOAuthRepository(),
            ).start(
              session,
              userId: userId,
              request: StartCodexOAuthRequest(
                workspaceId: workspace.id!,
                connectionId: connectionId,
              ),
            );
        final transactionId = started.transactionId;
        final state = Uri.parse(
          started.authorizationUrl,
        ).queryParameters['state']!;

        final exchangeStarted = Completer<void>();
        final releaseExchange = Completer<void>();
        final completing =
            CodexOAuthUseCases(
              CodexOAuthRepository(),
              exchange: (code, redirectUri, verifier) async {
                expect(code, 'synthetic-code');
                expect(redirectUri, 'http://localhost/callback');
                expect(verifier, isNotEmpty);
                exchangeStarted.complete();
                await releaseExchange.future;
                return const {
                  'access_token': 'synthetic-access-token',
                  'refresh_token': 'synthetic-refresh-token',
                };
              },
            ).complete(
              session,
              userId: userId,
              request: CompleteCodexOAuthRequest(
                transactionId: transactionId,
                state: state,
                code: 'synthetic-code',
              ),
            );
        await exchangeStarted.future.timeout(const Duration(seconds: 5));

        final erasing = endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          EraseCloudWorkspaceRequest(
            workspaceId: workspace.id!,
            confirmationName: workspace.name,
            requestId: const Uuid().v4().toString(),
            expectedWorkspaceRevision: workspace.revision,
          ),
        );
        CloudWorkspace? duringExchange;
        try {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          duringExchange = await CloudWorkspace.db.findById(
            authenticated.build(),
            workspace.id!,
          );
        } finally {
          releaseExchange.complete();
        }

        final completed = await completing.timeout(const Duration(seconds: 10));
        final erasure = await erasing.timeout(const Duration(seconds: 10));
        expect(duringExchange?.deletedAt, isNull);
        expect(duringExchange?.erasureRequestedAt, isNull);
        expect(completed.configured, isTrue);
        expect(erasure.state, 'complete');
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNull,
        );
        expect(
          await WorkspaceSecret.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          isEmpty,
        );
        expect(
          await CodexOAuthTransaction.db.find(
            session,
            where: (row) => row.transactionId.equals(transactionId),
          ),
          isEmpty,
        );
      });

      test(
        'account deletion waits for an in-flight OAuth token write',
        () async {
          final userId = const Uuid().v4().toString();
          final ownerId = const Uuid().v4().toString();
          final authenticated = builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              userId,
              const {},
            ),
          );
          final session = authenticated.build();
          session.passwords['workspaceSecretKey'] =
              'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
          session.passwords['openAICodexOAuthClientId'] = 'synthetic-client-id';
          session.passwords['openAICodexOAuthRedirectUri'] =
              'http://localhost/callback';
          await _insertAccount(session, userId);
          initializeTestAuthServices(session.serverpod);
          final now = DateTime.now().toUtc();
          final workspace = await _createSharedWorkspace(
            session,
            ownerId: ownerId,
            memberId: userId,
            name: 'Account deletion OAuth race',
            now: now,
          );
          const connectionId = 'account-deletion-codex-connection';
          final started =
              await CodexOAuthUseCases(
                CodexOAuthRepository(),
              ).start(
                session,
                userId: userId,
                request: StartCodexOAuthRequest(
                  workspaceId: workspace.id!,
                  connectionId: connectionId,
                ),
              );
          final exchangeStarted = Completer<void>();
          final releaseExchange = Completer<void>();
          final completing =
              CodexOAuthUseCases(
                CodexOAuthRepository(),
                exchange: (_, _, _) async {
                  exchangeStarted.complete();
                  await releaseExchange.future;
                  return const {
                    'access_token': 'synthetic-account-access-token',
                    'refresh_token': 'synthetic-account-refresh-token',
                  };
                },
              ).complete(
                session,
                userId: userId,
                request: CompleteCodexOAuthRequest(
                  transactionId: started.transactionId,
                  state: Uri.parse(started.authorizationUrl)
                      .queryParameters['state']!,
                  code: 'synthetic-account-code',
                ),
              );
          await exchangeStarted.future.timeout(const Duration(seconds: 5));

          Object? deletionError;
          final deleting = endpoints.account
              .deleteCurrentUser(authenticated)
              .then<void>(
                (_) {},
                onError: (Object error, StackTrace _) => deletionError = error,
              );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          releaseExchange.complete();
          final completed = await completing.timeout(
            const Duration(seconds: 10),
          );
          await deleting.timeout(const Duration(seconds: 10));

          expect(completed.configured, isTrue);
          expect(deletionError, isNull);
          expect(
            await WorkspaceSecret.db.find(
              session,
              where: (row) => row.ownerUserId.equals(userId),
            ),
            isEmpty,
          );
          expect(
            await CodexOAuthTransaction.db.find(
              session,
              where: (row) => row.userId.equals(userId),
            ),
            isEmpty,
          );
          expect(
            await AuthUser.db.findById(session, UuidValue.fromString(userId)),
            isNull,
          );
        },
      );

      test(
        'account deletion and OAuth start serialize on the AuthUser row',
        () async {
          final userId = const Uuid().v4().toString();
          final ownerId = const Uuid().v4().toString();
          final authenticated = builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              userId,
              const {},
            ),
          );
          final session = authenticated.build();
          session.passwords['workspaceSecretKey'] =
              'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
          session.passwords['openAICodexOAuthClientId'] = 'synthetic-client-id';
          session.passwords['openAICodexOAuthRedirectUri'] =
              'http://localhost/callback';
          await _insertAccount(session, userId);
          initializeTestAuthServices(session.serverpod);
          final now = DateTime.now().toUtc();
          final workspace = await _createSharedWorkspace(
            session,
            ownerId: ownerId,
            memberId: userId,
            name: 'Account deletion start race',
            now: now,
          );

          final lockSession = builder.build();
          final lockAcquired = Completer<void>();
          final releaseLock = Completer<void>();
          final holdingUserLock = lockSession.db.transaction((
            transaction,
          ) async {
            final authUser = await AuthUser.db.findById(
              lockSession,
              UuidValue.fromString(userId),
              transaction: transaction,
              lockMode: LockMode.forUpdate,
            );
            expect(authUser, isNotNull);
            lockAcquired.complete();
            await releaseLock.future;
          });
          await lockAcquired.future.timeout(const Duration(seconds: 5));

          var startFinished = false;
          Object? startError;
          final starting =
              CodexOAuthUseCases(
                    CodexOAuthRepository(),
                  )
                  .start(
                    session,
                    userId: userId,
                    request: StartCodexOAuthRequest(
                      workspaceId: workspace.id!,
                      connectionId: 'account-deletion-start-connection',
                    ),
                  )
                  .then<void>(
                    (_) => startFinished = true,
                    onError: (Object error, StackTrace _) {
                      startError = error;
                      startFinished = true;
                    },
                  );
          var deletionFinished = false;
          Object? deletionError;
          final deleting = endpoints.account
              .deleteCurrentUser(authenticated)
              .then<void>(
                (_) => deletionFinished = true,
                onError: (Object error, StackTrace _) {
                  deletionError = error;
                  deletionFinished = true;
                },
              );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          final startWasBlocked = !startFinished;
          final deletionWasBlocked = !deletionFinished;
          releaseLock.complete();
          await holdingUserLock.timeout(const Duration(seconds: 10));
          await Future.wait([starting, deleting]).timeout(
            const Duration(seconds: 10),
          );

          expect(startWasBlocked, isTrue);
          expect(deletionWasBlocked, isTrue);
          expect(deletionError, isNull);
          expect(
            startError,
            anyOf(
              isNull,
              isA<CloudWorkspaceException>().having(
                (error) => error.code,
                'code',
                CloudWorkspaceErrorCode.authenticationRequired,
              ),
            ),
          );
          expect(
            await AuthUser.db.findById(session, UuidValue.fromString(userId)),
            isNull,
          );
          expect(
            await WorkspaceSecret.db.find(
              session,
              where: (row) => row.ownerUserId.equals(userId),
            ),
            isEmpty,
          );
          expect(
            await CodexOAuthTransaction.db.find(
              session,
              where: (row) => row.userId.equals(userId),
            ),
            isEmpty,
          );
        },
      );

      test(
        'rejects OAuth completion for an erasure-pending workspace',
        () async {
          final userId = const Uuid().v4().toString();
          final authenticated = builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              userId,
              const {},
            ),
          );
          final session = authenticated.build();
          session.passwords['workspaceSecretKey'] =
              'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
          session.passwords['openAICodexOAuthClientId'] = 'synthetic-client-id';
          session.passwords['openAICodexOAuthRedirectUri'] =
              'http://localhost/callback';
          await _insertAccount(session, userId);
          final now = DateTime.now().toUtc();
          final workspace = await workspace_repo.CloudWorkspaceRepository()
              .createWorkspace(
                session,
                name: 'Pending OAuth erasure',
                ownerUserId: userId,
                now: now,
              );
          const connectionId = 'pending-codex-connection';
          final started =
              await CodexOAuthUseCases(
                CodexOAuthRepository(),
              ).start(
                session,
                userId: userId,
                request: StartCodexOAuthRequest(
                  workspaceId: workspace.id!,
                  connectionId: connectionId,
                ),
              );
          final transactionId = started.transactionId;
          final state = Uri.parse(
            started.authorizationUrl,
          ).queryParameters['state']!;
          await WorkspaceObject.db.insertRow(
            session,
            WorkspaceObject(
              workspaceId: workspace.id!,
              objectKey: 'private/pending-oauth-erasure',
              purpose: 'workspace_asset',
              displayName: 'pending.txt',
              mimeType: 'text/plain',
              sizeBytes: 4,
              checksumSha256: 'a' * 64,
              status: 'active',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

          final erasure = await endpoints.cloudWorkspace.eraseWorkspace(
            authenticated,
            EraseCloudWorkspaceRequest(
              workspaceId: workspace.id!,
              confirmationName: workspace.name,
              requestId: const Uuid().v4().toString(),
              expectedWorkspaceRevision: workspace.revision,
            ),
          );
          expect(erasure.state, 'pending');

          var exchangeCalled = false;
          final completion =
              CodexOAuthUseCases(
                CodexOAuthRepository(),
                exchange: (_, _, _) async {
                  exchangeCalled = true;
                  return const {'access_token': 'must-not-be-written'};
                },
              ).complete(
                session,
                userId: userId,
                request: CompleteCodexOAuthRequest(
                  transactionId: transactionId,
                  state: state,
                  code: 'synthetic-code',
                ),
              );
          await expectLater(
            completion,
            throwsA(
              isA<CloudWorkspaceException>().having(
                (error) => error.code,
                'code',
                CloudWorkspaceErrorCode.validationFailed,
              ),
            ),
          );
          expect(exchangeCalled, isFalse);
          final pendingWorkspace = await CloudWorkspace.db.findById(
            session,
            workspace.id!,
          );
          expect(pendingWorkspace?.erasureRequestedAt, isNotNull);
          expect(
            await WorkspaceSecret.db.find(
              session,
              where: (row) =>
                  row.workspaceId.equals(workspace.id!) &
                  row.resourceId.equals(connectionId),
            ),
            isEmpty,
          );
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

Future<void> _insertAccount(Session session, String userId) async {
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: UuidValue.fromString(userId),
      email: '$userId@example.invalid',
      passwordHash: 'unused',
    ),
  );
}

Future<CloudWorkspace> _createSharedWorkspace(
  Session session, {
  required String ownerId,
  required String memberId,
  required String name,
  required DateTime now,
}) async {
  final workspace = await workspace_repo.CloudWorkspaceRepository()
      .createWorkspace(
        session,
        name: name,
        ownerUserId: ownerId,
        now: now,
      );
  await WorkspaceMember.db.insertRow(
    session,
    WorkspaceMember(
      workspaceId: workspace.id!,
      userId: memberId,
      role: 'admin',
      revision: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
  return workspace;
}
