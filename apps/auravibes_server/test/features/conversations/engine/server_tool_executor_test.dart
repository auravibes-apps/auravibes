import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:test/test.dart';

void main() {
  const skills = [
    {
      'id': 'skill-1',
      'slug': 'research',
      'title': 'Research',
      'content': 'Use primary sources.',
      'isEnabled': true,
    },
  ];
  final descriptor = AgentResolvedToolName.skillTemplate(
    tableId: 'tool-1',
    skillSlug: 'research',
    toolIdentifier: 'search',
  );
  final tools = [
    ServerResolvedTool(
      descriptor: descriptor,
      spec: ToolSpec(
        name: descriptor.fullName,
        description: 'Search sources.',
        inputJsonSchema: const {
          'type': 'object',
          'properties': {
            'limit': {'type': 'integer'},
          },
          'required': ['limit'],
          'additionalProperties': false,
        },
      ),
    ),
  ];

  Future<SkillCommandTarget> command({
    String skill = 'research',
    String tool = 'search',
    Object? limit = 1,
    String? revision,
  }) async {
    final manifest = await buildCloudSkillManifest(
      slug: 'research',
      userSkills: skills,
      tools: tools,
    );
    return SkillCommandTarget.fromArguments({
      'skill': skill,
      'tool': tool,
      'args': {'limit': limit},
      'revision': revision ?? manifest!.revision,
    });
  }

  test('resolves current target and validates its schema', () async {
    expect(
      await resolveCloudSkillCommandTarget(
        command: await command(),
        userSkills: skills,
        tools: tools,
      ),
      same(tools.single),
    );
  });

  test('rejects unloaded target', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(),
        userSkills: skills,
        tools: const [],
      ),
      throwsStateError,
    );
  });

  test('rejects stale manifest revision', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(revision: 'stale'),
        userSkills: skills,
        tools: tools,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('current skill catalog to refresh'),
        ),
      ),
    );
  });

  test('rejects invalid target arguments', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(limit: 'wrong'),
        userSkills: skills,
        tools: tools,
      ),
      throwsFormatException,
    );
  });

  test('cloud skill controls require confirmation', () {
    expect(
      defaultCloudToolPermission(
        AgentResolvedToolName.skillControl(
          toolIdentifier: listSkillCredentialsToolName,
        ),
      ),
      AgentToolPermissionResult.needsConfirmation,
    );
    expect(
      defaultCloudToolPermission(
        AgentResolvedToolName.skillControl(
          toolIdentifier: activateSkillToolName,
        ),
      ),
      AgentToolPermissionResult.needsConfirmation,
    );
  });

  test('cloud resolves known Connector contract without discovery', () {
    final connector = serviceSkillDefinitions.singleWhere(
      (candidate) => candidate.identifier == 'duckduckgo',
    );
    final tool = connector.tools.single;
    final toolId = connectorToolId(connector, tool);
    final revision = connectorToolRevision(connector, tool);

    final resolved = resolveCloudConnectorTool(
      toolId: toolId,
      revision: revision,
      arguments: const {'query': 'weather'},
    );
    expect(resolved.connector, same(connector));
    expect(resolved.tool, same(tool));
    expect(
      () => resolveCloudConnectorTool(
        toolId: toolId,
        revision: 'stale',
        arguments: const {'query': 'weather'},
      ),
      throwsA(
        isA<AgentToolExecutionFailure>().having(
          (failure) => failure.responseRaw,
          'stale contract failure',
          contains('"code":"stale_contract"'),
        ),
      ),
    );
    expect(
      () => resolveCloudConnectorTool(
        toolId: toolId,
        arguments: const {'query': 5},
      ),
      throwsA(
        isA<AgentToolExecutionFailure>().having(
          (failure) => failure.responseRaw,
          'invalid arguments failure',
          contains('"code":"invalid_tool_arguments"'),
        ),
      ),
    );
    expect(
      () => resolveCloudConnectorTool(
        toolId: 'connector/unknown/tool',
        arguments: const {},
      ),
      throwsA(
        isA<AgentToolExecutionFailure>().having(
          (failure) => failure.responseRaw,
          'unknown tool failure',
          contains('"code":"unknown_tool"'),
        ),
      ),
    );
  });

  test('cloud Connector discovery lists current tools without secrets', () {
    final connector = serviceSkillDefinitions.singleWhere(
      (candidate) => candidate.identifier == 'anthropic',
    );
    final connections = [
      {
        'id': 'anthropic-connection',
        'name': 'Work account',
        'kind': 'appSkillCredential',
        'serviceId': connector.identifier,
        'isEnabled': true,
        'hasSecret': true,
        'apiKey': 'must-not-leak',
      },
      {
        'id': 'disabled-connection',
        'name': 'Disabled account',
        'kind': 'appSkillCredential',
        'serviceId': connector.identifier,
        'isEnabled': false,
        'hasSecret': true,
      },
      {
        'id': 'missing-secret',
        'name': 'Incomplete account',
        'kind': 'appSkillCredential',
        'serviceId': connector.identifier,
        'isEnabled': true,
        'hasSecret': false,
      },
    ];

    final toolRecords = cloudConnectorToolRecords(
      connectors: [connector],
      serviceConnections: connections,
    );
    final connectionRecords = cloudConnectorConnectionRecords(
      connectors: [connector],
      serviceConnections: connections,
    );
    final firstTool = connector.tools
        .where((tool) => tool.urlTemplate != null)
        .first;
    final firstToolRecord = toolRecords.singleWhere(
      (record) => record['toolId'] == connectorToolId(connector, firstTool),
    );

    expect(toolRecords, isNotEmpty);
    expect(toolRecords.first['toolId'], startsWith('connector/anthropic/'));
    expect(firstToolRecord['inputSchema'], firstTool.inputJsonSchema);
    expect(
      firstToolRecord['revision'],
      connectorToolRevision(connector, firstTool),
    );
    expect(
      toolRecords.first['connections'],
      [
        {'id': 'service:anthropic-connection', 'name': 'Work account'},
      ],
    );
    expect(
      connectionRecords,
      {
        'connections': [
          {
            'id': 'service:anthropic-connection',
            'name': 'Work account',
            'connectorIds': ['anthropic'],
          },
        ],
      },
    );
    expect(jsonEncode(toolRecords), isNot(contains('must-not-leak')));
    expect(jsonEncode(connectionRecords), isNot(contains('must-not-leak')));
  });

  test(
    'cloud Connector execution selects only current matching Connection',
    () {
      final connections = [
        {'id': 'service:first', 'name': 'First'},
        {'id': 'service:second', 'name': 'Second'},
      ];

      expect(
        resolveCloudConnectorConnectionId(
          connections: const [],
          requiresConnection: false,
        ),
        isNull,
      );
      expect(
        () => resolveCloudConnectorConnectionId(
          connections: const [],
          requiresConnection: true,
        ),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (failure) => failure.responseRaw,
            'recoverable response',
            contains('"recoverable":true'),
          ),
        ),
      );
      expect(
        resolveCloudConnectorConnectionId(
          connections: [connections.first],
          requiresConnection: true,
        ),
        'service:first',
      );
      expect(
        resolveCloudConnectorConnectionId(
          connections: connections,
          requiresConnection: true,
          requestedConnectionId: 'service:second',
        ),
        'service:second',
      );
      expect(
        () => resolveCloudConnectorConnectionId(
          connections: connections,
          requiresConnection: true,
        ),
        throwsA(isA<AgentToolExecutionFailure>()),
      );
      expect(
        () => resolveCloudConnectorConnectionId(
          connections: connections,
          requiresConnection: true,
          requestedConnectionId: 'service:stale',
        ),
        throwsA(isA<AgentToolExecutionFailure>()),
      );
    },
  );

  test('compiled DuckDuckGo template uses injected HTTP client', () async {
    UrlRequest? captured;
    final result = await runCompiledServiceSkillTool(
      skillSlug: 'duckduckgo',
      toolSlug: 'search',
      input: const {'query': 'aura vibes'},
      httpClient: (request) {
        captured = request;
        return CancelableOperation.fromValue(
          UrlResponse(
            statusCode: HttpStatus.ok,
            body: '<html></html>',
            headers: const {},
            elapsed: Duration.zero,
          ),
        );
      },
    );

    expect(captured?.url, 'https://html.duckduckgo.com/html/');
    expect(captured?.method, UrlRequestMethod.post);
    expect(result, '<html></html>');
  });

  test('dynamic skill cannot supply a compiled callback', () async {
    expect(
      () => runCompiledServiceSkillTool(
        skillSlug: 'user-skill',
        toolSlug: 'search',
        input: const {},
        httpClient: (_) => throw StateError('must not run'),
      ),
      throwsA(isA<ServerToolNotConfiguredException>()),
    );
  });

  test(
    'server callback target rejects private, loopback, and HTTP credentials',
    () async {
      Future<List<InternetAddress>> privateLookup(String _) async => [
        InternetAddress('10.0.0.1'),
      ];
      Future<List<InternetAddress>> loopbackLookup(String _) async => [
        InternetAddress.loopbackIPv4,
      ];

      await expectLater(
        validateServerSkillRequestTarget(
          const UrlRequest(url: 'https://example.com'),
          requireHttps: false,
          lookup: privateLookup,
        ),
        throwsFormatException,
      );
      await expectLater(
        validateServerSkillRequestTarget(
          const UrlRequest(url: 'https://example.com'),
          requireHttps: false,
          lookup: loopbackLookup,
        ),
        throwsFormatException,
      );
      await expectLater(
        validateServerSkillRequestTarget(
          const UrlRequest(url: 'http://example.com'),
          requireHttps: true,
          lookup: (_) async => [InternetAddress('8.8.8.8')],
        ),
        throwsFormatException,
      );
    },
  );

  test('server callback bounds stalled DNS lookups', () async {
    final lookup = Completer<List<InternetAddress>>();

    await expectLater(
      validateServerSkillRequestTarget(
        const UrlRequest(url: 'https://example.com'),
        requireHttps: true,
        lookup: (_) => lookup.future,
        dnsTimeout: const Duration(milliseconds: 1),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('server callback target accepts resolved public address', () async {
    final target = await validateServerSkillRequestTarget(
      const UrlRequest(url: 'https://example.com/search'),
      requireHttps: true,
      lookup: (_) async => [InternetAddress('8.8.8.8')],
    );

    expect(target.uri.host, 'example.com');
    expect(target.addresses.single.address, '8.8.8.8');
  });

  test('server callback rejects redirects and oversized responses', () async {
    expect(
      () => rejectServerSkillRedirect(true),
      throwsA(isA<HttpException>()),
    );
    await expectLater(
      readBoundedServerSkillResponse(
        Stream.value([1, 2, 3]),
        maxBytes: 2,
      ),
      throwsFormatException,
    );
  });

  test('server callback bounds stalled response bodies', () async {
    final response = StreamController<List<int>>();
    addTearDown(response.close);

    await expectLater(
      readBoundedServerSkillResponse(
        response.stream,
        idleTimeout: const Duration(milliseconds: 1),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('server callback cancellation closes request', () async {
    var closed = false;
    await closeOnServerSkillCancellation(
      isCancelled: () async => true,
      close: () => closed = true,
      done: Completer<void>().future,
      pollInterval: Duration.zero,
    );

    expect(closed, isTrue);
  });

  test(
    'production HTTP adapter timeout force-closes registered client',
    () async {
      final client = HttpClient();
      final never = Completer<void>();
      HttpClient? closedClient;

      await expectLater(
        runBoundedServerSkillHttpRequest<void>(
          timeout: Duration.zero,
          run: (registerClient) {
            registerClient(client);
            return never.future;
          },
          closeClient: (client) => closedClient = client,
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(closedClient, same(client));
      client.close(force: true);
    },
  );
}
