// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/agent_adapters/message_transcript_snapshot_mapper.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class SelectCompactionRangeUsecase {
  const SelectCompactionRangeUsecase();

  CompactionRange? call(List<MessageEntity> messages) {
    return switch (selectAgentCompactionRange(
      toAgentContextSnapshot(messages),
    )) {
      final AgentCompactionRangeSelected range => CompactionRange(
        fromMessageId: range.fromMessageId,
        throughMessageId: range.throughMessageId,
        messageIds: range.messageIds,
        keptTailMessageIds: range.keptTailMessageIds,
      ),
      AgentCompactionUnsafeUnresolvedTool() =>
        throw const CompactionUnsafeException(),
      AgentCompactionNoRange() => null,
    };
  }
}

final selectCompactionRangeUsecaseProvider =
    Provider<SelectCompactionRangeUsecase>((ref) {
      return const SelectCompactionRangeUsecase();
    });
