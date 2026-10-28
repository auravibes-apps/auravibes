import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_server/src/features/mcp_servers/mcp_server_probe.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_sse_session.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_oauth_token_resolver.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_server_repository.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_server_use_cases.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_secret_cipher.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('MCP server verification', (sessionBuilder, _) {
    test('OAuth receipt, encrypted rotation, and reauth state', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      await McpCatalogEntry.db.insertRow(
        fixture.session,
        McpCatalogEntry(
          catalogId: 'oauth-catalog',
          name: 'OAuth server',
          description: 'OAuth tools',
          url: 'https://mcp.example.com',
          transport: 'streamableHttp',
          isEnabled: true,
          optionsJson: '[{"key":"oauth","name":"OAuth","authType":"oauth","fields":[{"key":"clientId","isSecret":false,"isRequired":true}]}]',
        ),
      );
      const oauthJson =
          '{"clientId":"client","tokenEndpoint":"https://auth.example.com/token","token":{"accessToken":"access-secret","refreshToken":"refresh-secret","issuedAt":"2026-01-01T00:00:00Z","tokenType":"Bearer"}}';
      final useCases = McpServerUseCases(
        McpServerRepository(),
        _FakeMcpServerProbe(),
      );
      final verified = await useCases.verify(
        fixture.session,
        userId: fixture.userId,
        request: VerifyMcpServerRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'verify-oauth',
          url: 'https://mcp.example.com',
          transport: 'streamableHttp',
          useHttp2: false,
          bearerToken: 'access-secret',
          oauthJson: oauthJson,
        ),
      );
      final request = CreateMcpServerRequest(
        workspaceId: fixture.workspaceId,
        requestId: 'create-oauth',
        name: 'OAuth server',
        url: 'https://mcp.example.com',
        transport: 'streamableHttp',
        useHttp2: false,
        bearerToken: 'access-secret',
        oauthJson: oauthJson,
        catalogListingId: 'oauth-catalog',
        catalogOptionKey: 'oauth',
        verificationReceipt: verified.verificationReceipt,
      );
      await expectLater(
        useCases.create(
          fixture.session,
          userId: fixture.userId,
          request: request.copyWith(
            requestId: 'tampered-oauth',
            oauthJson: oauthJson.replaceFirst('refresh-secret', 'changed'),
          ),
        ),
        throwsA(_cloudError(CloudWorkspaceErrorCode.validationFailed)),
      );
      final created = await useCases.create(
        fixture.session,
        userId: fixture.userId,
        request: request,
      );
      final secret = (await WorkspaceSecret.db.find(
        fixture.session,
        where: (table) => table.workspaceId.equals(fixture.workspaceId),
      )).single;
      expect(
        base64Encode(secret.ciphertext.buffer.asUint8List()),
        isNot(contains('refresh-secret')),
      );
      final resolver = McpOAuthTokenResolver(
        now: () => DateTime.utc(2026, 1, 1, 2),
        exchange: (credentials) async => credentials.withRefreshedToken(
          accessToken: 'rotated-access',
          refreshToken: 'rotated-refresh',
          expiresIn: 7200,
          now: DateTime.utc(2026, 1, 1, 2),
        ),
      );
      final beforeRefresh = await fixture.counts();
      final sequenceBeforeRefresh = (await CloudWorkspace.db.findById(
        fixture.session,
        fixture.workspaceId,
      ))!.sequence;
      expect(
        await resolver.resolve(
          fixture.session,
          secret,
          actorUserId: fixture.userId,
        ),
        'rotated-access',
      );
      final persisted = (await WorkspaceSecret.db.find(
        fixture.session,
        where: (table) => table.workspaceId.equals(fixture.workspaceId),
      )).single;
      final encrypted = await const WorkspaceSecretCipher().decrypt(
        fixture.session,
        persisted,
      );
      expect(encrypted, contains('rotated-refresh'));
      expect(encrypted, isNot(contains('refresh-secret')));
      expect(created.mcpServerId, persisted.resourceId);
      final rotatedResource = await WorkspaceResource.db.findFirstRow(
        fixture.session,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.resourceId.equals(created.mcpServerId),
      );
      final rotatedData = jsonDecode(rotatedResource!.data) as Map;
      expect(rotatedData['secretRevision'], persisted.revision);
      expect(rotatedData['authStatus'], 'active');
      expect(rotatedResource.revision, 2);
      final afterRefresh = await fixture.counts();
      expect(afterRefresh.events, beforeRefresh.events + 1);
      expect(
        (await CloudWorkspace.db.findById(
          fixture.session,
          fixture.workspaceId,
        ))!.sequence,
        sequenceBeforeRefresh + 1,
      );
      final stillValid = McpOAuthTokenResolver(
        now: () => DateTime.utc(2026, 1, 1, 2, 1),
        exchange: (_) => throw StateError('Must not refresh'),
      );
      expect(
        await stillValid.resolve(
          fixture.session,
          persisted,
          actorUserId: fixture.userId,
        ),
        'rotated-access',
      );
      expect((await fixture.counts()).events, afterRefresh.events);
      final failed = McpOAuthTokenResolver(
        now: () => DateTime.utc(2026, 1, 2),
        exchange: (_) => throw const McpOAuthReauthRequired(),
      );
      await expectLater(
        failed.resolve(
          fixture.session,
          persisted,
          actorUserId: fixture.userId,
        ),
        throwsA(isA<McpOAuthReauthRequired>()),
      );
      final resource = await WorkspaceResource.db.findFirstRow(
        fixture.session,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.resourceId.equals(created.mcpServerId),
      );
      expect(
        (jsonDecode(resource!.data) as Map)['authStatus'],
        'reauthRequired',
      );
      expect((await fixture.counts()).events, afterRefresh.events + 1);
      final noRefresh = encrypted
          .replaceFirst(
            '"refreshToken":"rotated-refresh"',
            '"refreshToken":null',
          )
          .replaceFirst('"expiresIn":7200', '"expiresIn":null');
      final cipher = await const WorkspaceSecretCipher().encrypt(
        fixture.session,
        noRefresh,
        workspaceId: persisted.workspaceId,
        resourceId: persisted.resourceId,
      );
      final withoutRefresh = await WorkspaceSecret.db.updateRow(
        fixture.session,
        persisted.copyWith(
          ciphertext: cipher.ciphertext,
          nonce: cipher.nonce,
          authenticationTag: cipher.authenticationTag,
        ),
      );
      await expectLater(
        McpOAuthTokenResolver(
          now: () => DateTime.utc(2026, 1, 2),
          exchange: (_) => throw StateError('Must not exchange'),
        ).resolve(
          fixture.session,
          withoutRefresh,
          actorUserId: fixture.userId,
        ),
        throwsA(isA<McpOAuthReauthRequired>()),
      );
    });

    test(
      'catalog install keeps metadata and encrypted workspace headers',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        await McpCatalogEntry.db.insertRow(
          fixture.session,
          McpCatalogEntry(
            catalogId: 'catalog-1',
            name: 'Original',
            description: 'Original description',
            url: 'https://mcp.example.com',
            transport: 'streamableHttp',
            isEnabled: true,
            optionsJson: '[{"key":"personal","name":"Personal","authType":"apiKey","fields":[{"key":"X-API-Key","isSecret":true,"isRequired":true}]}]',
          ),
        );
        final probe = _FakeMcpServerProbe();
        final useCases = McpServerUseCases(McpServerRepository(), probe);
        final verification = await useCases.verify(
          fixture.session,
          userId: fixture.userId,
          request: VerifyMcpServerRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'verify-catalog',
            url: 'https://mcp.example.com',
            transport: 'streamableHttp',
            useHttp2: false,
            httpHeadersJson: '{"X-API-Key":"secret-value"}',
          ),
        );
        final createRequest = CreateMcpServerRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'create-catalog',
          name: 'Original',
          url: 'https://mcp.example.com',
          transport: 'streamableHttp',
          useHttp2: false,
          httpHeadersJson: '{"X-API-Key":"secret-value"}',
          catalogListingId: 'catalog-1',
          catalogOptionKey: 'personal',
          verificationReceipt: verification.verificationReceipt,
        );
        final created = await useCases.create(
          fixture.session,
          userId: fixture.userId,
          request: createRequest,
        );
        final resources = await WorkspaceResource.db.find(
          fixture.session,
          where: (table) => table.workspaceId.equals(fixture.workspaceId),
        );
        final server = resources.singleWhere(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.mcpServer,
        );
        final snapshot = jsonDecode(server.data) as Map<String, dynamic>;
        final copiedSnapshotJson = snapshot['catalogSnapshotJson'] as String;
        final secret = (await WorkspaceSecret.db.find(
          fixture.session,
          where: (table) => table.workspaceId.equals(fixture.workspaceId),
        )).single;
        expect(copiedSnapshotJson, contains('Original'));
        expect(copiedSnapshotJson, isNot(contains('secret-value')));
        expect(
          base64Encode(secret.ciphertext.buffer.asUint8List()),
          isNot(contains('secret-value')),
        );
        expect(probe.lastHeaders, {'X-API-Key': 'secret-value'});
        await McpCatalogEntry.db.deleteWhere(
          fixture.session,
          where: (table) => table.catalogId.equals('catalog-1'),
        );
        final persistedServer = await WorkspaceResource.db.findFirstRow(
          fixture.session,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.resourceKind.equals(WorkspaceResourceKind.mcpServer) &
              table.resourceId.equals(created.mcpServerId),
        );
        expect(persistedServer, isNotNull);
        final storedServer = persistedServer!;
        final persistedServerData =
            jsonDecode(storedServer.data) as Map<String, dynamic>;
        final persistedSnapshotJson =
            persistedServerData['catalogSnapshotJson'] as String;
        final persistedSnapshot =
            jsonDecode(persistedSnapshotJson) as Map<String, dynamic>;
        expect(persistedSnapshotJson, copiedSnapshotJson);
        expect(storedServer.data, isNot(contains('secret-value')));
        expect(persistedSnapshot['id'], 'catalog-1');
        expect(persistedSnapshot['name'], 'Original');
        expect(persistedSnapshot['transport'], 'streamableHttp');
        final persistedOption =
            persistedSnapshot['option'] as Map<String, dynamic>;
        expect(persistedOption['key'], 'personal');
        expect(persistedOption['name'], 'Personal');
        final replay = await useCases.create(
          fixture.session,
          userId: fixture.userId,
          request: createRequest,
        );
        expect(replay.toJson(), created.toJson());
      },
    );

    test('verify is read-only and create reuses its discovery', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      final probe = _FakeMcpServerProbe();
      final useCases = McpServerUseCases(McpServerRepository(), probe);
      final before = await fixture.counts();
      final verification = await useCases.verify(
        fixture.session,
        userId: fixture.userId,
        request: VerifyMcpServerRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'verify-1',
          url: ' https://mcp.example.com ',
          transport: 'streamableHttp',
          useHttp2: false,
          bearerToken: 'fixture-credential',
        ),
      );

      expect(probe.calls, 1);
      expect(verification.discovery.tools, hasLength(1));
      expect(
        verification.verificationReceipt,
        isNot(contains('fixture-credential')),
      );
      expect(await fixture.counts(), before);

      final request = CreateMcpServerRequest(
        workspaceId: fixture.workspaceId,
        requestId: 'create-1',
        name: 'MCP server',
        url: 'https://mcp.example.com',
        transport: 'streamableHttp',
        useHttp2: false,
        description: 'Description',
        bearerToken: 'fixture-credential',
        verificationReceipt: verification.verificationReceipt,
      );
      final created = await useCases.create(
        fixture.session,
        userId: fixture.userId,
        request: request,
      );
      final replay = await useCases.create(
        fixture.session,
        userId: fixture.userId,
        request: request,
      );

      expect(probe.calls, 1);
      expect(replay.toJson(), created.toJson());
      expect((await fixture.counts()).resources, 3);
      expect((await fixture.counts()).secrets, 1);
      expect((await fixture.counts()).events, 3);
      expect((await fixture.counts()).receipts, 1);
    });

    test(
      'create rejects malformed, tampered, expired, and mismatched receipts',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        final probe = _FakeMcpServerProbe();
        final useCases = McpServerUseCases(McpServerRepository(), probe);
        final verification = await useCases.verify(
          fixture.session,
          userId: fixture.userId,
          request: _verifyRequest(fixture.workspaceId),
        );
        final validRequest = _createRequest(
          fixture.workspaceId,
          verification.verificationReceipt,
        );
        final tamperedEnvelope = jsonDecode(
          verification.verificationReceipt,
        ) as Map<String, dynamic>;
        tamperedEnvelope['ciphertext'] = base64Encode(const [0]);

        for (final request in [
          validRequest.copyWith(
            requestId: 'missing',
            verificationReceipt: null,
          ),
          validRequest.copyWith(
            requestId: 'malformed',
            verificationReceipt: 'not-json',
          ),
          validRequest.copyWith(
            requestId: 'tampered',
            verificationReceipt: jsonEncode(tamperedEnvelope),
          ),
          validRequest.copyWith(
            requestId: 'mismatched-credential',
            bearerToken: 'different-credential',
          ),
          validRequest.copyWith(
            requestId: 'expired',
            verificationReceipt: await _expiredReceipt(
              fixture,
              requestId: 'expired-verification',
            ),
          ),
        ]) {
          await expectLater(
            useCases.create(
              fixture.session,
              userId: fixture.userId,
              request: request,
            ),
            throwsA(_cloudError(CloudWorkspaceErrorCode.validationFailed)),
          );
        }

        expect(probe.calls, 1);
        expect((await fixture.counts()).resources, 0);
        expect((await fixture.counts()).secrets, 0);
        expect((await fixture.counts()).events, 0);
        expect((await fixture.counts()).receipts, 0);
      },
    );

    test('verify authorizes before probing', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      final nonMemberUserId = const Uuid().v4().toString();
      await AuthUser.db.insertRow(
        fixture.session,
        AuthUser(
          id: UuidValue.fromString(nonMemberUserId),
          scopeNames: const {},
        ),
      );
      final probe = _FakeMcpServerProbe();
      final useCases = McpServerUseCases(McpServerRepository(), probe);

      await expectLater(
        useCases.verify(
          fixture.session,
          userId: nonMemberUserId,
          request: _verifyRequest(fixture.workspaceId),
        ),
        throwsA(_cloudError(CloudWorkspaceErrorCode.membershipRequired)),
      );

      expect(probe.calls, 0);
      expect((await fixture.counts()).resources, 0);
    });

    test('verify rejects probe results after membership is removed', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      final entered = Completer<void>();
      final release = Completer<void>();
      final probe = _WaitingMcpServerProbe(entered, release);
      final useCases = McpServerUseCases(McpServerRepository(), probe);
      final pending = useCases.verify(
        fixture.session,
        userId: fixture.userId,
        request: _verifyRequest(fixture.workspaceId),
      );

      await entered.future;
      await _removeMembership(fixture);
      release.complete();

      await expectLater(
        pending,
        throwsA(_cloudError(CloudWorkspaceErrorCode.membershipRequired)),
      );
      expect(probe.calls, 1);
    });

    test(
      'discoverAndCheck rejects probe results after membership is removed',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        await WorkspaceResource.db.insertRow(
          fixture.session,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.mcpServer,
            resourceId: 'server',
            data: jsonEncode({
              'url': 'https://mcp.example.com',
              'transport': {'type': 'streamableHttp', 'useHttp2': false},
              'authType': 'none',
              'hasSecret': false,
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        final entered = Completer<void>();
        final release = Completer<void>();
        final probe = _WaitingMcpServerProbe(entered, release);
        final useCases = McpServerUseCases(McpServerRepository(), probe);
        final pending = useCases.discoverAndCheck(
          fixture.session,
          userId: fixture.userId,
          request: DiscoverMcpServerRequest(
            workspaceId: fixture.workspaceId,
            mcpServerId: 'server',
          ),
        );

        await entered.future;
        await _removeMembership(fixture);
        release.complete();

        await expectLater(
          pending,
          throwsA(_cloudError(CloudWorkspaceErrorCode.membershipRequired)),
        );
        expect(probe.calls, 1);
      },
    );

    test(
      'create rolls back all persistence when a resource insert fails',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        final probe = _FakeMcpServerProbe();
        final verification =
            await McpServerUseCases(
              McpServerRepository(),
              probe,
            ).verify(
              fixture.session,
              userId: fixture.userId,
              request: _verifyRequest(fixture.workspaceId),
            );
        final useCases = McpServerUseCases(
          _FailingMcpServerRepository(),
          probe,
        );

        await expectLater(
          useCases.create(
            fixture.session,
            userId: fixture.userId,
            request: _createRequest(
              fixture.workspaceId,
              verification.verificationReceipt,
            ),
          ),
          throwsA(isA<Exception>()),
        );
        expect(probe.calls, 1);
        expect((await fixture.counts()).resources, 0);
        expect((await fixture.counts()).secrets, 0);
        expect((await fixture.counts()).events, 0);
        expect((await fixture.counts()).receipts, 0);
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}

Matcher _cloudError(CloudWorkspaceErrorCode code) =>
    isA<CloudWorkspaceException>().having((error) => error.code, 'code', code);

VerifyMcpServerRequest _verifyRequest(int workspaceId) =>
    VerifyMcpServerRequest(
      workspaceId: workspaceId,
      requestId: 'verify-request',
      url: 'https://mcp.example.com',
      transport: 'streamableHttp',
      useHttp2: false,
      bearerToken: 'fixture-credential',
    );

CreateMcpServerRequest _createRequest(int workspaceId, String receipt) =>
    CreateMcpServerRequest(
      workspaceId: workspaceId,
      requestId: 'create-request',
      name: 'MCP server',
      url: 'https://mcp.example.com',
      transport: 'streamableHttp',
      useHttp2: false,
      description: null,
      bearerToken: 'fixture-credential',
      verificationReceipt: receipt,
    );

Future<String> _expiredReceipt(
  _Fixture fixture, {
  required String requestId,
}) async {
  final expiresAt = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
  final encrypted = await const WorkspaceSecretCipher().encrypt(
    fixture.session,
    jsonEncode({
      'workspaceId': fixture.workspaceId,
      'userId': fixture.userId,
      'requestId': requestId,
      'url': 'https://mcp.example.com',
      'transport': 'streamableHttp',
      'useHttp2': false,
      'bearerTokenDigest': await _bearerTokenDigest('fixture-credential'),
      'expiresAt': expiresAt.toIso8601String(),
      'discovery': _discovery().toJson(),
    }),
    workspaceId: fixture.workspaceId,
    resourceId: requestId,
  );

  return jsonEncode({
    'requestId': requestId,
    'ciphertext': _base64(encrypted.ciphertext),
    'nonce': _base64(encrypted.nonce),
    'authenticationTag': _base64(encrypted.authenticationTag),
  });
}

Future<String> _bearerTokenDigest(String token) async => base64UrlEncode(
  (await Sha256().hash(utf8.encode(token))).bytes,
);

String _base64(ByteData value) => base64Encode(
  value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes),
);

DiscoverMcpServerResult _discovery() => DiscoverMcpServerResult(
  health: McpServerHealth.healthy,
  tools: [
    DiscoveredMcpTool(
      name: 'sum',
      inputSchemaJson: jsonEncode({'type': 'object'}),
    ),
  ],
);

class _FakeMcpServerProbe extends McpServerProbe {
  var calls = 0;
  Map<String, String>? lastHeaders;

  @override
  Future<List<InternetAddress>> resolveAddresses(Uri uri) async => [
    InternetAddress('8.8.8.8'),
  ];

  @override
  Future<DiscoverMcpServerResult> call({
    required Uri uri,
    required String transport,
    required bool useHttp2,
    String? bearerToken,
    Map<String, String> httpHeaders = const {},
    List<InternetAddress>? resolvedAddresses,
    McpOutboundRequestFence? dispatchFence,
  }) async {
    calls++;
    lastHeaders = httpHeaders;

    return _discovery();
  }
}

class _WaitingMcpServerProbe extends McpServerProbe {
  _WaitingMcpServerProbe(this.entered, this.release);

  final Completer<void> entered;
  final Completer<void> release;
  var calls = 0;

  @override
  Future<List<InternetAddress>> resolveAddresses(Uri uri) async => [
    InternetAddress('8.8.8.8'),
  ];

  @override
  Future<DiscoverMcpServerResult> call({
    required Uri uri,
    required String transport,
    required bool useHttp2,
    String? bearerToken,
    Map<String, String> httpHeaders = const {},
    List<InternetAddress>? resolvedAddresses,
    McpOutboundRequestFence? dispatchFence,
  }) async {
    Future<DiscoverMcpServerResult> probe() async {
      calls++;
      entered.complete();
      await release.future;

      return _discovery();
    }

    final dispatch = dispatchFence;
    return dispatch == null ? probe() : dispatch(probe);
  }
}

Future<void> _removeMembership(_Fixture fixture) async {
  final membership = await WorkspaceMember.db.findFirstRow(
    fixture.session,
    where: (row) =>
        row.workspaceId.equals(fixture.workspaceId) &
        row.userId.equals(fixture.userId),
  );
  await WorkspaceMember.db.updateRow(
    fixture.session,
    membership!.copyWith(removedAt: DateTime.now().toUtc()),
  );
}

class _FailingMcpServerRepository extends McpServerRepository {
  @override
  Future<WorkspaceResource> insertResource(
    Session session, {
    required WorkspaceResource resource,
    required Transaction transaction,
  }) {
    if (resource.resourceKind == WorkspaceResourceKind.toolGroup) {
      throw Exception('resource insert failed');
    }

    return super.insertResource(
      session,
      resource: resource,
      transaction: transaction,
    );
  }
}

class _Fixture {
  const _Fixture({
    required this.session,
    required this.userId,
    required this.workspaceId,
  });

  final Session session;
  final String userId;
  final int workspaceId;

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
          name: 'MCP verification workspace',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );

    return _Fixture(
      session: session,
      userId: userId,
      workspaceId: workspace.id!,
    );
  }

  Future<({int resources, int secrets, int events, int receipts})>
  counts() async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) => table.workspaceId.equals(workspaceId),
    );
    final secrets = await WorkspaceSecret.db.find(
      session,
      where: (table) => table.workspaceId.equals(workspaceId),
    );
    final events = await WorkspaceEvent.db.find(
      session,
      where: (table) => table.workspaceId.equals(workspaceId),
    );
    final receipts = await WorkspaceMutationReceipt.db.find(
      session,
      where: (table) => table.workspaceId.equals(workspaceId),
    );

    return (
      resources: resources.length,
      secrets: secrets.length,
      events: events.length,
      receipts: receipts.length,
    );
  }
}
