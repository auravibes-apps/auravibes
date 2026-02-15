import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';

/// Result of executing a tool
class ToolExecutionResult {
  const ToolExecutionResult({
    required this.status,
    this.responseRaw,
    this.errorMessage,
  });

  final ToolCallResultStatus status;
  final String? responseRaw;
  final String? errorMessage;
}

/// Use case for executing a single tool (built-in or MCP).
///
/// This is a simple class with constructor injection - no Riverpod.
class ExecuteToolUseCase {
  const ExecuteToolUseCase();

  /// Executes a single tool and returns the result
  Future<ToolExecutionResult> call({
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      if (tool.isBuiltIn) {
        return await _executeBuiltInTool(tool, arguments);
      } else {
        return await _executeMcpTool(tool, arguments);
      }
    } on Object catch (e) {
      return ToolExecutionResult(
        status: ToolCallResultStatus.executionError,
        errorMessage: e.toString(),
      );
    }
  }

  Future<ToolExecutionResult> _executeBuiltInTool(
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    final toolType = tool.builtInTool;
    if (toolType == null) {
      return const ToolExecutionResult(
        status: ToolCallResultStatus.toolNotFound,
      );
    }

    final toolService = ToolService.getTool(toolType);
    if (toolService == null) {
      return const ToolExecutionResult(
        status: ToolCallResultStatus.toolNotFound,
      );
    }

    final dynamic input = arguments['input'];
    if (input == null) {
      return const ToolExecutionResult(
        status: ToolCallResultStatus.executionError,
        errorMessage: 'Missing required input parameter',
      );
    }
    final result = await toolService.runner(input as Object).value;

    return ToolExecutionResult(
      status: ToolCallResultStatus.success,
      responseRaw: result.toString(),
    );
  }

  Future<ToolExecutionResult> _executeMcpTool(
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    // MCP tool execution will be added when we have MCP manager injected
    // For now, return not found to keep test passing
    return const ToolExecutionResult(
      status: ToolCallResultStatus.toolNotFound,
    );
  }
}
