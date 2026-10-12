import 'dart:convert';

import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/tool_output_policy.dart';

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
  final String? responseContextRaw,
  final bool outputTruncated = false,
  final int? originalResponseBytes,
  final bool fullOutputForContext = false,
});

class const AgentToolExecutionFailure({
  required final String responseRaw,
  required final Object error,
  required final StackTrace stackTrace,
  required final String failurePhase,
}) implements Exception;

typedef AgentToolExecutionErrorRequest<TTool extends Object> = ({
  String conversationId,
  String toolCallId,
  TTool tool,
  Object error,
  StackTrace stackTrace,
  String? failurePhase,
});

typedef AgentResolvedToolRunner<TTool extends Object> =
    Future<Object?> Function({
      required String conversationId,
      required String toolCallId,
      required TTool tool,
      required Map<String, dynamic> arguments,
    });

typedef AgentToolCancellationChecker = bool Function(String conversationId);

typedef AgentToolOutputPolicyResolver<TTool extends Object> =
    AgentToolOutputPolicy Function(TTool tool);

typedef AgentToolExecutionErrorLogger<TTool extends Object> = void Function(
  AgentToolExecutionErrorRequest<TTool> request,
);

class const AgentToolExecutionDispatcher<TTool extends Object>({
  required final AgentResolvedToolRunner<TTool> runResolvedTool,
  required final AgentToolCancellationChecker isCancellationRequested,
  required final AgentToolExecutionErrorLogger<TTool> logToolExecutionError,
  final AgentToolOutputPolicyResolver<TTool>? outputPolicyForTool,
}) {
  Future<AgentToolExecutionResult> call({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required String argumentsRaw,
  }) async {
    try {
      if (isCancellationRequested(conversationId)) {
        return const AgentToolExecutionResult(resultStatus: .stoppedByUser);
      }

      final arguments = safeJsonDecodeToolArguments(argumentsRaw);
      final result = await runResolvedTool(
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        arguments: arguments,
      );
      if (result == null) {
        if (isCancellationRequested(conversationId)) {
          return const AgentToolExecutionResult(resultStatus: .stoppedByUser);
        }

        return const AgentToolExecutionResult(resultStatus: .toolNotFound);
      }

      final responseRaw = switch (result) {
        final String value => value,
        final Map<Object?, Object?> value => jsonEncode(value),
        final List<Object?> value => jsonEncode(value),
        _ => result.toString(),
      };
      final projection = projectToolOutput(
        responseRaw,
        policy:
            outputPolicyForTool?.call(tool) ?? const AgentToolOutputPolicy(),
      );
      if (isCancellationRequested(conversationId)) {
        return AgentToolExecutionResult(
          resultStatus: .stoppedByUser,
          responseRaw: projection.persistedText,
          responseContextRaw: _responseContext(projection),
          outputTruncated: projection.truncated,
          originalResponseBytes: projection.truncated
              ? projection.originalBytes
              : null,
          fullOutputForContext: projection.fullOutputForContext,
        );
      }

      return AgentToolExecutionResult(
        resultStatus: .success,
        responseRaw: projection.persistedText,
        responseContextRaw: _responseContext(projection),
        outputTruncated: projection.truncated,
        originalResponseBytes: projection.truncated
            ? projection.originalBytes
            : null,
        fullOutputForContext: projection.fullOutputForContext,
      );
    } on FormatException catch (error, stackTrace) {
      logToolExecutionError((
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        error: error,
        stackTrace: stackTrace,
        failurePhase: null,
      ));

      return const AgentToolExecutionResult(
        resultStatus: .executionError,
        responseRaw: 'Tool execution failed.',
      );
    } on AgentToolExecutionFailure catch (failure) {
      logToolExecutionError((
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        error: failure.error,
        stackTrace: failure.stackTrace,
        failurePhase: failure.failurePhase,
      ));

      final projection = projectToolOutput(failure.responseRaw);
      return AgentToolExecutionResult(
        resultStatus: .executionError,
        responseRaw: projection.persistedText,
        responseContextRaw: _responseContext(projection),
        outputTruncated: projection.truncated,
        originalResponseBytes: projection.truncated
            ? projection.originalBytes
            : null,
        fullOutputForContext: projection.fullOutputForContext,
      );
    } on Object catch (error, stackTrace) {
      logToolExecutionError((
        conversationId: conversationId,
        toolCallId: toolCallId,
        tool: tool,
        error: error,
        stackTrace: stackTrace,
        failurePhase: null,
      ));

      return const AgentToolExecutionResult(resultStatus: .executionError);
    }
  }
}

String? _responseContext(AgentToolOutputProjection projection) =>
    projection.fullOutputForContext ||
        projection.text == projection.persistedText
    ? null
    : projection.text;

Map<String, dynamic> safeJsonDecodeToolArguments(String source) {
  final decoded = jsonDecode(source);
  if (decoded is Map<String, dynamic>) return decoded;

  throw const FormatException('Tool arguments must be a JSON object.');
}
