import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';

class const AgentToolBatchCall<TTool extends Object>({
  required final String conversationId,
  required final String messageId,
  required final String toolCallId,
  required final TTool tool,
  required final String argumentsRaw,
});

class const AgentToolBatchResult<TTool extends Object>({
  required final AgentToolBatchCall<TTool> call,
  required final AgentToolExecutionResult result,
});

typedef AgentToolBatchResultHandler<TTool extends Object> =
    Future<void> Function(AgentToolBatchResult<TTool> result);

class const AgentToolBatchExecutor<TTool extends Object>({
  required final AgentResolvedToolRunner<TTool> runResolvedTool,
  required final AgentToolCancellationChecker isCancellationRequested,
  required final AgentToolExecutionErrorLogger<TTool> logToolExecutionError,
}) {
  Future<List<AgentToolBatchResult<TTool>>> call(
    Iterable<AgentToolBatchCall<TTool>> calls, {
    AgentToolBatchResultHandler<TTool>? onResult,
  }) => Future.wait(
    calls.map((call) async {
      final result =
          await AgentToolExecutionDispatcher<TTool>(
            runResolvedTool: runResolvedTool,
            isCancellationRequested: isCancellationRequested,
            logToolExecutionError: logToolExecutionError,
          ).call(
            conversationId: call.conversationId,
            toolCallId: call.toolCallId,
            tool: call.tool,
            argumentsRaw: call.argumentsRaw,
          );
      final batchResult = AgentToolBatchResult(call: call, result: result);
      if (onResult != null) await onResult(batchResult);

      return batchResult;
    }),
  );
}
