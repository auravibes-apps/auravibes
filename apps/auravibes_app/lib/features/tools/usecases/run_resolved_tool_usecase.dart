import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:riverpod/riverpod.dart';

typedef McpToolCaller =
    Future<String> Function({
      required String mcpServerId,
      required String toolIdentifier,
      required Map<String, dynamic> arguments,
    });

class RunResolvedToolUsecase {
  const RunResolvedToolUsecase({
    required this.agentCancellationRuntime,
    required this.mcpToolCaller,
  });

  final AgentCancellationRuntime agentCancellationRuntime;
  final McpToolCaller mcpToolCaller;

  Future<Object?> call({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) async {
    if (tool.isBuiltIn) {
      return _runBuiltInTool(conversationId, tool, arguments);
    }

    if (tool.isNative) {
      return _runNativeTool(conversationId, tool, arguments);
    }

    if (tool.isMcp) {
      return _runMcpTool(tool, arguments);
    }

    return null;
  }

  Future<Object?> _runBuiltInTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) {
    final input = arguments['input'];
    if (input == null) {
      throw const FormatException('Built-in tools require an input argument.');
    }

    final builtInTool = tool.builtInTool;
    final toolService = builtInTool == null
        ? null
        : ToolService.getTool(builtInTool);
    if (toolService == null) return Future.value();

    final operation = toolService.runner(input as Object);
    agentCancellationRuntime.registerCancelableOperation(
      conversationId,
      operation,
    );
    return operation.valueOrCancellation();
  }

  Future<Object?> _runNativeTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) {
    final input = arguments['input'];
    if (input == null) {
      throw const FormatException('Native tools require an input argument.');
    }

    final nativeTool = tool.nativeTool;
    final toolService = nativeTool == null
        ? null
        : NativeToolService.getTool(nativeTool);
    if (toolService == null) return Future.value();

    final operation = toolService.runner(input as Object);
    agentCancellationRuntime.registerCancelableOperation(
      conversationId,
      operation,
    );
    return operation.valueOrCancellation();
  }

  Future<Object?> _runMcpTool(
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) {
    final mcpServerId = tool.mcpServerId;
    if (mcpServerId == null) return Future.value();

    return mcpToolCaller(
      mcpServerId: mcpServerId,
      toolIdentifier: tool.toolIdentifier,
      arguments: arguments,
    );
  }
}

final runResolvedToolUsecaseProvider = Provider<RunResolvedToolUsecase>((ref) {
  return RunResolvedToolUsecase(
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    mcpToolCaller: ref.watch(mcpToolCallerProvider),
  );
});

final mcpToolCallerProvider = Provider<McpToolCaller>((ref) {
  return ({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) {
    return ref
        .read(mcpConnectionProvider.notifier)
        .callTool(
          mcpServerId: mcpServerId,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
        );
  };
});
