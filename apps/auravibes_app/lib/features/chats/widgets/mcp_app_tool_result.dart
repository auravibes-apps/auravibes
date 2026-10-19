import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
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

class const McpAppToolResult({
  required final String workspaceId,
  required final String conversationId,
  required final MessageToolCallEntity toolCall,
  required final String? fallbackText,
  required final McpAppToolResultController controller,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final components = McpToolIdComponents.fromComposite(toolCall.name);
    final response = toolCall.responseRaw;
    final appData = toolCall.appData;
    final resultStatus = toolCall.resultStatus;
    if (components == null ||
        (response == null && appData == null) ||
        (resultStatus != null &&
            resultStatus != ToolCallResultStatus.success)) {
      return const SizedBox.shrink();
    }

    final connection = ref
        .watch(mcpConnectionProvider)
        .firstWhereOrNull((value) => value.server.id == components.mcpServerId);
    final tool = connection?.tools.firstWhereOrNull(
      (value) => value.toolName == components.toolIdentifier,
    );
    final resourceUri = McpAppToolMetadata.fromMetadata(tool?.metadata)
        .resourceUri;
    if (resourceUri == null) return const SizedBox.shrink();

    return _McpAppResourceLoader(
      workspaceId: workspaceId,
      conversationId: conversationId,
      mcpServerId: components.mcpServerId,
      mcpSlug: components.slugName,
      toolIdentifier: components.toolIdentifier,
      resourceUri: resourceUri,
      toolCall: toolCall,
      fallbackText: fallbackText,
      controller: controller,
      key: ValueKey('mcp_app_${toolCall.id}'),
    );
  }
}

class const _McpAppResourceLoader({
  required final String workspaceId,
  required final String conversationId,
  required final String mcpServerId,
  required final String mcpSlug,
  required final String toolIdentifier,
  required final String resourceUri,
  required final MessageToolCallEntity toolCall,
  required final String? fallbackText,
  required final McpAppToolResultController controller,
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
  Widget build(BuildContext context) {
    final resourceFuture = _resource;
    if (resourceFuture == null) return const SizedBox.shrink();

    return FutureBuilder<McpAppResource>(
      future: resourceFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _McpAppResourceStatus(
            child: AuraRow(
              children: [
                const Expanded(
                  child: TextLocale(LocaleKeys.mcp_apps_unavailable),
                ),
                AuraButton(
                  onPressed: _retry,
                  child: const TextLocale(LocaleKeys.mcp_apps_retry),
                  variant: .ghost,
                  size: .small,
                ),
              ],
              spacing: .xs,
            ),
          );
        }
        final resource = snapshot.data;
        if (resource == null) {
          return const _McpAppResourceStatus(
            child: AuraRow(
              children: [
                SizedBox.square(
                  child: CircularProgressIndicator(strokeWidth: 2),
                  dimension: 14,
                ),
                TextLocale(LocaleKeys.mcp_apps_loading),
              ],
              spacing: .xs,
              mainAxisSize: .min,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
          child: _McpAppEmbeddedView(
            workspaceId: widget.workspaceId,
            conversationId: widget.conversationId,
            mcpServerId: widget.mcpServerId,
            mcpSlug: widget.mcpSlug,
            toolIdentifier: widget.toolIdentifier,
            toolCall: widget.toolCall,
            fallbackText: widget.fallbackText,
            controller: widget.controller,
            resource: resource,
          ),
        );
      },
    );
  }

  Future<McpAppResource> _loadResource() async {
    final result = await ref
        .read(mcpConnectionProvider.notifier)
        .readAppResource(
          mcpServerId: widget.mcpServerId,
          toolIdentifier: widget.toolIdentifier,
          resourceUri: widget.resourceUri,
        );

    return McpAppResource.fromReadResult(
      result,
      resourceUri: widget.resourceUri,
    );
  }

  void _retry() => setState(() => _resource = _loadResource());
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
  required final String workspaceId,
  required final String conversationId,
  required final String mcpServerId,
  required final String mcpSlug,
  required final String toolIdentifier,
  required final MessageToolCallEntity toolCall,
  required final String? fallbackText,
  required final McpAppToolResultController controller,
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
    _bridge = .new(
      initialArguments: _toolArguments(widget.toolCall.argumentsRaw),
      initialResult: _toolResult(
        widget.toolCall.appData,
        widget.toolCall.responseRaw,
        widget.fallbackText,
      ),
      callTool: _callAppTool,
    );
    widget.controller.teardownHandler = _prepareForResourceTeardown;
  }

  @override
  void dispose() {
    widget.controller.teardownHandler = null;
    // Flutter dispose is synchronous; start teardown before WebView disposal.
    unawaited(_prepareForResourceTeardown());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _McpAppEmbeddedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.teardownHandler = null;
      widget.controller.teardownHandler = _prepareForResourceTeardown;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewFailed) {
      return Padding(
        padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
        child: AuraContainer(
          child: AuraRow(
            children: [
              const Expanded(
                child: TextLocale(LocaleKeys.mcp_apps_unavailable),
              ),
              AuraButton(
                onPressed: _retryView,
                child: const TextLocale(LocaleKeys.mcp_apps_retry),
                variant: .ghost,
                size: .small,
              ),
            ],
            spacing: .xs,
          ),
          padding: .small,
          variant: .surfaceVariant,
          borderRadius: 8,
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: Semantics(
        child: InAppWebView(
          key: ValueKey('mcp_app_view_${widget.toolCall.id}_$_viewRevision'),
          initialData: .new(
            data: buildMcpAppHostPage(
              html: widget.resource.html,
              csp: widget.resource.csp,
              isWeb: kIsWeb,
            ),
          ),
          initialSettings: .new(
            supportZoom: false,
            allowFileAccess: false,
            javaScriptHandlersForMainFrameOnly: true,
            javaScriptBridgeForMainFrameOnly: true,
          ),
          onReceivedError: (controller, request, error) {
            if (request.isForMainFrame ?? true) _showViewFailure();
          },
          onWebViewCreated: _onWebViewCreated,
          onRenderProcessGone: (controller, detail) => _showViewFailure(),
          onWebContentProcessDidTerminate: (controller) => _showViewFailure(),
        ),
        container: true,
      ),
    );
  }

  void _showViewFailure() {
    unawaited(_showFailureAfterTeardown());
  }

  Future<void> _showFailureAfterTeardown() async {
    await _prepareForResourceTeardown();
    if (mounted) setState(() => _viewFailed = true);
  }

  void _retryView() => unawaited(_restartView());

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
      final _ = await controller.evaluateJavascript(
        source: 'window.mcpAppsReply(${jsonEncode(teardown.message)});',
      );
      await teardown.response;
    } on Object {
      // The view can close while the platform WebView is shutting down.
    }
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    controller.addJavaScriptHandler(
      handlerName: 'mcpAppsMessage',
      callback: _onAppMessage,
    );
  }

  Future<Object?> _onAppMessage(JavaScriptHandlerFunctionData data) async {
    if (!data.isMainFrame ||
        data.args.length != 1 ||
        data.args.single is! String) {
      return null;
    }
    final bridge = _bridge;
    if (bridge == null) return null;
    final controller = _controller;
    if (controller == null) return null;

    final messages = await bridge.handleMessage(data.args.single as String);
    for (final message in messages) {
      final payload = jsonEncode(message);
      final _ = await controller.evaluateJavascript(
        source: 'window.mcpAppsReply($payload);',
      );
    }

    return null;
  }

  Future<Map<String, Object?>> _callAppTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final connection = ref
        .read(mcpConnectionProvider.notifier)
        .getConnection(widget.mcpServerId);
    final tool = connection?.tools.firstWhereOrNull(
      (value) => value.toolName == toolName,
    );
    if (tool == null ||
        !McpAppToolMetadata.fromMetadata(tool.metadata).isVisibleToApp) {
      throw StateError('MCP tool is unavailable to this app.');
    }

    final decision = await ref
        .read(resolveToolApprovalDecisionUsecaseProvider(widget.workspaceId))
        .call(
          conversationId: widget.conversationId,
          workspaceId: widget.workspaceId,
          toolCallId: widget.toolCall.id,
          resolvedTool: ResolvedTool.mcp(
            tableId: tool.toolName,
            toolIdentifier: toolName,
            mcp: (
              mcpServerId: widget.mcpServerId,
              mcpSlug: widget.mcpSlug,
              outputSchemaJson: null,
            ),
          ),
        );

    if (!mounted) throw StateError('MCP tool call was not approved.');
    if (!decision.isGranted()) {
      if (!decision.needsConfirmation || !await _confirmToolCall(toolName)) {
        throw StateError('MCP tool call was not approved.');
      }
      if (!mounted) throw StateError('MCP tool call was not approved.');
    }

    return await ref
        .read(mcpConnectionProvider.notifier)
        .callAppTool(
          mcpServerId: widget.mcpServerId,
          toolIdentifier: toolName,
          arguments: arguments,
        );
  }

  Future<bool> _confirmToolCall(String toolName) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const TextLocale(LocaleKeys.mcp_apps_tool_approval_title),
          content: Text(
            LocaleKeys.mcp_apps_tool_approval_message.tr(
              namedArgs: {'tool': toolName},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const TextLocale(LocaleKeys.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const TextLocale(LocaleKeys.tool_confirmation_allow_once),
            ),
          ],
        ),
      ) ??
      false;
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
  if (raw != null) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['content'] is List) {
        return Map<String, Object?>.from(decoded);
      }
    } on FormatException {
      // Plain text MCP results are not JSON objects.
    }
  }

  return null;
}
