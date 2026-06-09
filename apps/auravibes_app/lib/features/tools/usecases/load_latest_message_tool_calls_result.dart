// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:riverpod/riverpod.dart';

class LoadLatestMessageToolCallsResult {
  const LoadLatestMessageToolCallsResult({
    required this.messageId,
    required this.hasToolCalls,
    required this.toolsToRun,
    required this.notFoundToolCallIds,
    required this.previouslyFailedToolCallIds,
  });

  final String messageId;
  final bool hasToolCalls;
  final List<ToolToCall> toolsToRun;
  final List<String> notFoundToolCallIds;
  final List<String> previouslyFailedToolCallIds;
}

class LoadLatestMessageToolCallsUsecase {
  const LoadLatestMessageToolCallsUsecase({
    required this.messageRepository,
    required this.toolResolverService,
  });

  final MessageRepository messageRepository;
  final ToolResolverService toolResolverService;

  Future<LoadLatestMessageToolCallsResult> call({
    required String conversationId,
  }) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );
    final latestAssistantMessage = messages.lastWhere(
      (message) => !message.isUser,
      orElse: () =>
          throw Exception('No assistant message found for conversation'),
    );

    final toolCalls = latestAssistantMessage.metadata?.toolCalls ?? const [];
    if (toolCalls.isEmpty) {
      return LoadLatestMessageToolCallsResult(
        messageId: latestAssistantMessage.id,
        hasToolCalls: false,
        toolsToRun: const [],
        notFoundToolCallIds: const [],
        previouslyFailedToolCallIds: const [],
      );
    }

    final toolsToRun = <ToolToCall>[];
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

      final resolvedTool = toolResolverService.resolveTool(toolCall.name);
      if (resolvedTool == null) {
        notFoundToolCallIds.add(toolCall.id);
        continue;
      }

      toolsToRun.add(
        ToolToCall(
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
    List<MessageEntity> messages, {
    required String excludeMessageId,
  }) {
    final excludeIndex = messages.indexWhere(
      (m) => m.id == excludeMessageId,
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
    List<MessageEntity> messages,
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

  Map<({String argumentsRaw, String name}), ToolCallResultStatus>
  _collectLatestToolStatuses(
    List<MessageEntity> messages, {
    required int startIndex,
    required int endIndex,
  }) {
    final latestStatusByToolCall =
        <({String argumentsRaw, String name}), ToolCallResultStatus>{};
    for (var i = startIndex; i < endIndex; i++) {
      final message = messages[i];
      if (message.isUser) continue;
      final toolCalls = message.metadata?.toolCalls ?? const [];
      for (final toolCall in toolCalls) {
        final status = toolCall.resultStatus;
        if (status == null) continue;
        latestStatusByToolCall[_toolCallIdentity(toolCall)] = status;
      }
    }

    return latestStatusByToolCall;
  }

  Set<({String argumentsRaw, String name})> _failedToolCalls(
    Map<({String argumentsRaw, String name}), ToolCallResultStatus>
    latestStatusByToolCall,
  ) {
    final failedCalls = <({String argumentsRaw, String name})>{};
    latestStatusByToolCall.forEach((toolCall, status) {
      if (status != ToolCallResultStatus.success &&
          status != ToolCallResultStatus.skippedByUser &&
          status != ToolCallResultStatus.stoppedByUser) {
        final _ = failedCalls.add(toolCall);
      }
    });

    return failedCalls;
  }
}

({String argumentsRaw, String name}) _toolCallIdentity(
  MessageToolCallEntity toolCall,
) {
  return (name: toolCall.name, argumentsRaw: toolCall.argumentsRaw);
}

final loadLatestMessageToolCallsUsecaseProvider =
    Provider<LoadLatestMessageToolCallsUsecase>((ref) {
      return LoadLatestMessageToolCallsUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        toolResolverService: ToolResolverService(),
      );
    });
