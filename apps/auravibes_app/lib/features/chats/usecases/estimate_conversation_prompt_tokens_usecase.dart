import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class EstimateConversationPromptTokensUsecase {
  const EstimateConversationPromptTokensUsecase({
    required this.messageRepository,
  });

  final MessageRepository messageRepository;

  static const int _fallbackCharsPerToken = 4;

  Future<ConversationPromptEstimate> call({
    required String conversationId,
    required String selectedModelId,
    required String selectedProviderId,
    required int maxOutputTokens,
    int? contextLimit,
  }) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    final totalTokens = _estimateTokens(messages, contextLimit);

    final remainingTokens = contextLimit != null
        ? contextLimit - totalTokens
        : null;
    final usagePercentage = contextLimit != null && contextLimit > 0
        ? (totalTokens / contextLimit) * 100
        : null;

    return ConversationPromptEstimate(
      conversationId: conversationId,
      selectedModelId: selectedModelId,
      selectedProviderId: selectedProviderId,
      estimatedPromptTokens: totalTokens,
      maxOutputTokens: maxOutputTokens,
      contextLimit: contextLimit,
      remainingTokens: remainingTokens,
      usagePercentage: usagePercentage,
    );
  }

  int _estimateTokens(List<MessageEntity> messages, int? contextLimit) {
    var totalFromUsage = 0;
    var hasUsageData = false;

    for (final message in messages.reversed) {
      final tokens = message.metadata?.usedTokens ?? 0;
      if (tokens > 0) {
        totalFromUsage = tokens;
        hasUsageData = true;
        break;
      }
    }

    if (hasUsageData) return totalFromUsage;

    var charCount = 0;
    for (final message in messages) {
      charCount += message.content.length;
      final toolCalls = message.metadata?.toolCalls;
      if (toolCalls != null) {
        for (final tc in toolCalls) {
          charCount += tc.argumentsRaw.length;
          charCount += tc.responseRaw?.length ?? 0;
        }
      }
    }

    return (charCount / _fallbackCharsPerToken).ceil();
  }
}

final estimateConversationPromptTokensUsecaseProvider =
    Provider<EstimateConversationPromptTokensUsecase>((ref) {
      return EstimateConversationPromptTokensUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
      );
    });
