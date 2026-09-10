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

typedef _CompactionCheckInput = ({
  String conversationId,
  String workspaceId,
  String selectedModelId,
  String selectedProviderId,
  int maxOutputTokens,
  int? contextLimit,
  CompactionTrigger trigger,
});

class const ShouldCompactConversationUsecase({
  required final MessageRepository messageRepository,
  required final WorkspaceCompactionSettingsRepository settingsRepository,
}) {
  Future<CompactionDecision> call(_CompactionCheckInput request) =>
      _shouldCompactConversation((
        usecase: this,
        conversationId: request.conversationId,
        workspaceId: request.workspaceId,
        selectedModelId: request.selectedModelId,
        selectedProviderId: request.selectedProviderId,
        maxOutputTokens: request.maxOutputTokens,
        contextLimit: request.contextLimit,
        trigger: request.trigger,
      ));
}

typedef _CompactionCheckRequest = ({
  ShouldCompactConversationUsecase usecase,
  String conversationId,
  String workspaceId,
  String selectedModelId,
  String selectedProviderId,
  int maxOutputTokens,
  int? contextLimit,
  CompactionTrigger trigger,
});

Future<CompactionDecision> _shouldCompactConversation(
  _CompactionCheckRequest request,
) async {
  final settings = await _loadCompactionSettings(request);
  final blocked = _blockedCompactionDecision(
    settings: settings,
    trigger: request.trigger,
    contextLimit: request.contextLimit,
  );
  if (blocked != null) return blocked;

  return await _decideForMessages(request, settings);
}

Future<CompactionSettings> _loadCompactionSettings(
  _CompactionCheckRequest request,
) => request.usecase.settingsRepository.getEffectiveSettings(
  request.workspaceId,
);

Future<CompactionDecision> _decideForMessages(
  _CompactionCheckRequest request,
  CompactionSettings settings,
) async {
  final messages = await request.usecase.messageRepository
      .getMessagesByConversation(request.conversationId);
  final context = MessageTranscriptSnapshotMapper.toAgentContextSnapshot(
    messages,
  );

  return _decideForContext(request, settings, context);
}

CompactionDecision _decideForContext(
  _CompactionCheckRequest request,
  CompactionSettings settings,
  AgentContextSnapshot context,
) {
  if (!isContextSafeForCompaction(context)) {
    return _unsafeCompactionDecision(request, settings);
  }
  if (request.trigger == CompactionTrigger.manual) {
    return _manualCompactionDecision(request, settings);
  }

  return _evaluateCompaction(request, settings, context);
}

CompactionDecision _unsafeCompactionDecision(
  _CompactionCheckRequest request,
  CompactionSettings settings,
) => CompactionDecision(
  shouldCompact: false,
  reason: .unsafeState,
  trigger: request.trigger,
  settings: settings,
);

CompactionDecision _manualCompactionDecision(
  _CompactionCheckRequest request,
  CompactionSettings settings,
) => CompactionDecision(
  shouldCompact: true,
  reason: .eligible,
  trigger: request.trigger,
  settings: settings,
);

CompactionDecision? _blockedCompactionDecision({
  required CompactionSettings settings,
  required CompactionTrigger trigger,
  required int? contextLimit,
}) {
  if (trigger == CompactionTrigger.auto && !settings.autoCompactionEnabled) {
    return CompactionDecision(
      shouldCompact: false,
      reason: .disabled,
      trigger: trigger,
      settings: settings,
    );
  }
  if (trigger == CompactionTrigger.auto && contextLimit == null) {
    return CompactionDecision(
      shouldCompact: false,
      reason: .unknownContextLimit,
      trigger: trigger,
      settings: settings,
    );
  }

  return null;
}

CompactionDecision _evaluateCompaction(
  _CompactionCheckRequest request,
  CompactionSettings settings,
  AgentContextSnapshot context,
) {
  final contextLimit = request.contextLimit;
  if (contextLimit == null) {
    return CompactionDecision(
      shouldCompact: false,
      reason: .unknownContextLimit,
      trigger: request.trigger,
      settings: settings,
    );
  }
  final evaluation = evaluateContextCompaction(
    context: context,
    usagePercentageThreshold: settings.usagePercentageThreshold,
    remainingTokenThreshold: _remainingTokenThreshold(
      request,
      settings,
      contextLimit,
    ),
    contextLimit: contextLimit,
  );

  return _evaluatedCompactionDecision(request, settings, evaluation);
}

int _remainingTokenThreshold(
  _CompactionCheckRequest request,
  CompactionSettings settings,
  int contextLimit,
) =>
    settings.remainingTokenThreshold ==
        CompactionSettings.defaults.remainingTokenThreshold
    ? defaultRemainingTokenThreshold(
        maxOutputTokens: request.maxOutputTokens,
        contextLimit: contextLimit,
      )
    : settings.remainingTokenThreshold;

CompactionDecision _evaluatedCompactionDecision(
  _CompactionCheckRequest request,
  CompactionSettings settings,
  AgentCompactionEvaluation evaluation,
) => CompactionDecision(
  shouldCompact: evaluation.shouldCompact,
  reason: evaluation.shouldCompact
      ? CompactionDecisionReason.eligible
      : CompactionDecisionReason.belowPercentageThreshold,
  trigger: request.trigger,
  estimate: _promptEstimate(request, evaluation.usage),
  settings: settings,
);

ConversationPromptEstimate _promptEstimate(
  _CompactionCheckRequest request,
  AgentContextWindowUsage usage,
) => ConversationPromptEstimate(
  conversationId: request.conversationId,
  selectedModelId: request.selectedModelId,
  selectedProviderId: request.selectedProviderId,
  estimatedPromptTokens: usage.usedTokens,
  maxOutputTokens: request.maxOutputTokens,
  contextLimit: usage.contextLimit,
  remainingTokens: usage.remainingTokens,
  usagePercentage: usage.usagePercentage,
);

final shouldCompactConversationUsecaseProvider =
    Provider<ShouldCompactConversationUsecase>((ref) {
      return ShouldCompactConversationUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        settingsRepository: ref.watch(
          workspaceCompactionSettingsRepositoryProvider,
        ),
      );
    });
