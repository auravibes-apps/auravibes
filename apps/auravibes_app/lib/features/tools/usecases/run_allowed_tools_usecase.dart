import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:riverpod/riverpod.dart';

class RunAllowedToolsUsecase {
  const RunAllowedToolsUsecase({
    required this.messageRepository,
  });

  final MessageRepository messageRepository;
  Future<void> call({
    required String conversationId,
  }) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    ); // TODO: only get latest

    if (messages.isEmpty) {
      throw Exception('No messages found for conversation');
    }

    final lastMessage = messages.last;

    final toolCalls = lastMessage.metadata?.toolCalls;
    if (toolCalls == null || toolCalls.isEmpty) {
      throw Exception('No tools to run');
    }
    final hasUnresolvedToolCalls = toolCalls.any((element) {
      return !element.isResolved;
    });
    if (hasUnresolvedToolCalls) {
      throw Exception('There are unresolved tools to run');
    }

    final resolver = ToolResolverService();

    final mapedToolsResolved = toolCalls.asMap().map(
      (key, value) {
        final tool = resolver.resolveTool(value.name);

        if (tool == null) return MapEntry(value.name, null);

        return MapEntry(
          value.id,
          ToolToCall(
            tool: tool,
            argumentsRaw: value.argumentsRaw,
            id: value.id,
          ),
        );
      },
    );

    // load the tools to run for last message of conversation
  }
}

final runAllowedToolsUsecaseProvider = Provider<RunAllowedToolsUsecase>((ref) {
  return RunAllowedToolsUsecase(
    messageRepository: ref.watch(messageRepositoryProvider),
  );
});
