import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/tool_content_digest.dart';
import 'package:auravibes_engine/src/tool_output_policy.dart';

enum AgentToolResultStatus {
  success,
  toolNotFound,
  executionError,
  uncertain,
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
    .executionError =>
      'Tool execution failed. Read the tool error and use a corrected request '
          'or a different approach.',
    .uncertain =>
      'Write outcome is uncertain. Do not retry before reconciliation.',
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
  final String? outputDigest,
  final List<AgentToolResultMedia> media = const [],
  final bool outputTruncated = false,
  final int? originalResponseBytes,
  final bool fullOutputForContext = false,
});

class const AgentToolExecutionOutput({
  required final Object output,
  final List<AgentToolResultMedia> media = const [],
});

class const AgentToolResultMedia({
  required final Uint8List bytes,
  required final String mimeType,
  required final String fileName,
});

class const AgentToolExecutionFailure({
  required final String responseRaw,
  required final Object error,
  required final StackTrace stackTrace,
  required final String failurePhase,
  final AgentToolResultStatus resultStatus =
      AgentToolResultStatus.executionError,
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
  final bool captureOutputDigest = false,
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

      final executionOutput = switch (result) {
        final AgentToolExecutionOutput output => output,
        final Object output => AgentToolExecutionOutput(output: output),
      };
      final responseRaw = switch (executionOutput.output) {
        final String value => value,
        final Map<Object?, Object?> value => jsonEncode(value),
        final List<Object?> value => jsonEncode(value),
        final Object value => value.toString(),
      };
      final outputDigest = captureOutputDigest ? sha256Utf8(responseRaw) : null;
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
          outputDigest: outputDigest,
          media: executionOutput.media,
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
        outputDigest: outputDigest,
        media: executionOutput.media,
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
        responseRaw:
            '{"outcome":"failed","code":"invalid_request","error":"Tool '
            'rejected the request format.","nextAction":"Check this tool\'s '
            'schema and send a corrected request."}',
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

      try {
        final projection = projectToolOutput(
          failure.responseRaw,
          policy:
              outputPolicyForTool?.call(tool) ?? const AgentToolOutputPolicy(),
        );
        return AgentToolExecutionResult(
          resultStatus: failure.resultStatus,
          responseRaw: projection.persistedText,
          responseContextRaw: _responseContext(projection),
          outputDigest: captureOutputDigest
              ? sha256Utf8(failure.responseRaw)
              : null,
          outputTruncated: projection.truncated,
          originalResponseBytes: projection.truncated
              ? projection.originalBytes
              : null,
          fullOutputForContext: projection.fullOutputForContext,
        );
      } on Object {
        return const AgentToolExecutionResult(
          resultStatus: .executionError,
          responseRaw:
              '{"outcome":"failed","code":"execution_error","error":"Tool '
              'returned an unreadable error result.","nextAction":"Use a '
              'different approach; do not repeat the unchanged request."}',
        );
      }
    } on Object catch (error, stackTrace) {
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
        responseRaw:
            '{"outcome":"failed","code":"execution_error","error":"Tool '
            'could not complete the request.","nextAction":"Check the tool '
            'result and try a different approach; '
            'do not repeat the unchanged request."}',
      );
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
