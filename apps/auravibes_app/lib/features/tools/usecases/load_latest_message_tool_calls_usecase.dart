import 'package:auravibes_app/domain/entities/messages.dart';
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

    final failedToolNames = _collectFailedToolNames(
      messages,
      excludeMessageId: latestAssistantMessage.id,
    );

    for (final toolCall in toolCalls.where((toolCall) => toolCall.isPending)) {
      if (failedToolNames.contains(toolCall.name)) {
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

  Set<String> _collectFailedToolNames(
    List<MessageEntity> messages, {
    required String excludeMessageId,
  }) {
    final excludeIndex = messages.indexWhere(
      (m) => m.id == excludeMessageId,
    );
    if (excludeIndex == -1) return const {};

    var startIndex = 0;
    var userCount = 0;
    for (var i = excludeIndex - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        userCount++;
        if (userCount == 2) {
          startIndex = i + 1;
          break;
        }
      }
    }
    if (userCount < 2) {
      startIndex = 0;
    }

    final latestStatusByToolName = <String, ToolCallResultStatus>{};
    for (var i = startIndex; i < excludeIndex; i++) {
      final message = messages[i];
      if (message.isUser) continue;
      final toolCalls = message.metadata?.toolCalls ?? const [];
      for (final toolCall in toolCalls) {
        final status = toolCall.resultStatus;
        if (status == null) continue;
        latestStatusByToolName[toolCall.name] = status;
      }
    }

    final failedNames = <String>{};
    latestStatusByToolName.forEach((toolName, status) {
      if (status != ToolCallResultStatus.success &&
          status != ToolCallResultStatus.skippedByUser &&
          status != ToolCallResultStatus.stoppedByUser) {
        failedNames.add(toolName);
      }
    });
    return failedNames;
  }
}

final loadLatestMessageToolCallsUsecaseProvider =
    Provider<LoadLatestMessageToolCallsUsecase>((ref) {
      return LoadLatestMessageToolCallsUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        toolResolverService: ToolResolverService(),
      );
    });
