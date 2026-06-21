// Required: Existing thresholds and limits use numeric values.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class ShouldCompactConversationUsecase {
  const ShouldCompactConversationUsecase({
    required this.messageRepository,
    required this.settingsRepository,
  });

  final MessageRepository messageRepository;
  final WorkspaceCompactionSettingsRepository settingsRepository;

  Future<CompactionDecision> call({
    required String conversationId,
    required String workspaceId,
    required String selectedModelId,
    required String selectedProviderId,
    required int maxOutputTokens,
    int? contextLimit,
    CompactionTrigger trigger = CompactionTrigger.auto,
  }) async {
    final settings = await settingsRepository.getEffectiveSettings(workspaceId);

    if (trigger == CompactionTrigger.auto && !settings.autoCompactionEnabled) {
      return CompactionDecision(
        shouldCompact: false,
        reason: CompactionDecisionReason.disabled,
        trigger: trigger,
        settings: settings,
      );
    }

    if (trigger == CompactionTrigger.auto && contextLimit == null) {
      return CompactionDecision(
        shouldCompact: false,
        reason: CompactionDecisionReason.unknownContextLimit,
        trigger: trigger,
        settings: settings,
      );
    }

    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    if (_hasUnsafeState(messages)) {
      return CompactionDecision(
        shouldCompact: false,
        reason: CompactionDecisionReason.unsafeState,
        trigger: trigger,
        settings: settings,
      );
    }

    if (trigger == CompactionTrigger.manual) {
      return CompactionDecision(
        shouldCompact: true,
        reason: CompactionDecisionReason.eligible,
        trigger: trigger,
        settings: settings,
      );
    }

    final effectiveContextLimit = contextLimit;
    if (effectiveContextLimit == null) {
      return CompactionDecision(
        shouldCompact: false,
        reason: CompactionDecisionReason.unknownContextLimit,
        trigger: trigger,
        settings: settings,
      );
    }

    final estimate = await _buildEstimate(
      conversationId: conversationId,
      selectedModelId: selectedModelId,
      selectedProviderId: selectedProviderId,
      maxOutputTokens: maxOutputTokens,
      contextLimit: effectiveContextLimit,
      messages: messages,
    );

    final usagePercentage = estimate.usagePercentage ?? 0;
    final remainingTokens = estimate.remainingTokens ?? 0;

    final effectiveRemainingThreshold =
        settings.remainingTokenThreshold ==
            CompactionSettings.defaults.remainingTokenThreshold
        ? CompactionSettings.defaultRemainingTokenThreshold(
            maxOutputTokens: maxOutputTokens,
            contextLimit: effectiveContextLimit,
          )
        : settings.remainingTokenThreshold;

    final meetsUsageThreshold =
        usagePercentage >= settings.usagePercentageThreshold;
    final meetsRemainingThreshold =
        remainingTokens <= effectiveRemainingThreshold;

    if (meetsUsageThreshold || meetsRemainingThreshold) {
      return CompactionDecision(
        shouldCompact: true,
        reason: CompactionDecisionReason.eligible,
        trigger: trigger,
        estimate: estimate,
        settings: settings,
      );
    }

    return CompactionDecision(
      shouldCompact: false,
      reason: CompactionDecisionReason.belowPercentageThreshold,
      trigger: trigger,
      estimate: estimate,
      settings: settings,
    );
  }

  Future<ConversationPromptEstimate> _buildEstimate({
    required String conversationId,
    required String selectedModelId,
    required String selectedProviderId,
    required int maxOutputTokens,
    required int contextLimit,
    required List<MessageEntity> messages,
  }) async {
    final totalTokens = _estimateTokensFromMessages(messages);
    final remainingTokens = contextLimit - totalTokens;
    final usagePercentage = contextLimit > 0
        ? (totalTokens / contextLimit) * 100
        : 0.0;

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

  int _estimateTokensFromMessages(List<MessageEntity> messages) {
    for (final message in messages.reversed) {
      final tokens = message.metadata?.usedTokens ?? 0;
      if (tokens > 0) return tokens;
    }

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

    return (charCount / 4).ceil();
  }

  bool _hasUnsafeState(List<MessageEntity> messages) {
    for (final message in messages) {
      if (message.status == MessageStatus.sending ||
          message.status == MessageStatus.unfinished) {
        return true;
      }

      if (!message.isUser) {
        final toolCalls = message.metadata?.toolCalls;
        if (toolCalls != null) {
          final hasPending = toolCalls.any((tc) => tc.isPending);
          if (hasPending) return true;
        }
      }
    }

    return false;
  }
}

final shouldCompactConversationUsecaseProvider =
    Provider<ShouldCompactConversationUsecase>((ref) {
      return ShouldCompactConversationUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        settingsRepository: ref.watch(
          workspaceCompactionSettingsRepositoryProvider,
        ),
      );
    });
