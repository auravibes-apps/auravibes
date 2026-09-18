import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../domain/conversation_values.dart';
import 'conversation_host_effects.dart';
import '../repositories/conversation_repository.dart' as conversation_repo;

enum ServerToolDisposition {
  completed,
  awaitingApproval,
  awaitingSubAgents,
}

enum ServerToolReplayAction { execute, pause, skip, awaitingSubAgents }

// Exceeds current 90s provider and 30s skill I/O bounds; tolerates clock drift.
// ponytail: timestamp lease; add owner tokens if tool runtimes exceed this bound.
const serverToolRunningRecoveryTimeout = Duration(minutes: 2);
const _subAgentFailedMessage = 'Sub-agent failed.';
const _subAgentCancelledMessage = 'Sub-agent cancelled.';

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
    (descriptor.kind == AgentResolvedToolKind.skillAppTemplate &&
        serviceSkillDefinitions.any(
          (skill) =>
              skill.kind == AppSkillDefinitionKind.template &&
              skill.slug == descriptor.skillSlug &&
              skill.tools.any(
                (tool) =>
                    tool.slug == descriptor.toolIdentifier &&
                    tool.urlTemplate != null,
              ),
        )) ||
    (descriptor.kind == AgentResolvedToolKind.skillControl &&
        skillCommandToolNames.contains(descriptor.toolIdentifier)) ||
    (descriptor.kind == AgentResolvedToolKind.skillNative &&
        (descriptor.skillSlug == agentsSkillSlug ||
            serviceSkillDefinitions.any(
              (skill) =>
                  skill.slug == descriptor.skillSlug &&
                  skill.kind == AppSkillDefinitionKind.native &&
                  skill.tools.any(
                    (tool) => tool.slug == descriptor.toolIdentifier,
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
          .where(
            (tool) =>
                tool.descriptor.skillSlug == slug &&
                !(slug == agentsSkillSlug &&
                    tool.descriptor.toolIdentifier == runSubAgentToolName),
          )
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
  if (manifest == null ||
      manifest.revision != command.revision ||
      !manifest.tools.any((tool) => tool.name == command.tool)) {
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
  return templateTools.any(
    (tool) {
      if (tool['skillId'] != skillId || tool['isEnabled'] == false) {
        return false;
      }
      final credentialIds = _templateCredentialIds(
        skill,
        serviceConnections,
        tool['credentialDefinitionId'],
      );
      return tool['requiresCredential'] != true || credentialIds.isNotEmpty;
    },
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
      tool['credentialDefinitionId'],
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
            _cloudTemplateDefinitionSource(tool),
            requiresCredential: tool['requiresCredential'] == true,
            credentialIds: credentialIds,
          ),
        ),
      ),
    );
  }
  if (!isChildConversation &&
      cloudAppSkillEnabled(agentsSkillSlug, appSkillSettings)) {
    tools.addAll(
      [
        runSubAgentToolSpec,
        if (selectedSkillIds.contains(agentsSkillSlug)) listAgentsToolSpec,
      ].map(
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
    for (final tool in skill.tools) {
      if (skill.kind != AppSkillDefinitionKind.template ||
          tool.urlTemplate == null ||
          (tool.requiresCredential && credentialIds.isEmpty)) {
        continue;
      }
      tools.add(
        _appTemplateTool(
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
  Object? definitionJson, {
  required bool requiresCredential,
  Iterable<String> credentialIds = const [],
}) {
  final schema = _templateDefinitionSchema(definitionJson);
  if (schema != null) {
    return materializeSkillToolSchema(
      schema,
      requiresCredential: requiresCredential,
      credentialIds: credentialIds,
    );
  }
  return templateInputSchema(
    definitionJson,
    requiresCredential: requiresCredential,
    credentialIds: credentialIds,
  );
}

Object? _cloudTemplateDefinitionSource(Map<String, dynamic> tool) {
  final definition = tool['definitionJson'];
  if (definition is! String ||
      (definition.trim().isNotEmpty && definition != '{}')) {
    return definition ?? tool['inputsJson'];
  }

  return tool['inputsJson'];
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
  Object? toolDefinitionId,
) {
  final definitionId = toolDefinitionId is String
      ? toolDefinitionId
      : skill?['credentialDefinitionId'];
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

Map<String, Object?>? _templateDefinitionSchema(Object? value) {
  try {
    final definition = switch (value) {
      final String source
          when source.trim().isNotEmpty && source.trim() != '{}' =>
        SkillTemplateDefinition.fromJsonString(source),
      final Map<Object?, Object?> source => SkillTemplateDefinition.fromJsonMap(
        source,
      ),
      _ => null,
    };
    return definition?.inputSchema;
  } on FormatException {
    return null;
  }
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
    tableId: 'skill__app_native__${skillSlug}__$toolIdentifier',
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

ServerResolvedTool _appTemplateTool({
  required String skillSlug,
  required String toolIdentifier,
  required String description,
  required Map<String, Object?> inputJsonSchema,
}) {
  final descriptor = AgentResolvedToolName.skillAppTemplate(
    tableId: 'skill__app_template__${skillSlug}__$toolIdentifier',
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
) => skill.tools.any(
  (tool) =>
      skill.kind == AppSkillDefinitionKind.template &&
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
      'awaitingSubAgents' => ServerToolReplayAction.awaitingSubAgents,
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

class const ServerResolvedTool({
  required final AgentResolvedToolName descriptor,
  required final ToolSpec spec,
});

class const ServerToolRequest({
  required final String id,
  required final String name,
  required final Map<String, dynamic> arguments,
});

class const ServerToolAwaitingSubAgents({
  required final List<Map<String, Object?>> children,
});

typedef ServerToolExecutor = Future<Object?> Function(
  Session session,
  ConversationTurn turn,
  ServerResolvedTool tool,
  ServerToolRequest request,
);

/// Server-owned persistence and policy around deterministic engine tool names.
class ServerToolRuntime({
  final AgentToolNameResolver _resolver = const AgentToolNameResolver(
    skillControlToolNames: skillCommandToolNames,
  ),
  final ServerToolExecutor? _executor,
  final Future<void> Function()? beforeApprovedClaim,
  final ConversationCancellationProbe cancellationProbe =
      const DatabaseConversationCancellationProbe(),
}) {
  static const maxResultCharacters = 50000;

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
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(conversationStableId) &
          table.deletedAt.equals(null),
    );
    final appSkillSettings = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.skillSetting,
        )
        .map(_data);
    final agentTools =
        conversation != null &&
            conversation.parentConversationStableId == null &&
            cloudAppSkillEnabled(agentsSkillSlug, appSkillSettings)
        ? [
            _nativeTool(
              skillSlug: agentsSkillSlug,
              toolIdentifier: runSubAgentToolName,
              description: runSubAgentToolSpec.description,
              inputJsonSchema: runSubAgentToolSpec.inputJsonSchema,
            ),
          ]
        : const <ServerResolvedTool>[];

    return [
      ...genericTools,
      ...fixedCloudSkillCommandTools(),
      ...agentTools,
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
      if (replay == ServerToolReplayAction.awaitingSubAgents) {
        return await _reconcileAwaitingSubAgents(session, existing);
      }
      if (replay == ServerToolReplayAction.skip) {
        if (existing.status == 'running' && _isSubAgentTool(existing.name)) {
          final recovered = await _recoverRunningSubAgent(session, existing);
          if (recovered != null) return recovered;
        }
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
      if (result case ServerToolAwaitingSubAgents(:final children)) {
        await _finish(
          session,
          call,
          'awaitingSubAgents',
          _boundedJson({'children': children}),
        );
        final waiting = await ConversationToolCall.db.findById(
          session,
          call.id!,
        );
        if (waiting == null) return ServerToolDisposition.completed;
        return await _reconcileAwaitingSubAgents(session, waiting);
      }
      await _finish(session, call, 'success', _boundedJson(result));
    } on AgentToolExecutionFailure catch (failure) {
      await _finish(
        session,
        call,
        'executionError',
        _boundedRawJson(failure.responseRaw),
      );
      session.log(
        'Conversation tool execution failed: tool=${tool.spec.name}, '
        'turn=${turn.id}, failure=${serverToolExecutionFailureCode(failure)}, '
        'phase=${failure.failurePhase}.',
        level: LogLevel.warning,
      );
      // The typed result is already durable and safe. Let the current model
      // batch finish so sibling sub-agent calls are not skipped or retried.
      return ServerToolDisposition.completed;
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
      orderBy: (table) => table.id.desc(),
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
      orderBy: (table) => table.id.desc(),
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
    final turn = await ConversationTurn.db.findById(
      session,
      current.turnId,
      transaction: transaction,
    );
    if (turn == null || ConversationStatuses.isTerminal(turn.status)) {
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
    final turn = await ConversationTurn.db.findById(
      session,
      current.turnId,
      transaction: transaction,
    );
    if (turn == null || ConversationStatuses.isTerminal(turn.status)) return;
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
    final turn = await ConversationTurn.db.findById(
      session,
      current.turnId,
      transaction: transaction,
    );
    if (turn == null || ConversationStatuses.isTerminal(turn.status)) return;
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

  bool _isSubAgentTool(String name) {
    final descriptor = _resolver.resolve(name);
    if (descriptor?.kind == AgentResolvedToolKind.skillNative &&
        descriptor?.skillSlug == agentsSkillSlug &&
        descriptor?.toolIdentifier == runSubAgentToolName) {
      return true;
    }
    return name == callSkillToolName;
  }

  Future<ServerToolDisposition?> _recoverRunningSubAgent(
    Session session,
    ConversationToolCall call,
  ) async {
    final jobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(call.workspaceId) &
          table.kind.equals(ConversationJobKinds.turn),
      orderBy: (table) => table.id,
    );
    final childJob = jobs
        .where(
          (job) =>
              conversation_repo.conversationParentTurnIdForJob(
                    job.payloadJson,
                  ) ==
                  call.turnId &&
              conversation_repo.conversationParentToolCallIdForJob(
                    job.payloadJson,
                  ) ==
                  call.stableId,
        )
        .firstOrNull;
    if (childJob == null) return null;
    final childConversation = await Conversation.db.findById(
      session,
      childJob.conversationId,
    );
    if (childConversation == null) return null;
    final child = <String, Object?>{
      'conversationId': childConversation.stableId,
      'turnId': conversation_repo.conversationExecutionIdForJob(
        childJob.requestId,
        childJob.payloadJson,
      ),
      'status': 'running',
    };
    await _finish(
      session,
      call,
      'awaitingSubAgents',
      _boundedJson({
        'children': [child],
      }),
    );
    final recovered = await ConversationToolCall.db.findById(
      session,
      call.id!,
    );
    return recovered == null
        ? ServerToolDisposition.completed
        : _reconcileAwaitingSubAgents(session, recovered);
  }

  Future<ServerToolDisposition> _reconcileAwaitingSubAgents(
    Session session,
    ConversationToolCall call,
  ) async {
    final metadata = call.resultJson == null
        ? const <String, dynamic>{}
        : _jsonMap(call.resultJson!);
    final children = (metadata['children'] as List?)
        ?.whereType<Map>()
        .map((child) => Map<String, dynamic>.from(child))
        .toList(growable: false);
    if (children == null || children.isEmpty) {
      await _finish(
        session,
        call,
        'executionError',
        _boundedJson({'content': _subAgentFailedMessage}),
      );
      return ServerToolDisposition.completed;
    }
    final results = <Map<String, Object?>>[];
    for (final child in children) {
      final result = await _childTerminalResult(
        session,
        call.workspaceId,
        child,
      );
      if (result == null) return ServerToolDisposition.awaitingSubAgents;
      results.add(result);
    }
    final status = switch ((
      results.every((result) => result['status'] == 'success'),
      results.any((result) => result['status'] == 'cancelled'),
    )) {
      (true, _) => 'success',
      (_, true) => 'cancelled',
      _ => 'executionError',
    };
    await _finish(
      session,
      call,
      status,
      _boundedJson(
        results.length == 1 ? results.single : {'children': results},
      ),
    );
    return ServerToolDisposition.completed;
  }

  Future<Map<String, Object?>?> _childTerminalResult(
    Session session,
    int workspaceId,
    Map<String, dynamic> child,
  ) async {
    final conversationId = child['conversationId'];
    final executionId = child['turnId'];
    if (conversationId is! String || executionId is! String) {
      return {'status': 'error', 'content': _subAgentFailedMessage};
    }
    final childConversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(conversationId) &
          table.deletedAt.equals(null),
    );
    if (childConversation == null) {
      return {
        'conversationId': conversationId,
        'status': 'error',
        'content': _subAgentFailedMessage,
        if (child['agentId'] is String) 'agentId': child['agentId'],
      };
    }
    final execution = await ConversationExecution.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(childConversation.id) &
          table.stableId.equals(executionId),
    );
    if (execution == null) return null;
    if (!ConversationStatuses.isTerminal(execution.status)) return null;
    final assistant = execution.assistantMessageId == null
        ? null
        : await ConversationMessage.db.findById(
            session,
            execution.assistantMessageId!,
          );
    final status = switch (execution.status) {
      ConversationStatuses.completed => 'success',
      ConversationStatuses.cancelled => 'cancelled',
      _ => 'error',
    };
    return {
      'conversationId': conversationId,
      'status': status,
      'content': switch (status) {
        'success' => assistant?.content ?? '',
        'cancelled' => _subAgentCancelledMessage,
        _ => _subAgentFailedMessage,
      },
      if (child['agentId'] is String) 'agentId': child['agentId'],
    };
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

  String _boundedRawJson(String value) {
    return value.length <= maxResultCharacters
        ? value
        : _boundedJson({'content': _subAgentFailedMessage});
  }
}
