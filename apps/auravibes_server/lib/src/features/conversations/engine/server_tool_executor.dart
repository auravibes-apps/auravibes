import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../mcp_servers/mcp_server_policy.dart';
import '../../workspace_state/workspace_secret_cipher.dart';
import '../../workspace_state/workspace_secret_resolver.dart';
import '../../workspace_state/repositories/workspace_state_repository.dart';
import '../../workspace_state/usecases/workspace_state_usecases.dart';
import '../domain/conversation_values.dart';
import '../repositories/conversation_repository.dart' as conversation_repo;
import '../usecases/conversation_usecases.dart';
import 'conversation_host_effects.dart';
import 'server_tool_runtime.dart';

String cloudServiceConnectionId(String credentialId) =>
    credentialId.startsWith('service:')
    ? credentialId.substring('service:'.length)
    : credentialId;

bool isCloudAppSkillCredential(
  Map<String, dynamic> data,
  String skillIdentifier,
) =>
    data['kind'] == 'appSkillCredential' &&
    data['serviceId'] == skillIdentifier &&
    data['isEnabled'] != false &&
    data['hasSecret'] == true;

bool cloudToolAllowsCredential(
  ServerResolvedTool tool,
  String credentialId,
) =>
    (((tool.spec.inputJsonSchema['properties'] as Map?)?['credentialId']
                as Map?)?['enum']
            as List?)
        ?.contains(credentialId) ==
    true;

bool cloudSkillControlIsNoop({
  required String controlName,
  required bool isSelected,
}) =>
    (controlName == loadSkillToolName && isSelected) ||
    (controlName == unloadSkillToolName && !isSelected);

PatchWorkspaceStateRequest cloudSkillSelectionPatchRequest({
  required int workspaceId,
  required String turnRequestId,
  required String conversationId,
  required String skillId,
  required bool isAppSkill,
  required String controlName,
  required String toolCallId,
  int? existingRevision,
}) {
  final resourceId = '$conversationId:$skillId';
  final operation = switch (controlName) {
    loadSkillToolName when existingRevision == null => WorkspacePatchOperation(
      operation: WorkspacePatchOperationKind.create,
      resourceKind: WorkspaceResourceKind.conversationSkillSelection,
      resourceId: resourceId,
      data: jsonEncode({
        'id': resourceId,
        'conversationId': conversationId,
        'skillId': skillId,
        if (isAppSkill) 'source': 'app',
      }),
      fieldMask: const [],
    ),
    unloadSkillToolName when existingRevision != null =>
      WorkspacePatchOperation(
        operation: WorkspacePatchOperationKind.delete,
        resourceKind: WorkspaceResourceKind.conversationSkillSelection,
        resourceId: resourceId,
        fieldMask: const [],
        expectedRevision: existingRevision,
      ),
    _ => throw const ServerToolNotConfiguredException(),
  };
  return PatchWorkspaceStateRequest(
    workspaceId: workspaceId,
    requestId: '$turnRequestId:$toolCallId:$controlName:$skillId',
    operations: [operation],
  );
}

typedef ServerToolExecutorInterlock = Future<void> Function();

Future<Object?> runCompiledServiceSkillTool({
  required String skillSlug,
  required String toolSlug,
  required Map<String, dynamic> input,
  Map<String, String> credentials = const {},
  required SkillHttpClient httpClient,
}) {
  final skill = serviceSkillDefinitions
      .where((candidate) => candidate.slug == skillSlug)
      .firstOrNull;
  final nativeTool = skill?.nativeTools
      .where((candidate) => candidate.slug == toolSlug)
      .firstOrNull;
  if (skill == null ||
      nativeTool == null ||
      (nativeTool.urlTemplate == null && nativeTool.callback == null)) {
    throw const ServerToolNotConfiguredException();
  }
  return AppSkillExecutor(
        RunSkillUrlTemplate(const ResolveSkillUrlTemplate(), httpClient),
        httpClient,
      )
      .run(
        skill: skill,
        toolSlug: toolSlug,
        input: input,
        credentials: credentials,
      )
      .value;
}

Future<({Uri uri, List<InternetAddress> addresses})>
validateServerSkillRequestTarget(
  UrlRequest request, {
  required bool requireHttps,
  Future<List<InternetAddress>> Function(String host) lookup =
      InternetAddress.lookup,
}) async {
  final uri = requirePublicUriSyntax(request.url, requireHttps: requireHttps);
  final addresses = await lookup(uri.host);
  if (addresses.isEmpty ||
      addresses.any(
        (address) => isPrivateIpAddress(
          address.rawAddress,
          isIpv6: address.type == InternetAddressType.IPv6,
        ),
      )) {
    throw const FormatException(publicUrlError);
  }
  return (uri: uri, addresses: addresses);
}

void rejectServerSkillRedirect(bool isRedirect) {
  if (isRedirect) throw const HttpException('Redirect rejected.');
}

Future<String> readBoundedServerSkillResponse(
  Stream<List<int>> response, {
  int maxBytes = McpServerPolicy.maxResponseBytes,
}) async {
  final bytes = <int>[];
  await for (final chunk in response) {
    bytes.addAll(chunk);
    if (bytes.length > maxBytes) {
      throw const FormatException('Tool response is too large.');
    }
  }
  return utf8.decode(bytes);
}

Future<void> closeOnServerSkillCancellation({
  required Future<bool> Function() isCancelled,
  required void Function() close,
  required Future<void> done,
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  while (true) {
    if (await isCancelled()) {
      close();
      return;
    }
    final completed = await Future.any([
      done.then((_) => true),
      Future<void>.delayed(pollInterval).then((_) => false),
    ]);
    if (completed) return;
  }
}

Future<T> runBoundedServerSkillRequest<T>({
  required Duration timeout,
  required Future<T> Function() run,
  required void Function() close,
}) async {
  final timedOut = Completer<T>();
  final timer = Timer(timeout, () {
    close();
    timedOut.completeError(
      TimeoutException('Tool request timed out.', timeout),
    );
  });
  try {
    return await Future.any([run(), timedOut.future]);
  } finally {
    timer.cancel();
  }
}

class ServerToolExecutorService {
  const ServerToolExecutorService({
    this.beforeChildLaunch,
    this.afterChildContinuation,
    this.beforeSkillSelectionMutation,
  });

  final ServerToolExecutorInterlock? beforeChildLaunch;
  final ServerToolExecutorInterlock? afterChildContinuation;
  final ServerToolExecutorInterlock? beforeSkillSelectionMutation;

  Future<Object?> call(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    ServerToolRequest request,
  ) async {
    await _throwIfCancelled(session, turn);
    return switch (tool.descriptor.kind) {
      AgentResolvedToolKind.mcp => _runMcp(
        session,
        turn,
        tool,
        request.arguments,
      ),
      AgentResolvedToolKind.skillControl => _runSkillControl(
        session,
        turn,
        tool,
        request,
      ),
      AgentResolvedToolKind.skillTemplate => _runSkill(
        session,
        turn,
        tool,
        request.arguments,
      ),
      AgentResolvedToolKind.skillNative
          when tool.descriptor.skillSlug == agentsSkillSlug =>
        _runSubAgentTool(session, turn, tool, request.arguments),
      AgentResolvedToolKind.skillNative => _runNativeSkill(
        session,
        turn,
        tool,
        request.arguments,
      ),
      _ => throw const ServerToolNotConfiguredException(),
    };
  }

  Future<Object?> _runSkillControl(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    ServerToolRequest request,
  ) async {
    if (tool.descriptor.toolIdentifier == listSkillsToolName) {
      return _listSkills(session, turn);
    }
    if (tool.descriptor.toolIdentifier == listSkillCredentialsToolName) {
      return _listSkillCredentials(session, turn, request.arguments);
    }
    if (tool.descriptor.toolIdentifier == callSkillToolName) {
      return _runDispatchedSkill(session, turn, request.arguments);
    }
    final slug = request.arguments['slug'];
    if (slug is! String || slug.isEmpty) {
      throw const ServerToolNotConfiguredException();
    }
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.conversationId) &
          table.workspaceId.equals(turn.workspaceId),
    );
    if (conversation == null) throw const ServerToolNotConfiguredException();
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.deletedAt.equals(null),
    );
    final selectedSkillIds = resources
        .where(
          (resource) =>
              resource.resourceKind ==
              WorkspaceResourceKind.conversationSkillSelection,
        )
        .map((resource) => _jsonMap(resource.data))
        .where((data) => data['conversationId'] == conversation.stableId)
        .map((data) => data['skillId'])
        .whereType<String>()
        .toSet();
    final controlName = tool.descriptor.toolIdentifier;
    if (controlName != loadSkillToolName &&
        controlName != unloadSkillToolName) {
      throw const ServerToolNotConfiguredException();
    }
    // A provider can issue duplicate controls in one response. Check the
    // durable selection before recomputing controls after an earlier call.
    final existingSkillId = _cloudSkillId(
      slug,
      resources: resources,
      allowUnavailable: true,
    );
    if (existingSkillId != null) {
      final resourceId = '${conversation.stableId}:$existingSkillId';
      final selection = resources
          .where(
            (resource) =>
                resource.resourceKind ==
                    WorkspaceResourceKind.conversationSkillSelection &&
                resource.resourceId == resourceId,
          )
          .firstOrNull;
      if (cloudSkillControlIsNoop(
        controlName: controlName,
        isSelected: selection != null,
      )) {
        if (controlName == unloadSkillToolName) return {'unloaded': slug};
        final state = await _skillCommandState(session, turn);
        final manifest = await buildCloudSkillManifest(
          slug: slug,
          userSkills: state.userSkills,
          tools: _materializeStateTools(state),
        );
        if (manifest == null) throw const ServerToolNotConfiguredException();
        return {'loaded': slug, 'manifest': manifest.toJson()};
      }
    }
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: selectedSkillIds,
      userSkills: resources
          .where(
            (resource) => resource.resourceKind == WorkspaceResourceKind.skill,
          )
          .map(
            (resource) => {
              'id': resource.resourceId,
              ..._jsonMap(resource.data),
            },
          ),
      templateTools: resources
          .where(
            (resource) =>
                resource.resourceKind ==
                WorkspaceResourceKind.skillTemplateTool,
          )
          .map(
            (resource) => {
              'id': resource.resourceId,
              ..._jsonMap(resource.data),
            },
          ),
      appSkillSettings: resources
          .where(
            (resource) =>
                resource.resourceKind == WorkspaceResourceKind.skillSetting,
          )
          .map((resource) => _jsonMap(resource.data)),
      serviceConnections: resources
          .where(
            (resource) =>
                resource.resourceKind ==
                WorkspaceResourceKind.serviceConnection,
          )
          .map(
            (resource) => {
              'id': resource.resourceId,
              ..._jsonMap(resource.data),
            },
          ),
      isChildConversation: conversation.parentConversationStableId != null,
    );
    final control = controls
        .where((candidate) => candidate.spec.name == tool.spec.name)
        .firstOrNull;
    final allowedSlugs =
        ((control?.spec.inputJsonSchema['properties'] as Map?)?['slug']
                as Map?)?['enum']
            as List?;
    if (allowedSlugs == null || !allowedSlugs.contains(slug)) {
      throw const ServerToolNotConfiguredException();
    }
    final skillId = _cloudSkillId(
      slug,
      resources: resources,
      allowUnavailable: tool.descriptor.toolIdentifier == unloadSkillToolName,
    );
    if (skillId == null) throw const ServerToolNotConfiguredException();
    final resourceId = '${conversation.stableId}:$skillId';
    final selection = resources
        .where(
          (resource) =>
              resource.resourceKind ==
                  WorkspaceResourceKind.conversationSkillSelection &&
              resource.resourceId == resourceId,
        )
        .firstOrNull;
    final patchRequest = cloudSkillSelectionPatchRequest(
      workspaceId: turn.workspaceId,
      turnRequestId: turn.requestId,
      conversationId: conversation.stableId,
      skillId: skillId,
      isAppSkill: !resources.any(
        (resource) =>
            resource.resourceKind == WorkspaceResourceKind.skill &&
            resource.resourceId == skillId &&
            _jsonMap(resource.data)['source'] != 'app',
      ),
      controlName: tool.descriptor.toolIdentifier,
      toolCallId: request.id,
      existingRevision: selection?.revision,
    );
    await _throwIfCancelled(session, turn);
    await beforeSkillSelectionMutation?.call();
    await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
      session,
      userId: turn.initiatorUserId,
      request: patchRequest,
      guard: (transaction) => _throwIfCancelledUnderTurnLock(
        session,
        turn,
        transaction,
      ),
    );
    if (controlName == unloadSkillToolName) return {'unloaded': slug};
    final state = await _skillCommandState(session, turn);
    final manifest = await buildCloudSkillManifest(
      slug: slug,
      userSkills: state.userSkills,
      tools: _materializeStateTools(state),
    );
    if (manifest == null) throw const ServerToolNotConfiguredException();
    return {'loaded': slug, 'manifest': manifest.toJson()};
  }

  Future<Object?> _runDispatchedSkill(
    Session session,
    ConversationTurn turn,
    Map<String, dynamic> arguments,
  ) async {
    final target = SkillCommandTarget.fromArguments(arguments);
    final state = await _skillCommandState(session, turn);
    final tools = _materializeStateTools(state);
    final resolved = await resolveCloudSkillCommandTarget(
      command: target,
      userSkills: state.userSkills,
      tools: tools,
    );
    final normalized = Map<String, dynamic>.from(target.args);
    final result = await switch (resolved.descriptor.kind) {
      AgentResolvedToolKind.skillTemplate => _runSkill(
        session,
        turn,
        resolved,
        normalized,
      ),
      AgentResolvedToolKind.skillNative
          when resolved.descriptor.skillSlug == agentsSkillSlug =>
        _runSubAgentTool(session, turn, resolved, normalized),
      AgentResolvedToolKind.skillNative => _runNativeSkill(
        session,
        turn,
        resolved,
        normalized,
      ),
      _ => throw const ServerToolNotConfiguredException(),
    };
    return {'result': result};
  }

  Future<Object?> _listSkills(Session session, ConversationTurn turn) async {
    final state = await _skillCommandState(session, turn);
    final controls = materializeCloudSkillControlTools(
      selectedSkillIds: state.selectedSkillIds,
      userSkills: state.userSkills,
      templateTools: state.templateTools,
      appSkillSettings: state.appSkillSettings,
      serviceConnections: state.serviceConnections,
      isChildConversation:
          state.conversation.parentConversationStableId != null,
    );
    List<Map<String, String>> summaries(String controlName) {
      final control = controls
          .where((candidate) => candidate.spec.name == controlName)
          .firstOrNull;
      final slugs =
          ((control?.spec.inputJsonSchema['properties'] as Map?)?['slug']
                  as Map?)?['enum']
              as List? ??
          const [];
      return slugs.whereType<String>().map((slug) {
          final user = state.userSkills
              .where((skill) => skill['slug'] == slug)
              .firstOrNull;
          final app = serviceSkillDefinitions
              .where((skill) => skill.identifier == slug || skill.slug == slug)
              .firstOrNull;
          return {
            'slug': slug,
            'title': user?['title'] is String
                ? user!['title']! as String
                : app?.title ??
                      (slug == agentsSkillSlug ? agentsSkillTitle : slug),
          };
        }).toList()
        ..sort((left, right) => left['slug']!.compareTo(right['slug']!));
    }

    return {
      'loadable': summaries(loadSkillToolName),
      'loaded': summaries(unloadSkillToolName),
    };
  }

  Future<Object?> _listSkillCredentials(
    Session session,
    ConversationTurn turn,
    Map<String, dynamic> arguments,
  ) async {
    final slug = arguments['slug'];
    if (slug is! String || slug.isEmpty) {
      throw const FormatException('slug required');
    }
    final state = await _skillCommandState(session, turn);
    final user = state.userSkills
        .where((skill) => skill['slug'] == slug)
        .firstOrNull;
    final app = serviceSkillDefinitions
        .where((skill) => skill.slug == slug || skill.identifier == slug)
        .firstOrNull;
    final selectedId = user?['id'] ?? app?.identifier ?? slug;
    if (!state.authorizedSkillIds.contains(selectedId)) {
      throw const ServerToolNotConfiguredException();
    }
    final credentials = state.serviceConnections.where((connection) {
      if (connection['isEnabled'] == false || connection['hasSecret'] != true) {
        return false;
      }
      if (user != null) {
        return connection['kind'] == 'skillCredential' &&
            connection['credentialDefinitionId'] ==
                user['credentialDefinitionId'];
      }
      return app != null &&
          connection['kind'] == 'appSkillCredential' &&
          connection['serviceId'] == app.identifier;
    });
    return {
      'skillSlug': slug,
      'credentials': [
        for (final credential in credentials)
          {
            'id': credential['id'],
            'name': credential['name'] ?? credential['id'],
          },
      ],
    };
  }

  Future<
    ({
      Conversation conversation,
      Set<String> selectedSkillIds,
      Set<String> authorizedSkillIds,
      List<Map<String, dynamic>> userSkills,
      List<Map<String, dynamic>> templateTools,
      List<Map<String, dynamic>> appSkillSettings,
      List<Map<String, dynamic>> serviceConnections,
    })
  >
  _skillCommandState(Session session, ConversationTurn turn) async {
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.conversationId) &
          table.workspaceId.equals(turn.workspaceId),
    );
    if (conversation == null) throw const ServerToolNotConfiguredException();
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.deletedAt.equals(null),
    );
    Map<String, dynamic> withId(WorkspaceResource resource) => {
      'id': resource.resourceId,
      ..._jsonMap(resource.data),
    };
    final selectedSkillIds = resources
        .where(
          (resource) =>
              resource.resourceKind ==
              WorkspaceResourceKind.conversationSkillSelection,
        )
        .map(withId)
        .where((data) => data['conversationId'] == conversation.stableId)
        .map((data) => data['skillId'])
        .whereType<String>()
        .toSet();
    return (
      conversation: conversation,
      selectedSkillIds: selectedSkillIds,
      authorizedSkillIds: cloudAuthorizedSkillIds(
        conversation: conversation,
        resources: resources,
      ),
      userSkills: resources
          .where(
            (resource) =>
                resource.resourceKind == WorkspaceResourceKind.skill &&
                _jsonMap(resource.data)['source'] != 'app',
          )
          .map(withId)
          .toList(),
      templateTools: resources
          .where(
            (resource) =>
                resource.resourceKind ==
                WorkspaceResourceKind.skillTemplateTool,
          )
          .map(withId)
          .toList(),
      appSkillSettings: resources
          .where(
            (resource) =>
                resource.resourceKind == WorkspaceResourceKind.skillSetting,
          )
          .map(withId)
          .toList(),
      serviceConnections: resources
          .where(
            (resource) =>
                resource.resourceKind ==
                WorkspaceResourceKind.serviceConnection,
          )
          .map(withId)
          .toList(),
    );
  }

  List<ServerResolvedTool> _materializeStateTools(
    ({
      Conversation conversation,
      Set<String> selectedSkillIds,
      Set<String> authorizedSkillIds,
      List<Map<String, dynamic>> userSkills,
      List<Map<String, dynamic>> templateTools,
      List<Map<String, dynamic>> appSkillSettings,
      List<Map<String, dynamic>> serviceConnections,
    })
    state,
  ) => materializeCloudSkillTools(
    selectedSkillIds: state.authorizedSkillIds,
    userSkills: state.userSkills,
    templateTools: state.templateTools,
    appSkillSettings: state.appSkillSettings,
    serviceConnections: state.serviceConnections,
    isChildConversation: state.conversation.parentConversationStableId != null,
  );

  String? _cloudSkillId(
    String slug, {
    required Iterable<WorkspaceResource> resources,
    required bool allowUnavailable,
  }) {
    final userSkill = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.skill &&
              _jsonMap(resource.data)['source'] != 'app' &&
              (allowUnavailable ||
                  _jsonMap(resource.data)['isEnabled'] != false) &&
              _jsonMap(resource.data)['slug'] == slug,
        )
        .firstOrNull;
    if (userSkill != null) return userSkill.resourceId;
    if (slug == agentsSkillSlug) {
      return allowUnavailable || _appSkillEnabled(agentsSkillSlug, resources)
          ? agentsSkillSlug
          : null;
    }
    final serviceSkill = serviceSkillDefinitions
        .where((skill) => skill.identifier == slug || skill.slug == slug)
        .firstOrNull;
    if (serviceSkill == null ||
        (!allowUnavailable &&
            !_appSkillEnabled(serviceSkill.identifier, resources))) {
      return null;
    }
    return serviceSkill.identifier;
  }

  bool _appSkillEnabled(
    String skillId,
    Iterable<WorkspaceResource> resources,
  ) {
    final setting = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.skillSetting &&
              _jsonMap(resource.data)['skillId'] == skillId,
        )
        .map((resource) => _jsonMap(resource.data))
        .lastOrNull;
    return setting?['isEnabled'] != false;
  }

  Future<Object?> _runNativeSkill(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    final skill = serviceSkillDefinitions
        .where((candidate) => candidate.slug == tool.descriptor.skillSlug)
        .firstOrNull;
    final nativeTool = skill?.nativeTools
        .where((candidate) => candidate.slug == tool.descriptor.toolIdentifier)
        .firstOrNull;
    final credentialId = arguments['credentialId'];
    if (skill == null ||
        nativeTool == null ||
        (nativeTool.urlTemplate == null && nativeTool.callback == null)) {
      throw const ServerToolNotConfiguredException();
    }
    var credentials = const <String, String>{};
    if (nativeTool.requiresCredential) {
      if (credentialId is! String ||
          credentialId.isEmpty ||
          !cloudToolAllowsCredential(tool, credentialId)) {
        throw const ServerToolNotConfiguredException();
      }
      final connectionId = cloudServiceConnectionId(credentialId);
      final resource = await _resource(
        session,
        turn.workspaceId,
        WorkspaceResourceKind.serviceConnection,
        connectionId,
      );
      final data = _jsonMap(resource.data);
      if (!isCloudAppSkillCredential(data, skill.identifier)) {
        throw const ServerToolNotConfiguredException();
      }
      final secret = await _secret(
        session,
        turn.workspaceId,
        turn.initiatorUserId,
        WorkspaceSecretKind.skillCredential,
        connectionId,
      );
      if (secret == null) throw const ServerToolNotConfiguredException();
      credentials = Map<String, String>.from(
        _jsonMap(await const WorkspaceSecretCipher().decrypt(session, secret)),
      );
    }
    final httpClient = _skillHttpClient(
      session,
      turn,
      requireHttps: credentials.isNotEmpty,
    );
    return runCompiledServiceSkillTool(
      skillSlug: skill.slug,
      toolSlug: nativeTool.slug,
      input: arguments,
      credentials: credentials,
      httpClient: httpClient,
    );
  }

  Future<Object?> _runSubAgentTool(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    if (tool.descriptor.toolIdentifier == listAgentsToolName) {
      return _listAgents(session, turn.workspaceId, arguments['type']);
    }
    if (tool.descriptor.toolIdentifier != runSubAgentToolName) {
      throw const ServerToolNotConfiguredException();
    }
    final title = arguments['title'];
    final prompt = arguments['prompt'];
    final agentId = arguments['agentId'];
    if (title is! String ||
        title.trim().isEmpty ||
        title.length > maxSubAgentTitleLength ||
        prompt is! String ||
        prompt.trim().isEmpty ||
        prompt.length > maxSubAgentPromptLength ||
        (agentId != null && agentId is! String)) {
      throw const FormatException('Invalid sub-agent request.');
    }
    final parent = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.conversationId) &
          table.workspaceId.equals(turn.workspaceId) &
          table.deletedAt.equals(null),
    );
    if (parent == null || parent.parentConversationStableId != null) {
      throw const ServerToolNotConfiguredException();
    }
    if (agentId is String &&
        !await _isRunnableAgent(session, turn.workspaceId, agentId)) {
      throw const ServerToolNotConfiguredException();
    }
    final id = const Uuid().v4();
    final useCases = ConversationUseCases(
      conversation_repo.ConversationRepository(),
    );
    ConversationSummary? child;
    try {
      await _throwIfCancelled(session, turn);
      child = await useCases.create(
        session,
        userId: turn.initiatorUserId,
        request: CreateConversationRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:create',
          conversationId: id,
          title: title.trim(),
          isPinned: false,
          modelId:
              await _activeTurnModelSelectionId(session, turn) ??
              parent.modelId,
          agentId: agentId as String?,
          parentConversationId: parent.stableId,
        ),
      );
      final queued = await useCases.queueConversationMessage(
        session,
        userId: turn.initiatorUserId,
        request: QueueConversationMessageRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:queue',
          conversationId: child.id,
          expectedProjectionRevision: child.revision,
          clientMessageId: '$id:user',
          content: prompt.trim(),
          attachmentIds: const [],
        ),
      );
      await beforeChildLaunch?.call();
      final started = await useCases.continueConversation(
        session,
        userId: turn.initiatorUserId,
        request: ContinueConversationRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:continue',
          conversationId: child.id,
          expectedProjectionRevision: queued.conversation.projectionRevision,
        ),
        parentTurnId: turn.id,
      );
      final execution = started.activeExecution;
      if (execution == null) throw const ServerToolNotConfiguredException();
      await afterChildContinuation?.call();
      await session.db.transaction(
        (transaction) => _throwIfCancelledUnderTurnLock(
          session,
          turn,
          transaction,
        ),
      );
      return {
        'conversationId': child.id,
        'turnId': execution.id,
        'status': execution.status,
        if (child.agentId != null) 'agentId': child.agentId,
      };
    } on Object {
      if (child != null && await _isCancelled(session, turn)) {
        await _compensateCancelledChild(
          session,
          turn: turn,
          childId: child.id,
          useCases: useCases,
        );
      }
      rethrow;
    }
  }

  Future<String?> _activeTurnModelSelectionId(
    Session session,
    ConversationTurn turn,
  ) async {
    final messageId = turn.userMessageId;
    if (messageId == null) return null;
    final message = await ConversationMessage.db.findById(session, messageId);
    if (message?.metadataJson == null) return null;
    final selectionId = _jsonMap(message!.metadataJson!)['modelSelectionId'];
    return selectionId is String && selectionId.isNotEmpty ? selectionId : null;
  }

  Future<void> _compensateCancelledChild(
    Session session, {
    required ConversationTurn turn,
    required String childId,
    required ConversationUseCases useCases,
  }) async {
    final parent = await Conversation.db.findById(session, turn.conversationId);
    if (parent == null) return;
    final activeTurn = await session.db.transaction((transaction) async {
      final child = await Conversation.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(turn.workspaceId) &
            table.stableId.equals(childId) &
            table.parentConversationStableId.equals(parent.stableId) &
            table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (child == null) return null;
      final execution = child.activeExecutionId == null
          ? null
          : await ConversationExecution.db.findById(
              session,
              child.activeExecutionId!,
              transaction: transaction,
              lockMode: LockMode.forUpdate,
            );
      if (execution != null) {
        return ConversationTurn.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(turn.workspaceId) &
              table.requestId.equals(execution.stableId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
      }
      final pending = await ConversationMessage.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(turn.workspaceId) &
            table.conversationId.equals(child.id) &
            table.pendingOrder.notEquals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      for (final message in pending) {
        await ConversationMessage.db.deleteRow(
          session,
          message,
          transaction: transaction,
        );
      }
      await Conversation.db.updateRow(
        session,
        child.copyWith(
          deletedAt: DateTime.now().toUtc(),
          revision: child.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
      return null;
    });
    if (activeTurn == null ||
        ConversationStatuses.isTerminal(activeTurn.status)) {
      return;
    }
    await useCases.cancelTurn(
      session,
      userId: turn.initiatorUserId,
      request: CancelTurnRequest(
        workspaceId: turn.workspaceId,
        requestId: '$childId:cancelled-parent',
        turnId: activeTurn.requestId,
        expectedTurnRevision: activeTurn.revision,
      ),
    );
    await _retireCancelledChildExecution(
      session,
      workspaceId: turn.workspaceId,
      childId: childId,
      actorUserId: turn.initiatorUserId,
    );
  }

  Future<void> _retireCancelledChildExecution(
    Session session, {
    required int workspaceId,
    required String childId,
    required String actorUserId,
  }) => session.db.transaction((transaction) async {
    final child = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(childId),
      transaction: transaction,
    );
    final childDatabaseId = child?.id;
    final executionId = child?.activeExecutionId;
    if (childDatabaseId == null || executionId == null) return;
    final execution = await ConversationExecution.db.findById(
      session,
      executionId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (execution == null) return;
    final lockedChild = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.id.equals(childDatabaseId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedChild == null || lockedChild.activeExecutionId != execution.id) {
      return;
    }
    final now = DateTime.now().toUtc();
    if (execution.assistantMessageId case final assistantMessageId?) {
      final assistant = await ConversationMessage.db.findById(
        session,
        assistantMessageId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (assistant != null &&
          assistant.status != ConversationStatuses.cancelled) {
        await ConversationMessage.db.updateRow(
          session,
          assistant.copyWith(
            content: '',
            status: ConversationStatuses.cancelled,
            metadataJson: '{"errorCode":"cancelled"}',
            revision: assistant.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
    }
    await ConversationExecution.db.updateRow(
      session,
      execution.copyWith(
        status: ConversationStatuses.cancelled,
        terminalAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final sequence = lockedChild.eventSequence + 1;
    await Conversation.db.updateRow(
      session,
      lockedChild.copyWith(
        executionState: 'idle',
        activeExecutionId: null,
        eventSequence: sequence,
        projectionRevision: lockedChild.projectionRevision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationEvent.db.insertRow(
      session,
      ConversationEvent(
        workspaceId: workspaceId,
        conversationId: lockedChild.id!,
        sequence: sequence,
        eventId: const Uuid().v7(),
        actorUserId: actorUserId,
        requestId: '$childId:cancelled-parent',
        kind: ConversationEventType.executionStopped,
        payloadJson: jsonEncode({
          'executionId': execution.stableId,
          'status': ConversationStatuses.cancelled,
        }),
        createdAt: now,
      ),
      transaction: transaction,
    );
  });

  Future<Map<String, Object?>> _listAgents(
    Session session,
    int workspaceId,
    Object? type,
  ) async {
    if (type != null && type != 'main' && type != 'sub_agent') {
      throw const FormatException('Unknown agent type.');
    }
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.agent) &
          table.deletedAt.equals(null),
    );
    return {
      'agents': [
        for (final resource in resources)
          if (_agentTypes(_jsonMap(resource.data), type).isNotEmpty)
            {
              'id': resource.resourceId,
              'name': _jsonMap(resource.data)['name'],
              'description': _jsonMap(resource.data)['description'] ?? '',
              'types': _agentTypes(_jsonMap(resource.data), null),
            },
      ],
    };
  }

  Future<bool> _isRunnableAgent(
    Session session,
    int workspaceId,
    String agentId,
  ) async {
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.agent) &
          table.resourceId.equals(agentId) &
          table.deletedAt.equals(null),
    );
    return resource != null &&
        _agentTypes(_jsonMap(resource.data), 'sub_agent').isNotEmpty;
  }

  List<String> _agentTypes(Map<String, dynamic> data, Object? filter) {
    if (data['isEnabled'] == false) return const [];
    final types = switch (data['visibility']) {
      'chatSelector' => const ['main'],
      'subAgentList' => const ['sub_agent'],
      _ => const ['main', 'sub_agent'],
    };
    return filter == null || types.contains(filter) ? types : const [];
  }

  Future<Object?> _runMcp(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    final serverId = tool.descriptor.mcpServerId!;
    final server = await _resource(
      session,
      turn.workspaceId,
      WorkspaceResourceKind.mcpServer,
      serverId,
    );
    final data = _jsonMap(server.data);
    final transport = data['transport'];
    if (transport is! Map || transport['type'] != 'streamableHttp') {
      throw const ServerToolNotConfiguredException();
    }
    final uri = McpServerPolicy.validateUri(data['url'] as String);
    final addresses = await InternetAddress.lookup(uri.host);
    McpServerPolicy.validateAddresses(addresses);
    final secret = await _secret(
      session,
      turn.workspaceId,
      turn.initiatorUserId,
      WorkspaceSecretKind.mcp,
      serverId,
    );
    await _throwIfCancelled(session, turn);
    final result = await _postJson(
      session,
      turn,
      uri,
      addresses,
      {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'tools/call',
        'params': {
          'name': tool.descriptor.toolIdentifier,
          'arguments': arguments,
        },
      },
      bearerToken: secret == null
          ? null
          : await const WorkspaceSecretCipher().decrypt(session, secret),
    );
    return McpToolResult(
      content: switch (result['content']) {
        final List<dynamic> content =>
          content
              .whereType<Map<String, dynamic>>()
              .where((item) => item['type'] == 'text')
              .map((item) => McpTextContent('${item['text'] ?? ''}'))
              .toList(),
        _ => const [],
      },
      structuredContent: switch (result['structuredContent']) {
        final Map<String, dynamic> content => content,
        _ => null,
      },
      isError: result['isError'] as bool?,
    ).toModelText();
  }

  Future<Object?> _runSkill(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.skillTemplateTool) &
          table.deletedAt.equals(null),
    );
    final resource = resources.where((candidate) {
      final data = _jsonMap(candidate.data);
      return data['skillSlug'] == tool.descriptor.skillSlug &&
          (data['toolSlug'] == tool.descriptor.toolIdentifier ||
              data['name'] == tool.descriptor.toolIdentifier);
    }).firstOrNull;
    if (resource == null) throw const ServerToolNotConfiguredException();
    final data = _jsonMap(resource.data);
    final templateJson = data['templateJson'] ?? data['urlTemplateJson'];
    final inputsJson = data['inputsJson'];
    if (templateJson is! String || inputsJson is! String) {
      throw const ServerToolNotConfiguredException();
    }
    final credentialId = arguments['credentialId'];
    final secret = credentialId is String && credentialId.isNotEmpty
        ? await _skillCredentialSecret(
            session,
            turn: turn,
            skillData: data,
            credentialId: credentialId,
          )
        : null;
    if (data['requiresCredential'] == true && secret == null) {
      throw const ServerToolNotConfiguredException();
    }
    final credentials = secret == null
        ? const <String, String>{}
        : Map<String, String>.from(
            _jsonMap(
              await const WorkspaceSecretCipher().decrypt(session, secret),
            ),
          );
    final request = const ResolveSkillUrlTemplate()(
      template: SkillUrlTemplate.fromJsonString(templateJson),
      inputs: arguments,
      credentials: credentials,
      inputDefinitions: SkillTemplateInputDefinition.parseMap(inputsJson),
    );
    final uri = requirePublicUriSyntax(
      request.url,
      requireHttps: credentials.isNotEmpty,
    );
    final addresses = await InternetAddress.lookup(uri.host);
    if (addresses.any(
      (address) => isPrivateIpAddress(
        address.rawAddress,
        isIpv6: address.type == InternetAddressType.IPv6,
      ),
    )) {
      throw const FormatException(publicUrlError);
    }
    await _throwIfCancelled(session, turn);
    final response = await _request(session, turn, uri, addresses, request);
    return const UrlContentTransformer()
        .transform(
          response,
          requestedFormat: request.format,
        )
        .body;
  }

  Future<WorkspaceSecret?> _skillCredentialSecret(
    Session session, {
    required ConversationTurn turn,
    required Map<String, dynamic> skillData,
    required String credentialId,
  }) async {
    final credential = await _resource(
      session,
      turn.workspaceId,
      WorkspaceResourceKind.serviceConnection,
      credentialId,
    );
    final credentialData = _jsonMap(credential.data);
    final skillId = skillData['skillId'];
    if (credentialData['kind'] != 'skillCredential' ||
        credentialData['isEnabled'] != true ||
        skillId is! String) {
      throw const ServerToolNotConfiguredException();
    }
    final skill = await _resource(
      session,
      turn.workspaceId,
      WorkspaceResourceKind.skill,
      skillId,
    );
    final definitionId = _jsonMap(skill.data)['credentialDefinitionId'];
    if (definitionId is! String ||
        credentialData['credentialDefinitionId'] != definitionId) {
      throw const ServerToolNotConfiguredException();
    }
    return _secret(
      session,
      turn.workspaceId,
      turn.initiatorUserId,
      WorkspaceSecretKind.skillCredential,
      credentialId,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    Session session,
    ConversationTurn turn,
    Uri uri,
    List<InternetAddress> addresses,
    Map<String, Object?> body, {
    String? bearerToken,
  }) async {
    final client = _client(addresses);
    final requestDone = Completer<void>();
    unawaited(_closeClientOnCancellation(client, session, turn, requestDone));
    try {
      final request = await client.postUrl(uri);
      request
        ..followRedirects = false
        ..headers.contentType = ContentType.json
        ..headers.set('Accept', 'application/json');
      if (bearerToken != null) {
        request.headers.set('Authorization', 'Bearer $bearerToken');
      }
      request.write(jsonEncode(body));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok || response.isRedirect) {
        throw const HttpException('Tool request failed.');
      }
      final decoded = jsonDecode(await _readResponse(response));
      if (decoded is! Map<String, dynamic> ||
          decoded['result'] is! Map<String, dynamic>) {
        throw const FormatException('Invalid tool response.');
      }
      return decoded['result']! as Map<String, dynamic>;
    } on Object {
      await _throwIfCancelled(session, turn);
      rethrow;
    } finally {
      client.close(force: true);
      if (!requestDone.isCompleted) requestDone.complete();
    }
  }

  SkillHttpClient _skillHttpClient(
    Session session,
    ConversationTurn turn, {
    required bool requireHttps,
  }) => (input) {
    HttpClient? activeClient;
    var closed = false;
    void close() {
      closed = true;
      activeClient?.close(force: true);
    }

    return CancelableOperation<UrlResponse>.fromFuture(
      runBoundedServerSkillRequest(
        timeout: input.timeout,
        close: close,
        run: () async {
          final target = await validateServerSkillRequestTarget(
            input,
            requireHttps: requireHttps,
          );
          await _throwIfCancelled(session, turn);
          return _request(
            session,
            turn,
            target.uri,
            target.addresses,
            input,
            onClient: (client) {
              activeClient = client;
              if (closed) client.close(force: true);
            },
          );
        },
      ),
      onCancel: close,
    );
  };

  Future<UrlResponse> _request(
    Session session,
    ConversationTurn turn,
    Uri uri,
    List<InternetAddress> addresses,
    UrlRequest input, {
    void Function(HttpClient client)? onClient,
  }) async {
    final client = _client(addresses);
    onClient?.call(client);
    final requestDone = Completer<void>();
    unawaited(_closeClientOnCancellation(client, session, turn, requestDone));
    final stopwatch = Stopwatch()..start();
    try {
      final request = await client.openUrl(input.method.value, uri);
      request.followRedirects = false;
      input.headers.forEach(request.headers.set);
      if (input.body != null) request.write(input.body);
      final response = await request.close();
      rejectServerSkillRedirect(response.isRedirect);
      final headers = <String, List<String>>{};
      response.headers.forEach((name, values) => headers[name] = values);
      return UrlResponse(
        statusCode: response.statusCode,
        body: await _readResponse(response),
        headers: headers,
        elapsed: stopwatch.elapsed,
      );
    } on Object {
      await _throwIfCancelled(session, turn);
      rethrow;
    } finally {
      client.close(force: true);
      if (!requestDone.isCompleted) requestDone.complete();
    }
  }

  Future<void> _throwIfCancelled(
    Session session,
    ConversationTurn turn,
  ) async {
    if (await _isCancelled(session, turn)) {
      throw const ConversationCancelledException();
    }
  }

  Future<bool> _isCancelled(
    Session session,
    ConversationTurn turn,
  ) => const DatabaseConversationCancellationProbe().isCancelled(
    session,
    turn.id!,
  );

  Future<void> _throwIfCancelledUnderTurnLock(
    Session session,
    ConversationTurn turn,
    Transaction transaction,
  ) async {
    final current = await ConversationTurn.db.findById(
      session,
      turn.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (current == null ||
        current.cancellationRequestedAt != null ||
        ConversationStatuses.isTerminal(current.status)) {
      throw const ConversationCancelledException();
    }
  }

  Future<void> _closeClientOnCancellation(
    HttpClient client,
    Session session,
    ConversationTurn turn,
    Completer<void> requestDone,
  ) => closeOnServerSkillCancellation(
    isCancelled: () =>
        const DatabaseConversationCancellationProbe().isCancelled(
          session,
          turn.id!,
        ),
    close: () {
      if (!requestDone.isCompleted) client.close(force: true);
    },
    done: requestDone.future,
  );

  HttpClient _client(List<InternetAddress> addresses) => HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..connectionFactory = (target, proxyHost, proxyPort) =>
        Socket.startConnect(addresses.first, target.port);

  Future<String> _readResponse(HttpClientResponse response) =>
      readBoundedServerSkillResponse(response);

  Future<WorkspaceResource> _resource(
    Session session,
    int workspaceId,
    WorkspaceResourceKind kind,
    String id,
  ) async {
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(kind) &
          table.resourceId.equals(id) &
          table.deletedAt.equals(null),
    );
    if (resource == null) throw const ServerToolNotConfiguredException();
    return resource;
  }

  Future<WorkspaceSecret?> _secret(
    Session session,
    int workspaceId,
    String userId,
    WorkspaceSecretKind kind,
    String resourceId,
  ) => const WorkspaceSecretResolver().findForInitiator(
    session,
    workspaceId: workspaceId,
    kind: kind,
    initiatorUserId: userId,
    resourceId: resourceId,
    allowWorkspaceFallback: true,
  );

  Map<String, dynamic> _jsonMap(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }
}

class ServerToolNotConfiguredException implements Exception {
  const ServerToolNotConfiguredException();
}
