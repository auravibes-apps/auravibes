import 'package:auravibes_app/domain/entities/messages.dart';
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
  });

  final String messageId;
  final bool hasToolCalls;
  final List<ToolToCall> toolsToRun;
  final List<String> notFoundToolCallIds;
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
      );
    }

    final toolsToRun = <ToolToCall>[];
    final notFoundToolCallIds = <String>[];

    for (final toolCall in toolCalls.where((toolCall) => toolCall.isPending)) {
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
    );
  }
}

final loadLatestMessageToolCallsUsecaseProvider =
    Provider<LoadLatestMessageToolCallsUsecase>((ref) {
      return LoadLatestMessageToolCallsUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        toolResolverService: ToolResolverService(),
      );
    });
