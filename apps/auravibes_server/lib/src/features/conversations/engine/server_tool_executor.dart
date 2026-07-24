import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../mcp_servers/mcp_server_policy.dart';
import '../../workspace_state/workspace_secret_cipher.dart';
import '../../workspace_state/workspace_secret_resolver.dart';
import '../repositories/conversation_repository.dart' as conversation_repo;
import '../usecases/conversation_usecases.dart';
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
    data['serviceId'] == skillIdentifier;

class ServerToolExecutorService {
  const ServerToolExecutorService();

  Future<Object?> call(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    Map<String, dynamic> arguments,
  ) => switch (tool.descriptor.kind) {
    AgentResolvedToolKind.mcp => _runMcp(session, turn, tool, arguments),
    AgentResolvedToolKind.skillTemplate => _runSkill(
      session,
      turn,
      tool,
      arguments,
    ),
    AgentResolvedToolKind.skillNative
        when tool.descriptor.skillSlug == agentsSkillSlug =>
      _runSubAgentTool(session, turn, tool, arguments),
    AgentResolvedToolKind.skillNative => _runNativeSkill(
      session,
      turn,
      tool,
      arguments,
    ),
    _ => throw const ServerToolNotConfiguredException(),
  };

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
    final template = nativeTool?.urlTemplate;
    final credentialId = arguments['credentialId'];
    if (skill == null || nativeTool == null || template == null) {
      throw const ServerToolNotConfiguredException();
    }
    var credentials = const <String, String>{};
    if (nativeTool.requiresCredential) {
      if (credentialId is! String || credentialId.isEmpty) {
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
    final request = const ResolveSkillUrlTemplate()(
      template: template.template,
      inputs: arguments,
      credentials: credentials,
      inputDefinitions: template.inputs,
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
    final response = await _request(uri, addresses, request);
    return const UrlContentTransformer()
        .transform(response, requestedFormat: request.format)
        .body;
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
    final child = await useCases.create(
      session,
      userId: turn.initiatorUserId,
      request: CreateConversationRequest(
        workspaceId: turn.workspaceId,
        requestId: '$id:create',
        conversationId: id,
        title: title.trim(),
        isPinned: false,
        modelId: parent.modelId,
        agentId: agentId as String?,
        parentConversationId: parent.stableId,
      ),
    );
    final started = await useCases.startTurn(
      session,
      userId: turn.initiatorUserId,
      request: StartTurnRequest(
        workspaceId: turn.workspaceId,
        requestId: '$id:turn',
        conversationId: child.id,
        expectedConversationRevision: child.revision,
        clientMessageId: '$id:user',
        content: prompt.trim(),
        attachmentIds: const [],
        modelSelectionId: child.modelId,
        agentId: child.agentId,
      ),
    );
    return {
      'conversationId': child.id,
      'turnId': started.turnId,
      'status': started.status,
      if (child.agentId != null) 'agentId': child.agentId,
    };
  }

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
    final result = await _postJson(
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
    final response = await _request(uri, addresses, request);
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
    Uri uri,
    List<InternetAddress> addresses,
    Map<String, Object?> body, {
    String? bearerToken,
  }) async {
    final client = _client(addresses);
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
    } finally {
      client.close(force: true);
    }
  }

  Future<UrlResponse> _request(
    Uri uri,
    List<InternetAddress> addresses,
    UrlRequest input,
  ) async {
    final client = _client(addresses);
    final stopwatch = Stopwatch()..start();
    try {
      final request = await client.openUrl(input.method.value, uri);
      request.followRedirects = false;
      input.headers.forEach(request.headers.set);
      if (input.body != null) request.write(input.body);
      final response = await request.close();
      if (response.isRedirect) throw const HttpException('Redirect rejected.');
      final headers = <String, List<String>>{};
      response.headers.forEach((name, values) => headers[name] = values);
      return UrlResponse(
        statusCode: response.statusCode,
        body: await _readResponse(response),
        headers: headers,
        elapsed: stopwatch.elapsed,
      );
    } finally {
      client.close(force: true);
    }
  }

  HttpClient _client(List<InternetAddress> addresses) => HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..connectionFactory = (target, proxyHost, proxyPort) =>
        Socket.startConnect(addresses.first, target.port);

  Future<String> _readResponse(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('Tool response is too large.');
      }
    }
    return utf8.decode(bytes);
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

class ServerToolNotConfiguredException implements Exception {
  const ServerToolNotConfiguredException();
}
