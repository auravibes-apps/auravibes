import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_server/src/features/model_connections/repositories/model_connection_repository.dart';
import 'package:auravibes_server/src/features/model_connections/usecases/model_connection_usecases.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_resource_validation.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_secret_cipher.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Model connection verification', (sessionBuilder, _) {
    test('verifies a stored secret without returning it', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      var fetchCalls = 0;
      final useCases = _useCases(
        fetch: (_, _, _) async {
          fetchCalls++;

          return const {
            'data': [
              {'id': 'gpt-4o'},
            ],
          };
        },
      );

      final result = await useCases.verifyDraft(
        fixture.session,
        userId: fixture.userId,
        request: _verifyRequest(fixture, url: 'https://new.example/v1'),
      );

      expect(fetchCalls, 1);
      expect(result.providerId, 'openai');
      expect(result.modelIds, ['gpt-4o']);
      expect(result.verificationReceipt, isNot(contains('stored-api-key')));
      expect(result.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('authorizes before reading or probing the stored secret', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      var fetchCalls = 0;
      final useCases = _useCases(
        fetch: (_, _, _) async {
          fetchCalls++;

          return const {'data': []};
        },
      );

      await expectLater(
        useCases.verifyDraft(
          fixture.session,
          userId: 'not-a-member',
          request: _verifyRequest(fixture),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      expect(fetchCalls, 0);
    });

    test(
      'rejects invalid URLs, missing secrets, and revision mismatches',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        final useCases = _useCases(
          fetch: (_, _, _) async => const {
            'data': [
              {'id': 'gpt-4o'},
            ],
          },
        );

        await expectLater(
          useCases.verifyDraft(
            fixture.session,
            userId: fixture.userId,
            request: _verifyRequest(fixture, url: 'http://public.example'),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          useCases.verifyDraft(
            fixture.session,
            userId: fixture.userId,
            request: _verifyRequest(fixture, expectedRevision: 2),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );

        final withoutSecret = await _Fixture.create(
          sessionBuilder.build(),
          includeSecret: false,
        );
        await expectLater(
          _useCases(fetch: (_, _, _) async => const {'data': []}).verifyDraft(
            withoutSecret.session,
            userId: withoutSecret.userId,
            request: _verifyRequest(withoutSecret),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );

    test('requires a bound, unexpired receipt for URL updates', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      final useCases = _useCases(
        fetch: (_, _, _) async => const {
          'data': [
            {'id': 'gpt-4o'},
          ],
        },
      );
      final verification = await useCases.verifyDraft(
        fixture.session,
        userId: fixture.userId,
        request: _verifyRequest(fixture, url: 'https://new.example/v1'),
      );

      final update = _updateRequest(
        fixture,
        url: 'https://new.example/v1',
        verificationReceipt: verification.verificationReceipt,
      );
      await expectLater(
        useCases.update(
          fixture.session,
          userId: fixture.userId,
          request: update.copyWith(verificationReceipt: null),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        useCases.update(
          fixture.session,
          userId: fixture.userId,
          request: update.copyWith(url: 'https://other.example/v1'),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        useCases.update(
          fixture.session,
          userId: fixture.userId,
          request: update.copyWith(
            verificationReceipt: await _expiredReceipt(fixture),
          ),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );

      final updated = await useCases.update(
        fixture.session,
        userId: fixture.userId,
        request: update,
      );
      expect(updated.url, 'https://new.example/v1');
      expect(updated.revision, 2);
    });
  });
}

ModelConnectionUseCases _useCases({required ModelCatalogFetcher fetch}) =>
    ModelConnectionUseCases(
      ModelConnectionRepository(),
      fetch: fetch,
      lookup: (_) async => [InternetAddress('8.8.8.8')],
    );

VerifyModelConnectionRequest _verifyRequest(
  _Fixture fixture, {
  String? url,
  int expectedRevision = 1,
}) => VerifyModelConnectionRequest(
  workspaceId: fixture.workspaceId,
  requestId: 'verify-${fixture.connectionId}',
  connectionId: fixture.connectionId,
  expectedRevision: expectedRevision,
  url: url,
);

UpdateModelConnectionRequest _updateRequest(
  _Fixture fixture, {
  required String url,
  required String? verificationReceipt,
}) => UpdateModelConnectionRequest(
  workspaceId: fixture.workspaceId,
  requestId: 'update-${fixture.connectionId}',
  connectionId: fixture.connectionId,
  expectedRevision: 1,
  name: 'OpenAI',
  url: url,
  verificationReceipt: verificationReceipt,
);

Future<String> _expiredReceipt(_Fixture fixture) async {
  final request = _verifyRequest(fixture, url: 'https://new.example/v1');
  final encrypted = await const WorkspaceSecretCipher().encrypt(
    fixture.session,
    jsonEncode({
      'workspaceId': fixture.workspaceId,
      'userId': fixture.userId,
      'requestId': request.requestId,
      'connectionId': request.connectionId,
      'expectedRevision': request.expectedRevision,
      'providerId': 'openai',
      'url': request.url,
      'modelIds': ['gpt-4o'],
      'expiresAt': DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 1))
          .toIso8601String(),
    }),
    workspaceId: fixture.workspaceId,
    resourceId: request.requestId,
  );

  return jsonEncode({
    'requestId': request.requestId,
    'ciphertext': _base64(encrypted.ciphertext),
    'nonce': _base64(encrypted.nonce),
    'authenticationTag': _base64(encrypted.authenticationTag),
  });
}

String _base64(ByteData value) => base64Encode(
  value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes),
);

class _Fixture {
  const _Fixture({
    required this.session,
    required this.userId,
    required this.workspaceId,
    required this.connectionId,
  });

  final Session session;
  final String userId;
  final int workspaceId;
  final String connectionId;

  static Future<_Fixture> create(
    Session session, {
    bool includeSecret = true,
  }) async {
    final userId = const Uuid().v4().toString();
    final workspace = await workspace_repo.CloudWorkspaceRepository()
        .createWorkspace(
          session,
          name: 'Model verification workspace',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );
    final workspaceId = workspace.id!;
    const connectionId = 'model-connection';
    final now = DateTime.now().toUtc();
    await WorkspaceModelConnection.db.insertRow(
      session,
      WorkspaceModelConnection(
        workspaceId: workspaceId,
        connectionId: connectionId,
        providerId: 'openai',
        name: 'OpenAI',
        url: 'https://old.example/v1',
        hasSecret: includeSecret,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (includeSecret) {
      final encrypted = await const WorkspaceSecretCipher().encrypt(
        session,
        'stored-api-key',
        workspaceId: workspaceId,
        resourceId: connectionId,
      );
      await WorkspaceSecret.db.insertRow(
        session,
        WorkspaceSecret(
          workspaceId: workspaceId,
          secretKind: WorkspaceSecretKind.provider,
          scope: WorkspaceSecretScope.user,
          ownerUserId: WorkspaceResourceValidation.secretOwnerKey(
            WorkspaceSecretScope.user,
            userId,
          ),
          resourceId: connectionId,
          ciphertext: encrypted.ciphertext,
          nonce: encrypted.nonce,
          authenticationTag: encrypted.authenticationTag,
          algorithm: 'AES-256-GCM',
          keyVersion: 1,
          displaySuffix: 'e-key',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return _Fixture(
      session: session,
      userId: userId,
      workspaceId: workspaceId,
      connectionId: connectionId,
    );
  }
}
