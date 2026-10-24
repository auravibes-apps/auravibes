import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('cloud skill controls require confirmation', () {
    expect(
      defaultCloudToolPermission(
        AgentResolvedToolName.skillControl(
          toolIdentifier: loadSkillResourceToolName,
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
    final connector = connectorDefinitions.singleWhere(
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
    final connector = connectorDefinitions.singleWhere(
      (candidate) => candidate.identifier == 'anthropic',
    );
    final connections = [
      {
        'id': 'anthropic-connection',
        'name': 'Work account',
        'kind': 'customHttp',
        'serviceId': connector.identifier,
        'isEnabled': true,
        'hasSecret': true,
        'apiKey': 'must-not-leak',
      },
      {
        'id': 'disabled-connection',
        'name': 'Disabled account',
        'kind': 'customHttp',
        'serviceId': connector.identifier,
        'isEnabled': false,
        'hasSecret': true,
      },
      {
        'id': 'missing-secret',
        'name': 'Incomplete account',
        'kind': 'customHttp',
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

  test('cloud Connector discovery includes compatible model Connections', () {
    final connector = connectorDefinitions.singleWhere(
      (candidate) => candidate.identifier == 'openai',
    );
    final modelConnections = [
      {
        'id': 'openai-key',
        'name': 'OpenAI key',
        'providerId': 'openai',
        'hasSecret': true,
        'apiKey': 'must-not-leak',
      },
      {
        'id': 'other-provider',
        'name': 'Other provider',
        'providerId': 'anthropic',
        'hasSecret': true,
      },
      {
        'id': 'missing-secret',
        'name': 'Incomplete OpenAI key',
        'providerId': 'openai',
        'hasSecret': false,
      },
    ];

    final toolRecords = cloudConnectorToolRecords(
      connectors: [connector],
      serviceConnections: const [],
      modelConnections: modelConnections,
    );
    final connectionRecords = cloudConnectorConnectionRecords(
      connectors: [connector],
      serviceConnections: const [],
      modelConnections: modelConnections,
    );

    expect(toolRecords, hasLength(1));
    expect(
      toolRecords.single['connections'],
      [
        {'id': 'model:openai-key', 'name': 'OpenAI key'},
      ],
    );
    expect(
      connectionRecords['connections'],
      [
        {
          'id': 'model:openai-key',
          'name': 'OpenAI key',
          'connectorIds': ['openai'],
        },
      ],
    );
    expect(jsonEncode(toolRecords), isNot(contains('must-not-leak')));
    expect(jsonEncode(connectionRecords), isNot(contains('must-not-leak')));
  });

  test('converts cloud model credentials for Connector execution', () {
    expect(
      cloudModelConnectorCredentialAttributes('openai', 'secret-key'),
      {'apiKey': 'secret-key'},
    );
    final claims = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'https://api.openai.com/auth': {
                'chatgpt_account_id': 'account-1',
              },
            }),
          ),
        )
        .replaceAll('=', '');
    final token = jsonEncode({
      'accessToken': 'access-token',
      'idToken': 'header.$claims.signature',
    });

    expect(
      cloudModelConnectorCredentialAttributes('openai-codex', token),
      {'apiKey': 'access-token', 'accountId': 'account-1'},
    );
  });

  test('cloud discovery hides credentialed tools without a Connection', () {
    final connectors = [
      connectorDefinitions.singleWhere(
        (candidate) => candidate.identifier == 'openai',
      ),
      connectorDefinitions.singleWhere(
        (candidate) => candidate.identifier == 'duckduckgo',
      ),
    ];

    final records = cloudConnectorToolRecords(
      connectors: connectors,
      serviceConnections: const [],
    );

    expect(
      records.map((record) => record['connectorId']),
      isNot(contains('openai')),
    );
    expect(
      records.map((record) => record['toolId']),
      contains('connector/duckduckgo/search'),
    );
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

  test(
    'compiled Connector write uses common executor with injected HTTP client',
    () async {
      UrlRequest? captured;
      final resolved = resolveCloudConnectorTool(
        toolId: 'connector/duckduckgo/search',
        arguments: const {'query': 'aura vibes'},
      );
      final result = await ConnectorRequestExecution(
        connector: resolved.connector,
        tool: resolved.tool,
        inputs: const {'query': 'aura vibes'},
        credentials: const {},
        connectionId: '',
        operationId: 'compiled-write',
        journal: _FirstWriteJournal(),
        executor: ConnectorToolTemplateExecutor(
          const ResolveConnectorRequestTemplate(),
          (request) {
            captured = request;
            return CancelableOperation.fromValue(
              const UrlResponse(
                statusCode: HttpStatus.ok,
                body: '<html></html>',
                headers: {},
                elapsed: Duration.zero,
              ),
            );
          },
        ),
      ).call();
      expect(captured?.url, 'https://html.duckduckgo.com/html/');
      expect(captured?.method, UrlRequestMethod.post);
      expect(result, containsPair('response', '<html></html>'));
      expect(result, containsPair('outcome', 'completed'));
    },
  );

  test('dynamic Connector cannot supply a compiled callback', () {
    expect(
      () => resolveCloudConnectorTool(
        toolId: 'connector/user-skill/search',
        arguments: const {},
      ),
      throwsA(isA<AgentToolExecutionFailure>()),
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

class _FirstWriteJournal implements ConnectorWriteJournal {
  @override
  Future<ConnectorWriteReceipt?> claim(
    String operationId,
    String requestDigest,
  ) => Future.value();

  @override
  Future<void> save(ConnectorWriteReceipt receipt) => Future.value();
}
