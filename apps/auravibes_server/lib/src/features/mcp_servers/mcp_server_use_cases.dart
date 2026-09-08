import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspaces/domain/workspace_roles.dart';
import '../workspace_state/workspace_secret_cipher.dart';
import 'mcp_server_policy.dart';
import 'mcp_server_probe.dart';
import 'mcp_server_repository.dart';

class McpServerUseCases(
  final McpServerRepository _repository,
  final McpServerProbe _probe,
) {
  static const _endpointCreate = 'mcpServer.create';
  Future<CreateMcpServerResult> create(
    Session session, {
    required String userId,
    required CreateMcpServerRequest request,
  }) async {
    final name = request.name.trim();
    final url = request.url.trim();
    final description = request.description?.trim();
    if (request.requestId.isEmpty ||
        name.isEmpty ||
        name.length > 200 ||
        description != null && description.length > 4000) {
      _validation();
    }
    final hash = await _requestHash(
      workspaceId: request.workspaceId,
      name: name,
      url: url,
      transport: request.transport,
      useHttp2: request.useHttp2,
      description: description,
      bearerToken: request.bearerToken,
    );
    final existing = await session.db.transaction((transaction) async {
      await _authorize(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        transaction: transaction,
      );
      return _receiptResult(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        requestId: request.requestId,
        hash: hash,
        transaction: transaction,
      );
    });
    if (existing != null) return existing;
    final uri = McpServerPolicy.validateUri(url);
    final discovery = await _probe(
      uri: uri,
      transport: request.transport,
      useHttp2: request.useHttp2,
      bearerToken: request.bearerToken,
    );
    if (discovery.health != McpServerHealth.healthy) _validation();

    return session.db.transaction((transaction) async {
      await _authorize(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        transaction: transaction,
      );
      final workspace = await _repository.findWorkspace(
        session,
        workspaceId: request.workspaceId,
        transaction: transaction,
      );
      if (workspace == null) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.membershipRequired,
        );
      }
      final receipt = await _receiptResult(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        requestId: request.requestId,
        hash: hash,
        transaction: transaction,
      );
      if (receipt != null) return receipt;

      final now = DateTime.now().toUtc();
      final serverId = const Uuid().v7();
      final groupId = const Uuid().v7();
      final resources = [
        WorkspaceResource(
          workspaceId: request.workspaceId,
          resourceKind: WorkspaceResourceKind.mcpServer,
          resourceId: serverId,
          data: jsonEncode({
            'id': serverId,
            'name': name,
            'url': url,
            'transport': {
              'type': request.transport,
              'useHttp2': request.useHttp2,
            },
            'description': description,
            'isEnabled': true,
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
        WorkspaceResource(
          workspaceId: request.workspaceId,
          resourceKind: WorkspaceResourceKind.toolGroup,
          resourceId: groupId,
          data: jsonEncode({
            'id': groupId,
            'name': name,
            'mcpServerId': serverId,
            'isEnabled': true,
            'permissionMode': 'alwaysAsk',
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
        for (final tool in discovery.tools)
          WorkspaceResource(
            workspaceId: request.workspaceId,
            resourceKind: WorkspaceResourceKind.tool,
            resourceId: const Uuid().v7(),
            data: jsonEncode({
              'toolId': tool.name,
              'toolGroupId': groupId,
              'mcpServerId': serverId,
              'description': tool.description,
              'inputSchema': jsonDecode(tool.inputSchemaJson),
              'isEnabled': true,
              'permissionMode': 'alwaysAsk',
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
      ];
      for (final resource in resources) {
        await _repository.insertResource(
          session,
          resource: resource,
          transaction: transaction,
        );
      }
      if (request.bearerToken case final token? when token.isNotEmpty) {
        final encrypted = await const WorkspaceSecretCipher().encrypt(
          session,
          token,
          workspaceId: request.workspaceId,
          resourceId: serverId,
        );
        await _repository.insertSecret(
          session,
          secret: WorkspaceSecret(
            workspaceId: request.workspaceId,
            secretKind: WorkspaceSecretKind.mcp,
            scope: WorkspaceSecretScope.workspace,
            ownerUserId: 'workspace',
            resourceId: serverId,
            ciphertext: encrypted.ciphertext,
            nonce: encrypted.nonce,
            authenticationTag: encrypted.authenticationTag,
            algorithm: 'AES-256-GCM',
            keyVersion: 1,
            displaySuffix: _suffix(token),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
      var sequence = workspace.sequence;
      for (final resource in resources) {
        sequence++;
        await _repository.insertEvent(
          session,
          event: WorkspaceEvent(
            eventId: const Uuid().v7(),
            workspaceId: request.workspaceId,
            sequence: sequence,
            actorUserId: userId,
            kind: 'updated',
            resourceKind: resource.resourceKind.name,
            resourceId: resource.resourceId,
            createdAt: now,
          ),
          transaction: transaction,
        );
      }
      await _repository.updateWorkspace(
        session,
        workspace: workspace.copyWith(sequence: sequence, updatedAt: now),
        transaction: transaction,
      );
      final result = CreateMcpServerResult(
        mcpServerId: serverId,
        createdAt: now,
        discovery: discovery,
      );
      await _repository.insertReceipt(
        session,
        receipt: WorkspaceMutationReceipt(
          workspaceId: request.workspaceId,
          actorUserId: userId,
          scopeKey: 'workspace:${request.workspaceId}',
          endpoint: _endpointCreate,
          requestId: request.requestId,
          requestHash: hash,
          responseJson: jsonEncode(result.toJson()),
          createdAt: now,
        ),
        transaction: transaction,
      );
      return result;
    });
  }

  Future<void> delete(
    Session session, {
    required String userId,
    required DeleteMcpServerRequest request,
  }) async {
    if (request.mcpServerId.isEmpty) _validation();
    await session.db.transaction((transaction) async {
      await _authorize(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        transaction: transaction,
      );
      final workspace = await _repository.findWorkspace(
        session,
        workspaceId: request.workspaceId,
        transaction: transaction,
      );
      if (workspace == null) _membershipRequired();
      final server = await _repository.findServer(
        session,
        workspaceId: request.workspaceId,
        resourceId: request.mcpServerId,
        transaction: transaction,
      );
      if (server == null) return;
      final groups = (await _repository.findResources(
        session,
        workspaceId: request.workspaceId,
        kind: WorkspaceResourceKind.toolGroup,
        transaction: transaction,
      )).where((group) => _data(group)['mcpServerId'] == request.mcpServerId);
      final groupIds = groups.map((group) => group.resourceId).toSet();
      final tools =
          (await _repository.findResources(
            session,
            workspaceId: request.workspaceId,
            kind: WorkspaceResourceKind.tool,
            transaction: transaction,
          )).where((tool) {
            final data = _data(tool);
            return data['mcpServerId'] == request.mcpServerId ||
                groupIds.contains(data['toolGroupId']);
          });
      final toolIds = tools.map((tool) => tool.resourceId).toSet();
      final permissions =
          (await _repository.findResources(
            session,
            workspaceId: request.workspaceId,
            kind: WorkspaceResourceKind.toolPermission,
            transaction: transaction,
          )).where((permission) {
            final data = _data(permission);
            return groupIds.contains(data['toolGroupId']) ||
                toolIds.contains(data['toolId']);
          });
      final secrets = await _repository.findSecrets(
        session,
        workspaceId: request.workspaceId,
        resourceId: request.mcpServerId,
        transaction: transaction,
      );
      final now = DateTime.now().toUtc();
      final resources = [server, ...groups, ...tools, ...permissions];
      var sequence = workspace.sequence;
      for (final resource in resources) {
        await _repository.updateResource(
          session,
          resource: resource.copyWith(
            revision: resource.revision + 1,
            updatedAt: now,
            deletedAt: now,
          ),
          transaction: transaction,
        );
        sequence++;
        await _repository.insertEvent(
          session,
          event: WorkspaceEvent(
            eventId: const Uuid().v7(),
            workspaceId: request.workspaceId,
            sequence: sequence,
            actorUserId: userId,
            kind: 'deleted',
            resourceKind: resource.resourceKind.name,
            resourceId: resource.resourceId,
            createdAt: now,
          ),
          transaction: transaction,
        );
      }
      for (final secret in secrets) {
        await _repository.updateSecret(
          session,
          secret: secret.copyWith(
            revision: secret.revision + 1,
            updatedAt: now,
            deletedAt: now,
          ),
          transaction: transaction,
        );
      }
      await _repository.updateWorkspace(
        session,
        workspace: workspace.copyWith(sequence: sequence, updatedAt: now),
        transaction: transaction,
      );
    });
  }

  Future<void> _authorize(
    Session session, {
    required int workspaceId,
    required String userId,
    required Transaction transaction,
  }) async {
    final member = await _repository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (member == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    if (member.role != WorkspaceRoles.owner &&
        member.role != WorkspaceRoles.admin) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.permissionDenied,
      );
    }
  }

  Future<CreateMcpServerResult?> _receiptResult(
    Session session, {
    required int workspaceId,
    required String userId,
    required String requestId,
    required String hash,
    required Transaction transaction,
  }) async {
    final receipt = await _repository.findReceipt(
      session,
      workspaceId: workspaceId,
      userId: userId,
      endpoint: _endpointCreate,
      requestId: requestId,
      transaction: transaction,
    );
    if (receipt == null) return null;
    if (receipt.requestHash != hash) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.idempotencyConflict,
      );
    }
    return CreateMcpServerResult.fromJson(
      jsonDecode(receipt.responseJson) as Map<String, dynamic>,
    );
  }

  Future<String> _requestHash({
    required int workspaceId,
    required String name,
    required String url,
    required String transport,
    required bool useHttp2,
    required String? description,
    required String? bearerToken,
  }) async {
    final tokenDigest = base64UrlEncode(
      (await Sha256().hash(utf8.encode(bearerToken ?? ''))).bytes,
    );
    final bytes = await Sha256().hash(
      utf8.encode(
        jsonEncode({
          'workspaceId': workspaceId,
          'name': name,
          'url': url,
          'transport': transport,
          'useHttp2': useHttp2,
          'description': description,
          'bearerTokenDigest': tokenDigest,
        }),
      ),
    );
    return base64UrlEncode(bytes.bytes);
  }

  Future<DiscoverMcpServerResult> discoverAndCheck(
    Session session, {
    required String userId,
    required DiscoverMcpServerRequest request,
  }) async {
    if (request.mcpServerId.isEmpty) _validation();
    final member = await _repository.findMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    if (member == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    if (member.role != WorkspaceRoles.owner &&
        member.role != WorkspaceRoles.admin) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.permissionDenied,
      );
    }
    final resource = await _repository.findServer(
      session,
      workspaceId: request.workspaceId,
      resourceId: request.mcpServerId,
    );
    if (resource == null) _validation();
    final metadata = _metadata(resource.data);
    final secret = await _repository.findSecret(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      resourceId: request.mcpServerId,
    );
    try {
      return await _probe(
        uri: McpServerPolicy.validateUri(metadata.url),
        transport: metadata.transport,
        useHttp2: metadata.useHttp2,
        bearerToken: secret == null
            ? null
            : await const WorkspaceSecretCipher().decrypt(session, secret),
      );
    } on FormatException {
      return _unhealthy('invalid_response');
    } on TimeoutException {
      return _unhealthy('timeout');
    } on SocketException {
      return _unhealthy('unreachable');
    } on HttpException {
      return _unhealthy('http_error');
    } on HandshakeException {
      return _unhealthy('tls_error');
    }
  }

  _McpMetadata _metadata(String encoded) {
    final value = jsonDecode(encoded);
    if (value is! Map<String, Object?> || value['url'] is! String) {
      _validation();
    }
    final transport = value['transport'];
    if (transport is! Map<String, Object?> || transport['type'] is! String) {
      _validation();
    }
    return _McpMetadata(
      url: value['url']! as String,
      transport: transport['type']! as String,
      useHttp2: transport['useHttp2'] == true,
    );
  }

  Map<String, Object?> _data(WorkspaceResource resource) {
    final value = jsonDecode(resource.data);
    if (value is! Map<String, Object?>) _validation();
    return value;
  }

  DiscoverMcpServerResult _unhealthy(String code) => DiscoverMcpServerResult(
    health: McpServerHealth.unhealthy,
    tools: const [],
    errorCode: code,
  );

  Never _validation() => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.validationFailed,
  );

  Never _membershipRequired() => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.membershipRequired,
  );

  String _suffix(String secret) =>
      secret.length <= 4 ? secret : secret.substring(secret.length - 4);
}

class const _McpMetadata({
  required final String url,
  required final String transport,
  required final bool useHttp2,
});
