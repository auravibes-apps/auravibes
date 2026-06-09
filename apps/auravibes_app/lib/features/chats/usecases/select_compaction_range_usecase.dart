// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:riverpod/riverpod.dart';

class SelectCompactionRangeUsecase {
  const SelectCompactionRangeUsecase();

  CompactionRange? call(List<MessageEntity> messages) {
    if (messages.length < 3) return null;

    final safeTailStart = _findSafeTailStart(messages);
    if (safeTailStart <= 0) return null;

    final compactable = messages.sublist(0, safeTailStart);
    final compactableSafe = _excludeUnsafeMessages(compactable);
    final firstCompactable = compactableSafe.firstOrNull;
    if (firstCompactable == null) return null;

    final keptTail = messages.sublist(safeTailStart);

    return CompactionRange(
      fromMessageId: firstCompactable.id,
      throughMessageId: compactableSafe.last.id,
      messageIds: compactableSafe.map((m) => m.id).toList(),
      keptTailMessageIds: keptTail.map((m) => m.id).toList(),
    );
  }

  int _findSafeTailStart(List<MessageEntity> messages) {
    final tailStart = _findTailStart(messages);
    if (tailStart <= 0) return 0;
    _validateTailSafety(messages, tailStart);

    return tailStart;
  }

  int _findTailStart(List<MessageEntity> messages) {
    var lastUserIndex = -1;
    var lastAssistantIndex = -1;

    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.isUser && lastUserIndex == -1) lastUserIndex = i;
      if (!m.isUser &&
          m.messageType == MessageType.text &&
          lastAssistantIndex == -1) {
        lastAssistantIndex = i;
      }
      if (lastUserIndex != -1 && lastAssistantIndex != -1) break;
    }

    if (lastUserIndex == -1 || lastAssistantIndex == -1) return 0;

    return lastUserIndex;
  }

  void _validateTailSafety(List<MessageEntity> messages, int tailStart) {
    for (var i = tailStart; i >= 0; i--) {
      if (!messages[i].isUser) {
        final toolCalls = messages[i].metadata?.toolCalls;
        if (toolCalls != null && toolCalls.isNotEmpty) {
          final hasUnresolved = toolCalls.any((tc) => tc.isPending);
          if (hasUnresolved) {
            throw const CompactionUnsafeException();
          }
        }
      }

      if (messages[i].isUser && i != tailStart) break;
    }
  }

  List<MessageEntity> _excludeUnsafeMessages(List<MessageEntity> messages) {
    return messages.where(_isSafeToCompact).toList();
  }

  bool _isSafeToCompact(MessageEntity m) {
    if (_hasErrorStatus(m)) return false;
    if (_hasUnfinishedStatus(m)) return false;
    if (_hasPendingToolApproval(m)) return false;
    if (_isCompactionSummary(m)) return false;

    return true;
  }

  static bool _hasErrorStatus(MessageEntity m) =>
      m.status == MessageStatus.error;

  static bool _hasUnfinishedStatus(MessageEntity m) =>
      m.status == MessageStatus.sending || m.status == MessageStatus.unfinished;

  static bool _hasPendingToolApproval(MessageEntity m) {
    if (m.isUser) return false;
    final toolCalls = m.metadata?.toolCalls;

    return toolCalls != null && toolCalls.any((tc) => tc.isPending);
  }

  static bool _isCompactionSummary(MessageEntity m) =>
      m.messageType == MessageType.system &&
      m.metadata?.isCompactionSummary == true;
}

final selectCompactionRangeUsecaseProvider =
    Provider<SelectCompactionRangeUsecase>((ref) {
      return const SelectCompactionRangeUsecase();
    });
