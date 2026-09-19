import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../agents/agent_catalog_repository.dart';
import '../../agents/agent_catalog_use_cases.dart';
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

List<SkillCredentialOption> cloudSkillCredentialOptions({
  required String slug,
  required Iterable<Map<String, dynamic>> userSkills,
  required Iterable<Map<String, dynamic>> serviceConnections,
}) {
  final user = userSkills.where((skill) => skill['slug'] == slug).firstOrNull;
  final app = serviceSkillDefinitions
      .where((skill) => skill.slug == slug || skill.identifier == slug)
      .firstOrNull;
  return [
    for (final connection in serviceConnections)
      if (connection['isEnabled'] != false &&
          connection['hasSecret'] == true &&
          ((user != null &&
                  connection['kind'] == 'skillCredential' &&
                  connection['credentialDefinitionId'] ==
                      user['credentialDefinitionId']) ||
              (user == null &&
                  app != null &&
                  connection['kind'] == 'appSkillCredential' &&
                  connection['serviceId'] == app.identifier)))
        if (connection['id'] case final String id)
          SkillCredentialOption(
            credentialId: id,
            displayName: connection['name'] is String
                ? connection['name']! as String
                : id,
          ),
  ];
}

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

String? cloudToolCredentialId(ServerResolvedTool tool, Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();

  final ids =
      (((tool.spec.inputJsonSchema['properties'] as Map?)?['credentialId']
                  as Map?)?['enum']
              as List?)
          ?.whereType<String>()
          .toList(growable: false) ??
      const <String>[];
  return ids.length == 1 ? ids.single : null;
}

PatchWorkspaceStateRequest cloudSkillSelectionPatchRequest({
  required int workspaceId,
  required String turnRequestId,
  required String conversationId,
  required String skillId,
  required bool isAppSkill,
  required String toolCallId,
}) {
  final resourceId = '$conversationId:$skillId';
  final operation = WorkspacePatchOperation(
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
  );
  return PatchWorkspaceStateRequest(
    workspaceId: workspaceId,
    requestId: '$turnRequestId:$toolCallId:activate_skill:$skillId',
    operations: [operation],
  );
}

typedef ServerToolExecutorInterlock = Future<void> Function();
const _runCreateChildPhase = 'run.createChild';
const _runCreatePromptPhase = 'run.createPrompt';
const _runContinueAgentPhase = 'run.continueAgent';

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
  final templateTool = skill?.tools
      .where((candidate) => candidate.slug == toolSlug)
      .firstOrNull;
  if (skill == null ||
      templateTool == null ||
      templateTool.urlTemplate == null) {
    throw const ServerToolNotConfiguredException();
  }
  return AppSkillExecutor(
        SkillTemplateExecutor(const ResolveSkillUrlTemplate(), httpClient),
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
  Duration dnsTimeout = const Duration(seconds: 5),
}) async {
  final uri = requirePublicUriSyntax(request.url, requireHttps: requireHttps);
  final addresses = await lookup(uri.host).timeout(dnsTimeout);
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
  Duration idleTimeout = const Duration(seconds: 30),
}) async {
  final bytes = <int>[];
  await for (final chunk in response.timeout(idleTimeout)) {
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

Future<T> runBoundedServerSkillHttpRequest<T>({
  required Duration timeout,
  required Future<T> Function(void Function(HttpClient client) registerClient)
  run,
  void Function(HttpClient client)? closeClient,
}) {
  HttpClient? activeClient;
  var closed = false;
  void close() {
    closed = true;
    final client = activeClient;
    if (client != null) {
      (closeClient ?? (client) => client.close(force: true))(client);
    }
  }

  return runBoundedServerSkillRequest(
    timeout: timeout,
    close: close,
    run: () => run((client) {
      activeClient = client;
      if (closed) {
        (closeClient ?? (client) => client.close(force: true))(client);
      }
    }),
  );
}

class const ServerToolExecutorService({
  final ServerToolExecutorInterlock? beforeChildLaunch,
  final ServerToolExecutorInterlock? afterChildContinuation,
  final ServerToolExecutorInterlock? beforeSkillSelectionMutation,
}) {
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
      AgentResolvedToolKind.skillAppTemplate => _runNativeSkill(
        session,
        turn,
        tool,
        request.arguments,
      ),
      AgentResolvedToolKind.skillNative
          when tool.descriptor.skillSlug == agentsSkillSlug =>
        _runSubAgentTool(session, turn, tool, request),
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
    if (tool.descriptor.toolIdentifier == listSkillCredentialsToolName) {
      return _listSkillCredentials(session, turn, request.arguments);
    }
    if (tool.descriptor.toolIdentifier == callSkillToolName) {
      return _runDispatchedSkill(session, turn, request);
    }
    if (tool.descriptor.toolIdentifier != activateSkillToolName) {
      throw const ServerToolNotConfiguredException();
    }
    final target = SkillActivationTarget.fromArguments(
      Map<String, Object?>.from(request.arguments),
    );
    final state = await _skillCommandState(session, turn);
    final skillId = _availableSkillId(target.slug, state);
    if (skillId == null) throw const ServerToolNotConfiguredException();
    final tools = materializeCloudSkillTools(
      selectedSkillIds: {...state.authorizedSkillIds, skillId},
      userSkills: state.userSkills,
      templateTools: state.templateTools,
      appSkillSettings: state.appSkillSettings,
      serviceConnections: state.serviceConnections,
      isChildConversation:
          state.conversation.parentConversationStableId != null,
    );
    final manifest = await buildCloudSkillManifest(
      slug: target.slug,
      userSkills: state.userSkills,
      tools: tools,
    );
    if (manifest == null || manifest.revision != target.revision) {
      throw FormatException(
        'Skill revision changed; use the current skill catalog to refresh: '
        '${target.slug}',
      );
    }
    final credentials = manifest.tools.any((tool) => tool.credentialRequired)
        ? cloudSkillCredentialOptions(
            slug: target.slug,
            userSkills: state.userSkills,
            serviceConnections: state.serviceConnections,
          )
        : const <SkillCredentialOption>[];
    if (!state.selectedSkillIds.contains(skillId) &&
        !state.authorizedSkillIds.contains(skillId)) {
      await _throwIfCancelled(session, turn);
      await beforeSkillSelectionMutation?.call();
      await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
        session,
        userId: turn.initiatorUserId,
        request: cloudSkillSelectionPatchRequest(
          workspaceId: turn.workspaceId,
          turnRequestId: turn.requestId,
          conversationId: state.conversation.stableId,
          skillId: skillId,
          isAppSkill: !_isUserSkill(skillId, state.userSkills),
          toolCallId: request.id,
        ),
        guard: (transaction) => _throwIfCancelledUnderTurnLock(
          session,
          turn,
          transaction,
        ),
      );
    }
    return buildSkillActivationResult(
      manifest: manifest,
      content: _skillContent(target.slug, state),
      credentials: credentials,
    );
  }

  Future<Object?> _runDispatchedSkill(
    Session session,
    ConversationTurn turn,
    ServerToolRequest request,
  ) async {
    final target = SkillCommandTarget.fromArguments(request.arguments);
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
      AgentResolvedToolKind.skillAppTemplate => _runNativeSkill(
        session,
        turn,
        resolved,
        normalized,
      ),
      AgentResolvedToolKind.skillNative
          when resolved.descriptor.skillSlug == agentsSkillSlug =>
        _runSubAgentTool(
          session,
          turn,
          resolved,
          ServerToolRequest(
            id: request.id,
            name: resolved.spec.name,
            arguments: normalized,
          ),
        ),
      AgentResolvedToolKind.skillNative => _runNativeSkill(
        session,
        turn,
        resolved,
        normalized,
      ),
      _ => throw const ServerToolNotConfiguredException(),
    };
    return result is ServerToolAwaitingSubAgents ? result : {'result': result};
  }

  Future<Object?> _listSkillCredentials(
    Session session,
    ConversationTurn turn,
    Map<String, dynamic> arguments,
  ) async {
    final slug = arguments['slug'] ?? arguments['skillSlug'];
    if (slug is! String || slug.isEmpty) {
      throw const FormatException('slug required');
    }
    final state = await _skillCommandState(session, turn);
    final selectedId =
        state.userSkills
            .where((skill) => skill['slug'] == slug)
            .map((skill) => skill['id'])
            .whereType<String>()
            .firstOrNull ??
        serviceSkillDefinitions
            .where((skill) => skill.slug == slug || skill.identifier == slug)
            .map((skill) => skill.identifier)
            .firstOrNull ??
        slug;
    if (!state.authorizedSkillIds.contains(selectedId)) {
      throw const ServerToolNotConfiguredException();
    }
    final credentials = cloudSkillCredentialOptions(
      slug: slug,
      userSkills: state.userSkills,
      serviceConnections: state.serviceConnections,
    );
    return {
      'skillSlug': slug,
      'credentials': [
        for (final credential in credentials)
          {
            'id': credential.credentialId,
            'name': credential.displayName,
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

  String? _availableSkillId(
    String slug,
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
  ) {
    final user = state.userSkills
        .where((skill) => skill['slug'] == slug)
        .firstOrNull;
    if (user != null &&
        cloudUserSkillReady(
          user,
          state.templateTools,
          state.serviceConnections,
        )) {
      return user['id'] as String?;
    }
    if (slug == agentsSkillSlug &&
        state.conversation.parentConversationStableId == null &&
        cloudAppSkillEnabled(agentsSkillSlug, state.appSkillSettings)) {
      return agentsSkillSlug;
    }
    final app = serviceSkillDefinitions
        .where((skill) => skill.slug == slug || skill.identifier == slug)
        .firstOrNull;
    if (app == null ||
        !cloudAppSkillEnabled(app.identifier, state.appSkillSettings) ||
        !cloudServiceSkillReady(app, state.serviceConnections)) {
      return null;
    }
    return app.identifier;
  }

  bool _isUserSkill(
    String skillId,
    Iterable<Map<String, dynamic>> userSkills,
  ) => userSkills.any((skill) => skill['id'] == skillId);

  String _skillContent(
    String slug,
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
  ) {
    final user = state.userSkills
        .where((skill) => skill['slug'] == slug)
        .firstOrNull;
    if (user?['content'] case final String content) return content;
    if (slug == agentsSkillSlug) return agentsSkillContent;
    final app = serviceSkillDefinitions
        .where((skill) => skill.slug == slug || skill.identifier == slug)
        .firstOrNull;
    if (app != null) return app.content;
    throw const ServerToolNotConfiguredException();
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
    final templateTool = skill?.tools
        .where((candidate) => candidate.slug == tool.descriptor.toolIdentifier)
        .firstOrNull;
    final credentialId = cloudToolCredentialId(
      tool,
      arguments['credentialId'],
    );
    if (skill == null ||
        skill.kind != AppSkillDefinitionKind.template ||
        templateTool == null ||
        templateTool.urlTemplate == null) {
      throw const ServerToolNotConfiguredException();
    }
    var credentials = const <String, String>{};
    if (templateTool.requiresCredential) {
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
      toolSlug: templateTool.slug,
      input: arguments,
      credentials: credentials,
      httpClient: httpClient,
    );
  }

  Future<Object?> _runSubAgentTool(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    ServerToolRequest request,
  ) async {
    if (tool.descriptor.toolIdentifier == listAgentsToolName) {
      return _listAgents(session, turn, request.arguments);
    }
    if (tool.descriptor.toolIdentifier != runSubAgentToolName) {
      throw const ServerToolNotConfiguredException();
    }
    final rawAgentId = request.arguments['agentId'];
    final id = const Uuid().v4();
    final useCases = ConversationUseCases(
      conversation_repo.ConversationRepository(),
    );
    ConversationSummary? child;
    final startedAt = DateTime.now().toUtc();
    var failurePhase = 'run.validate';
    void logLifecycle(
      String phase, {
      String? childId,
      required String state,
      int childCount = 1,
    }) {
      session.log(
        'Sub-agent lifecycle: parentConversation=${turn.conversationId}, '
        'parentTurn=${turn.id}, toolCall=${request.id}, '
        'childConversation=${childId ?? '-'}, phase=$phase, '
        'elapsedMs=${DateTime.now().toUtc().difference(startedAt).inMilliseconds}, '
        'childCount=$childCount, state=$state.',
      );
    }

    try {
      final input = _validatedSubAgentRequest(request.arguments);
      failurePhase = 'run.parentValidation';
      final parent = await _requireSubAgentParent(session, turn);
      failurePhase = 'run.agentValidation';
      await _validateSubAgentAgent(session, turn, input.agentId);
      failurePhase = _runCreateChildPhase;
      await _throwIfCancelled(session, turn);
      logLifecycle(_runCreateChildPhase, state: 'started');
      child = await useCases.create(
        session,
        userId: turn.initiatorUserId,
        request: CreateConversationRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:create',
          conversationId: id,
          title: input.title.trim(),
          isPinned: false,
          modelId:
              await _activeTurnModelSelectionId(session, turn) ??
              parent.modelId,
          agentId: input.agentId,
          parentConversationId: parent.stableId,
        ),
      );
      logLifecycle(
        _runCreateChildPhase,
        childId: child.id,
        state: 'completed',
      );
      failurePhase = _runCreatePromptPhase;
      logLifecycle(_runCreatePromptPhase, childId: child.id, state: 'started');
      final queued = await useCases.queueConversationMessage(
        session,
        userId: turn.initiatorUserId,
        request: QueueConversationMessageRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:queue',
          conversationId: child.id,
          expectedProjectionRevision: child.revision,
          clientMessageId: '$id:user',
          content: input.prompt.trim(),
          attachmentIds: const [],
        ),
      );
      logLifecycle(
        _runCreatePromptPhase,
        childId: child.id,
        state: 'completed',
      );
      failurePhase = 'run.beforeChildLaunch';
      await beforeChildLaunch?.call();
      failurePhase = _runContinueAgentPhase;
      logLifecycle(
        _runContinueAgentPhase,
        childId: child.id,
        state: 'started',
      );
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
        parentToolCallId: request.id,
      );
      logLifecycle(
        _runContinueAgentPhase,
        childId: child.id,
        state: 'completed',
      );
      failurePhase = 'run.readResult';
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
      logLifecycle(
        'run.awaitingSubAgents',
        childId: child.id,
        state: 'waiting',
      );
      return ServerToolAwaitingSubAgents(
        children: [
          {
            'conversationId': child.id,
            'turnId': execution.id,
            'status': execution.status,
            if (child.agentId != null) 'agentId': child.agentId,
          },
        ],
      );
    } on ConversationCancelledException {
      logLifecycle(
        failurePhase,
        childId: child?.id,
        state: 'cancelled',
      );
      if (child != null) {
        await _compensateCancelledChild(
          session,
          turn: turn,
          childId: child.id,
          useCases: useCases,
        );
      }
      rethrow;
    } on AgentToolExecutionFailure catch (failure) {
      logLifecycle(
        failure.failurePhase,
        childId: child?.id,
        state: 'failed',
      );
      if (child == null) rethrow;

      throw _subAgentFailure(
        error: failure.error,
        stackTrace: failure.stackTrace,
        failurePhase: failure.failurePhase,
        childId: child.id,
        agentId: child.agentId,
      );
    } on Object catch (error, stackTrace) {
      logLifecycle(
        failurePhase,
        childId: child?.id,
        state: 'failed',
      );
      if (child != null && await _isCancelled(session, turn)) {
        await _compensateCancelledChild(
          session,
          turn: turn,
          childId: child.id,
          useCases: useCases,
        );
      }
      throw _subAgentFailure(
        error: error,
        stackTrace: stackTrace,
        failurePhase: failurePhase,
        childId: child?.id,
        agentId: child?.agentId ?? (rawAgentId is String ? rawAgentId : null),
      );
    }
  }

  ({String title, String prompt, String? agentId}) _validatedSubAgentRequest(
    Map<String, dynamic> arguments,
  ) {
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
    return (
      title: title,
      prompt: prompt,
      agentId: agentId as String?,
    );
  }

  Future<Conversation> _requireSubAgentParent(
    Session session,
    ConversationTurn turn,
  ) async {
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
    return parent;
  }

  Future<void> _validateSubAgentAgent(
    Session session,
    ConversationTurn turn,
    String? agentId,
  ) async {
    if (agentId is String &&
        !await _isRunnableAgent(session, turn.workspaceId, agentId)) {
      throw const ServerToolNotConfiguredException();
    }
  }

  AgentToolExecutionFailure _subAgentFailure({
    required Object error,
    required StackTrace stackTrace,
    required String failurePhase,
    String? childId,
    String? agentId,
  }) => AgentToolExecutionFailure(
    responseRaw: jsonEncode({
      'conversationId': ?childId,
      'status': 'error',
      'content': 'Sub-agent failed.',
      'agentId': ?agentId,
    }),
    error: error,
    stackTrace: stackTrace,
    failurePhase: failurePhase,
  );

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
          !ConversationStatuses.isMessageTerminal(assistant.status)) {
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
    ConversationTurn turn,
    Map<String, dynamic> arguments,
  ) async {
    final query = SubAgentCatalogQuery.fromArguments(
      turn.workspaceId.toString(),
      arguments,
    );
    final page =
        await AgentCatalogUseCases(
          AgentCatalogRepository(),
          WorkspaceStateRepository(),
        ).list(
          session,
          userId: turn.initiatorUserId,
          request: ListAgentsRequest(
            workspaceId: turn.workspaceId,
            search: query.query,
            type: switch (query.type) {
              'main' => AgentCatalogType.chatSelector,
              'sub_agent' => AgentCatalogType.subAgentList,
              _ => null,
            },
            status: AgentCatalogStatus.enabled,
            limit: query.limit,
            cursor: query.cursor,
          ),
        );
    return {
      'agents': [
        for (final agent in page.agents)
          {
            'id': agent.id,
            'name': agent.name,
            'description': agent.description,
            'types': _agentCatalogTypes(agent.visibility),
          },
      ],
      'nextCursor': page.nextCursor,
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

  List<String> _agentCatalogTypes(AgentCatalogVisibility visibility) =>
      switch (visibility) {
        .chatSelector => const ['main'],
        .subAgentList => const ['sub_agent'],
        .both => const ['main', 'sub_agent'],
      };

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
    final addresses = await InternetAddress.lookup(
      uri.host,
    ).timeout(const Duration(seconds: 5));
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
    final credentialDefinitionId = await _skillCredentialDefinitionId(
      session,
      turn.workspaceId,
      data,
    );
    final definition = await _skillTemplateDefinition(
      session,
      turn.workspaceId,
      data,
      credentialDefinitionId,
    );
    validateSkillTemplateDefinition(definition);
    final credentialId = await _resolveSkillTemplateCredentialId(
      session,
      turn: turn,
      skillData: data,
      value: arguments['credentialId'],
      definitionId: credentialDefinitionId,
    );
    final secret = credentialId == null
        ? null
        : await _skillCredentialSecret(
            session,
            turn: turn,
            skillData: data,
            credentialId: credentialId,
            credentialDefinitionId: credentialDefinitionId,
          );
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
    await _throwIfCancelled(session, turn);
    final response =
        await SkillTemplateExecutor(
              const ResolveSkillUrlTemplate(),
              _skillHttpClient(
                session,
                turn,
                requireHttps: credentials.isNotEmpty,
              ),
            )
            .call(
              definition: definition,
              inputs: arguments,
              credentials: credentials,
            )
            .value;
    return response.body;
  }

  Future<SkillTemplateDefinition> _skillTemplateDefinition(
    Session session,
    int workspaceId,
    Map<String, dynamic> data,
    String? credentialDefinitionId,
  ) async {
    final definition = _skillTemplateDefinitionFromData(data);
    if (credentialDefinitionId == null) return definition;

    final credentialDefinition = await _resource(
      session,
      workspaceId,
      WorkspaceResourceKind.skillDefinition,
      credentialDefinitionId,
    );
    final credentialData = _jsonMap(credentialDefinition.data);
    final attributesJson = credentialData['attributesJson'];
    if (attributesJson is! String) {
      throw const ServerToolNotConfiguredException();
    }

    return definition.copyWith(
      credentialDefinitions: {
        ...SkillCredentialAttributeDefinition.parseMap(attributesJson),
        ...definition.credentialDefinitions,
      },
    );
  }

  SkillTemplateDefinition _skillTemplateDefinitionFromData(
    Map<String, dynamic> data,
  ) {
    final definitionJson = data['definitionJson'];
    if (definitionJson is String &&
        definitionJson.trim().isNotEmpty &&
        definitionJson != '{}') {
      return SkillTemplateDefinition.fromJsonString(definitionJson);
    }
    final templateJson = data['templateJson'] ?? data['urlTemplateJson'];
    final inputsJson = data['inputsJson'];
    if (templateJson is! String || inputsJson is! String) {
      throw const ServerToolNotConfiguredException();
    }

    return SkillTemplateDefinition.fromLegacyJson(
      templateJson: templateJson,
      inputsJson: inputsJson,
    );
  }

  Future<String?> _skillCredentialDefinitionId(
    Session session,
    int workspaceId,
    Map<String, dynamic> data,
  ) async {
    final toolDefinitionId = data['credentialDefinitionId'];
    if (toolDefinitionId is String && toolDefinitionId.trim().isNotEmpty) {
      return toolDefinitionId.trim();
    }
    final skillId = data['skillId'];
    if (skillId is! String || skillId.isEmpty) return null;

    final skill = await _resource(
      session,
      workspaceId,
      WorkspaceResourceKind.skill,
      skillId,
    );
    final skillDefinitionId = _jsonMap(skill.data)['credentialDefinitionId'];
    if (skillDefinitionId is! String || skillDefinitionId.trim().isEmpty) {
      return null;
    }

    return skillDefinitionId.trim();
  }

  Future<String?> _resolveSkillTemplateCredentialId(
    Session session, {
    required ConversationTurn turn,
    required Map<String, dynamic> skillData,
    required Object? value,
    String? definitionId,
  }) async {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (skillData['requiresCredential'] != true) return null;

    final skillId = skillData['skillId'];
    final resolvedDefinitionId =
        definitionId ?? skillData['credentialDefinitionId'];
    if (skillId is! String || resolvedDefinitionId is! String) {
      throw const ServerToolNotConfiguredException();
    }
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.serviceConnection) &
          table.deletedAt.equals(null),
    );
    final candidates = resources
        .where((resource) {
          final data = _jsonMap(resource.data);
          return data['kind'] == 'skillCredential' &&
              data['credentialDefinitionId'] == resolvedDefinitionId &&
              data['isEnabled'] == true &&
              data['hasSecret'] == true;
        })
        .map((resource) => resource.resourceId)
        .toList(growable: false);
    if (candidates.length == 1) return candidates.single;

    throw const ServerToolNotConfiguredException();
  }

  Future<WorkspaceSecret?> _skillCredentialSecret(
    Session session, {
    required ConversationTurn turn,
    required Map<String, dynamic> skillData,
    required String credentialId,
    String? credentialDefinitionId,
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
    final definitionId = credentialDefinitionId?.trim().isNotEmpty == true
        ? credentialDefinitionId
        : _jsonMap(skill.data)['credentialDefinitionId'];
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
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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
  }) =>
      (input) => CancelableOperation<UrlResponse>.fromFuture(
        runBoundedServerSkillHttpRequest(
          timeout: input.timeout,
          run: (registerClient) async {
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
              onClient: registerClient,
            );
          },
        ),
      );

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
      final response = await request.close().timeout(input.timeout);
      rejectServerSkillRedirect(response.isRedirect);
      final headers = <String, List<String>>{};
      response.headers.forEach((name, values) => headers[name] = values);
      return UrlResponse(
        statusCode: response.statusCode,
        body: await _readResponse(response, idleTimeout: input.timeout),
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

  Future<String> _readResponse(
    HttpClientResponse response, {
    Duration? idleTimeout,
  }) {
    final timeout = idleTimeout;
    if (timeout == null) return readBoundedServerSkillResponse(response);
    return readBoundedServerSkillResponse(response, idleTimeout: timeout);
  }

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

class const ServerToolNotConfiguredException() implements Exception;
