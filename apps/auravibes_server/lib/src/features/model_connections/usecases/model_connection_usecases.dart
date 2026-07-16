import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../mcp_servers/mcp_server_policy.dart';
import '../domain/virtual_workspace_model_selection.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../../workspace_state/workspace_secret_cipher.dart';
import '../repositories/model_connection_repository.dart';

typedef ModelCatalogFetcher =
    Future<Object?> Function(
      Uri uri,
      Map<String, String> headers,
      InternetAddress address,
    );

class ModelConnectionUseCases {
  ModelConnectionUseCases(
    this._repository, {
    ModelCatalogFetcher? fetch,
    Future<List<InternetAddress>> Function(String host)? lookup,
  }) : _fetch = fetch ?? _fetchJson,
       _lookup = lookup ?? InternetAddress.lookup;

  static const maxModels = 500;
  final ModelConnectionRepository _repository;
  final ModelCatalogFetcher _fetch;
  final Future<List<InternetAddress>> Function(String host) _lookup;

  Future<ModelConnectionView> create(
    Session session, {
    required String userId,
    required CreateModelConnectionRequest request,
  }) => session.db.transaction((transaction) async {
    _requireManager(
      await _requireMember(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
      ),
    );
    _requireConnectionInput(
      request.connectionId,
      request.name,
      request.providerId,
      request.url,
    );
    final existing = await _repository.findConnection(
      session,
      workspaceId: request.workspaceId,
      connectionId: request.connectionId,
    );
    if (existing != null) _invalid();
    final now = DateTime.now().toUtc();
    final connection = await _repository.insertConnection(
      session,
      WorkspaceModelConnection(
        workspaceId: request.workspaceId,
        connectionId: request.connectionId,
        providerId: request.providerId,
        name: request.name.trim(),
        url: request.url?.trim(),
        hasSecret: false,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await _recordWorkspaceEvent(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      resourceId: connection.connectionId,
      kind: 'created',
      transaction: transaction,
    );
    return _connectionView(connection, null);
  });

  Future<List<ModelConnectionView>> list(
    Session session, {
    required String userId,
    required ListModelConnectionsRequest request,
  }) async {
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    final connections = await _repository.listConnections(
      session,
      workspaceId: request.workspaceId,
    );
    return Future.wait([
      for (final connection in connections)
        _connectionViewForUser(session, connection, userId),
    ]);
  }

  Future<ModelConnectionView> update(
    Session session, {
    required String userId,
    required UpdateModelConnectionRequest request,
  }) => session.db.transaction((transaction) async {
    _requireManager(
      await _requireMember(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
      ),
    );
    _requireConnectionInput(
      request.connectionId,
      request.name,
      'provider',
      request.url,
    );
    final connection = await _repository.findConnection(
      session,
      workspaceId: request.workspaceId,
      connectionId: request.connectionId,
    );
    if (connection == null || connection.revision != request.expectedRevision) {
      _invalid();
    }
    final updated = await _repository.updateConnection(
      session,
      connection.copyWith(
        name: request.name.trim(),
        url: request.url?.trim(),
        revision: connection.revision + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
    await _recordWorkspaceEvent(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      resourceId: updated.connectionId,
      kind: 'updated',
      transaction: transaction,
    );
    return _connectionViewForUser(session, updated, userId);
  });

  Future<void> delete(
    Session session, {
    required String userId,
    required DeleteModelConnectionRequest request,
  }) => session.db.transaction((transaction) async {
    _requireManager(
      await _requireMember(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
      ),
    );
    final connection = await _repository.findConnection(
      session,
      workspaceId: request.workspaceId,
      connectionId: request.connectionId,
    );
    if (connection == null || connection.revision != request.expectedRevision) {
      _invalid();
    }
    await _repository.updateConnection(
      session,
      connection.copyWith(
        deletedAt: DateTime.now().toUtc(),
        revision: connection.revision + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
    await _recordWorkspaceEvent(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      resourceId: connection.connectionId,
      kind: 'deleted',
      transaction: transaction,
    );
  });

  Future<void> _recordWorkspaceEvent(
    Session session, {
    required int workspaceId,
    required String userId,
    required String resourceId,
    required String kind,
    required Transaction transaction,
  }) async {
    final workspace = await CloudWorkspace.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(workspaceId) & table.deletedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) _permissionDenied();
    final now = DateTime.now().toUtc();
    final sequence = workspace.sequence + 1;
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(sequence: sequence, updatedAt: now),
      transaction: transaction,
    );
    await WorkspaceEvent.db.insertRow(
      session,
      WorkspaceEvent(
        eventId: const Uuid().v7(),
        workspaceId: workspaceId,
        sequence: sequence,
        actorUserId: userId,
        kind: kind,
        resourceKind: WorkspaceResourceKind.modelConnection.name,
        resourceId: resourceId,
        createdAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<List<WorkspaceModelSelectionView>> listSelections(
    Session session, {
    required String userId,
    required ListWorkspaceModelSelectionsRequest request,
  }) async {
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    final connections = await _repository.listConnections(
      session,
      workspaceId: request.workspaceId,
    );
    final views = <WorkspaceModelSelectionView>[];
    for (final connection in connections) {
      final secret = await _repository.findSecret(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        connectionId: connection.connectionId,
      );
      final models = await _repository.listCatalogModels(
        session,
        providerId: connection.providerId,
      );
      views.addAll(
        models.map((model) => _selectionView(connection, model, secret)),
      );
    }
    return views;
  }

  Future<ModelSyncResult> testAndSync(
    Session session, {
    required String userId,
    required TestAndSyncModelConnectionRequest request,
  }) async {
    final member = await _repository.findMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    if (member == null) _permissionDenied();
    _requireManager(member);
    final connection = await _repository.findConnection(
      session,
      workspaceId: request.workspaceId,
      connectionId: request.connectionId,
    );
    final secret = await _repository.findSecret(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      connectionId: request.connectionId,
    );
    if (connection == null || secret == null) return _invalid();

    final providerId = connection.providerId;
    final validated = await validatePublicHttpsUri(
      connection.url ?? defaultProviderUrl(providerId),
      lookup: _lookup,
    );
    final apiKey = await const WorkspaceSecretCipher().decrypt(session, secret);
    final headers = providerHeaders(providerId, apiKey);
    final response = await _fetch(
      modelCatalogUri(providerId, validated.uri),
      headers,
      validated.address,
    );
    final modelIds = parseModelIds(response, maxModels: maxModels);
    if (modelIds.isEmpty) return _invalid();
    return ModelSyncResult(providerId: providerId, modelIds: modelIds);
  }

  Future<WorkspaceMember> _requireMember(
    Session session, {
    required int workspaceId,
    required String userId,
  }) async {
    final member = await _repository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
    );
    if (member == null) _permissionDenied();
    return member;
  }

  void _requireManager(WorkspaceMember member) {
    if (member.role != WorkspaceRoles.owner &&
        member.role != WorkspaceRoles.admin) {
      _permissionDenied();
    }
  }

  void _requireConnectionInput(
    String connectionId,
    String name,
    String providerId,
    String? url,
  ) {
    if (connectionId.trim().isEmpty ||
        name.trim().isEmpty ||
        providerId.trim().isEmpty ||
        connectionId.length > 200 ||
        name.length > 500 ||
        providerId.length > 200 ||
        (url != null && url.trim().isEmpty)) {
      _invalid();
    }
  }

  Future<ModelConnectionView> _connectionViewForUser(
    Session session,
    WorkspaceModelConnection connection,
    String userId,
  ) async => _connectionView(
    connection,
    await _repository.findSecret(
      session,
      workspaceId: connection.workspaceId,
      userId: userId,
      connectionId: connection.connectionId,
    ),
  );

  ModelConnectionView _connectionView(
    WorkspaceModelConnection connection,
    WorkspaceSecret? secret,
  ) => ModelConnectionView(
    id: connection.connectionId,
    name: connection.name,
    providerId: connection.providerId,
    url: connection.url,
    hasSecret: secret != null,
    keySuffix: secret?.displaySuffix,
    revision: connection.revision,
    createdAt: connection.createdAt,
    updatedAt: connection.updatedAt,
  );

  WorkspaceModelSelectionView _selectionView(
    WorkspaceModelConnection connection,
    ApiModel model,
    WorkspaceSecret? secret,
  ) => WorkspaceModelSelectionView(
    id: VirtualWorkspaceModelSelectionId.encode(
      connectionId: connection.connectionId,
      modelId: model.modelId,
    ),
    connectionId: connection.connectionId,
    connectionName: connection.name,
    connectionUrl: connection.url,
    connectionHasSecret: secret != null,
    connectionKeySuffix: secret?.displaySuffix,
    providerId: model.providerId,
    modelId: model.modelId,
    modelName: model.name,
    revision: connection.revision,
    createdAt: connection.createdAt,
    updatedAt: connection.updatedAt,
  );
}

String defaultProviderUrl(String providerId) => switch (providerId) {
  'openai-codex' => 'https://chatgpt.com/backend-api/codex/',
  'openai' => 'https://api.openai.com/v1',
  'openrouter' => 'https://openrouter.ai/api/v1',
  'anthropic' => 'https://api.anthropic.com/v1',
  _ => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.validationFailed,
  ),
};

Map<String, String> providerHeaders(String providerId, String apiKey) =>
    switch (providerId) {
      'openai-codex' => {
        'authorization': 'Bearer $apiKey',
        'originator': 'auravibes',
        'user-agent': 'AuraVibes',
      },
      'anthropic' => {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      'openai' || 'openrouter' => {'authorization': 'Bearer $apiKey'},
      _ => _invalid(),
    };

Uri modelCatalogUri(String providerId, Uri baseUri) {
  final path = baseUri.path.replaceFirst(RegExp(r'/$'), '');
  return baseUri.replace(
    path: '$path/models',
    queryParameters: providerId == 'anthropic'
        ? {'limit': '${ModelConnectionUseCases.maxModels}'}
        : null,
  );
}

List<String> parseModelIds(Object? response, {required int maxModels}) {
  if (response is! Map<String, dynamic> || response['data'] is! List) {
    return _invalid();
  }
  final ids = <String>[];
  for (final item in response['data'] as List) {
    if (item is! Map ||
        item['id'] is! String ||
        (item['id'] as String).isEmpty) {
      return _invalid();
    }
    if (ids.length == maxModels) break;
    ids.add(item['id'] as String);
  }
  return List.unmodifiable(ids);
}

Future<Uri> requirePublicHttpsUri(
  String source, {
  required Future<List<InternetAddress>> Function(String host) lookup,
}) async {
  return (await validatePublicHttpsUri(source, lookup: lookup)).uri;
}

class ValidatedPublicUri {
  const ValidatedPublicUri(this.uri, this.address);
  final Uri uri;
  final InternetAddress address;
}

Future<ValidatedPublicUri> validatePublicHttpsUri(
  String source, {
  required Future<List<InternetAddress>> Function(String host) lookup,
}) async {
  final uri = Uri.tryParse(source);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    return _invalid();
  }
  final addresses = await lookup(uri.host);
  if (addresses.isEmpty || addresses.any((address) => !_isPublic(address))) {
    return _invalid();
  }
  return ValidatedPublicUri(uri, addresses.first);
}

bool _isPublic(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    final a = bytes[0];
    final b = bytes[1];
    final c = bytes[2];
    return a != 0 &&
        a != 10 &&
        !(a == 100 && b >= 64 && b <= 127) &&
        a != 127 &&
        !(a == 169 && b == 254) &&
        !(a == 172 && b >= 16 && b <= 31) &&
        !(a == 192 && b == 0) &&
        !(a == 192 && b == 0 && c == 2) &&
        !(a == 192 && b == 88 && c == 99) &&
        !(a == 192 && b == 168) &&
        !(a == 198 && (b == 18 || b == 19)) &&
        !(a == 198 && b == 51 && c == 100) &&
        !(a == 203 && b == 0 && c == 113) &&
        a < 224;
  }
  final isIpv4Compatible = bytes.take(12).every((byte) => byte == 0);
  final isIpv4Mapped =
      bytes.take(10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (isIpv4Compatible || isIpv4Mapped) {
    return _isPublic(InternetAddress.fromRawAddress(bytes.sublist(12)));
  }
  return bytes.any((byte) => byte != 0) &&
      !(bytes.take(15).every((byte) => byte == 0) && bytes[15] == 1) &&
      (bytes[0] & 0xfe) != 0xfc &&
      !(bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80) &&
      !(bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0xc0) &&
      bytes[0] != 0xff &&
      !(bytes[0] == 0x20 &&
          bytes[1] == 0x01 &&
          bytes[2] == 0x0d &&
          bytes[3] == 0xb8);
}

Future<Object?> _fetchJson(
  Uri uri,
  Map<String, String> headers,
  InternetAddress address,
) async {
  final client = pinnedHttpClient(address);
  try {
    final request = await client.getUrl(uri);
    headers.forEach(request.headers.set);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _invalid();
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('Model catalog response is too large.');
      }
    }
    return jsonDecode(utf8.decode(bytes));
  } finally {
    client.close(force: true);
  }
}

HttpClient pinnedHttpClient(InternetAddress address) => HttpClient()
  ..connectionTimeout = const Duration(seconds: 10)
  ..connectionFactory = (target, proxyHost, proxyPort) async {
    final task = await Socket.startConnect(address, target.port);
    return ConnectionTask.fromSocket(
      task.socket.then(
        (socket) => SecureSocket.secure(socket, host: target.host),
      ),
      task.cancel,
    );
  };

Never _invalid() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.validationFailed,
);

Never _permissionDenied() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.permissionDenied,
);
