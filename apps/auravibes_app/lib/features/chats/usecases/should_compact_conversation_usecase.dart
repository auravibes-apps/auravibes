// Required: Existing thresholds and limits use numeric values.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/chats/agent_adapters/message_transcript_snapshot_mapper.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
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

    final context = MessageTranscriptSnapshotMapper.toAgentContextSnapshot(
      messages,
    );
    if (!isContextSafeForCompaction(context)) {
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

    final effectiveRemainingThreshold =
        settings.remainingTokenThreshold ==
            CompactionSettings.defaults.remainingTokenThreshold
        ? defaultRemainingTokenThreshold(
            maxOutputTokens: maxOutputTokens,
            contextLimit: effectiveContextLimit,
          )
        : settings.remainingTokenThreshold;
    final evaluation = evaluateContextCompaction(
      context: context,
      usagePercentageThreshold: settings.usagePercentageThreshold,
      remainingTokenThreshold: effectiveRemainingThreshold,
      contextLimit: effectiveContextLimit,
    );
    final usage = evaluation.usage;
    final estimate = ConversationPromptEstimate(
      conversationId: conversationId,
      selectedModelId: selectedModelId,
      selectedProviderId: selectedProviderId,
      estimatedPromptTokens: usage.usedTokens,
      maxOutputTokens: maxOutputTokens,
      contextLimit: usage.contextLimit,
      remainingTokens: usage.remainingTokens,
      usagePercentage: usage.usagePercentage,
    );

    if (evaluation.shouldCompact) {
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
