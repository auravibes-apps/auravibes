import 'package:auravibes_engine/src/model_capabilities.dart';
import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/transcript_context.dart';

enum AgentContextLimitValidity { known, unknown, invalid }

final class const AgentContextWindowUsage({
  required final int usedTokens,
  required final int? contextLimit,
  required final int? remainingTokens,
  required final double? usagePercentage,
  required final int? overflowTokens,
  required final AgentContextLimitValidity limitValidity,
});

final class const AgentCompactionEvaluation({
  required final AgentContextWindowUsage usage,
  required final bool isSafe,
  required final bool meetsUsageThreshold,
  required final bool meetsRemainingThreshold,
}) {
  bool get shouldCompact =>
      isSafe && (meetsUsageThreshold || meetsRemainingThreshold);
}

AgentContextWindowUsage calculateContextWindowUsage({
  required AgentContextSnapshot context,
  int? contextLimit,
  ModelCapabilities? model,
}) {
  final limit = contextLimit ?? model?.limitContext;
  final usedTokens = _estimateUsedTokens(context);
  if (limit == null) {
    return AgentContextWindowUsage(
      usedTokens: usedTokens,
      contextLimit: null,
      remainingTokens: null,
      usagePercentage: null,
      overflowTokens: null,
      limitValidity: AgentContextLimitValidity.unknown,
    );
  }

  final remainingTokens = limit - usedTokens;
  return AgentContextWindowUsage(
    usedTokens: usedTokens,
    contextLimit: limit,
    remainingTokens: remainingTokens,
    usagePercentage: limit > 0 ? usedTokens / limit * 100 : 0,
    overflowTokens: remainingTokens < 0 ? -remainingTokens : 0,
    limitValidity: limit > 0
        ? AgentContextLimitValidity.known
        : AgentContextLimitValidity.invalid,
  );
}

AgentCompactionEvaluation evaluateContextCompaction({
  required AgentContextSnapshot context,
  required int usagePercentageThreshold,
  required int remainingTokenThreshold,
  int? contextLimit,
  ModelCapabilities? model,
}) {
  final usage = calculateContextWindowUsage(
    context: context,
    contextLimit: contextLimit,
    model: model,
  );

  return AgentCompactionEvaluation(
    usage: usage,
    isSafe: isContextSafeForCompaction(context),
    meetsUsageThreshold:
        (usage.usagePercentage ?? 0) >= usagePercentageThreshold,
    meetsRemainingThreshold:
        (usage.remainingTokens ?? 0) <= remainingTokenThreshold,
  );
}

bool isContextSafeForCompaction(AgentContextSnapshot context) {
  for (final message in context.messages) {
    if (message.status == AgentTranscriptStatus.sending ||
        message.status == AgentTranscriptStatus.unfinished) {
      return false;
    }
    if (message.role != AgentTranscriptRole.user &&
        message.toolCalls.any((toolCall) => toolCall.lifecycle.isPending)) {
      return false;
    }
  }
  return true;
}

int defaultRemainingTokenThreshold({
  required int maxOutputTokens,
  int? contextLimit,
  ModelCapabilities? model,
}) {
  final limit = contextLimit ?? model?.limitContext;
  if (limit == null) return 2000;
  final threshold = (limit * 0.2).round();
  final outputAwareThreshold = threshold > maxOutputTokens
      ? threshold
      : maxOutputTokens;
  return outputAwareThreshold > 15000 ? 15000 : outputAwareThreshold;
}

int _estimateUsedTokens(AgentContextSnapshot context) {
  for (final message in context.messages.reversed) {
    final tokens = message.latestCumulativeTokenCount ?? 0;
    if (tokens > 0) return tokens;
  }

  var characterCount = 0;
  for (final message in context.messages) {
    characterCount += message.textCharacterCount;
    for (final toolCall in message.toolCalls) {
      characterCount += toolCall.argumentCharacterCount;
      characterCount += toolCall.resultCharacterCount;
    }
  }
  return (characterCount / 4).ceil();
}
