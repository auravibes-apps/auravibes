import 'dart:convert';

import 'package:auravibes_engine/src/skills/skill_command.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:crypto/crypto.dart';

enum AgentToolGrantLevel { once, conversation }

String toolCallApprovalDigest({
  required String messageId,
  required String toolName,
  required String argumentsRaw,
}) {
  final canonicalArguments = _canonicalArguments(argumentsRaw);
  return sha256
      .convert(
        utf8.encode('$messageId\u0000$toolName\u0000$canonicalArguments'),
      )
      .toString();
}

String _canonicalArguments(String argumentsRaw) {
  try {
    return jsonEncode(_canonicalJsonValue(jsonDecode(argumentsRaw)));
  } on FormatException {
    return argumentsRaw;
  }
}

Object? _canonicalJsonValue(Object? value) => switch (value) {
  final Map<String, dynamic> map => _canonicalJsonMap(map),
  final List<dynamic> list => list.map(_canonicalJsonValue).toList(),
  _ => value,
};

Map<String, Object?> _canonicalJsonMap(Map<String, dynamic> map) {
  final keys = map.keys.toList()..sort();

  return {for (final key in keys) key: _canonicalJsonValue(map[key])};
}

typedef AgentToolCallResultUpdateRequest = ({
  String messageId,
  String toolCallId,
  String conversationId,
  AgentToolResultStatus resultStatus,
  String? responseRaw,
});

class const AgentApprovableToolCall({
  required final String conversationId,
  required final String name,
  required final String argumentsRaw,
});

abstract interface class ApproveToolCallProvider<TTool extends Object> {
  Future<AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  });

  Future<TTool?> resolveTool({
    required String conversationId,
    required String toolName,
    required String argumentsRaw,
  });

  Future<void> grantToolForConversation({
    required String conversationId,
    required TTool tool,
  });

  Future<Object?> runResolvedTool({
    required String conversationId,
    required TTool tool,
    required Map<String, dynamic> arguments,
  });

  Future<void> markToolCallRunning({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  });

  Future<void> updateToolCallResult(AgentToolCallResultUpdateRequest request);

  Future<void> resumeConversationIfReady({
    required String messageId,
    required String conversationId,
  });

  bool isCancellationRequested(String conversationId);

  void logToolExecutionError(AgentToolExecutionErrorRequest<TTool> request);
}

abstract interface class SkipToolCallProvider {
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  });

  Future<void> resumeConversationIfReady({
    required String messageId,
    required String conversationId,
  });
}

abstract interface class StopPendingToolCallsProvider {
  Future<void> stopPendingToolCalls({
    required String messageId,
    required String conversationId,
  });
}

class const ApproveToolCallService<TTool extends Object>({
  required final ApproveToolCallProvider<TTool> provider,
}) {
  Future<void> call({
    required String toolCallId,
    required String messageId,
    required String conversationId,
    required AgentToolGrantLevel level,
    required String approvalDigest,
  }) async {
    final toolCall = await provider.loadToolCall(
      messageId: messageId,
      toolCallId: toolCallId,
      conversationId: conversationId,
    );
    if (toolCall == null) return;
    if (toolCall.conversationId != conversationId) {
      throw StateError('Tool call does not belong to conversation.');
    }
    if (toolCallApprovalDigest(
          messageId: messageId,
          toolName: toolCall.name,
          argumentsRaw: toolCall.argumentsRaw,
        ) !=
        approvalDigest) {
      throw StateError('Tool call no longer matches the approved request.');
    }

    final tool = await provider.resolveTool(
      conversationId: toolCall.conversationId,
      toolName: toolCall.name,
      argumentsRaw: toolCall.argumentsRaw,
    );
    if (tool == null) {
      await provider.updateToolCallResult((
        messageId: messageId,
        toolCallId: toolCallId,
        resultStatus: toolCall.name == callSkillToolName
            ? .notConfigured
            : .toolNotFound,
        conversationId: conversationId,
        responseRaw: null,
      ));
      await provider.resumeConversationIfReady(
        messageId: messageId,
        conversationId: conversationId,
      );

      return;
    }

    if (level == AgentToolGrantLevel.conversation) {
      await provider.grantToolForConversation(
        conversationId: toolCall.conversationId,
        tool: tool,
      );
    }

    await provider.markToolCallRunning(
      messageId: messageId,
      toolCallId: toolCallId,
      conversationId: conversationId,
    );

    final executionResult = await _executeTool(
      conversationId: toolCall.conversationId,
      toolCallId: toolCallId,
      tool: tool,
      argumentsRaw: toolCall.argumentsRaw,
    );

    await provider.updateToolCallResult((
      messageId: messageId,
      toolCallId: toolCallId,
      conversationId: conversationId,
      resultStatus: executionResult.resultStatus,
      responseRaw: executionResult.responseRaw,
    ));

    if (provider.isCancellationRequested(toolCall.conversationId)) return;

    await provider.resumeConversationIfReady(
      messageId: messageId,
      conversationId: conversationId,
    );
  }

  Future<AgentToolExecutionResult> _executeTool({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required String argumentsRaw,
  }) {
    return AgentToolExecutionDispatcher<TTool>(
      runResolvedTool: provider.runResolvedTool,
      isCancellationRequested: provider.isCancellationRequested,
      logToolExecutionError: provider.logToolExecutionError,
    ).call(
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
      argumentsRaw: argumentsRaw,
    );
  }
}

class const SkipToolCallService({
  required final SkipToolCallProvider provider,
}) {
  Future<void> call({
    required String toolCallId,
    required String messageId,
    required String conversationId,
  }) async {
    final skipped = await provider.skipToolCall(
      messageId: messageId,
      toolCallId: toolCallId,
      conversationId: conversationId,
    );
    if (!skipped) return;

    await provider.resumeConversationIfReady(
      messageId: messageId,
      conversationId: conversationId,
    );
  }
}
