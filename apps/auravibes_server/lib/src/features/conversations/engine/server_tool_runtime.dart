import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import 'conversation_host_effects.dart';

enum ServerToolDisposition { completed, awaitingApproval }

enum ServerToolReplayAction { execute, pause, recover, skip }

String serverToolExecutionFailureCode(Object error) => switch (error) {
  FormatException() => 'invalid_request',
  CloudWorkspaceException(:final code) => 'workspace_${code.name}',
  _ => 'unexpected',
};

bool serverToolIsExecutable(AgentResolvedToolName descriptor) =>
    descriptor.kind == AgentResolvedToolKind.mcp ||
    descriptor.kind == AgentResolvedToolKind.skillTemplate ||
    (descriptor.kind == AgentResolvedToolKind.skillControl &&
        skillControlToolNames.contains(descriptor.toolIdentifier)) ||
    (descriptor.kind == AgentResolvedToolKind.skillNative &&
        (descriptor.skillSlug == agentsSkillSlug ||
            serviceSkillDefinitions.any(
              (skill) =>
                  skill.slug == descriptor.skillSlug &&
                  skill.nativeTools.any(
                    (tool) =>
                        tool.slug == descriptor.toolIdentifier &&
                        tool.urlTemplate != null,
                  ),
            )));

bool isCloudToolEnabled({
  required Map<String, dynamic> toolData,
  Map<String, dynamic>? toolGroupData,
}) => toolData['isEnabled'] != false && toolGroupData?['isEnabled'] != false;

List<ServerResolvedTool> materializeCloudSkillControlTools({
  required Set<String> selectedSkillIds,
  required Iterable<Map<String, dynamic>> userSkills,
  Iterable<Map<String, dynamic>> templateTools = const [],
  required Iterable<Map<String, dynamic>> appSkillSettings,
  Iterable<Map<String, dynamic>> serviceConnections = const [],
  required bool isChildConversation,
}) {
  final selectable = <String>[
    if (!isChildConversation &&
        cloudAppSkillEnabled(agentsSkillSlug, appSkillSettings))
      agentsSkillSlug,
    for (final skill in userSkills)
      if (cloudUserSkillReady(skill, templateTools, serviceConnections))
        if (skill['slug'] case final String slug) slug,
    for (final skill in serviceSkillDefinitions)
      if (cloudAppSkillEnabled(skill.identifier, appSkillSettings) &&
          cloudServiceSkillReady(skill, serviceConnections))
        skill.identifier,
  ];
  final selected = <String>[
    for (final skill in userSkills)
      if (skill['id'] case final String id)
        if (selectedSkillIds.contains(id))
          if (skill['slug'] case final String slug) slug,
    if (!isChildConversation && selectedSkillIds.contains(agentsSkillSlug))
      agentsSkillSlug,
    for (final skill in serviceSkillDefinitions)
      if (selectedSkillIds.contains(skill.identifier) ||
          selectedSkillIds.contains(skill.slug))
        skill.identifier,
  ];
  final loadable = selectable
      .where((slug) => !selected.contains(slug))
      .toSet()
      .toList(growable: false);
  return buildSkillControlToolSpecs(
        loadableSkillSlugs: loadable,
        loadedSkillSlugs: selected,
      )
      .map((spec) {
        final descriptor = AgentResolvedToolName.skillControl(
          toolIdentifier: spec.name,
        );
        return ServerResolvedTool(descriptor: descriptor, spec: spec);
      })
      .toList(growable: false);
}

bool cloudUserSkillReady(
  Map<String, dynamic> skill,
  Iterable<Map<String, dynamic>> templateTools,
  Iterable<Map<String, dynamic>> serviceConnections,
) {
  final skillId = skill['id'];
  if (skillId is! String || skill['isEnabled'] == false) return false;
  final credentialIds = _templateCredentialIds(skill, serviceConnections);
  return templateTools.any(
    (tool) =>
        tool['skillId'] == skillId &&
        tool['isEnabled'] != false &&
        (tool['requiresCredential'] != true || credentialIds.isNotEmpty),
  );
}

List<ServerResolvedTool> materializeCloudSkillTools({
  required Set<String> selectedSkillIds,
  required Iterable<Map<String, dynamic>> userSkills,
  required Iterable<Map<String, dynamic>> templateTools,
  required Iterable<Map<String, dynamic>> appSkillSettings,
  Iterable<Map<String, dynamic>> serviceConnections = const [],
  required bool isChildConversation,
}) {
  final enabledUserSkills = {
    for (final skill in userSkills)
      if (skill['id'] case final String id when skill['isEnabled'] != false)
        id: skill,
  };
  final tools = <ServerResolvedTool>[];
  for (final tool in templateTools) {
    final skillId = tool['skillId'];
    final skillSlug = tool['skillSlug'];
    final toolSlug = tool['toolSlug'] ?? tool['slug'];
    if (skillId is! String ||
        skillSlug is! String ||
        toolSlug is! String ||
        tool['isEnabled'] == false ||
        !selectedSkillIds.contains(skillId) ||
        !enabledUserSkills.containsKey(skillId)) {
      continue;
    }
    final credentialIds = _templateCredentialIds(
      enabledUserSkills[skillId],
      serviceConnections,
    );
    if (tool['requiresCredential'] == true && credentialIds.isEmpty) {
      continue;
    }
    final descriptor = AgentResolvedToolName.skillTemplate(
      tableId: tool['id'] is String
          ? tool['id']! as String
          : 'skill__user__${skillSlug}__$toolSlug',
      skillSlug: skillSlug,
      toolIdentifier: toolSlug,
    );
    if (!serverToolIsExecutable(descriptor)) continue;
    tools.add(
      ServerResolvedTool(
        descriptor: descriptor,
        spec: ToolSpec(
          name: descriptor.fullName,
          description: tool['description'] is String
              ? tool['description']! as String
              : '',
          inputJsonSchema: cloudTemplateInputSchema(
            tool['inputsJson'],
            requiresCredential: tool['requiresCredential'] == true,
            credentialIds: credentialIds,
          ),
        ),
      ),
    );
  }
  if (!isChildConversation &&
      selectedSkillIds.contains(agentsSkillSlug) &&
      cloudAppSkillEnabled(agentsSkillSlug, appSkillSettings)) {
    tools.addAll(
      subAgentToolSpecs.map(
        (spec) => _nativeTool(
          skillSlug: agentsSkillSlug,
          toolIdentifier: spec.name,
          description: spec.description,
          inputJsonSchema: spec.inputJsonSchema,
        ),
      ),
    );
  }
  for (final skill in serviceSkillDefinitions) {
    if (!selectedSkillIds.contains(skill.identifier) &&
        !selectedSkillIds.contains(skill.slug)) {
      continue;
    }
    if (!cloudAppSkillEnabled(skill.identifier, appSkillSettings) ||
        !cloudServiceSkillReady(skill, serviceConnections)) {
      continue;
    }
    final credentialIds = _serviceCredentialIds(skill, serviceConnections);
    for (final tool in skill.nativeTools) {
      if (tool.urlTemplate == null ||
          (tool.requiresCredential && credentialIds.isEmpty)) {
        continue;
      }
      tools.add(
        _nativeTool(
          skillSlug: skill.slug,
          toolIdentifier: tool.slug,
          description: tool.description,
          inputJsonSchema: cloudNativeInputSchema(
            tool.inputJsonSchema,
            requiresCredential: tool.requiresCredential,
            credentialIds: credentialIds,
          ),
        ),
      );
    }
  }
  return tools
      .where((tool) => serverToolIsExecutable(tool.descriptor))
      .fold(<String, ServerResolvedTool>{}, (unique, tool) {
        unique.putIfAbsent(tool.spec.name, () => tool);
        return unique;
      })
      .values
      .toList(growable: false);
}

Map<String, Object?> cloudTemplateInputSchema(
  Object? inputsJson, {
  required bool requiresCredential,
  Iterable<String> credentialIds = const [],
}) {
  return templateInputSchema(
    inputsJson,
    requiresCredential: requiresCredential,
    credentialIds: credentialIds,
  );
}

Map<String, Object?> cloudNativeInputSchema(
  Map<String, Object?> inputJsonSchema, {
  required bool requiresCredential,
  Iterable<String> credentialIds = const [],
}) {
  return materializeSkillToolSchema(
    inputJsonSchema,
    requiresCredential: requiresCredential,
    credentialIds: credentialIds,
  );
}

List<String> _templateCredentialIds(
  Map<String, dynamic>? skill,
  Iterable<Map<String, dynamic>> connections,
) {
  final definitionId = skill?['credentialDefinitionId'];
  if (definitionId is! String) return const [];
  return connections
      .where(
        (connection) =>
            connection['kind'] == 'skillCredential' &&
            connection['credentialDefinitionId'] == definitionId &&
            connection['isEnabled'] == true &&
            connection['hasSecret'] == true,
      )
      .map((connection) => connection['id'])
      .whereType<String>()
      .toList(growable: false);
}

List<String> _serviceCredentialIds(
  AppSkillDefinition skill,
  Iterable<Map<String, dynamic>> connections,
) => connections
    .where(
      (connection) =>
          connection['kind'] == 'appSkillCredential' &&
          connection['serviceId'] == skill.identifier &&
          connection['isEnabled'] != false &&
          connection['hasSecret'] == true,
    )
    .map((connection) => connection['id'])
    .whereType<String>()
    .toList(growable: false);

ServerResolvedTool _nativeTool({
  required String skillSlug,
  required String toolIdentifier,
  required String description,
  required Map<String, Object?> inputJsonSchema,
}) {
  final descriptor = AgentResolvedToolName.skillNative(
    tableId: 'skill__app__${skillSlug}__$toolIdentifier',
    skillSlug: skillSlug,
    toolIdentifier: toolIdentifier,
  );
  return ServerResolvedTool(
    descriptor: descriptor,
    spec: ToolSpec(
      name: descriptor.fullName,
      description: description,
      inputJsonSchema: inputJsonSchema,
    ),
  );
}

bool cloudAppSkillEnabled(
  String skillId,
  Iterable<Map<String, dynamic>> settings,
) {
  final setting = settings
      .where((candidate) => candidate['skillId'] == skillId)
      .lastOrNull;
  return setting?['isEnabled'] == true ||
      (setting == null && skillId == agentsSkillSlug);
}

bool cloudServiceSkillReady(
  AppSkillDefinition skill,
  Iterable<Map<String, dynamic>> serviceConnections,
) => skill.nativeTools.any(
  (tool) =>
      tool.urlTemplate != null &&
      (!tool.requiresCredential ||
          serviceConnections.any(
            (connection) =>
                connection['kind'] == 'appSkillCredential' &&
                connection['serviceId'] == skill.identifier &&
                connection['isEnabled'] != false &&
                connection['hasSecret'] == true,
          )),
);

AgentToolPermissionResult resolveCloudToolPermission({
  required AgentToolPermissionResult workspacePermission,
  String? agentPermissionMode,
}) {
  if (workspacePermission != AgentToolPermissionResult.granted &&
      workspacePermission != AgentToolPermissionResult.needsConfirmation) {
    return workspacePermission;
  }
  return switch (agentPermissionMode) {
    'alwaysAllow' => AgentToolPermissionResult.granted,
    'alwaysDeny' => AgentToolPermissionResult.disabledInWorkspace,
    'alwaysAsk' => AgentToolPermissionResult.needsConfirmation,
    _ => workspacePermission,
  };
}

AgentToolPermissionResult defaultCloudToolPermission(
  AgentResolvedToolName descriptor,
) =>
    (descriptor.isSkill ||
            descriptor.kind == AgentResolvedToolKind.skillControl) &&
        serverToolIsExecutable(descriptor)
    ? AgentToolPermissionResult.needsConfirmation
    : AgentToolPermissionResult.notConfigured;

ServerToolReplayAction serverToolReplayAction(String status) =>
    switch (status) {
      'approved' => ServerToolReplayAction.execute,
      'pending' => ServerToolReplayAction.pause,
      'running' => ServerToolReplayAction.recover,
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
      ServerToolRequest request,
    );

/// Server-owned persistence and policy around deterministic engine tool names.
class ServerToolRuntime {
  ServerToolRuntime({
    this._resolver = const AgentToolNameResolver(
      skillControlToolNames: skillControlToolNames,
    ),
    this._executor,
    this.cancellationProbe = const DatabaseConversationCancellationProbe(),
  });

  static const maxResultCharacters = 50000;

  final AgentToolNameResolver _resolver;
  final ServerToolExecutor? _executor;
  final ConversationCancellationProbe cancellationProbe;

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
    final selectedSkillIds = resources
        .where(
          (resource) =>
              resource.resourceKind ==
              WorkspaceResourceKind.conversationSkillSelection,
        )
        .map(_data)
        .where((data) => data['conversationId'] == conversationStableId)
        .map((data) => data['skillId'])
        .whereType<String>()
        .toSet();
    final toolGroups = {
      for (final resource in resources.where(
        (resource) => resource.resourceKind == WorkspaceResourceKind.toolGroup,
      ))
        resource.resourceId: _data(resource),
    };
    final genericTools = resources
        .where(
          (resource) => resource.resourceKind == WorkspaceResourceKind.tool,
        )
        .where(
          (resource) =>
              selectedIds.isEmpty || selectedIds.contains(resource.resourceId),
        )
        .where((resource) {
          final data = _data(resource);
          final toolGroupId = data['toolGroupId'];
          return isCloudToolEnabled(
            toolData: data,
            toolGroupData: toolGroupId is String
                ? toolGroups[toolGroupId]
                : null,
          );
        })
        .map(_tool)
        .whereType<ServerResolvedTool>()
        .toList(growable: false);
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(conversationStableId),
    );
    final serviceConnections = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.serviceConnection,
        )
        .map((resource) => {'id': resource.resourceId, ..._data(resource)});
    final userSkills = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.skill &&
              _data(resource)['source'] != 'app',
        )
        .map((resource) => {'id': resource.resourceId, ..._data(resource)});
    return [
      ...genericTools,
      ...materializeCloudSkillTools(
        selectedSkillIds: selectedSkillIds,
        userSkills: userSkills,
        templateTools: resources
            .where(
              (resource) =>
                  resource.resourceKind ==
                  WorkspaceResourceKind.skillTemplateTool,
            )
            .map((resource) => {'id': resource.resourceId, ..._data(resource)}),
        appSkillSettings: resources
            .where(
              (resource) =>
                  resource.resourceKind == WorkspaceResourceKind.skillSetting,
            )
            .map(_data),
        serviceConnections: serviceConnections,
        isChildConversation: conversation?.parentConversationStableId != null,
      ),
      ...materializeCloudSkillControlTools(
        selectedSkillIds: selectedSkillIds,
        userSkills: userSkills,
        templateTools: resources
            .where(
              (resource) =>
                  resource.resourceKind ==
                  WorkspaceResourceKind.skillTemplateTool,
            )
            .map((resource) => {'id': resource.resourceId, ..._data(resource)}),
        appSkillSettings: resources
            .where(
              (resource) =>
                  resource.resourceKind == WorkspaceResourceKind.skillSetting,
            )
            .map(_data),
        serviceConnections: serviceConnections,
        isChildConversation: conversation?.parentConversationStableId != null,
      ),
    ];
  }

  Future<ServerToolDisposition> handle(
    Session session, {
    required ConversationTurn turn,
    required int messageId,
    required ServerToolRequest request,
  }) async {
    final conversation = await Conversation.db.findById(
      session,
      turn.conversationId,
    );
    final currentTools = conversation == null
        ? const <ServerResolvedTool>[]
        : await loadTools(
            session,
            workspaceId: turn.workspaceId,
            conversationStableId: conversation.stableId,
          );
    final tool = currentTools
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
      if (replay == ServerToolReplayAction.recover) {
        await _finish(
          session,
          existing,
          'executionError',
          _boundedJson({
            'error': 'Tool execution was interrupted before completion.',
          }),
        );
        return ServerToolDisposition.completed;
      }
      request = ServerToolRequest(
        id: request.id,
        name: request.name,
        arguments: _jsonMap(existing.argumentsJson),
      );
    }

    if (tool == null) {
      if (existing != null) {
        await _finish(
          session,
          existing,
          'toolNotFound',
          _boundedJson({'error': 'Tool is no longer available.'}),
        );
        return ServerToolDisposition.completed;
      }
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
      if (existing != null) {
        await _finish(
          session,
          existing,
          AgentToolPermissionResult.notConfigured.name,
          _boundedJson({'error': 'Tool is not configured for cloud use.'}),
        );
        return ServerToolDisposition.completed;
      }
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
      descriptor: tool.descriptor,
      agentId: conversation?.agentId,
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
    if (existing != null && permission != AgentToolPermissionResult.granted) {
      await _finish(
        session,
        existing,
        permission.name,
        _boundedJson({'error': 'Tool permission is no longer granted.'}),
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
    if (await cancellationProbe.isCancelled(session, turn.id!)) {
      throw const ConversationCancelledException();
    }
    try {
      final result = await executor(session, turn, tool, request);
      await _finish(session, call, 'success', _boundedJson(result));
    } on Object catch (error) {
      await _finish(session, call, 'executionError', null);
      session.log(
        'Conversation tool execution failed: tool=${tool.spec.name}, '
        'turn=${turn.id}, failure=${serverToolExecutionFailureCode(error)}.',
        level: LogLevel.warning,
      );
      rethrow;
    }
    return ServerToolDisposition.completed;
  }

  Future<AgentToolPermissionResult> _permission(
    Session session, {
    required int workspaceId,
    required AgentResolvedToolName descriptor,
    required String? agentId,
  }) async {
    final toolId = descriptor.tableId;
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
    if (permission == null) return defaultCloudToolPermission(descriptor);
    final data = _data(permission);
    if (data['isEnabled'] == false) {
      return AgentToolPermissionResult.disabledInWorkspace;
    }
    final workspacePermission = switch (data['permissionMode']) {
      'alwaysAllow' => AgentToolPermissionResult.granted,
      'alwaysDeny' => AgentToolPermissionResult.disabledInWorkspace,
      _ => AgentToolPermissionResult.needsConfirmation,
    };
    if (agentId == null) return workspacePermission;
    final associations = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.agentAssociation) &
          table.deletedAt.equals(null),
      orderBy: (table) => table.id,
      orderDescending: true,
    );
    final agentPermissionMode = associations
        .map(_data)
        .where(
          (association) =>
              association['agentId'] == agentId &&
              association['toolId'] == toolId,
        )
        .map((association) => association['permissionMode'])
        .whereType<String>()
        .firstOrNull;
    return resolveCloudToolPermission(
      workspacePermission: workspacePermission,
      agentPermissionMode: agentPermissionMode,
    );
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
