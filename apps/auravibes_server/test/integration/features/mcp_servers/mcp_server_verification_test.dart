import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_server/src/features/mcp_servers/mcp_server_probe.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_server_repository.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_server_use_cases.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_secret_cipher.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('MCP server verification', (sessionBuilder, _) {
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
      final probe = _FakeMcpServerProbe();
      final useCases = McpServerUseCases(McpServerRepository(), probe);

      await expectLater(
        useCases.verify(
          fixture.session,
          userId: 'not-a-member',
          request: _verifyRequest(fixture.workspaceId),
        ),
        throwsA(_cloudError(CloudWorkspaceErrorCode.membershipRequired)),
      );

      expect(probe.calls, 0);
      expect((await fixture.counts()).resources, 0);
    });

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
  });
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

  @override
  Future<DiscoverMcpServerResult> call({
    required Uri uri,
    required String transport,
    required bool useHttp2,
    String? bearerToken,
  }) async {
    calls++;

    return _discovery();
  }
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
    final userId = const Uuid().v4().toString();
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
