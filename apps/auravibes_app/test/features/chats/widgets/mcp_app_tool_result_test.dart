import 'dart:convert';

import 'package:auravibes_app/data/repositories/mcp_servers_repository_contract.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_webview_flutter/in_app_webview_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

const _resourceUri = 'ui://weather/forecast';

void main() {
  test('formats app arguments and caps preview length', () {
    final formatted = formatMcpAppApprovalArguments({'target': 'file.txt'});
    final emoji = String.fromCharCodes([0x1f600]);
    final truncated = formatMcpAppApprovalArguments({'value': emoji * 3000});
    final ellipsis = String.fromCharCode(0x2026);

    expect(formatted, '{\n  "target": "file.txt"\n}');
    expect(truncated.runes.length, 2001);
    expect(truncated.endsWith(ellipsis), isTrue);
  });

  testWidgets('matches App result and keeps retry fallback beside text', (
    tester,
  ) async {
    final server = McpServerEntity(
      id: 'server-1',
      workspaceId: 'workspace-1',
      name: 'Weather Server',
      url: 'https://mcp.example',
      transport: const McpTransportTypeSSE(),
      authenticationType: const McpAuthenticationTypeNone(),
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    const appTool = McpToolInfo(
      toolName: 'get_forecast',
      description: 'Gets forecast',
      inputSchema: {},
      metadata: {
        'ui': {'resourceUri': _resourceUri},
      },
    );
    final connection = McpConnectionState(
      server: server,
      status: .connected,
      tools: [appTool],
    );
    final appToolCall = _toolCall(
      id: 'app-result',
      name: appTool.finalToolName(server),
    );
    final unmatchedToolCall = _toolCall(
      id: 'unmatched-result',
      name: 'browser_search',
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Column(
            children: [
              const Text('Forecast result'),
              McpAppToolResult(
                workspaceId: server.workspaceId,
                conversationId: 'conversation-1',
                toolCall: appToolCall,
                fallbackText: 'Forecast result',
                controller: .new(),
              ),
              const Text('Search result'),
              McpAppToolResult(
                workspaceId: server.workspaceId,
                conversationId: 'conversation-1',
                toolCall: unmatchedToolCall,
                fallbackText: 'Search result',
                controller: .new(),
              ),
            ],
          ),
          overrides: [
            mcpConnectionProvider.overrideWith(
              () => _TestMcpConnectionNotifier([connection]),
            ),
          ],
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Forecast result'), findsOneWidget);
    expect(find.text('Search result'), findsOneWidget);
    expect(
      find.text(
        'Interactive result unavailable. The text result remains above.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loads App resource and sends result to embedded view', (
    tester,
  ) async {
    final previousPlatform = InAppWebViewPlatform.instance;
    final platform = _TestMcpAppWebViewPlatform();
    InAppWebViewPlatform.instance = platform;
    addTearDown(() {
      if (previousPlatform != null) {
        InAppWebViewPlatform.instance = previousPlatform;
      }
    });

    final server = McpServerEntity(
      id: 'server-1',
      workspaceId: 'workspace-1',
      name: 'Weather Server',
      url: 'https://mcp.example',
      transport: const McpTransportTypeSSE(),
      authenticationType: const McpAuthenticationTypeNone(),
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    const appTool = McpToolInfo(
      toolName: 'get_forecast',
      description: 'Gets forecast',
      inputSchema: {},
      metadata: {
        'ui': {'resourceUri': _resourceUri},
      },
    );
    final appData = <String, Object?>{
      'content': [
        {'type': 'text', 'text': 'fixture-result-payload'},
      ],
    };
    const resourceHtml = '<html><body>fixture-mcp-app</body></html>';
    final resourceResult = <String, Object?>{
      'contents': [
        {
          'uri': _resourceUri,
          'mimeType': 'text/html;profile=mcp-app',
          'text': resourceHtml,
        },
      ],
    };
    final client = _TestMcpManagerClient();
    final repositoryTools = [appTool];
    final manager = _TestMcpManagerService(
      client: client,
      tools: repositoryTools,
      resource: resourceResult,
    );
    final repository = _TestMcpServersRepository();
    final oauth = _TestOAuthCredentialService();
    final workspaceSession = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: server.workspaceId),
    );
    final toolCall = _toolCall(
      id: 'app-result',
      name: appTool.finalToolName(server),
      argumentsRaw: '{"location":"Bogota"}',
      appData: appData,
    );
    when(() => repository.getEnabledMcpServersForWorkspace(server.workspaceId))
        .thenAnswer((_) async => [server]);
    when(
      () => repository.syncMcpTools(
        mcpServerId: server.id,
        currentTools: repositoryTools,
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(() => oauth.resolveMcpAuthentication(server.serviceConnectionId))
        .thenAnswer((_) async => server.authenticationType);

    try {
      final _ = await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: Column(
              children: [
                const Text('Forecast result'),
                McpAppToolResult(
                  workspaceId: server.workspaceId,
                  conversationId: 'conversation-1',
                  toolCall: toolCall,
                  fallbackText: 'Forecast result',
                  controller: .new(),
                ),
              ],
            ),
            overrides: [
              currentRouteWorkspaceIdProvider.overrideWithValue(
                server.workspaceId,
              ),
              mcpServersRepositoryProvider(workspaceSession)
                  .overrideWithValue(repository),
              mcpManagerServiceProvider.overrideWithValue(manager),
              oauthCredentialServiceProvider.overrideWithValue(oauth),
            ],
            workspaceSession: workspaceSession,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Forecast result'), findsOneWidget);
      expect(find.byType(InAppWebView), findsOneWidget);
      expect(manager.readResourceUris, [_resourceUri]);
      expect(
        platform.creationParams?.initialData?.data,
        contains(base64Encode(utf8.encode(resourceHtml))),
      );

      final appMessage = platform.controller.messageHandler;
      if (appMessage == null) fail('MCP App message handler was not added.');
      final _ = await tester.runAsync(() async {
        final _ = await appMessage(
          _appMessageData(
            jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
          ),
        );
        final _ = await appMessage(
          _appMessageData(
            jsonEncode({
              'jsonrpc': '2.0',
              'method': 'ui/notifications/initialized',
            }),
          ),
        );
      });

      final appMessages = platform.controller.evaluatedScripts.join('\n');
      expect(appMessages, contains('"method":"ui/notifications/tool-input"'));
      expect(appMessages, contains('"method":"ui/notifications/tool-result"'));
      expect(appMessages, contains('fixture-result-payload'));
      expect(appMessages, contains('Bogota'));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }
  });
}

MessageToolCallEntity _toolCall({
  required String id,
  required String name,
  String argumentsRaw = '{}',
  Map<String, Object?>? appData,
}) => MessageToolCallEntity(
  id: id,
  name: name,
  argumentsRaw: argumentsRaw,
  responseRaw: '{"content":[]}',
  appData: appData,
  resultStatus: .success,
);

JavaScriptHandlerFunctionData _appMessageData(String message) =>
    JavaScriptHandlerFunctionData(
      args: [message],
      isMainFrame: true,
      origin: .new('https://mcp-app.example'),
      requestUrl: .new('https://mcp-app.example'),
    );

class _TestMcpConnectionNotifier(final List<McpConnectionState> _connections)
    extends McpConnectionNotifier {
  @override
  List<McpConnectionState> build() => _connections;
}

class _TestMcpManagerClient implements McpManagerClient {
  int disconnectCount = 0;
  void Function()? registeredToolsListChangedHandler;

  @override
  bool get isConnected => true;

  @override
  Stream<OAuthTokenEntity>? get onTokenUpdate => null;

  @override
  McpTransportType get resolvedTransport => const McpTransportTypeSSE();

  @override
  void disconnect() => disconnectCount++;

  @override
  void onToolsListChanged(void Function() handler) =>
      registeredToolsListChangedHandler = handler;
}

class _TestMcpManagerService({
  required final _TestMcpManagerClient client,
  required final List<McpToolInfo> tools,
  required final Map<String, Object?> resource,
}) extends McpManagerService {
  final readResourceUris = <String>[];

  @override
  Future<McpManagerClient> connectMcp(McpServerToCreate _) async => client;

  @override
  Future<List<McpToolInfo>> getTools(McpManagerClient _) async => tools;

  @override
  Future<Map<String, Object?>> readResource(
    McpManagerClient _,
    String uri,
  ) async {
    readResourceUris.add(uri);

    return resource;
  }
}

class _TestMcpServersRepository extends Mock
    implements McpServersRepositoryContract;

class _TestOAuthCredentialService extends Mock
    implements OAuthCredentialService;

class _TestMcpAppWebViewPlatform extends InAppWebViewPlatform {
  final _TestMcpAppPlatformController controller = .new();
  PlatformInAppWebViewWidgetCreationParams? creationParams;

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidgetStatic() =>
      _TestMcpAppPlatformWidget(
        .new(),
        controller: .new(),
        shouldAttach: false,
      );

  @override
  PlatformInAppWebViewController createPlatformInAppWebViewControllerStatic() =>
      _TestMcpAppPlatformController();

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    creationParams = params;

    return _TestMcpAppPlatformWidget(
      params,
      controller: controller,
      shouldAttach: true,
    );
  }
}

class _TestMcpAppPlatformWidget(
  super.params, {
  required final _TestMcpAppPlatformController controller,
  required final bool shouldAttach,
}) extends PlatformInAppWebViewWidget {
  this : super.implementation();

  var _didAttach = false;

  @override
  Widget build(BuildContext _) {
    if (shouldAttach && !_didAttach) {
      _didAttach = true;
      final controller = controllerFromPlatform<InAppWebViewController>(
        this.controller,
      );
      params.onWebViewCreated?.call(controller);
    }

    return const SizedBox.expand();
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      params.controllerFromPlatform?.call(controller) as T;

  @override
  void dispose() => controller.dispose();
}

class _TestMcpAppPlatformController() extends PlatformInAppWebViewController {
  this
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'mcp-app-test'),
      );

  final evaluatedScripts = <String>[];
  JavaScriptHandlerFunction? messageHandler;
  bool disposed = false;
  bool? disposedKeepAlive;

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required Function callback,
  }) {
    if (handlerName == 'mcpAppsMessage') {
      messageHandler = callback as JavaScriptHandlerFunction;
    }
  }

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    evaluatedScripts.add(source);
    final payload = _hostMessage(source);
    if (payload?['method'] == 'ui/resource-teardown') {
      final requestId = payload?['id'];
      final handler = messageHandler;
      if (requestId is String && handler != null) {
        final _ = await handler(
          _appMessageData(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestId,
              'result': <String, Object?>{},
            }),
          ),
        );
      }
    }

    return null;
  }

  @override
  void dispose({bool isKeepAlive = false}) {
    disposed = true;
    disposedKeepAlive = isKeepAlive;
  }
}

Map<Object?, Object?>? _hostMessage(String source) {
  final match = RegExp(
    r'^window\.mcpAppsReply\((.*)\);$',
    dotAll: true,
  ).firstMatch(source);
  if (match == null) return null;
  final payload = match.group(1);
  if (payload == null) return null;
  final Object? decoded = jsonDecode(payload);

  return decoded is Map ? decoded : null;
}
