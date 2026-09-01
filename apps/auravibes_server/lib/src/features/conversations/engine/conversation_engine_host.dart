import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/plugin.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../model_connections/domain/virtual_workspace_model_selection.dart';
import '../../model_connections/usecases/model_connection_usecases.dart';
import '../../workspace_state/workspace_secret_cipher.dart';
import '../../workspace_state/workspace_secret_resolver.dart';
import 'conversation_host_effects.dart';
import 'server_tool_executor.dart';
import 'server_tool_runtime.dart';

class const ConversationEngineResult({
  required final String content,
  required final String finishReason,
  required final int inputTokens,
  required final int outputTokens,
  required final int totalTokens,
  final bool awaitingApproval = false,
});

class const ConversationCompactionResult({
  required final String summary,
  required final AgentCompactionRangeSelected range,
});

typedef ConversationProviderTransport =
    Future<ProviderTransportResponse> Function(Map<String, dynamic> body);

typedef ConversationHostLookup = Future<List<InternetAddress>> Function(
  String host,
);

String providerCredential(String providerId, String secret) {
  if (providerId != 'openai-codex') return secret;
  final value = jsonDecode(secret);
  if (value is! Map || value['access_token'] is! String) {
    throw const ConversationEngineConfigurationException('provider_secret');
  }
  return value['access_token']! as String;
}

List<Map<String, dynamic>> buildCloudSkillContextMessages({
  String? agentContent,
  required Iterable<AgentSkill> conversationSkills,
  required Iterable<AgentSkill> agentSkills,
}) => const BuildSkillContextMessages()
    .compose(
      agentContent: agentContent,
      conversationSkills: conversationSkills,
      agentSkills: agentSkills,
    )
    .map((message) => {'role': message.role.name, 'content': message.content})
    .toList(growable: false);

List<Map<String, dynamic>> cloudRequestMessagesWithToolExchanges({
  required Iterable<Map<String, dynamic>> baseMessages,
  required Iterable<Map<String, dynamic>> toolExchanges,
}) => composeProviderRequestMessages(
  baseMessages: baseMessages,
  toolExchanges: toolExchanges,
).map((message) => Map<String, dynamic>.from(message)).toList(growable: false);

const _providerToolBatchesMetadataKey = 'providerToolBatches';

Future<void> persistProviderToolBatch(
  Session session, {
  required int assistantMessageId,
  required Map<String, dynamic> assistantMessage,
  required Iterable<ServerToolRequest> requests,
}) => session.db.transaction((transaction) async {
  final assistant = await ConversationMessage.db.findById(
    session,
    assistantMessageId,
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
  if (assistant == null) {
    throw const ConversationEngineConfigurationException('assistant_message');
  }
  final metadata = assistant.metadataJson == null
      ? <String, dynamic>{}
      : _jsonObject(assistant.metadataJson!);
  final batches = List<dynamic>.from(
    metadata[_providerToolBatchesMetadataKey] as List? ?? const [],
  );
  batches.add({
    'assistant': assistantMessage,
    'toolCallIds': requests.map((request) => request.id).toList(),
  });
  metadata[_providerToolBatchesMetadataKey] = batches;
  await ConversationMessage.db.updateRow(
    session,
    assistant.copyWith(
      metadataJson: jsonEncode(metadata),
      revision: assistant.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    ),
    transaction: transaction,
  );
});

List<Map<String, dynamic>> persistedProviderToolExchanges({
  required Iterable<ConversationMessage> messages,
  required Iterable<ConversationToolCall> calls,
}) {
  final callsById = {
    for (final call in calls.where((call) => call.status != 'running'))
      call.stableId: call,
  };
  final replayedCallIds = <String>{};
  final exchanges = <Map<String, dynamic>>[];
  for (final message in messages) {
    if (message.metadataJson == null) continue;
    final batches = _jsonObject(
      message.metadataJson!,
    )[_providerToolBatchesMetadataKey];
    if (batches is! List) continue;
    for (final batch in batches.whereType<Map>()) {
      final assistant = batch['assistant'];
      final callIds = batch['toolCallIds'];
      if (assistant is! Map || callIds is! List) continue;
      final batchCalls = callIds
          .whereType<String>()
          .map(callsById.remove)
          .whereType<ConversationToolCall>()
          .toList(growable: false);
      if (batchCalls.isEmpty) continue;
      replayedCallIds.addAll(batchCalls.map((call) => call.stableId));
      exchanges.addAll(
        providerToolExchangeMessages(
          [
            for (final call in batchCalls)
              ProviderToolCallRecord(
                id: call.stableId,
                name: call.name,
                arguments: Map<String, Object?>.from(
                  jsonDecode(call.argumentsJson) as Map,
                ),
              ),
          ],
          assistantContent: assistant['content'] as String?,
          resultsByCallId: {
            for (final call in batchCalls)
              call.stableId: call.resultJson ?? call.status,
          },
        ).map((message) => Map<String, dynamic>.from(message)),
      );
    }
  }
  final unbatchedCalls = calls
      .where(
        (call) =>
            call.status != 'running' &&
            !replayedCallIds.contains(call.stableId),
      )
      .toList(growable: false);
  if (unbatchedCalls.isNotEmpty) {
    exchanges.addAll(
      providerToolExchangeMessages(
        [
          for (final call in unbatchedCalls)
            ProviderToolCallRecord(
              id: call.stableId,
              name: call.name,
              arguments: Map<String, Object?>.from(
                jsonDecode(call.argumentsJson) as Map,
              ),
            ),
        ],
        resultsByCallId: {
          for (final call in unbatchedCalls)
            call.stableId: call.resultJson ?? call.status,
        },
      ).map((message) => Map<String, dynamic>.from(message)),
    );
  }
  return exchanges;
}

List<AgentSkill> cloudAppSkillsForIds(Iterable<String> skillIds) {
  final appSkills = <AgentSkill>[];
  for (final skillId in skillIds) {
    if (skillId == agentsSkillSlug) {
      appSkills.add(
        const AgentSkill(
          title: agentsSkillTitle,
          content: agentsSkillContent,
          identity: agentsSkillSlug,
        ),
      );
      continue;
    }
    for (final definition in serviceSkillDefinitions) {
      if (definition.identifier == skillId || definition.slug == skillId) {
        appSkills.add(
          AgentSkill(
            title: definition.title,
            content: definition.content,
            identity: definition.identifier,
          ),
        );
        break;
      }
    }
  }
  return appSkills;
}

abstract interface class ConversationEngineHost {
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  });

  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  });
}

final class const ServerConversationEngineHost({
  final ConversationCancellationProbe cancellationProbe =
      const DatabaseConversationCancellationProbe(),
  final ConversationAdmissionGate admissionGate =
      const DatabaseConversationAdmissionGate(),
  final ConversationAttachmentReader attachmentReader =
      const ServerConversationAttachmentReader(),
  final ServerToolRuntime? toolRuntime,
  final ConversationProviderTransport? providerTransport,
  final ConversationHostLookup lookup = InternetAddress.lookup,
}) implements ConversationEngineHost {
  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    if (await cancellationProbe.isCancelled(session, turn.id!)) {
      throw const ConversationCancelledException();
    }
    final config = await _loadConfig(session, job, messages);
    var requestMessages = await _requestMessages(session, job, messages);
    requestMessages.insertAll(0, await _agentContextMessages(session, job));
    final toolExchanges = <Map<String, dynamic>>[];
    final codec = ChatCompletionsCodec(
      errorLabel: config.providerId,
      customize: (modelName, _) => (model: modelName, extraBody: const {}),
    );
    final response = ConversationResponseAccumulator(publisher: liveTurns);
    final runtime =
        toolRuntime ??
        ServerToolRuntime(executor: const ServerToolExecutorService().call);
    final conversation = await Conversation.db.findById(
      session,
      job.conversationId,
    );
    if (conversation == null) {
      throw const ConversationEngineConfigurationException('conversation');
    }
    var tools = await runtime.loadTools(
      session,
      workspaceId: job.workspaceId,
      conversationStableId: conversation.stableId,
    );
    final resumedCalls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.turnId.equals(turn.id),
      orderBy: (table) => table.id,
    );
    final replayableCalls = resumedCalls
        .where(
          (call) => call.status == 'approved' || call.status == 'running',
        )
        .toList(growable: false);
    if (resumedCalls.isNotEmpty) {
      for (final call in replayableCalls) {
        final disposition = await runtime.handle(
          session,
          turn: turn,
          messageId: turn.assistantMessageId!,
          request: ServerToolRequest(
            id: call.stableId,
            name: call.name,
            arguments: _jsonObject(call.argumentsJson),
          ),
        );
        if (disposition == ServerToolDisposition.awaitingApproval) {
          return const ConversationEngineResult(
            content: '',
            finishReason: 'awaiting_approval',
            inputTokens: 0,
            outputTokens: 0,
            totalTokens: 0,
            awaitingApproval: true,
          );
        }
      }
      final completedCalls = await ConversationToolCall.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(job.workspaceId) &
            table.turnId.equals(turn.id),
        orderBy: (table) => table.id,
      );
      final pendingCalls = completedCalls
          .where((call) => call.status == 'pending')
          .toList(growable: false);
      if (pendingCalls.isNotEmpty) {
        return const ConversationEngineResult(
          content: '',
          finishReason: 'awaiting_approval',
          inputTokens: 0,
          outputTokens: 0,
          totalTokens: 0,
          awaitingApproval: true,
        );
      }

      if (completedCalls.any((call) => call.status == 'running')) {
        throw const ConversationEngineConfigurationException(
          'tool_execution_in_progress',
        );
      }
      final resolvedCalls = completedCalls
          .where((call) => call.status != 'pending' && call.status != 'running')
          .toList(growable: false);
      final persistedMessages = await ConversationMessage.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(job.workspaceId) &
            table.conversationId.equals(job.conversationId),
        orderBy: (table) => table.id,
      );
      toolExchanges.addAll(
        persistedProviderToolExchanges(
          messages: persistedMessages,
          calls: resolvedCalls,
        ),
      );
      requestMessages = await _refreshedRequestMessages(
        session,
        job,
        messages,
        toolExchanges,
      );
      tools = await runtime.loadTools(
        session,
        workspaceId: job.workspaceId,
        conversationStableId: conversation.stableId,
      );
    }
    ModelResponse providerResponse;
    for (var iteration = 0; ; iteration++) {
      if (iteration >= 20) {
        throw const ConversationEngineConfigurationException('tool_loop_limit');
      }
      providerResponse = await admissionGate.run(
        session,
        job: job,
        providerId: config.providerId,
        body: (admissionLost) => codec.stream(
          (body) =>
              providerTransport?.call(body) ??
              _transport(
                config,
                body,
                session: session,
                turnId: turn.id!,
                leaseLost: _first(leaseLost, admissionLost),
              ),
          {
            'model': config.modelId,
            'messages': requestMessages,
            if (tools.isNotEmpty)
              'tools': tools.map(_providerTool).toList(growable: false),
            'stream': true,
            'stream_options': {'include_usage': true},
          },
          (chunk) {
            response.addText(
              chunk.content
                  .where((part) => part.isText)
                  .map((part) => part.text ?? '')
                  .join(),
            );
          },
        ),
      );
      final requests = _toolRequests(providerResponse.raw);
      if (requests.isEmpty) break;
      final assistantToolMessage = _assistantToolMessage(providerResponse.raw);
      await persistProviderToolBatch(
        session,
        assistantMessageId: turn.assistantMessageId!,
        assistantMessage: assistantToolMessage,
        requests: requests,
      );

      var paused = false;
      for (final request in requests) {
        final disposition = await runtime.handle(
          session,
          turn: turn,
          messageId: turn.assistantMessageId!,
          request: request,
        );
        paused |= disposition == ServerToolDisposition.awaitingApproval;
      }
      if (paused) {
        await response.close();
        return const ConversationEngineResult(
          content: '',
          finishReason: 'stop',
          inputTokens: 0,
          outputTokens: 0,
          totalTokens: 0,
          awaitingApproval: true,
        );
      }
      final calls = await ConversationToolCall.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(job.workspaceId) &
            table.turnId.equals(turn.id),
      );
      final toolResults = <Map<String, dynamic>>[];
      for (final request in requests) {
        final call = calls.where((item) => item.stableId == request.id).first;
        toolResults.add({
          'role': 'tool',
          'tool_call_id': request.id,
          'content': call.resultJson ?? call.status,
        });
      }
      toolExchanges
        ..add(assistantToolMessage)
        ..addAll(toolResults);
      requestMessages = await _refreshedRequestMessages(
        session,
        job,
        messages,
        toolExchanges,
      );
      tools = await runtime.loadTools(
        session,
        workspaceId: job.workspaceId,
        conversationStableId: conversation.stableId,
      );
    }
    await response.close();
    if (await cancellationProbe.isCancelled(session, turn.id!)) {
      throw const ConversationCancelledException();
    }
    final usage = providerResponse.usage;
    return ConversationEngineResult(
      content: response.content,
      finishReason: providerResponse.finishReason.value,
      inputTokens: usage?.inputTokens?.toInt() ?? 0,
      outputTokens: usage?.outputTokens?.toInt() ?? 0,
      totalTokens: usage?.totalTokens?.toInt() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> _requestMessages(
    Session session,
    ConversationJob job,
    List<ConversationMessage> messages,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final message in messages.where(
      (message) =>
          message.status != 'queued' &&
          (message.role != 'assistant' || message.content.isNotEmpty),
    )) {
      final metadata = message.metadataJson == null
          ? const <String, dynamic>{}
          : _jsonObject(message.metadataJson!);
      final attachmentIds =
          (metadata['attachmentIds'] as List?)?.whereType<int>().toList() ??
          const <int>[];
      final attachments = await attachmentReader.read(
        session,
        workspaceId: job.workspaceId,
        objectIds: attachmentIds,
      );
      result.add({
        'role': message.role,
        'content': attachments.isEmpty
            ? message.content
            : [
                {'type': 'text', 'text': message.content},
                for (final attachment in attachments)
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url':
                          'data:${attachment.mimeType};base64,${base64Encode(attachment.bytes)}',
                    },
                  },
              ],
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _refreshedRequestMessages(
    Session session,
    ConversationJob job,
    List<ConversationMessage> messages,
    List<Map<String, dynamic>> toolExchanges,
  ) async {
    final baseMessages = await _requestMessages(session, job, messages);
    baseMessages.insertAll(0, await _agentContextMessages(session, job));
    return cloudRequestMessagesWithToolExchanges(
      baseMessages: baseMessages,
      toolExchanges: toolExchanges,
    );
  }

  Future<List<Map<String, dynamic>>> _agentContextMessages(
    Session session,
    ConversationJob job,
  ) async {
    final conversation = await Conversation.db.findById(
      session,
      job.conversationId,
    );
    if (conversation == null) return const [];
    final selections = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.resourceKind.equals(
            WorkspaceResourceKind.conversationSkillSelection,
          ) &
          table.deletedAt.equals(null),
    );
    final conversationSkillIds = selections
        .map((selection) => _jsonObject(selection.data))
        .where((data) => data['conversationId'] == conversation.stableId)
        .map((data) => data['skillId'])
        .whereType<String>()
        .toSet();
    final agentContext = await _agentContext(
      session,
      job,
      conversation: conversation,
    );
    return buildCloudSkillContextMessages(
      agentContent: agentContext.content,
      conversationSkills: await _skillsForIds(
        session,
        job.workspaceId,
        conversationSkillIds,
        isChildConversation: conversation.parentConversationStableId != null,
      ),
      agentSkills: await _skillsForIds(
        session,
        job.workspaceId,
        agentContext.skillIds,
        isChildConversation: conversation.parentConversationStableId != null,
      ),
    );
  }

  Future<({String? content, Set<String> skillIds})> _agentContext(
    Session session,
    ConversationJob job, {
    required Conversation conversation,
  }) async {
    final agentId = conversation.agentId;
    if (agentId == null) return (content: null, skillIds: <String>{});
    final agent = await _activeResource(
      session,
      job.workspaceId,
      WorkspaceResourceKind.agent,
      agentId,
    );
    if (agent == null) return (content: null, skillIds: <String>{});
    final agentData = _jsonObject(agent.data);
    final visibility = agentData['visibility'];
    final isChild = conversation.parentConversationStableId != null;
    if (agentData['isEnabled'] == false ||
        (isChild && visibility == 'chatSelector') ||
        (!isChild && visibility == 'subAgentList')) {
      return (content: null, skillIds: <String>{});
    }
    final associations = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.agentAssociation) &
          table.deletedAt.equals(null),
    );
    return (
      content: switch (agentData['content']) {
        final String content => content,
        _ => null,
      },
      skillIds: associations
          .map((association) => _jsonObject(association.data))
          .where((data) => data['agentId'] == agentId)
          .map((data) => data['skillId'])
          .whereType<String>()
          .toSet(),
    );
  }

  Future<List<AgentSkill>> _skillsForIds(
    Session session,
    int workspaceId,
    Iterable<String> skillIds, {
    required bool isChildConversation,
  }) async {
    final skills = <AgentSkill>[];
    for (final skillId in skillIds) {
      final skill = await _activeResource(
        session,
        workspaceId,
        WorkspaceResourceKind.skill,
        skillId,
      );
      if (skill == null) continue;
      final data = _jsonObject(skill.data);
      if (data['source'] == 'app' ||
          data['isEnabled'] == false ||
          data['title'] is! String ||
          data['content'] is! String) {
        continue;
      }
      skills.add(
        AgentSkill(
          title: data['title']! as String,
          content: data['content']! as String,
          identity: skillId,
        ),
      );
    }
    final appResources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) & table.deletedAt.equals(null),
    );
    final appSettings = appResources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.skillSetting,
        )
        .map((resource) => _jsonObject(resource.data));
    final serviceConnections = appResources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.serviceConnection,
        )
        .map(
          (resource) => {
            'id': resource.resourceId,
            ..._jsonObject(resource.data),
          },
        );
    final enabledAppSkillIds = skillIds.where((skillId) {
      if (skillId == agentsSkillSlug) {
        return cloudAppSkillEnabled(agentsSkillSlug, appSettings);
      }
      final definition = serviceSkillDefinitions
          .where(
            (candidate) =>
                candidate.identifier == skillId || candidate.slug == skillId,
          )
          .firstOrNull;
      return definition != null &&
          cloudAppSkillEnabled(definition.identifier, appSettings) &&
          cloudServiceSkillReady(definition, serviceConnections);
    });
    skills.addAll(cloudAppSkillsForIds(enabledAppSkillIds));
    final userSkills = appResources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.skill &&
              _jsonObject(resource.data)['source'] != 'app',
        )
        .map(
          (resource) => {
            'id': resource.resourceId,
            ..._jsonObject(resource.data),
          },
        )
        .toList(growable: false);
    final targets = materializeCloudSkillTools(
      selectedSkillIds: skillIds.toSet(),
      userSkills: userSkills,
      templateTools: appResources
          .where(
            (resource) =>
                resource.resourceKind ==
                WorkspaceResourceKind.skillTemplateTool,
          )
          .map(
            (resource) => {
              'id': resource.resourceId,
              ..._jsonObject(resource.data),
            },
          ),
      appSkillSettings: appSettings,
      serviceConnections: serviceConnections,
      isChildConversation: isChildConversation,
    );
    final withManifests = <AgentSkill>[];
    for (final skill in skills) {
      final user = userSkills
          .where((candidate) => candidate['id'] == skill.identity)
          .firstOrNull;
      final app = serviceSkillDefinitions
          .where((candidate) => candidate.identifier == skill.identity)
          .firstOrNull;
      final slug = user?['slug'] as String? ?? app?.slug ?? skill.identity;
      final manifest = slug == null
          ? null
          : await buildCloudSkillManifest(
              slug: slug,
              userSkills: userSkills,
              tools: targets,
            );
      withManifests.add(
        AgentSkill(
          title: skill.title,
          content: skill.content,
          identity: skill.identity,
          manifest: manifest,
        ),
      );
    }
    return withManifests;
  }

  Future<WorkspaceResource?> _activeResource(
    Session session,
    int workspaceId,
    WorkspaceResourceKind kind,
    String id,
  ) => WorkspaceResource.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.resourceKind.equals(kind) &
        table.resourceId.equals(id) &
        table.deletedAt.equals(null),
  );

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) async {
    final range = selectConversationCompactionRange(messages);
    if (range is! AgentCompactionRangeSelected) {
      throw const ConversationEngineConfigurationException(
        'compaction_range',
      );
    }
    final compactableIds = range.messageIds.toSet();
    final compactable = messages
        .where((message) => compactableIds.contains('${message.id}'))
        .toList();
    final config = await _loadConfig(session, job, messages);
    final codec = ChatCompletionsCodec(
      errorLabel: config.providerId,
      customize: (modelName, _) => (model: modelName, extraBody: const {}),
    );
    final response = await codec.complete(
      (body) => _transport(config, body, leaseLost: leaseLost),
      {
        'model': config.modelId,
        'messages': [
          {'role': 'system', 'content': conversationCompactionSystemPrompt},
          for (final message in compactable)
            {'role': message.role, 'content': message.content},
          {
            'role': 'user',
            'content': conversationCompactionRequestPrompt,
          },
        ],
        'stream': false,
      },
    );
    final summaryText =
        response.message?.content
            .where((part) => part.isText)
            .map((part) => part.text ?? '')
            .join() ??
        '';
    late final String summary;
    try {
      summary = requireCompactionSummary(summaryText);
    } on FormatException {
      throw const ConversationEngineConfigurationException(
        'compaction_summary',
      );
    }
    return ConversationCompactionResult(summary: summary, range: range);
  }

  Future<_ProviderConfig> _loadConfig(
    Session session,
    ConversationJob job,
    List<ConversationMessage> messages,
  ) async {
    final payload = job.payloadJson;
    final actorUserId = payload == null
        ? null
        : _jsonObject(payload)['actorUserId'];
    if (actorUserId is! String) {
      throw const ConversationEngineConfigurationException('initiator');
    }
    final metadata = messages.reversed
        .where((message) => message.role == 'user')
        .map((message) => message.metadataJson)
        .whereType<String>()
        .map(_jsonObject)
        .firstOrNull;
    final selectionId = metadata?['modelSelectionId'];
    if (selectionId is! String || selectionId.isEmpty) {
      throw const ConversationEngineConfigurationException('model_selection');
    }
    final selection = await const VirtualWorkspaceModelSelectionResolver()
        .resolve(
          session,
          workspaceId: job.workspaceId,
          selectionId: selectionId,
        );
    if (selection == null) {
      throw const ConversationEngineConfigurationException('model');
    }
    final connection = selection.connection;
    final validated = await validatePublicHttpsUri(
      connection.url ?? defaultProviderUrl(connection.providerId),
      lookup: lookup,
    );
    final secret = await const WorkspaceSecretResolver().findForInitiator(
      session,
      workspaceId: job.workspaceId,
      kind: WorkspaceSecretKind.provider,
      initiatorUserId: actorUserId,
      resourceId: connection.connectionId,
      allowWorkspaceFallback: true,
    );
    if (secret == null) {
      throw const ConversationEngineConfigurationException('provider_secret');
    }
    final uri = providerRequestUri(connection.providerId, validated.uri);
    session.log(
      'Conversation provider request: job=${job.id}, '
      'provider=${connection.providerId}, model=${selection.model.modelId}, '
      'uri=$uri.',
    );
    return _ProviderConfig(
      providerId: connection.providerId,
      modelId: selection.model.modelId,
      uri: uri,
      address: validated.address,
      headers: providerHeaders(
        connection.providerId,
        providerCredential(
          connection.providerId,
          await const WorkspaceSecretCipher().decrypt(session, secret),
        ),
      ),
    );
  }

  Future<ProviderTransportResponse> _transport(
    _ProviderConfig config,
    Map<String, dynamic> body, {
    Session? session,
    int? turnId,
    Future<void>? leaseLost,
  }) async {
    final client = pinnedHttpClient(config.address);
    final transportDone = Completer<void>();
    if (session != null && turnId != null) {
      unawaited(
        _closeOnAbort(client, session, turnId, leaseLost, transportDone),
      );
    }
    try {
      final request = await client.postUrl(config.uri);
      config.headers.forEach(request.headers.set);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 90),
      );
      return ProviderTransportResponse(
        statusCode: response.statusCode,
        body: session == null || turnId == null
            ? _closeClientAfter(response, client, transportDone)
            : cancellationCheckedStream(
                _closeClientAfter(response, client, transportDone),
                () => cancellationProbe.isCancelled(session, turnId),
              ),
      );
    } on Object {
      client.close(force: true);
      if (!transportDone.isCompleted) transportDone.complete();
      rethrow;
    }
  }
}

Map<String, Object?> _providerTool(ServerResolvedTool tool) => {
  'type': 'function',
  'function': {
    'name': tool.spec.name,
    'description': tool.spec.description,
    'parameters': tool.spec.inputJsonSchema,
  },
};

Uri providerRequestUri(String providerId, Uri baseUri) {
  final endpoint = switch (providerId) {
    'openai-codex' => 'responses',
    'anthropic' => 'messages',
    _ => 'chat/completions',
  };
  final path = baseUri.path.replaceFirst(RegExp(r'/$'), '');
  return baseUri.replace(path: '$path/$endpoint', query: null);
}

List<ServerToolRequest> _toolRequests(Map<String, dynamic>? raw) {
  final choices = raw?['choices'];
  if (choices is! List || choices.isEmpty || choices.first is! Map) {
    return const [];
  }
  final message = (choices.first as Map)['message'];
  final calls = message is Map ? message['tool_calls'] : null;
  if (calls is! List) return const [];
  return calls
      .map((value) {
        if (value is! Map ||
            value['id'] is! String ||
            value['function'] is! Map) {
          throw const FormatException('Invalid provider tool call.');
        }
        final function = value['function']! as Map;
        final arguments = jsonDecode('${function['arguments'] ?? '{}'}');
        if (function['name'] is! String || arguments is! Map<String, dynamic>) {
          throw const FormatException('Invalid provider tool call.');
        }
        return ServerToolRequest(
          id: value['id']! as String,
          name: function['name']! as String,
          arguments: arguments,
        );
      })
      .toList(growable: false);
}

Map<String, dynamic> _assistantToolMessage(Map<String, dynamic>? raw) {
  final message = ((raw!['choices'] as List).first as Map)['message'] as Map;
  return Map<String, dynamic>.from(message);
}

Stream<List<int>> _closeClientAfter(
  Stream<List<int>> body,
  HttpClient client,
  Completer<void> transportDone,
) async* {
  try {
    yield* body;
  } finally {
    client.close(force: true);
    if (!transportDone.isCompleted) transportDone.complete();
  }
}

Future<void> _first(Future<void>? first, Future<void> second) =>
    first == null ? second : Future.any([first, second]);

Future<void> _closeOnAbort(
  HttpClient client,
  Session session,
  int turnId,
  Future<void>? leaseLost,
  Completer<void> transportDone,
) async {
  final cancellation = _waitForCancellation(session, turnId);
  final winner = await Future.any([
    transportDone.future.then((_) => _AbortSource.transportDone),
    cancellation.then((_) => _AbortSource.durableCancellation),
    ?leaseLost?.then((_) => _AbortSource.leaseLost),
  ]);
  if (transportDone.isCompleted) return;
  session.log(
    'Force-closing provider transport after abort: turn=$turnId, '
    'source=${switch (winner) {
      _AbortSource.durableCancellation => 'durable-cancellation',
      _AbortSource.leaseLost => 'lease-lost',
      _AbortSource.transportDone => 'transport-completed',
    }}.',
    level: LogLevel.info,
  );
  client.close(force: true);
}

enum _AbortSource { transportDone, durableCancellation, leaseLost }

Future<void> _waitForCancellation(Session session, int turnId) async {
  while (!await const DatabaseConversationCancellationProbe().isCancelled(
    session,
    turnId,
  )) {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

AgentCompactionRangeSelection selectConversationCompactionRange(
  List<ConversationMessage> messages,
) => selectAgentCompactionRange(
  AgentContextSnapshot(messages.map(_messageSnapshot).toList()),
);

AgentTranscriptMessageSnapshot _messageSnapshot(ConversationMessage message) {
  final metadata = switch (message.metadataJson) {
    final String source => _jsonObject(source),
    null => const <String, dynamic>{},
  };
  return AgentTranscriptMessageSnapshot(
    id: '${message.id}',
    role: switch (message.role) {
      'user' => AgentTranscriptRole.user,
      'system' => AgentTranscriptRole.system,
      _ => AgentTranscriptRole.model,
    },
    kind: message.kind == 'text'
        ? AgentTranscriptKind.text
        : AgentTranscriptKind.system,
    status: switch (message.status) {
      'sent' => AgentTranscriptStatus.sent,
      'sending' || 'queued' => AgentTranscriptStatus.sending,
      'unfinished' => AgentTranscriptStatus.unfinished,
      _ => AgentTranscriptStatus.error,
    },
    textCharacterCount: message.content.length,
    toolCalls: const [],
    latestCumulativeTokenCount: null,
    isCompactionSummary: metadata['isCompactionSummary'] == true,
    compactedThroughMessageId: switch (message.compactedThroughMessageId) {
      final int id => '$id',
      null => null,
    },
    excludedMessageIds: switch (metadata['compactedMessageIds']) {
      final List<dynamic> ids => ids.map((id) => '$id').toList(),
      _ => const [],
    },
  );
}

final class const ConversationEngineConfigurationException(final String code)
    implements Exception;

Map<String, dynamic> _jsonObject(String source) {
  final value = jsonDecode(source);
  if (value is! Map<String, dynamic>) {
    throw const ConversationEngineConfigurationException('resource_data');
  }
  return value;
}

class const _ProviderConfig({
  required final String providerId,
  required final String modelId,
  required final Uri uri,
  required final InternetAddress address,
  required final Map<String, String> headers,
});
