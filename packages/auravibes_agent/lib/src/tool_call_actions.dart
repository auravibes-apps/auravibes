import 'package:auravibes_agent/src/agent_tool_execution_service.dart';

enum AgentToolGrantLevel { once, conversation }

class AgentApprovableToolCall {
  const AgentApprovableToolCall({
    required this.conversationId,
    required this.name,
    required this.argumentsRaw,
  });

  final String conversationId;
  final String name;
  final String argumentsRaw;
}

abstract interface class ApproveToolCallProvider<TTool extends Object> {
  Future<AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
  });

  TTool? resolveTool(String toolName);

  Future<void> grantToolForConversation({
    required String conversationId,
    required TTool tool,
  });

  Future<Object?> runResolvedTool({
    required String conversationId,
    required TTool tool,
    required Map<String, dynamic> arguments,
  });

  Future<void> updateToolCallResult({
    required String messageId,
    required String toolCallId,
    required AgentToolResultStatus resultStatus,
    String? responseRaw,
  });

  Future<void> resumeConversationIfReady({required String messageId});

  bool isCancellationRequested(String conversationId);

  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required Object error,
    required StackTrace stackTrace,
  });
}

abstract interface class SkipToolCallProvider {
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
  });

  Future<void> resumeConversationIfReady({required String messageId});
}

// ignore: one_member_abstracts, provider interface keeps DB writes injectable.
abstract interface class StopPendingToolCallsProvider {
  Future<void> stopPendingToolCalls({required String messageId});
}

class ApproveToolCallService<TTool extends Object> {
  const ApproveToolCallService({
    required this.provider,
  });

  final ApproveToolCallProvider<TTool> provider;

  Future<void> call({
    required String toolCallId,
    required String messageId,
    required AgentToolGrantLevel level,
  }) async {
    final toolCall = await provider.loadToolCall(
      messageId: messageId,
      toolCallId: toolCallId,
    );
    if (toolCall == null) return;

    final tool = provider.resolveTool(toolCall.name);
    if (tool == null) {
      await provider.updateToolCallResult(
        messageId: messageId,
        toolCallId: toolCallId,
        resultStatus: AgentToolResultStatus.toolNotFound,
      );
      await provider.resumeConversationIfReady(messageId: messageId);

      return;
    }

    if (level == AgentToolGrantLevel.conversation) {
      await provider.grantToolForConversation(
        conversationId: toolCall.conversationId,
        tool: tool,
      );
    }

    final executionResult = await _executeTool(
      conversationId: toolCall.conversationId,
      toolCallId: toolCallId,
      tool: tool,
      argumentsRaw: toolCall.argumentsRaw,
    );

    await provider.updateToolCallResult(
      messageId: messageId,
      toolCallId: toolCallId,
      resultStatus: executionResult.resultStatus,
      responseRaw: executionResult.responseRaw,
    );

    if (provider.isCancellationRequested(toolCall.conversationId)) return;

    await provider.resumeConversationIfReady(messageId: messageId);
  }

  Future<AgentToolExecutionResult> _executeTool({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required String argumentsRaw,
  }) async {
    final arguments = safeJsonDecodeToolArguments(argumentsRaw);

    try {
      final result = await provider.runResolvedTool(
        conversationId: conversationId,
        tool: tool,
        arguments: arguments,
      );
      if (provider.isCancellationRequested(conversationId)) {
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
      provider.logToolExecutionError(
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
      provider.logToolExecutionError(
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

class SkipToolCallService {
  const SkipToolCallService({
    required this.provider,
  });

  final SkipToolCallProvider provider;

  Future<void> call({
    required String toolCallId,
    required String messageId,
  }) async {
    final skipped = await provider.skipToolCall(
      messageId: messageId,
      toolCallId: toolCallId,
    );
    if (!skipped) return;

    await provider.resumeConversationIfReady(messageId: messageId);
  }
}
