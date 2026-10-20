import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/features/chats/notifiers/mcp_elicitation_notifier.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result_controller.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_tool_approval_decision_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/mcp_service/mcp_app_message_bridge.dart';
import 'package:auravibes_app/services/mcp_service/mcp_app_resource.dart';
import 'package:auravibes_app/services/mcp_service/mcp_app_tool_metadata.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_webview_flutter/in_app_webview_flutter.dart';
import 'package:material_ui/material_ui.dart';

const _mcpAppLoadingStrokeWidth = 2.0;
const _mcpAppLoadingSize = 14.0;
const _mcpAppViewHeight = 320.0;
const _mcpAppTeardownEvaluationTimeout = Duration(seconds: 1);
const _maxMcpAppApprovalArgumentRunes = 2000;
const JsonEncoder _mcpAppApprovalArgumentsEncoder = .withIndent('  ');

typedef _McpAppToolViewData = ({
  String mcpServerId,
  String mcpSlug,
  String toolIdentifier,
  String resourceUri,
});

typedef _McpAppCallRequest = ({
  _McpAppEmbeddedView view,
  BuildContext Function() getContext,
  String toolName,
  Map<String, dynamic> arguments,
});

typedef _McpAppApprovalRequest = ({_McpAppCallRequest call, McpToolInfo tool});

class const McpAppToolResult({
  required final String workspaceId,
  required final String conversationId,
  required final MessageToolCallEntity toolCall,
  required final String? fallbackText,
  required final McpAppToolResultController controller,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext _, WidgetRef ref) {
    final viewData = _mcpAppToolViewData(
      toolCall,
      ref.watch(mcpConnectionProvider),
    );
    if (viewData == null) return const SizedBox.shrink();

    return _McpAppResourceLoader(
      result: this,
      viewData: viewData,
      key: ValueKey('mcp_app_${toolCall.id}'),
    );
  }
}

_McpAppToolViewData? _mcpAppToolViewData(
  MessageToolCallEntity toolCall,
  List<McpConnectionState> connections,
) {
  if (!_canRenderMcpAppResult(toolCall)) return null;
  final components = McpToolIdComponents.fromComposite(toolCall.name);
  if (components == null) return null;
  final resourceUri = _mcpAppResourceUri(connections, components);
  if (resourceUri == null) return null;

  return (
    mcpServerId: components.mcpServerId,
    mcpSlug: components.slugName,
    toolIdentifier: components.toolIdentifier,
    resourceUri: resourceUri,
  );
}

String? _mcpAppResourceUri(
  List<McpConnectionState> connections,
  McpToolIdComponents components,
) {
  final tool = _findMcpAppTool(connections, components);

  return parseMcpAppToolMetadata(tool?.metadata).resourceUri;
}

McpToolInfo? _findMcpAppTool(
  List<McpConnectionState> connections,
  McpToolIdComponents components,
) {
  final connection = connections.firstWhereOrNull(
    (value) => value.server.id == components.mcpServerId,
  );

  return connection?.tools.firstWhereOrNull(
    (value) => value.toolName == components.toolIdentifier,
  );
}

bool _canRenderMcpAppResult(MessageToolCallEntity toolCall) =>
    (toolCall.responseRaw != null || toolCall.appData != null) &&
    (toolCall.resultStatus == null ||
        toolCall.resultStatus == ToolCallResultStatus.success);

class const _McpAppResourceLoader({
  required final McpAppToolResult result,
  required final _McpAppToolViewData viewData,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_McpAppResourceLoader> createState() =>
      _McpAppResourceLoaderState();
}

class _McpAppResourceLoaderState extends ConsumerState<_McpAppResourceLoader> {
  Future<McpAppResource>? _resource;

  @override
  void initState() {
    super.initState();
    _resource = _loadResource();
  }

  @override
  Widget build(BuildContext _) => FutureBuilder<McpAppResource>(
    future: _resource,
    builder: (context, snapshot) => _McpAppResourceSnapshot(
      widget: widget,
      snapshot: snapshot,
      onRetry: _retry,
    ),
  );

  Future<McpAppResource> _loadResource() async {
    final result = await ref
        .read(mcpConnectionProvider.notifier)
        .readAppResource(
          mcpServerId: widget.viewData.mcpServerId,
          toolIdentifier: widget.viewData.toolIdentifier,
          resourceUri: widget.viewData.resourceUri,
        );

    return parseMcpAppResource(
      result,
      resourceUri: widget.viewData.resourceUri,
    );
  }

  void _retry() => setState(() => _resource = _loadResource());
}

class const _McpAppResourceSnapshot({
  required final _McpAppResourceLoader widget,
  required final AsyncSnapshot<McpAppResource> snapshot,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return _McpAppResourceError(onRetry: onRetry);
    }
    final resource = snapshot.data;
    if (resource == null) return const _McpAppResourceLoading();

    return _McpAppResourceLoaded(widget: widget, resource: resource);
  }
}

class const _McpAppResourceError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _McpAppResourceStatus(
    child: AuraRow(
      children: [
        const Expanded(child: TextLocale(LocaleKeys.mcp_apps_unavailable)),
        AuraButton(
          onPressed: onRetry,
          child: const TextLocale(LocaleKeys.mcp_apps_retry),
          variant: .ghost,
          size: .small,
        ),
      ],
      spacing: .xs,
    ),
  );
}

class const _McpAppResourceLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _McpAppResourceStatus(
    child: AuraRow(
      children: [
        SizedBox.square(
          child: CircularProgressIndicator(
            strokeWidth: _mcpAppLoadingStrokeWidth,
          ),
          dimension: _mcpAppLoadingSize,
        ),
        TextLocale(LocaleKeys.mcp_apps_loading),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
  );
}

class const _McpAppResourceLoaded({
  required final _McpAppResourceLoader widget,
  required final McpAppResource resource,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: _McpAppEmbeddedView(loader: widget, resource: resource),
  );
}

class const _McpAppResourceStatus({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: AuraContainer(
      child: child,
      padding: .small,
      variant: .surfaceVariant,
      borderRadius: 8,
    ),
  );
}

class const _McpAppEmbeddedView({
  required final _McpAppResourceLoader loader,
  required final McpAppResource resource,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_McpAppEmbeddedView> createState() =>
      _McpAppEmbeddedViewState();
}

class _McpAppEmbeddedViewState extends ConsumerState<_McpAppEmbeddedView> {
  InAppWebViewController? _controller;
  var _viewFailed = false;
  var _viewRevision = 0;
  McpAppMessageBridge? _bridge;
  Future<void>? _teardownFuture;

  @override
  void initState() {
    super.initState();
    final result = widget.loader.result;
    final toolCall = result.toolCall;
    _bridge = .new(
      initialArguments: _toolArguments(toolCall.argumentsRaw),
      initialResult: _toolResult(
        toolCall.appData,
        toolCall.responseRaw,
        result.fallbackText,
      ),
      callTool: _callAppTool,
    );
    result.controller.teardownHandler = _prepareForResourceTeardown;
  }

  @override
  void dispose() {
    widget.loader.result.controller.teardownHandler = null;
    // Flutter dispose is synchronous; start teardown before WebView disposal.
    unawaited(_prepareForResourceTeardown());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _McpAppEmbeddedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.loader.result.controller;
    final controller = widget.loader.result.controller;
    if (oldController != controller) {
      oldController.teardownHandler = null;
      controller.teardownHandler = _prepareForResourceTeardown;
    }
  }

  @override
  Widget build(BuildContext _) => _viewFailed
      ? _McpAppResourceError(onRetry: () => unawaited(_restartView()))
      : _McpAppWebView(state: this);

  Future<Map<String, Object?>> _callAppTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) {
    final request = (
      view: widget,
      getContext: () => context,
      toolName: toolName,
      arguments: arguments,
    );

    return _callMcpAppTool(ref, request, () => mounted);
  }

  Future<void> _showFailureAfterTeardown() async {
    await _prepareForResourceTeardown();
    if (mounted) setState(() => _viewFailed = true);
  }

  Future<void> _restartView() async {
    await _prepareForResourceTeardown();
    if (!mounted) return;
    _bridge?.reset();
    _teardownFuture = null;
    setState(() {
      _viewFailed = false;
      _viewRevision++;
    });
  }

  Future<void> _prepareForResourceTeardown() =>
      _teardownFuture ??= _sendResourceTeardown();

  Future<void> _sendResourceTeardown() async {
    final bridge = _bridge;
    final controller = _controller;
    if (bridge == null || controller == null) return;
    final teardown = bridge.beginResourceTeardown();
    if (teardown == null) return;

    try {
      final _ = await controller
          .evaluateJavascript(
            source: 'window.mcpAppsReply(${jsonEncode(teardown.message)});',
          )
          .timeout(_mcpAppTeardownEvaluationTimeout);
      await teardown.response;
    } on Object {
      // The view can close while the platform WebView is shutting down.
    }
  }
}

class const _McpAppWebView({required final _McpAppEmbeddedViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => SizedBox(
    height: _mcpAppViewHeight,
    child: Semantics(
      child: _McpAppHostedWebView(state: state),
      container: true,
    ),
  );
}

class const _McpAppHostedWebView({
  required final _McpAppEmbeddedViewState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => InAppWebView(
    key: ValueKey((
      toolCallId: state.widget.loader.result.toolCall.id,
      revision: state._viewRevision,
    )),
    initialData: _mcpAppInitialData(state),
    initialSettings: _mcpAppWebViewSettings(),
    onReceivedError: _onReceivedError,
    onWebViewCreated: _onWebViewCreated,
    onRenderProcessGone: _onRenderProcessGone,
    onWebContentProcessDidTerminate: _onWebContentProcessDidTerminate,
  );

  void _onReceivedError(
    InAppWebViewController _,
    WebResourceRequest request,
    WebResourceError _,
  ) => _handleMcpAppMainFrameError(state, request.isForMainFrame);

  void _onWebViewCreated(InAppWebViewController controller) =>
      _onMcpAppWebViewCreated(state, controller);

  void _onRenderProcessGone(
    InAppWebViewController _,
    RenderProcessGoneDetail _,
  ) => unawaited(state._showFailureAfterTeardown());

  void _onWebContentProcessDidTerminate(InAppWebViewController _) =>
      unawaited(state._showFailureAfterTeardown());
}

void _handleMcpAppMainFrameError(
  _McpAppEmbeddedViewState state,
  bool? isMainFrame,
) {
  if (isMainFrame ?? true) unawaited(state._showFailureAfterTeardown());
}

InAppWebViewInitialData _mcpAppInitialData(_McpAppEmbeddedViewState state) =>
    .new(
      data: buildMcpAppHostPage(
        html: state.widget.resource.html,
        csp: state.widget.resource.csp,
        isWeb: kIsWeb,
      ),
    );

InAppWebViewSettings _mcpAppWebViewSettings() => .new(
  supportZoom: false,
  allowFileAccess: false,
  javaScriptHandlersForMainFrameOnly: true,
  javaScriptBridgeForMainFrameOnly: true,
);

void _onMcpAppWebViewCreated(
  _McpAppEmbeddedViewState state,
  InAppWebViewController controller,
) {
  state._controller = controller;
  controller.addJavaScriptHandler(
    handlerName: 'mcpAppsMessage',
    callback: (JavaScriptHandlerFunctionData data) =>
        _onMcpAppMessage(state, data),
  );
}

Future<Object?> _onMcpAppMessage(
  _McpAppEmbeddedViewState state,
  JavaScriptHandlerFunctionData data,
) async {
  if (!_isMcpAppFrameMessage(data)) return null;
  final bridge = state._bridge;
  final controller = state._controller;
  if (bridge == null || controller == null) return null;
  final messages = await bridge.handleMessage(data.args.single as String);
  await _replyToMcpApp(controller, messages);

  return null;
}

bool _isMcpAppFrameMessage(JavaScriptHandlerFunctionData data) =>
    data.isMainFrame && data.args.length == 1 && data.args.single is String;

Future<void> _replyToMcpApp(
  InAppWebViewController controller,
  List<Map<String, Object?>> messages,
) async {
  for (final message in messages) {
    final payload = jsonEncode(message);
    final _ = await controller.evaluateJavascript(
      source: 'window.mcpAppsReply($payload);',
    );
  }
}

Future<Map<String, Object?>> _callMcpAppTool(
  WidgetRef ref,
  _McpAppCallRequest request,
  bool Function() isMounted,
) async {
  await _approveMcpAppToolCall(ref, request, isMounted);

  return await _runApprovedMcpAppTool(ref, request);
}

Future<void> _approveMcpAppToolCall(
  WidgetRef ref,
  _McpAppCallRequest request,
  bool Function() isMounted,
) async {
  final tool = _visibleMcpAppTool(ref, request.view, request.toolName);
  final approvalRequest = (call: request, tool: tool);
  await _ensureMcpAppToolCallApproved(ref, approvalRequest, isMounted);
}

Future<Map<String, Object?>> _runApprovedMcpAppTool(
  WidgetRef ref,
  _McpAppCallRequest request,
) {
  final elicit = ref
      .read(
        mcpElicitationProvider(request.view.loader.result.conversationId)
            .notifier,
      )
      .request;

  return ref
      .read(mcpConnectionProvider.notifier)
      .callAppTool(
        mcpServerId: request.view.loader.viewData.mcpServerId,
        toolIdentifier: request.toolName,
        arguments: request.arguments,
        onElicitation: elicit,
      );
}

McpToolInfo _visibleMcpAppTool(
  WidgetRef ref,
  _McpAppEmbeddedView widget,
  String toolName,
) {
  final tool = _findMcpAppToolByName(
    ref,
    widget.loader.viewData.mcpServerId,
    toolName,
  );
  if (tool == null ||
      !isMcpAppToolVisibleToApp(parseMcpAppToolMetadata(tool.metadata))) {
    throw StateError('MCP tool is unavailable to this app.');
  }

  return tool;
}

McpToolInfo? _findMcpAppToolByName(
  WidgetRef ref,
  String mcpServerId,
  String toolName,
) {
  final connection = ref
      .read(mcpConnectionProvider.notifier)
      .getConnection(mcpServerId);

  return connection?.tools.firstWhereOrNull(
    (value) => value.toolName == toolName,
  );
}

Future<void> _ensureMcpAppToolCallApproved(
  WidgetRef ref,
  _McpAppApprovalRequest request,
  bool Function() isMounted,
) async {
  final call = request.call;
  final decision = await _mcpAppToolApprovalDecision(ref, request);
  if (!isMounted()) throw StateError('MCP tool call was not approved.');
  if (decision.isGranted()) return;
  await _confirmMcpAppToolCallIfNeeded(call, decision, isMounted);
}

Future<void> _confirmMcpAppToolCallIfNeeded(
  _McpAppCallRequest call,
  ToolApprovalDecision decision,
  bool Function() isMounted,
) async {
  if (!decision.needsConfirmation ||
      !await _confirmMcpAppToolCall(
        call.getContext(),
        call.toolName,
        call.arguments,
      ) ||
      !isMounted()) {
    throw StateError('MCP tool call was not approved.');
  }
}

Future<ToolApprovalDecision> _mcpAppToolApprovalDecision(
  WidgetRef ref,
  _McpAppApprovalRequest request,
) {
  final embeddedView = request.call.view;
  final result = embeddedView.loader.result;
  final usecase = ref.read(
    resolveToolApprovalDecisionUsecaseProvider(result.workspaceId),
  );

  return usecase.call(
    conversationId: result.conversationId,
    workspaceId: result.workspaceId,
    toolCallId: result.toolCall.id,
    resolvedTool: _mcpAppResolvedTool(request),
  );
}

ResolvedTool _mcpAppResolvedTool(_McpAppApprovalRequest request) =>
    ResolvedTool.mcp(
      tableId: request.tool.toolName,
      toolIdentifier: request.call.toolName,
      mcp: (
        mcpServerId: request.call.view.loader.viewData.mcpServerId,
        mcpSlug: request.call.view.loader.viewData.mcpSlug,
        outputSchemaJson: null,
      ),
    );

Future<bool> _confirmMcpAppToolCall(
  BuildContext context,
  String toolName,
  Map<String, dynamic> arguments,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) =>
          _McpAppToolApprovalDialog(toolName: toolName, arguments: arguments),
    ) ??
    false;

class const _McpAppToolApprovalDialog({
  required final String toolName,
  required final Map<String, dynamic> arguments,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(LocaleKeys.mcp_apps_tool_approval_title),
    content: _McpAppToolApprovalMessage(
      toolName: toolName,
      arguments: arguments,
    ),
    actions: const [
      _McpAppToolApprovalCancelButton(),
      _McpAppToolApprovalAllowOnceButton(),
    ],
  );
}

class const _McpAppToolApprovalCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.pop(context, false),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}

class const _McpAppToolApprovalAllowOnceButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: () => Navigator.pop(context, true),
    child: const TextLocale(LocaleKeys.tool_confirmation_allow_once),
  );
}

class const _McpAppToolApprovalMessage({
  required final String toolName,
  required final Map<String, dynamic> arguments,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      Text(
        LocaleKeys.mcp_apps_tool_approval_message.tr(
          namedArgs: {'tool': toolName},
        ),
      ),
      const SizedBox(height: 12),
      const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_activity_arguments,
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 160,
        child: SingleChildScrollView(
          child: SelectableText(formatMcpAppApprovalArguments(arguments)),
        ),
      ),
    ],
  );
}

/// Formats app-supplied arguments for the bounded approval preview.
String formatMcpAppApprovalArguments(Map<String, dynamic> arguments) {
  final runes = _mcpAppApprovalArgumentsEncoder
      .convert(arguments)
      .runes
      .take(_maxMcpAppApprovalArgumentRunes + 1)
      .toList(growable: false);
  if (runes.length <= _maxMcpAppApprovalArgumentRunes) {
    return String.fromCharCodes(runes);
  }

  final preview = String.fromCharCodes(
    runes.take(_maxMcpAppApprovalArgumentRunes),
  );

  return '$preview${String.fromCharCode(0x2026)}';
}

Map<String, dynamic> _toolArguments(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded.keys.every((key) => key is String)) {
      return Map<String, dynamic>.from(decoded);
    }
  } on FormatException {
    // Older tool calls can contain non-JSON argument snapshots.
  }

  return const {};
}

Map<String, Object?> _toolResult(
  Map<String, Object?>? appData,
  String? raw,
  String? fallbackText,
) {
  final resultData = appData ?? _decodeToolResult(raw);
  if (resultData != null && resultData['content'] is List) {
    return resultData;
  }

  return {
    'content': [
      {'type': 'text', 'text': fallbackText ?? raw ?? ''},
    ],
  };
}

Map<String, Object?>? _decodeToolResult(String? raw) {
  if (raw == null) return null;
  final decoded = _decodeJson(raw);
  if (decoded is! Map || decoded['content'] is! List) return null;

  return Map<String, Object?>.from(decoded);
}

Object? _decodeJson(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    // Plain text MCP results are not JSON objects.
    return null;
  }
}
