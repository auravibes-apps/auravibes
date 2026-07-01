import 'dart:convert';

enum AgentToolResultStatus {
  success,
  toolNotFound,
  executionError,
  disabledInConversation,
  disabledInWorkspace,
  notConfigured,
  stoppedByUser,
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
        responseRaw: result.toString(),
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
