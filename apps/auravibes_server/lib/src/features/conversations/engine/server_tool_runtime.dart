import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

enum ServerToolDisposition { completed, awaitingApproval }

enum ServerToolReplayAction { execute, pause, skip }

bool serverToolIsExecutable(AgentResolvedToolName descriptor) =>
    descriptor.kind == AgentResolvedToolKind.mcp ||
    descriptor.kind == AgentResolvedToolKind.skillTemplate ||
    (descriptor.kind == AgentResolvedToolKind.skillNative &&
        (descriptor.skillSlug == agentsSkillSlug ||
            serviceSkillDefinitions.any(
              (skill) => skill.slug == descriptor.skillSlug,
            )));

ServerToolReplayAction serverToolReplayAction(String status) =>
    switch (status) {
      'approved' => ServerToolReplayAction.execute,
      'pending' => ServerToolReplayAction.pause,
      _ => ServerToolReplayAction.skip,
    };

class ServerResolvedTool {
  const ServerResolvedTool({required this.descriptor, required this.spec});

  final AgentResolvedToolName descriptor;
  final ToolSpec spec;
}

class ServerToolRequest {
  const ServerToolRequest({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}

typedef ServerToolExecutor =
    Future<Object?> Function(
      Session session,
      ConversationTurn turn,
      ServerResolvedTool tool,
      Map<String, dynamic> arguments,
    );

/// Server-owned persistence and policy around deterministic engine tool names.
class ServerToolRuntime {
  ServerToolRuntime({
    this._resolver = const AgentToolNameResolver(),
    this._executor,
  });

  static const maxResultCharacters = 50000;

  final AgentToolNameResolver _resolver;
  final ServerToolExecutor? _executor;

  Future<List<ServerResolvedTool>> loadTools(
    Session session, {
    required int workspaceId,
    required String conversationStableId,
  }) async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) & table.deletedAt.equals(null),
    );
    final selectedIds = resources
        .where(
          (resource) =>
              resource.resourceKind ==
              WorkspaceResourceKind.conversationToolSelection,
        )
        .map(_data)
        .where((data) => data['conversationId'] == conversationStableId)
        .map((data) => data['toolId'])
        .whereType<String>()
        .toSet();

    return resources
        .where(
          (resource) => resource.resourceKind == WorkspaceResourceKind.tool,
        )
        .where(
          (resource) =>
              selectedIds.isEmpty || selectedIds.contains(resource.resourceId),
        )
        .map(_tool)
        .whereType<ServerResolvedTool>()
        .toList(growable: false);
  }

  Future<ServerToolDisposition> handle(
    Session session, {
    required ConversationTurn turn,
    required int messageId,
    required ServerToolRequest request,
    required List<ServerResolvedTool> tools,
  }) async {
    final tool = tools
        .where((candidate) => candidate.spec.name == request.name)
        .firstOrNull;
    final argumentsJson = jsonEncode(request.arguments);
    final digest = await _digest(argumentsJson);
    final existing = await ConversationToolCall.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.stableId.equals(request.id),
    );
    if (existing != null) {
      if (existing.name != request.name ||
          (existing.decision == null && existing.argumentsDigest != digest)) {
        throw const FormatException('Tool call identity changed.');
      }
      final replay = serverToolReplayAction(existing.status);
      if (replay == ServerToolReplayAction.pause) {
        return ServerToolDisposition.awaitingApproval;
      }
      if (replay == ServerToolReplayAction.skip) {
        return ServerToolDisposition.completed;
      }
      request = ServerToolRequest(
        id: request.id,
        name: request.name,
        arguments: _jsonMap(existing.argumentsJson),
      );
    }

    if (tool == null) {
      await _insertResolved(
        session,
        turn: turn,
        messageId: messageId,
        request: request,
        argumentsJson: argumentsJson,
        digest: digest,
        status: 'toolNotFound',
      );
      return ServerToolDisposition.completed;
    }
    if (!serverToolIsExecutable(tool.descriptor)) {
      await _insertResolved(
        session,
        turn: turn,
        messageId: messageId,
        request: request,
        argumentsJson: argumentsJson,
        digest: digest,
        status: AgentToolPermissionResult.notConfigured.name,
      );
      return ServerToolDisposition.completed;
    }
    final permission = await _permission(
      session,
      workspaceId: turn.workspaceId,
      toolId: tool.descriptor.tableId,
    );
    if (existing == null &&
        permission == AgentToolPermissionResult.needsConfirmation) {
      await _insertResolved(
        session,
        turn: turn,
        messageId: messageId,
        request: request,
        argumentsJson: argumentsJson,
        digest: digest,
        status: 'pending',
      );
      return ServerToolDisposition.awaitingApproval;
    }
    if (existing == null && permission != AgentToolPermissionResult.granted) {
      await _insertResolved(
        session,
        turn: turn,
        messageId: messageId,
        request: request,
        argumentsJson: argumentsJson,
        digest: digest,
        status: permission.name,
      );
      return ServerToolDisposition.completed;
    }

    final call =
        existing ??
        await _insertResolved(
          session,
          turn: turn,
          messageId: messageId,
          request: request,
          argumentsJson: argumentsJson,
          digest: digest,
          status: 'running',
        );
    if (existing != null) {
      await ConversationToolCall.db.updateRow(
        session,
        existing.copyWith(status: 'running', updatedAt: DateTime.now().toUtc()),
      );
    }
    final executor = _executor;
    if (executor == null) {
      throw StateError('Server tool executor is not configured.');
    }
    try {
      final result = await executor(session, turn, tool, request.arguments);
      await _finish(session, call, 'success', _boundedJson(result));
    } on Object {
      await _finish(session, call, 'executionError', null);
      rethrow;
    }
    return ServerToolDisposition.completed;
  }

  Future<AgentToolPermissionResult> _permission(
    Session session, {
    required int workspaceId,
    required String toolId,
  }) async {
    final permissions = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.toolPermission) &
          table.deletedAt.equals(null),
      orderBy: (table) => table.id,
      orderDescending: true,
    );
    final permission = permissions
        .where((candidate) => _data(candidate)['toolId'] == toolId)
        .firstOrNull;
    if (permission == null) return AgentToolPermissionResult.notConfigured;
    final data = _data(permission);
    if (data['isEnabled'] == false) {
      return AgentToolPermissionResult.disabledInWorkspace;
    }
    return switch (data['permissionMode']) {
      'alwaysAllow' => AgentToolPermissionResult.granted,
      'alwaysDeny' => AgentToolPermissionResult.disabledInWorkspace,
      _ => AgentToolPermissionResult.needsConfirmation,
    };
  }

  ServerResolvedTool? _tool(WorkspaceResource resource) {
    final data = _data(resource);
    final name = data['name'] ?? data['fullName'];
    if (name is! String || name.isEmpty) return null;
    final descriptor = _resolver.resolve(name);
    if (descriptor == null) return null;
    final schema = data['inputSchema'] ?? data['inputJsonSchema'];
    return ServerResolvedTool(
      descriptor: descriptor,
      spec: ToolSpec(
        name: name,
        description: data['description'] is String
            ? data['description']! as String
            : '',
        inputJsonSchema: schema is Map
            ? Map<String, Object?>.from(schema)
            : const {'type': 'object', 'properties': <String, Object?>{}},
      ),
    );
  }

  Future<ConversationToolCall> _insertResolved(
    Session session, {
    required ConversationTurn turn,
    required int messageId,
    required ServerToolRequest request,
    required String argumentsJson,
    required String digest,
    required String status,
  }) {
    final now = DateTime.now().toUtc();
    return ConversationToolCall.db.insertRow(
      session,
      ConversationToolCall(
        workspaceId: turn.workspaceId,
        conversationId: turn.conversationId,
        turnId: turn.id!,
        messageId: messageId,
        stableId: request.id,
        name: request.name,
        argumentsJson: argumentsJson,
        argumentsDigest: digest,
        status: status,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _finish(
    Session session,
    ConversationToolCall call,
    String status,
    String? result,
  ) async {
    await ConversationToolCall.db.updateRow(
      session,
      call.copyWith(
        status: status,
        resultJson: result,
        revision: call.revision + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Map<String, dynamic> _data(WorkspaceResource resource) {
    final value = jsonDecode(resource.data);
    if (value is! Map<String, dynamic>) throw const FormatException();
    return value;
  }

  Future<String> _digest(String value) async {
    final hash = await Sha256().hash(utf8.encode(value));
    return base64UrlEncode(hash.bytes);
  }

  Map<String, dynamic> _jsonMap(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  String _boundedJson(Object? value) {
    final encoded = jsonEncode(value);
    return encoded.length <= maxResultCharacters
        ? encoded
        : jsonEncode(encoded.substring(0, maxResultCharacters));
  }
}
