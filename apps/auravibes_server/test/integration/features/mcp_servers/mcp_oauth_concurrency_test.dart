import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_server/src/features/mcp_servers/mcp_oauth_credentials.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_oauth_token_resolver.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_secret_cipher.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('OAuth refresh concurrency', (sessions, _) {
    test('delayed exchange holds neither workspace nor secret locks', () async {
      final f = await _Fixture.create(sessions.build());
      final entered = Completer<void>();
      final release = Completer<void>();
      final resolving = f.resolve(f.session, (credentials) async {
        entered.complete();
        await release.future;
        return f.rotated(credentials, 'rotated');
      });
      await entered.future;
      try {
        final other = sessions.build();
        await other.db
            .transaction((transaction) async {
              await other.db.unsafeExecute(
                'SET LOCAL lock_timeout = \'500ms\'',
                transaction: transaction,
              );
              await CloudWorkspace.db.findById(
                other,
                f.secret.workspaceId,
                transaction: transaction,
                lockMode: LockMode.forUpdate,
              );
              await WorkspaceSecret.db.findById(
                other,
                f.secret.id!,
                transaction: transaction,
                lockMode: LockMode.forUpdate,
              );
            })
            .timeout(const Duration(seconds: 2));
      } finally {
        release.complete();
        await resolving;
      }
      expect((await f.stored()).revision, 2);
      expect(await f.events(), hasLength(1));
    });

    test(
      'account deletion before refresh dispatch prevents exchange',
      () async {
        final f = await _Fixture.create(sessions.build());
        final authUser = await AuthUser.db.findById(
          f.session,
          UuidValue.fromString(f.userId),
        );
        await AuthUser.db.deleteRow(f.session, authUser!);
        var exchanges = 0;

        await expectLater(
          f.resolve(f.session, (credentials) async {
            exchanges++;
            return f.rotated(credentials, 'unexpected');
          }),
          throwsA(isA<McpOAuthReauthRequired>()),
        );
        expect(exchanges, 0);
        expect((await f.stored()).revision, 1);
      },
    );

    test(
      'member removal during refresh prevents credential persistence',
      () async {
        final f = await _Fixture.create(sessions.build());
        final entered = Completer<void>();
        final release = Completer<void>();
        final before = (await f.stored()).toJson();
        final pending = f.resolve(f.session, (credentials) async {
          entered.complete();
          await release.future;
          return f.rotated(credentials, 'stale');
        });
        final rejected = expectLater(
          pending,
          throwsA(isA<McpOAuthReauthRequired>()),
        );
        await entered.future;
        final membership = await WorkspaceMember.db.findFirstRow(
          f.session,
          where: (row) =>
              row.workspaceId.equals(f.secret.workspaceId) &
              row.userId.equals(f.userId),
        );
        await WorkspaceMember.db.updateRow(
          f.session,
          membership!.copyWith(removedAt: f.now),
        );
        release.complete();
        await rejected;
        expect((await f.stored()).toJson(), before);
        expect(await f.events(), isEmpty);
      },
    );

    for (final staleRejection in [false, true]) {
      test(
        'concurrent winner keeps rotated token, stale rejection: $staleRejection',
        () async {
          final f = await _Fixture.create(sessions.build());
          final entered = Completer<void>();
          final release = Completer<void>();
          final loser = f.resolve(f.session, (credentials) async {
            entered.complete();
            await release.future;
            if (staleRejection) throw const McpOAuthReauthRequired();
            return f.rotated(credentials, 'loser');
          });
          await entered.future;
          final winner = await f.resolve(
            sessions.build(),
            (credentials) async => f.rotated(credentials, 'winner'),
          );
          expect(winner, 'winner-access');
          release.complete();
          expect(await loser, 'winner-access');
          expect(await f.cleartext(), contains('winner-refresh'));
          expect(await f.cleartext(), isNot(contains('loser')));
          expect((await f.stored()).revision, 2);
          expect(await f.events(), hasLength(1));
          expect(jsonDecode((await f.resource()).data)['authStatus'], 'active');
        },
      );
    }

    test('successful rotation survives earlier concurrent rejection', () async {
      final f = await _Fixture.create(sessions.build());
      final entered = Completer<void>();
      final release = Completer<void>();
      final successful = f.resolve(f.session, (credentials) async {
        entered.complete();
        await release.future;
        return f.rotated(credentials, 'winner');
      });
      await entered.future;
      await expectLater(
        f.resolve(
          sessions.build(),
          (_) async => throw const McpOAuthReauthRequired(),
        ),
        throwsA(isA<McpOAuthReauthRequired>()),
      );
      release.complete();
      expect(await successful, 'winner-access');
      expect(await f.cleartext(), contains('winner-refresh'));
      expect((await f.stored()).revision, 2);
      expect(await f.events(), hasLength(2));
      expect(jsonDecode((await f.resource()).data)['authStatus'], 'active');
    });

    test('replacement token never reaches previous server identity', () async {
      final f = await _Fixture.create(sessions.build());
      final entered = Completer<void>();
      final release = Completer<void>();
      final pending = f.resolve(f.session, (credentials) async {
        entered.complete();
        await release.future;
        return f.rotated(credentials, 'stale');
      });
      final rejected = expectLater(
        pending,
        throwsA(isA<McpOAuthRefreshFailed>()),
      );
      await entered.future;
      final other = sessions.build();
      final replacement = f.rotated(f.credentials, 'replacement');
      final encrypted = await const WorkspaceSecretCipher().encrypt(
        other,
        jsonEncode(replacement.toJson()),
        workspaceId: f.secret.workspaceId,
        resourceId: f.secret.resourceId,
      );
      await other.db.transaction((transaction) async {
        final resource = await f.resource();
        await WorkspaceSecret.db.updateRow(
          other,
          f.secret.copyWith(
            ciphertext: encrypted.ciphertext,
            nonce: encrypted.nonce,
            authenticationTag: encrypted.authenticationTag,
            revision: 2,
          ),
          transaction: transaction,
        );
        await WorkspaceResource.db.updateRow(
          other,
          resource.copyWith(
            data: jsonEncode({
              'authStatus': 'active',
              'secretRevision': 2,
              'hasSecret': true,
              'url': 'https://replacement.example.com',
            }),
            revision: 2,
          ),
          transaction: transaction,
        );
      });
      release.complete();
      await rejected;
      expect(await f.cleartext(), contains('replacement-refresh'));
      expect((await f.stored()).revision, 2);
      expect(await f.events(), isEmpty);
    });

    for (final mutation in [
      'secret-edit',
      'metadata-edit',
      'secret-delete',
      'resource-delete',
      'workspace-delete',
    ]) {
      test('$mutation prevents stale refresh writes', () async {
        final f = await _Fixture.create(sessions.build());
        final entered = Completer<void>();
        final release = Completer<void>();
        final pending = f.resolve(f.session, (credentials) async {
          entered.complete();
          await release.future;
          return f.rotated(credentials, 'stale');
        });
        final rejected = expectLater(
          pending,
          throwsA(
            anyOf(isA<McpOAuthRefreshFailed>(), isA<McpOAuthReauthRequired>()),
          ),
        );
        await entered.future;
        final other = sessions.build();
        if (mutation == 'secret-edit') {
          final encrypted = await const WorkspaceSecretCipher().encrypt(
            other,
            jsonEncode(f.credentials.toJson()),
            workspaceId: f.secret.workspaceId,
            resourceId: f.secret.resourceId,
          );
          await WorkspaceSecret.db.updateRow(
            other,
            f.secret.copyWith(
              ciphertext: encrypted.ciphertext,
              nonce: encrypted.nonce,
              authenticationTag: encrypted.authenticationTag,
              revision: 2,
            ),
          );
        } else if (mutation == 'metadata-edit') {
          final resource = await f.resource();
          await WorkspaceResource.db.updateRow(
            other,
            resource.copyWith(
              revision: 2,
              data: jsonEncode({
                'authStatus': 'active',
                'secretRevision': 1,
                'name': 'user edit',
              }),
            ),
          );
        } else if (mutation == 'secret-delete') {
          await WorkspaceSecret.db.updateRow(
            other,
            f.secret.copyWith(deletedAt: f.now, revision: 2),
          );
        } else if (mutation == 'resource-delete') {
          final resource = await f.resource();
          await WorkspaceResource.db.updateRow(
            other,
            resource.copyWith(deletedAt: f.now, revision: 2),
          );
        } else {
          final workspace = (await CloudWorkspace.db.findById(
            other,
            f.secret.workspaceId,
          ))!;
          await CloudWorkspace.db.updateRow(
            other,
            workspace.copyWith(deletedAt: f.now),
          );
        }
        final before = (await f.stored()).toJson();
        final resourceBefore = (await f.resource()).toJson();
        release.complete();
        await rejected;
        expect((await f.stored()).toJson(), before);
        expect((await f.resource()).toJson(), resourceBefore);
        expect(await f.events(), isEmpty);
      });
    }

    for (final error in [
      const McpOAuthRefreshFailed(retryable: true),
      const McpOAuthRefreshFailed(retryable: false),
      TimeoutException('provider-secret'),
      const HttpException('provider-secret'),
      const FormatException('provider-secret'),
    ]) {
      test(
        '$error preserves encrypted credentials and auth metadata',
        () async {
          final f = await _Fixture.create(sessions.build());
          final before = (await f.stored()).toJson();
          final resourceBefore = (await f.resource()).toJson();
          await expectLater(
            f.resolve(f.session, (_) async => throw error),
            throwsA(isA<McpOAuthRefreshFailed>()),
          );
          expect((await f.stored()).toJson(), before);
          expect((await f.resource()).toJson(), resourceBefore);
          expect(await f.events(), isEmpty);
        },
      );
    }
  }, rollbackDatabase: RollbackDatabase.disabled);
}

class _Fixture(this.session, this.userId, this.secret, this.credentials) {
  final Session session;
  final String userId;
  final WorkspaceSecret secret;
  final McpOAuthCredentials credentials;
  final now = DateTime.utc(2026, 1, 2);

  static Future<_Fixture> create(Session session) async {
    session.passwords['workspaceSecretKey'] =
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
    final userId = const Uuid().v4().toString();
    await AuthUser.db.insertRow(
      session,
      AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
    );
    final workspace = await workspace_repo.CloudWorkspaceRepository()
        .createWorkspace(
          session,
          name: 'Isolated OAuth test',
          ownerUserId: userId,
          now: DateTime.utc(2026),
        );
    final credentials = McpOAuthCredentials(
      clientId: 'client',
      tokenEndpoint: 'https://auth.example.com/token',
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
      issuedAt: DateTime.utc(2026),
      expiresIn: 3600,
    );
    final encrypted = await const WorkspaceSecretCipher().encrypt(
      session,
      jsonEncode(credentials.toJson()),
      workspaceId: workspace.id!,
      resourceId: 'server',
    );
    final secret = await WorkspaceSecret.db.insertRow(
      session,
      WorkspaceSecret(
        workspaceId: workspace.id!,
        secretKind: WorkspaceSecretKind.mcp,
        scope: WorkspaceSecretScope.workspace,
        ownerUserId: '',
        resourceId: 'server',
        ciphertext: encrypted.ciphertext,
        nonce: encrypted.nonce,
        authenticationTag: encrypted.authenticationTag,
        algorithm: 'AES-256-GCM',
        keyVersion: 1,
        revision: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await WorkspaceResource.db.insertRow(
      session,
      WorkspaceResource(
        workspaceId: workspace.id!,
        resourceKind: WorkspaceResourceKind.mcpServer,
        resourceId: 'server',
        data: jsonEncode({
          'authStatus': 'active',
          'secretRevision': 1,
          'hasSecret': true,
        }),
        revision: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    return _Fixture(session, userId, secret, credentials);
  }

  Future<String> resolve(Session session, McpOAuthExchange exchange) =>
      McpOAuthTokenResolver(
        exchange: exchange,
        now: () => now,
      ).resolve(session, secret, actorUserId: userId);
  McpOAuthCredentials rotated(McpOAuthCredentials credentials, String name) =>
      credentials.withRefreshedToken(
        accessToken: '$name-access',
        refreshToken: '$name-refresh',
        expiresIn: 7200,
        now: now,
      );
  Future<WorkspaceSecret> stored() async =>
      (await WorkspaceSecret.db.findById(session, secret.id!))!;
  Future<String> cleartext() async =>
      const WorkspaceSecretCipher().decrypt(session, await stored());
  Future<WorkspaceResource> resource() async =>
      (await WorkspaceResource.db.findFirstRow(
        session,
        where: (t) =>
            t.workspaceId.equals(secret.workspaceId) &
            t.resourceId.equals(secret.resourceId),
      ))!;
  Future<List<WorkspaceEvent>> events() => WorkspaceEvent.db.find(
    session,
    where: (t) => t.workspaceId.equals(secret.workspaceId),
  );
}
