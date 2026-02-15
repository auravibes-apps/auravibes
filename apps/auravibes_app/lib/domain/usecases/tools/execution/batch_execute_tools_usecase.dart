import 'dart:convert';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/execute_tool_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/update_message_metadata_usecase.dart';

/// Extension to add arguments getter to entity ToolToCall
extension ToolToCallExtension on ToolToCall {
  Map<String, dynamic> get arguments {
    if (argumentsRaw.isEmpty) {
      return {};
    }
    return jsonDecode(argumentsRaw) as Map<String, dynamic>;
  }
}

/// Result of a batch execution
class BatchToolResult {
  BatchToolResult({
    required this.toolCallId,
    required this.update,
  });

  final String toolCallId;
  final ToolResultUpdate update;
}

/// Use case for executing a batch of tools.
///
/// This is a simple class with constructor injection - no Riverpod.
class BatchExecuteToolsUseCase {
  const BatchExecuteToolsUseCase(
    this._executeToolUseCase,
    this._updateMetadataUseCase,
  );

  final ExecuteToolUseCase _executeToolUseCase;
  final UpdateMessageMetadataUseCase _updateMetadataUseCase;

  /// Executes a batch of tools and persists results
  Future<List<BatchToolResult>> call({
    required List<ToolToCall> tools,
    required String messageId,
  }) async {
    if (tools.isEmpty) return [];

    final results = <BatchToolResult>[];
    final updates = <ToolResultUpdate>[];

    for (final toolToCall in tools) {
      final executionResult = await _executeToolUseCase.call(
        tool: toolToCall.tool,
        arguments: toolToCall.arguments,
      );

      final update = ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: executionResult.status,
        responseRaw: executionResult.responseRaw,
      );

      results.add(
        BatchToolResult(
          toolCallId: toolToCall.id,
          update: update,
        ),
      );
      updates.add(update);
    }

    // Persist all updates
    await _updateMetadataUseCase.call(
      messageId: messageId,
      updates: updates,
    );

    return results;
  }
}
