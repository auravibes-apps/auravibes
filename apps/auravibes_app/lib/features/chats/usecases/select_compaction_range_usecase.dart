// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/agent_adapters/message_transcript_snapshot_mapper.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class const SelectCompactionRangeUsecase() {
  CompactionRange? call(
    List<MessageEntity> messages, {
    ApiModelEntity? apiModel,
    CompactionModelOverride? modelOverride,
  }) {
    return switch (selectAgentCompactionRange(
      MessageTranscriptSnapshotMapper.toAgentContextSnapshot(messages),
      limitContext: apiModel?.limitContext,
      limitOutput: apiModel?.limitOutput,
      reserveTokens: modelOverride?.reserveTokens,
      keepRecentTokens: modelOverride?.keepRecentTokens,
    )) {
      final AgentCompactionRangeSelected range => _selectedCompactionRange(
        range,
      ),
      AgentCompactionUnsafeUnresolvedTool() =>
        throw const CompactionUnsafeException(),
      AgentCompactionNoRange() => null,
    };
  }
}

CompactionRange _selectedCompactionRange(AgentCompactionRangeSelected range) =>
    CompactionRange(
      fromMessageId: range.fromMessageId,
      throughMessageId: range.throughMessageId,
      messageIds: range.messageIds,
      keptTailMessageIds: range.keptTailMessageIds,
    );

final selectCompactionRangeUsecaseProvider =
    Provider<SelectCompactionRangeUsecase>((ref) {
      return const SelectCompactionRangeUsecase();
    });
