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
    .success => AgentToolCallLifecycle.success,
    .stoppedByUser => AgentToolCallLifecycle.stoppedByUser,
    _ => AgentToolCallLifecycle.failed,
  };

  String get modelFallback => switch (this) {
    .success => '',
    .toolNotFound => 'Tool not found.',
    .executionError => 'Tool execution failed.',
    .disabledInConversation => 'Tool is disabled for this conversation.',
    .disabledByAgent => 'Tool is denied by the selected agent.',
    .disabledInWorkspace => 'Tool is disabled in workspace.',
    .notConfigured => 'Tool is not configured.',
    .stoppedByUser => 'Tool execution was stopped by the user.',
  };
}

class const AgentToolExecutionResult({
  required final AgentToolResultStatus resultStatus,
  final String? responseRaw,
});

typedef AgentToolExecutionErrorRequest<TTool extends Object> = ({
  String conversationId,
  String toolCallId,
  TTool tool,
  Object error,
  StackTrace stackTrace,
});

typedef AgentResolvedToolRunner<TTool extends Object> =
    Future<Object?> Function({
      required String conversationId,
      required TTool tool,
      required Map<String, dynamic> arguments,
    });

typedef AgentToolCancellationChecker = bool Function(String conversationId);

typedef AgentToolExecutionErrorLogger<TTool extends Object> = void Function(
  AgentToolExecutionErrorRequest<TTool> request,
);

class const AgentToolExecutionDispatcher<TTool extends Object>({
  required final AgentResolvedToolRunner<TTool> runResolvedTool,
  required final AgentToolCancellationChecker isCancellationRequested,
  required final AgentToolExecutionErrorLogger<TTool> logToolExecutionError,
}) {
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
        return const AgentToolExecutionResult(resultStatus: .stoppedByUser);
      }
      if (result == null) {
        return const AgentToolExecutionResult(resultStatus: .toolNotFound);
      }

      return AgentToolExecutionResult(
        resultStatus: .success,
        responseRaw: switch (result) {
          final String value => value,
          final Map<Object?, Object?> value => jsonEncode(value),
          final List<Object?> value => jsonEncode(value),
          _ => result.toString(),
        },
      );
    } on FormatException catch (error, stackTrace) {
      logToolExecutionError((
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        error: error,
        stackTrace: stackTrace,
      ));

      return const AgentToolExecutionResult(
        resultStatus: .executionError,
        responseRaw: 'Tool execution failed.',
      );
    } on Object catch (error, stackTrace) {
      logToolExecutionError((
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        error: error,
        stackTrace: stackTrace,
      ));

      return const AgentToolExecutionResult(resultStatus: .executionError);
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
