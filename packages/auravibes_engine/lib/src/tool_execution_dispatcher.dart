import 'dart:convert';

import 'package:auravibes_engine/src/tool_calls.dart';

enum AgentToolResultStatus {
  success,
  toolNotFound,
  executionError,
  disabledInConversation,
  disabledByAgent,
  disabledInWorkspace,
  notConfigured,
  stoppedByUser,
}

extension AgentToolResultStatusX on AgentToolResultStatus {
  AgentToolCallLifecycle get lifecycle => switch (this) {
    AgentToolResultStatus.success => AgentToolCallLifecycle.success,
    AgentToolResultStatus.stoppedByUser => AgentToolCallLifecycle.stoppedByUser,
    _ => AgentToolCallLifecycle.failed,
  };

  String get modelFallback => switch (this) {
    AgentToolResultStatus.success => '',
    AgentToolResultStatus.toolNotFound => 'Tool not found.',
    AgentToolResultStatus.executionError => 'Tool execution failed.',
    AgentToolResultStatus.disabledInConversation =>
      'Tool is disabled for this conversation.',
    AgentToolResultStatus.disabledByAgent =>
      'Tool is denied by the selected agent.',
    AgentToolResultStatus.disabledInWorkspace =>
      'Tool is disabled in workspace.',
    AgentToolResultStatus.notConfigured => 'Tool is not configured.',
    AgentToolResultStatus.stoppedByUser =>
      'Tool execution was stopped by the user.',
  };
}

class AgentToolExecutionResult {
  const AgentToolExecutionResult({
    required this.resultStatus,
    this.responseRaw,
  });

  final AgentToolResultStatus resultStatus;
  final String? responseRaw;
}

typedef AgentResolvedToolRunner<TTool extends Object> =
    Future<Object?> Function({
      required String conversationId,
      required TTool tool,
      required Map<String, dynamic> arguments,
    });

typedef AgentToolCancellationChecker = bool Function(String conversationId);

typedef AgentToolExecutionErrorLogger<TTool extends Object> =
    void Function({
      required String conversationId,
      required String toolCallId,
      required TTool tool,
      required Object error,
      required StackTrace stackTrace,
    });

class AgentToolExecutionDispatcher<TTool extends Object> {
  const AgentToolExecutionDispatcher({
    required this.runResolvedTool,
    required this.isCancellationRequested,
    required this.logToolExecutionError,
  });

  final AgentResolvedToolRunner<TTool> runResolvedTool;
  final AgentToolCancellationChecker isCancellationRequested;
  final AgentToolExecutionErrorLogger<TTool> logToolExecutionError;

  Future<AgentToolExecutionResult> call({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required String argumentsRaw,
  }) async {
    final arguments = safeJsonDecodeToolArguments(argumentsRaw);

    try {
      final result = await runResolvedTool(
        conversationId: conversationId,
        tool: tool,
        arguments: arguments,
      );
      if (isCancellationRequested(conversationId)) {
        return const AgentToolExecutionResult(
          resultStatus: AgentToolResultStatus.stoppedByUser,
        );
      }
      if (result == null) {
        return const AgentToolExecutionResult(
          resultStatus: AgentToolResultStatus.toolNotFound,
        );
      }

      return AgentToolExecutionResult(
        resultStatus: AgentToolResultStatus.success,
        responseRaw: switch (result) {
          final String value => value,
          final Map<Object?, Object?> value => jsonEncode(value),
          final List<Object?> value => jsonEncode(value),
          _ => result.toString(),
        },
      );
    } on FormatException catch (error, stackTrace) {
      logToolExecutionError(
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        error: error,
        stackTrace: stackTrace,
      );

      return AgentToolExecutionResult(
        resultStatus: AgentToolResultStatus.executionError,
        responseRaw: 'Tool execution failed: ${error.message}',
      );
    } on Object catch (error, stackTrace) {
      logToolExecutionError(
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        error: error,
        stackTrace: stackTrace,
      );

      return const AgentToolExecutionResult(
        resultStatus: AgentToolResultStatus.executionError,
      );
    }
  }
}

Map<String, dynamic> safeJsonDecodeToolArguments(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
  } on Object catch (_) {}

  return const <String, dynamic>{};
}
