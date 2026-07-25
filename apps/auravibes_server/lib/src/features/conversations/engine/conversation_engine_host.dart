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

class ConversationEngineResult {
  const ConversationEngineResult({
    required this.content,
    required this.finishReason,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    this.awaitingApproval = false,
  });

  final String content;
  final String finishReason;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final bool awaitingApproval;
}

class ConversationCompactionResult {
  const ConversationCompactionResult({
    required this.summary,
    required this.range,
  });

  final String summary;
  final AgentCompactionRangeSelected range;
}

String providerCredential(String providerId, String secret) {
  if (providerId != 'openai-codex') return secret;
  final value = jsonDecode(secret);
  if (value is! Map || value['access_token'] is! String) {
    throw const ConversationEngineConfigurationException('provider_secret');
  }
  return value['access_token']! as String;
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

final class ServerConversationEngineHost implements ConversationEngineHost {
  const ServerConversationEngineHost({
    this.cancellationProbe = const DatabaseConversationCancellationProbe(),
    this.admissionGate = const DatabaseConversationAdmissionGate(),
    this.attachmentReader = const ServerConversationAttachmentReader(),
    this.toolRuntime,
  });

  final ConversationCancellationProbe cancellationProbe;
  final ConversationAdmissionGate admissionGate;
  final ConversationAttachmentReader attachmentReader;
  final ServerToolRuntime? toolRuntime;

  static const _compactionPrompt =
      'Create a comprehensive but concise summary of this conversation. '
      'Preserve user goals, constraints, decisions, current progress, technical '
      'references, resolved errors, pending tasks, and relevant tool results. '
      'Do not invent facts, expose sensitive tool output, or mark unresolved '
      'work complete.';

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
    final requestMessages = await _requestMessages(session, job, messages);
    requestMessages.insertAll(0, await _agentContextMessages(session, job));
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
    final tools = await runtime.loadTools(
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
    if (resumedCalls.any((call) => call.status == 'approved')) {
      requestMessages.add({
        'role': 'assistant',
        'content': null,
        'tool_calls': resumedCalls.map(_persistedProviderToolCall).toList(),
      });
      for (final call in resumedCalls) {
        await runtime.handle(
          session,
          turn: turn,
          messageId: turn.assistantMessageId!,
          request: ServerToolRequest(
            id: call.stableId,
            name: call.name,
            arguments: _jsonObject(call.argumentsJson),
          ),
          tools: tools,
        );
      }
      final completedCalls = await ConversationToolCall.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(job.workspaceId) &
            table.turnId.equals(turn.id),
        orderBy: (table) => table.id,
      );
      for (final call in completedCalls) {
        requestMessages.add({
          'role': 'tool',
          'tool_call_id': call.stableId,
          'content': call.resultJson ?? call.status,
        });
      }
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
          (body) => _transport(
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
      requestMessages.add(_assistantToolMessage(providerResponse.raw));
      var paused = false;
      for (final request in requests) {
        final disposition = await runtime.handle(
          session,
          turn: turn,
          messageId: turn.assistantMessageId!,
          request: request,
          tools: tools,
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
      for (final request in requests) {
        final call = calls.where((item) => item.stableId == request.id).first;
        requestMessages.add({
          'role': 'tool',
          'tool_call_id': request.id,
          'content': call.resultJson ?? call.status,
        });
      }
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
      (message) => message.status != 'queued',
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

  Future<List<Map<String, dynamic>>> _agentContextMessages(
    Session session,
    ConversationJob job,
  ) async {
    final conversation = await Conversation.db.findById(
      session,
      job.conversationId,
    );
    final agentId = conversation?.agentId;
    if (conversation == null || agentId == null) return const [];
    final agent = await _activeResource(
      session,
      job.workspaceId,
      WorkspaceResourceKind.agent,
      agentId,
    );
    if (agent == null) return const [];
    final agentData = _jsonObject(agent.data);
    final visibility = agentData['visibility'];
    final isChild = conversation.parentConversationStableId != null;
    if (agentData['isEnabled'] == false ||
        (isChild && visibility == 'chatSelector') ||
        (!isChild && visibility == 'subAgentList')) {
      return const [];
    }
    final associations = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.agentAssociation) &
          table.deletedAt.equals(null),
    );
    final skills = <AgentSkill>[];
    for (final association in associations) {
      final data = _jsonObject(association.data);
      if (data['agentId'] != agentId || data['skillId'] is! String) continue;
      final skill = await _activeResource(
        session,
        job.workspaceId,
        WorkspaceResourceKind.skill,
        data['skillId']! as String,
      );
      if (skill == null) continue;
      final skillData = _jsonObject(skill.data);
      if (skillData['isEnabled'] == false ||
          skillData['title'] is! String ||
          skillData['content'] is! String) {
        continue;
      }
      skills.add(
        AgentSkill(
          title: skillData['title']! as String,
          content: skillData['content']! as String,
        ),
      );
    }
    return [
      if (agentData['content'] case final String content)
        {'role': 'system', 'content': content},
      for (final message in const BuildSkillContextMessages().call(skills))
        {'role': message.role.name, 'content': message.content},
    ];
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
          {'role': 'system', 'content': _compactionPrompt},
          for (final message in compactable)
            {'role': message.role, 'content': message.content},
          {
            'role': 'user',
            'content': 'Summarize the conversation above.',
          },
        ],
        'stream': false,
      },
    );
    final summary =
        response.message?.content
            .where((part) => part.isText)
            .map((part) => part.text ?? '')
            .join()
            .trim() ??
        '';
    if (summary.isEmpty) {
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
      lookup: InternetAddress.lookup,
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

Map<String, Object?> _persistedProviderToolCall(ConversationToolCall call) => {
  'id': call.stableId,
  'type': 'function',
  'function': {'name': call.name, 'arguments': call.argumentsJson},
};

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

final class ConversationEngineConfigurationException implements Exception {
  const ConversationEngineConfigurationException(this.code);
  final String code;
}

Map<String, dynamic> _jsonObject(String source) {
  final value = jsonDecode(source);
  if (value is! Map<String, dynamic>) {
    throw const ConversationEngineConfigurationException('resource_data');
  }
  return value;
}

class _ProviderConfig {
  const _ProviderConfig({
    required this.providerId,
    required this.modelId,
    required this.uri,
    required this.address,
    required this.headers,
  });
  final String providerId;
  final String modelId;
  final Uri uri;
  final InternetAddress address;
  final Map<String, String> headers;
}
