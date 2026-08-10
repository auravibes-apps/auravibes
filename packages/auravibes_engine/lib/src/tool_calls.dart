enum AgentToolCallLifecycle {
  pending,
  success,
  skippedByUser,
  stoppedByUser,
  failed,
}

extension AgentToolCallLifecycleX on AgentToolCallLifecycle {
  bool get isPending => this == AgentToolCallLifecycle.pending;
  bool get isResolved => !isPending;
  bool get stopsAgentLoop => this == AgentToolCallLifecycle.stoppedByUser;

  String get modelFallback => switch (this) {
    AgentToolCallLifecycle.pending || AgentToolCallLifecycle.success => '',
    AgentToolCallLifecycle.skippedByUser => 'Tool was skipped by the user.',
    AgentToolCallLifecycle.stoppedByUser =>
      'Tool execution was stopped by the user.',
    AgentToolCallLifecycle.failed => 'Tool execution failed.',
  };

  bool canTransitionTo(AgentToolCallLifecycle next) => switch (this) {
    AgentToolCallLifecycle.pending => next != AgentToolCallLifecycle.pending,
    _ => false,
  };
}

class AgentMessageToolCall {
  const AgentMessageToolCall({
    required this.id,
    required this.name,
    required this.argumentsRaw,
    this.lifecycle = AgentToolCallLifecycle.pending,
  });

  final String id;
  final String name;
  final String argumentsRaw;
  final AgentToolCallLifecycle lifecycle;

  bool get isPending => lifecycle.isPending;
  bool get isResolved => lifecycle.isResolved;
}

class AgentToolMessage {
  const AgentToolMessage({
    required this.id,
    required this.isUser,
    this.toolCalls = const [],
  });

  final String id;
  final bool isUser;
  final List<AgentMessageToolCall> toolCalls;
}

class AgentToolToCall<TTool extends Object> {
  const AgentToolToCall({
    required this.tool,
    required this.id,
    required this.argumentsRaw,
  });

  final TTool tool;
  final String id;
  final String argumentsRaw;
}

class LoadLatestMessageToolCallsResult<TTool extends Object> {
  const LoadLatestMessageToolCallsResult({
    required this.messageId,
    required this.hasToolCalls,
    required this.toolsToRun,
    required this.notFoundToolCallIds,
    required this.previouslyFailedToolCallIds,
  });

  final String messageId;
  final bool hasToolCalls;
  final List<AgentToolToCall<TTool>> toolsToRun;
  final List<String> notFoundToolCallIds;
  final List<String> previouslyFailedToolCallIds;
}

abstract interface class AgentToolCallProvider<TTool extends Object> {
  Future<List<AgentToolMessage>> loadMessages(String conversationId);

  Future<TTool?> resolveTool({
    required String conversationId,
    required String toolName,
  });
}

class AgentToolCallLoader<TTool extends Object> {
  const AgentToolCallLoader({
    required this.provider,
  });

  final AgentToolCallProvider<TTool> provider;

  Future<LoadLatestMessageToolCallsResult<TTool>> call({
    required String conversationId,
  }) async {
    final messages = await provider.loadMessages(conversationId);
    final latestAssistantMessage = messages.lastWhere(
      (message) => !message.isUser,
      orElse: () =>
          throw Exception('No assistant message found for conversation'),
    );

    final toolCalls = latestAssistantMessage.toolCalls;
    if (toolCalls.isEmpty) {
      return LoadLatestMessageToolCallsResult(
        messageId: latestAssistantMessage.id,
        hasToolCalls: false,
        toolsToRun: const [],
        notFoundToolCallIds: const [],
        previouslyFailedToolCallIds: const [],
      );
    }

    final toolsToRun = <AgentToolToCall<TTool>>[];
    final notFoundToolCallIds = <String>[];
    final previouslyFailedToolCallIds = <String>[];
    final failedToolCalls = _collectFailedToolCalls(
      messages,
      excludeMessageId: latestAssistantMessage.id,
    );

    for (final toolCall in toolCalls.where((toolCall) => toolCall.isPending)) {
      if (failedToolCalls.contains(_toolCallIdentity(toolCall))) {
        previouslyFailedToolCallIds.add(toolCall.id);
        continue;
      }

      final resolvedTool = await provider.resolveTool(
        conversationId: conversationId,
        toolName: toolCall.name,
      );
      if (resolvedTool == null) {
        notFoundToolCallIds.add(toolCall.id);
        continue;
      }

      toolsToRun.add(
        AgentToolToCall(
          tool: resolvedTool,
          id: toolCall.id,
          argumentsRaw: toolCall.argumentsRaw,
        ),
      );
    }

    return LoadLatestMessageToolCallsResult(
      messageId: latestAssistantMessage.id,
      hasToolCalls: true,
      toolsToRun: toolsToRun,
      notFoundToolCallIds: notFoundToolCallIds,
      previouslyFailedToolCallIds: previouslyFailedToolCallIds,
    );
  }

  Set<({String argumentsRaw, String name})> _collectFailedToolCalls(
    List<AgentToolMessage> messages, {
    required String excludeMessageId,
  }) {
    final excludeIndex = messages.indexWhere(
      (message) => message.id == excludeMessageId,
    );
    if (excludeIndex == -1) return const {};

    final startIndex = _findFailedToolScanStart(messages, excludeIndex);
    final latestStatusByToolCall = _collectLatestToolStatuses(
      messages,
      startIndex: startIndex,
      endIndex: excludeIndex,
    );

    return _failedToolCalls(latestStatusByToolCall);
  }

  int _findFailedToolScanStart(
    List<AgentToolMessage> messages,
    int excludeIndex,
  ) {
    var userCount = 0;
    for (var i = excludeIndex - 1; i >= 0; i--) {
      if (!messages[i].isUser) continue;

      userCount++;
      if (userCount == 2) return i + 1;
    }

    return 0;
  }

  Map<({String argumentsRaw, String name}), AgentToolCallLifecycle>
  _collectLatestToolStatuses(
    List<AgentToolMessage> messages, {
    required int startIndex,
    required int endIndex,
  }) {
    final latestStatusByToolCall =
        <({String argumentsRaw, String name}), AgentToolCallLifecycle>{};
    for (var i = startIndex; i < endIndex; i++) {
      final message = messages[i];
      if (message.isUser) continue;
      for (final toolCall in message.toolCalls) {
        if (toolCall.isPending) continue;
        latestStatusByToolCall[_toolCallIdentity(toolCall)] =
            toolCall.lifecycle;
      }
    }

    return latestStatusByToolCall;
  }

  Set<({String argumentsRaw, String name})> _failedToolCalls(
    Map<({String argumentsRaw, String name}), AgentToolCallLifecycle>
    latestStatusByToolCall,
  ) {
    final failedCalls = <({String argumentsRaw, String name})>{};
    latestStatusByToolCall.forEach((toolCall, status) {
      if (status != AgentToolCallLifecycle.success &&
          status != AgentToolCallLifecycle.skippedByUser &&
          status != AgentToolCallLifecycle.stoppedByUser) {
        final _ = failedCalls.add(toolCall);
      }
    });

    return failedCalls;
  }
}

({String argumentsRaw, String name}) _toolCallIdentity(
  AgentMessageToolCall toolCall,
) {
  return (name: toolCall.name, argumentsRaw: toolCall.argumentsRaw);
}
