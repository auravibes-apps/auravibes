import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import 'conversation_host_effects.dart';

enum ServerToolDisposition { completed, awaitingApproval }

enum ServerToolReplayAction { execute, pause, skip }

// Exceeds current 90s provider and 30s skill I/O bounds; tolerates clock drift.
// ponytail: timestamp lease; add owner tokens if tool runtimes exceed this bound.
const serverToolRunningRecoveryTimeout = Duration(minutes: 2);

bool serverToolRunningIsStale({
  required DateTime updatedAt,
  required DateTime now,
  Duration timeout = serverToolRunningRecoveryTimeout,
}) => !updatedAt.add(timeout).isAfter(now);

String serverToolExecutionFailureCode(Object error) => switch (error) {
  FormatException() => 'invalid_request',
  CloudWorkspaceException(:final code) => 'workspace_${code.name}',
  _ => 'unexpected',
};

bool serverToolIsExecutable(AgentResolvedToolName descriptor) =>
    descriptor.kind == AgentResolvedToolKind.mcp ||
    descriptor.kind == AgentResolvedToolKind.skillTemplate ||
    (descriptor.kind == AgentResolvedToolKind.skillControl &&
        skillCommandToolNames.contains(descriptor.toolIdentifier)) ||
    (descriptor.kind == AgentResolvedToolKind.skillNative &&
        (descriptor.skillSlug == agentsSkillSlug ||
            serviceSkillDefinitions.any(
              (skill) =>
                  skill.slug == descriptor.skillSlug &&
                  skill.nativeTools.any(
                    (tool) =>
                        tool.slug == descriptor.toolIdentifier &&
                        (tool.urlTemplate != null || tool.callback != null),
                  ),
            )));

bool isCloudToolEnabled({
  required Map<String, dynamic> toolData,
  Map<String, dynamic>? toolGroupData,
}) => toolData['isEnabled'] != false && toolGroupData?['isEnabled'] != false;

Set<String> cloudAuthorizedSkillIds({
  required Conversation conversation,
  required Iterable<WorkspaceResource> resources,
}) {
  final ids = resources
      .where(
        (resource) =>
            resource.resourceKind ==
            WorkspaceResourceKind.conversationSkillSelection,
      )
      .map((resource) => jsonDecode(resource.data) as Map<String, dynamic>)
      .where((data) => data['conversationId'] == conversation.stableId)
      .map((data) => data['skillId'])
      .whereType<String>()
      .toSet();
  final agentId = conversation.agentId;
  if (agentId == null) return ids;
  final agent = resources
      .where(
        (resource) =>
            resource.resourceKind == WorkspaceResourceKind.agent &&
            resource.resourceId == agentId,
      )
      .lastOrNull;
  if (agent == null) return ids;
  final agentData = jsonDecode(agent.data) as Map<String, dynamic>;
  final isChild = conversation.parentConversationStableId != null;
  final visibility = agentData['visibility'];
  if (agentData['isEnabled'] == false ||
      (isChild && visibility == 'chatSelector') ||
      (!isChild && visibility == 'subAgentList')) {
    return ids;
  }
  ids.addAll(
    resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.agentAssociation,
        )
        .map((resource) => jsonDecode(resource.data) as Map<String, dynamic>)
        .where((data) => data['agentId'] == agentId)
        .map((data) => data['skillId'])
        .whereType<String>(),
  );
  return ids;
}

List<ServerResolvedTool> materializeCloudSkillControlTools({
  required Set<String> selectedSkillIds,
  required Iterable<Map<String, dynamic>> userSkills,
  Iterable<Map<String, dynamic>> templateTools = const [],
  required Iterable<Map<String, dynamic>> appSkillSettings,
  Iterable<Map<String, dynamic>> serviceConnections = const [],
  required bool isChildConversation,
}) => _materializeCloudSkillControlToolsBody(
  selectedSkillIds: selectedSkillIds,
  userSkills: userSkills,
  templateTools: templateTools,
  appSkillSettings: appSkillSettings,
  serviceConnections: serviceConnections,
  isChildConversation: isChildConversation,
);

List<ServerResolvedTool> fixedCloudSkillCommandTools() =>
    buildSkillCommandToolSpecs()
        .map(
          (spec) => ServerResolvedTool(
            descriptor: AgentResolvedToolName.skillControl(
              toolIdentifier: spec.name,
            ),
            spec: spec,
          ),
        )
        .toList(growable: false);

Future<SkillManifest?> buildCloudSkillManifest({
  required String slug,
  required Iterable<Map<String, dynamic>> userSkills,
  required Iterable<ServerResolvedTool> tools,
}) async {
  final userSkill = userSkills
      .where((skill) => skill['slug'] == slug && skill['isEnabled'] != false)
      .firstOrNull;
  final appSkill = serviceSkillDefinitions
      .where((skill) => skill.slug == slug || skill.identifier == slug)
      .firstOrNull;
  final title = switch ((userSkill?['title'], appSkill)) {
    (final String value, _) => value,
    (_, final AppSkillDefinition value) => value.title,
    _ when slug == agentsSkillSlug => agentsSkillTitle,
    _ => null,
  };
  final instructions = switch ((userSkill?['content'], appSkill)) {
    (final String value, _) => value,
    (_, final AppSkillDefinition value) => value.content,
    _ when slug == agentsSkillSlug => agentsSkillContent,
    _ => null,
  };
  if (title == null || instructions == null) return null;
  final manifestTools =
      tools
          .where((tool) => tool.descriptor.skillSlug == slug)
          .map(
            (tool) => SkillManifestTool(
              name: tool.descriptor.toolIdentifier,
              description: tool.spec.description,
              inputJsonSchema: tool.spec.inputJsonSchema,
            ),
          )
          .toList()
        ..sort((left, right) => left.name.compareTo(right.name));
  final canonical = jsonEncode({
    'identity': userSkill?['id'] ?? appSkill?.identifier ?? slug,
    'slug': slug,
    'title': title,
    'instructions': instructions,
    'tools': manifestTools.map((tool) => tool.toJson()).toList(),
  });
  final hash = await Sha256().hash(utf8.encode(canonical));
  return SkillManifest(
    slug: slug,
    title: title,
    instructions: instructions,
    revision: base64UrlEncode(hash.bytes),
    tools: manifestTools,
  );
}

Future<ServerResolvedTool> resolveCloudSkillCommandTarget({
  required SkillCommandTarget command,
  required Iterable<Map<String, dynamic>> userSkills,
  required Iterable<ServerResolvedTool> tools,
}) async {
  final target = tools
      .where(
        (candidate) =>
            candidate.descriptor.skillSlug == command.skill &&
            candidate.descriptor.toolIdentifier == command.tool,
      )
      .singleOrNull;
  if (target == null) {
    throw StateError('Skill tool is not loaded or configured.');
  }
  final manifest = await buildCloudSkillManifest(
    slug: command.skill,
    userSkills: userSkills,
    tools: tools,
  );
  if (manifest == null || manifest.revision != command.revision) {
    throw FormatException(
      'Skill manifest changed; call load_skill or list_skills to refresh: ${command.skill}',
    );
  }
  validateToolArguments(target.spec.inputJsonSchema, command.args);
  return target;
}

List<ServerResolvedTool> _materializeCloudSkillControlToolsBody({
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
        skill.slug,
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
        skill.slug,
  ];
  final loadable =
      selectable
          .where((slug) => !selected.contains(slug))
          .toSet()
          .toList(growable: false)
        ..sort();
  selected.sort();
  return <(String, List<String>)>[
        (loadSkillToolName, loadable),
        (unloadSkillToolName, selected),
      ]
      .map((spec) {
        final descriptor = AgentResolvedToolName.skillControl(
          toolIdentifier: spec.$1,
        );
        return ServerResolvedTool(
          descriptor: descriptor,
          spec: ToolSpec(
            name: spec.$1,
            description: spec.$1 == loadSkillToolName
                ? 'Load one skill for the current conversation.'
                : 'Unload one skill from the current conversation.',
            inputJsonSchema: {
              'type': 'object',
              'properties': {
                'slug': {'type': 'string', 'enum': spec.$2},
              },
              'required': ['slug'],
              'additionalProperties': false,
            },
          ),
        );
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
      if ((tool.urlTemplate == null && tool.callback == null) ||
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
      (tool.urlTemplate != null || tool.callback != null) &&
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
) {
  if (descriptor.kind == AgentResolvedToolKind.skillControl &&
      descriptor.toolIdentifier == listSkillsToolName) {
    return AgentToolPermissionResult.granted;
  }
  if ((descriptor.isSkill ||
          descriptor.kind == AgentResolvedToolKind.skillControl) &&
      serverToolIsExecutable(descriptor)) {
    return AgentToolPermissionResult.needsConfirmation;
  }
  return AgentToolPermissionResult.notConfigured;
}

ServerToolReplayAction serverToolReplayAction(String status) =>
    switch (status) {
      'approved' => ServerToolReplayAction.execute,
      'pending' => ServerToolReplayAction.pause,
      'running' => ServerToolReplayAction.skip,
      _ => ServerToolReplayAction.skip,
    };

bool serverToolStatusCanBeClaimed(String status) => status == 'approved';

bool serverToolCallCanTransition({
  required String currentStatus,
  required int currentRevision,
  required String expectedStatus,
  required int expectedRevision,
}) => currentStatus == expectedStatus && currentRevision == expectedRevision;

bool serverToolRunningCanRecover({
  required String currentStatus,
  required int currentRevision,
  required DateTime updatedAt,
  required DateTime now,
  required int expectedRevision,
}) =>
    serverToolCallCanTransition(
      currentStatus: currentStatus,
      currentRevision: currentRevision,
      expectedStatus: 'running',
      expectedRevision: expectedRevision,
    ) &&
    serverToolRunningIsStale(updatedAt: updatedAt, now: now);

bool serverToolPermissionAllowsExecution({
  required AgentToolPermissionResult permission,
  required String? persistedStatus,
}) =>
    permission == AgentToolPermissionResult.granted ||
    (persistedStatus == 'approved' &&
        permission == AgentToolPermissionResult.needsConfirmation);

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
      skillControlToolNames: skillCommandToolNames,
    ),
    this._executor,
    this.beforeApprovedClaim,
    this.cancellationProbe = const DatabaseConversationCancellationProbe(),
  });

  static const maxResultCharacters = 50000;

  final AgentToolNameResolver _resolver;
  final ServerToolExecutor? _executor;
  final Future<void> Function()? beforeApprovedClaim;
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

    return [
      ...genericTools,
      ...fixedCloudSkillCommandTools(),
    ];
  }

  Future<
    ({List<ServerResolvedTool> tools, List<Map<String, dynamic>> userSkills})
  >
  _skillTargets(
    Session session, {
    required int workspaceId,
    required String conversationStableId,
  }) async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) & table.deletedAt.equals(null),
    );
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(conversationStableId),
    );
    final selectedSkillIds = conversation == null
        ? <String>{}
        : cloudAuthorizedSkillIds(
            conversation: conversation,
            resources: resources,
          );
    final userSkills = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.skill &&
              _data(resource)['source'] != 'app',
        )
        .map((resource) => {'id': resource.resourceId, ..._data(resource)})
        .toList(growable: false);
    return (
      userSkills: userSkills,
      tools: materializeCloudSkillTools(
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
        serviceConnections: resources
            .where(
              (resource) =>
                  resource.resourceKind ==
                  WorkspaceResourceKind.serviceConnection,
            )
            .map((resource) => {'id': resource.resourceId, ..._data(resource)}),
        isChildConversation: conversation?.parentConversationStableId != null,
      ),
    );
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
    var tool = currentTools
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
      final persistedDescriptor = _resolver.resolve(existing.name);
      final storedArguments = _jsonMap(existing.argumentsJson);
      final storedCommand = _skillCommandOrNull(storedArguments);
      final isNestedSkillCall =
          (persistedDescriptor?.kind == AgentResolvedToolKind.skillTemplate ||
              persistedDescriptor?.kind == AgentResolvedToolKind.skillNative) &&
          storedCommand != null;
      if ((!isNestedSkillCall && existing.name != request.name) ||
          (isNestedSkillCall &&
              request.name != callSkillToolName &&
              request.name != existing.name) ||
          (existing.decision == null && existing.argumentsDigest != digest)) {
        throw const FormatException('Tool call identity changed.');
      }
      final replay = serverToolReplayAction(existing.status);
      if (replay == ServerToolReplayAction.pause) {
        return ServerToolDisposition.awaitingApproval;
      }
      if (replay == ServerToolReplayAction.skip) {
        if (existing.status == 'running') {
          await _recoverStaleRunning(session, existing);
        }
        return ServerToolDisposition.completed;
      }
      request = ServerToolRequest(
        id: request.id,
        name: isNestedSkillCall ? callSkillToolName : request.name,
        arguments: storedArguments,
      );
      if (isNestedSkillCall) {
        tool = currentTools
            .where((candidate) => candidate.spec.name == callSkillToolName)
            .singleOrNull;
      }
    }

    final legacyDescriptor = _resolver.resolve(request.name);
    if (tool == null &&
        existing != null &&
        (legacyDescriptor?.kind == AgentResolvedToolKind.skillTemplate ||
            legacyDescriptor?.kind == AgentResolvedToolKind.skillNative)) {
      try {
        final state = await _skillTargets(
          session,
          workspaceId: turn.workspaceId,
          conversationStableId: conversation!.stableId,
        );
        tool = state.tools
            .where((candidate) => candidate.spec.name == request.name)
            .singleOrNull;
        if (tool == null) {
          throw const FormatException('Tool is no longer available.');
        }
        validateToolArguments(tool.spec.inputJsonSchema, request.arguments);
      } on Object catch (error) {
        await _finish(
          session,
          existing,
          'executionError',
          _boundedJson({'error': '$error'}),
        );
        return ServerToolDisposition.completed;
      }
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
    var executionRequest = request;
    var permissionDescriptor = tool.descriptor;
    if (request.name == callSkillToolName) {
      try {
        final state = await _skillTargets(
          session,
          workspaceId: turn.workspaceId,
          conversationStableId: conversation!.stableId,
        );
        final command = _skillCommandOrNull(request.arguments);
        final resolvedTarget = await resolveEffectiveToolApprovalTarget(
          requestedTarget: tool.descriptor,
          arguments: request.arguments,
          resolveSkillTarget: (command) async =>
              (await resolveCloudSkillCommandTarget(
                command: command,
                userSkills: state.userSkills,
                tools: state.tools,
              )).descriptor,
        );
        if (resolvedTarget == null || command == null) {
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
        permissionDescriptor = resolvedTarget;
        if (existing != null &&
            existing.name != permissionDescriptor.fullName) {
          throw const FormatException('Tool call identity changed.');
        }
        tool = state.tools
            .where(
              (candidate) =>
                  candidate.descriptor.fullName ==
                  permissionDescriptor.fullName,
            )
            .singleOrNull;
        if (tool == null) {
          throw const FormatException('Tool is no longer available.');
        }
        executionRequest = ServerToolRequest(
          id: request.id,
          name: permissionDescriptor.fullName,
          arguments: Map<String, dynamic>.from(command.args),
        );
      } on Object catch (error) {
        final call =
            existing ??
            await _insertResolved(
              session,
              turn: turn,
              messageId: messageId,
              request: request,
              argumentsJson: argumentsJson,
              digest: digest,
              status: 'executionError',
            );
        await _finish(
          session,
          call,
          'executionError',
          _boundedJson({'error': '$error'}),
        );
        return ServerToolDisposition.completed;
      }
    }
    if (!serverToolIsExecutable(permissionDescriptor)) {
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
      descriptor: permissionDescriptor,
      agentId: conversation?.agentId,
    );
    final persistedRequest = request.name == callSkillToolName
        ? ServerToolRequest(
            id: request.id,
            name: permissionDescriptor.fullName,
            arguments: request.arguments,
          )
        : request;
    if (existing == null &&
        permission == AgentToolPermissionResult.needsConfirmation) {
      await _insertResolved(
        session,
        turn: turn,
        messageId: messageId,
        request: persistedRequest,
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
        request: persistedRequest,
        argumentsJson: argumentsJson,
        digest: digest,
        status: permission.name,
      );
      return ServerToolDisposition.completed;
    }
    if (!serverToolPermissionAllowsExecution(
      permission: permission,
      persistedStatus: existing?.status,
    )) {
      if (existing != null) {
        await _finish(
          session,
          existing,
          permission.name,
          _boundedJson({'error': 'Tool permission is no longer granted.'}),
        );
      }
      return ServerToolDisposition.completed;
    }

    ConversationToolCall? call;
    if (existing == null) {
      call = await _insertResolved(
        session,
        turn: turn,
        messageId: messageId,
        request: persistedRequest,
        argumentsJson: argumentsJson,
        digest: digest,
        status: 'running',
      );
    } else {
      await beforeApprovedClaim?.call();
      call = await _claimApproved(session, existing);
    }
    if (call == null) return ServerToolDisposition.completed;
    final executor = _executor;
    if (executor == null) {
      throw StateError('Server tool executor is not configured.');
    }
    if (await cancellationProbe.isCancelled(session, turn.id!)) {
      throw const ConversationCancelledException();
    }
    try {
      final result = await executor(session, turn, tool, executionRequest);
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

  Future<ConversationToolCall?> _claimApproved(
    Session session,
    ConversationToolCall call,
  ) => session.db.transaction((transaction) async {
    final current = await ConversationToolCall.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(call.id) & table.status.equals('approved'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (current == null || !serverToolStatusCanBeClaimed(current.status)) {
      return null;
    }
    return ConversationToolCall.db.updateRow(
      session,
      current.copyWith(
        status: 'running',
        revision: current.revision + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
  });

  Future<void> _finish(
    Session session,
    ConversationToolCall call,
    String status,
    String? result,
  ) => session.db.transaction((transaction) async {
    final current = await ConversationToolCall.db.findById(
      session,
      call.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (current == null ||
        !serverToolCallCanTransition(
          currentStatus: current.status,
          currentRevision: current.revision,
          expectedStatus: call.status,
          expectedRevision: call.revision,
        )) {
      return;
    }
    await ConversationToolCall.db.updateRow(
      session,
      current.copyWith(
        status: status,
        resultJson: result,
        revision: current.revision + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
  });

  Future<void> _recoverStaleRunning(
    Session session,
    ConversationToolCall call,
  ) => session.db.transaction((transaction) async {
    final current = await ConversationToolCall.db.findById(
      session,
      call.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final now = DateTime.now().toUtc();
    if (current == null ||
        !serverToolRunningCanRecover(
          currentStatus: current.status,
          currentRevision: current.revision,
          updatedAt: current.updatedAt,
          now: now,
          expectedRevision: call.revision,
        )) {
      return;
    }
    await ConversationToolCall.db.updateRow(
      session,
      current.copyWith(
        status: 'executionError',
        resultJson: _boundedJson({
          'error': 'Tool execution was interrupted before completion.',
        }),
        revision: current.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  });

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

  SkillCommandTarget? _skillCommandOrNull(Map<String, dynamic> arguments) {
    try {
      return SkillCommandTarget.fromArguments(arguments);
    } on FormatException {
      return null;
    }
  }

  String _boundedJson(Object? value) {
    final encoded = jsonEncode(value);
    return encoded.length <= maxResultCharacters
        ? encoded
        : jsonEncode(encoded.substring(0, maxResultCharacters));
  }
}
