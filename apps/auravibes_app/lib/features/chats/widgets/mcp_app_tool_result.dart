import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_tool_approval_decision_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/mcp_service/mcp_app_message_bridge.dart';
import 'package:auravibes_app/services/mcp_service/mcp_app_resource.dart';
import 'package:auravibes_app/services/mcp_service/mcp_app_tool_metadata.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/utils/tool_metadata_decoder.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_webview_flutter/in_app_webview_flutter.dart';

class const McpAppToolResult({
  required final String workspaceId,
  required final String conversationId,
  required final MessageToolCallEntity toolCall,
  required final String? fallbackText,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final components = McpToolIdComponents.fromComposite(toolCall.name);
    final response = toolCall.responseRaw;
    final resultStatus = toolCall.resultStatus;
    if (components == null ||
        response == null ||
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
    final resourceUri =
        McpAppToolMetadata.fromMetadata(tool?.metadata).resourceUri ??
        McpAppToolMetadata.fromResultRaw(response).resourceUri;
    if (resourceUri == null) return const SizedBox.shrink();

    return _McpAppResourceLoader(
      key: ValueKey('mcp_app_${toolCall.id}'),
      workspaceId: workspaceId,
      conversationId: conversationId,
      mcpServerId: components.mcpServerId,
      mcpSlug: components.slugName,
      toolIdentifier: components.toolIdentifier,
      resourceUri: resourceUri,
      toolCall: toolCall,
      fallbackText: fallbackText,
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
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_McpAppResourceLoader> createState() =>
      _McpAppResourceLoaderState();
}

class _McpAppResourceLoaderState extends ConsumerState<_McpAppResourceLoader> {
  late Future<McpAppResource> _resource;

  @override
  void initState() {
    super.initState();
    _resource = _loadResource();
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

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: FutureBuilder<McpAppResource>(
      future: _resource,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _resourceUnavailable();
        final resource = snapshot.data;
        if (resource == null) return _resourceLoading();

        return _McpAppEmbeddedView(
          workspaceId: widget.workspaceId,
          conversationId: widget.conversationId,
          mcpServerId: widget.mcpServerId,
          mcpSlug: widget.mcpSlug,
          toolIdentifier: widget.toolIdentifier,
          toolCall: widget.toolCall,
          fallbackText: widget.fallbackText,
          resource: resource,
        );
      },
    ),
  );

  Widget _resourceLoading() => _resourceStatus(
    child: const AuraRow(
      children: [
        SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        TextLocale(LocaleKeys.mcp_apps_loading),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
  );

  Widget _resourceUnavailable() => _resourceStatus(
    child: AuraRow(
      children: [
        const Expanded(child: TextLocale(LocaleKeys.mcp_apps_unavailable)),
        AuraButton(
          onPressed: _retry,
          variant: .ghost,
          size: .small,
          child: const TextLocale(LocaleKeys.mcp_apps_retry),
        ),
      ],
      spacing: .xs,
    ),
  );

  Widget _resourceStatus({required Widget child}) => AuraContainer(
    variant: AuraContainerVariant.surfaceVariant,
    padding: .small,
    borderRadius: 8,
    child: child,
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
  required final McpAppResource resource,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_McpAppEmbeddedView> createState() =>
      _McpAppEmbeddedViewState();
}

class _McpAppEmbeddedViewState extends ConsumerState<_McpAppEmbeddedView> {
  InAppWebViewController? _controller;
  late final _bridge = McpAppMessageBridge(
    initialArguments: _toolArguments(widget.toolCall.argumentsRaw),
    initialResult: _toolResult(
      widget.toolCall.responseRaw,
      widget.fallbackText,
    ),
    callTool: _callAppTool,
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: Semantics(
      container: true,
      child: InAppWebView(
        key: ValueKey('mcp_app_view_${widget.toolCall.id}'),
        initialData: InAppWebViewInitialData(
          data: buildMcpAppHostPage(
            html: widget.resource.html,
            csp: widget.resource.csp,
            isWeb: kIsWeb,
          ),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: false,
          javaScriptBridgeForMainFrameOnly: true,
          javaScriptHandlersForMainFrameOnly: true,
          allowFileAccess: false,
          allowFileAccessFromFileURLs: false,
          allowUniversalAccessFromFileURLs: false,
          supportZoom: false,
        ),
        onWebViewCreated: _onWebViewCreated,
      ),
    ),
  );

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
    final messages = await _bridge.handleMessage(data.args.single as String);
    for (final message in messages) {
      final payload = jsonEncode(message);
      await _controller?.evaluateJavascript(
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

    if (!decision.isGranted()) {
      if (!decision.needsConfirmation ||
          !await _confirmToolCall(toolName) ||
          !mounted) {
        throw StateError('MCP tool call was not approved.');
      }
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

Map<String, Object?> _toolResult(String? raw, String? fallbackText) {
  if (raw != null) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['content'] is List) {
        final result = Map<String, Object?>.from(decoded);

        return {
          'content': result['content'],
          if (result['structuredContent'] != null)
            'structuredContent': result['structuredContent'],
          if (result['isError'] != null) 'isError': result['isError'],
          if (result['_meta'] != null) '_meta': result['_meta'],
        };
      }
    } on FormatException {
      // Plain text MCP results are not JSON objects.
    }
  }

  return {
    'content': [
      {'type': 'text', 'text': fallbackText ?? raw ?? ''},
    ],
  };
}
