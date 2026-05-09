import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
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
    if (compactableSafe.isEmpty) return null;

    final keptTail = messages.sublist(safeTailStart);

    return CompactionRange(
      fromMessageId: compactableSafe.first.id,
      throughMessageId: compactableSafe.last.id,
      messageIds: compactableSafe.map((m) => m.id).toList(),
      keptTailMessageIds: keptTail.map((m) => m.id).toList(),
    );
  }

  int _findSafeTailStart(List<MessageEntity> messages) {
    var lastUserIndex = -1;
    var lastAssistantIndex = -1;

    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isUser && lastUserIndex == -1) {
        lastUserIndex = i;
      }
      if (!messages[i].isUser &&
          messages[i].messageType == MessageType.text &&
          lastAssistantIndex == -1) {
        lastAssistantIndex = i;
      }
      if (lastUserIndex != -1 && lastAssistantIndex != -1) break;
    }

    if (lastUserIndex == -1 || lastAssistantIndex == -1) return 0;

    final tailStart = lastUserIndex;

    final safeStart = tailStart;
    for (var i = tailStart; i >= 0; i--) {
      if (!messages[i].isUser) {
        final toolCalls = messages[i].metadata?.toolCalls;
        if (toolCalls != null && toolCalls.isNotEmpty) {
          final hasUnresolved = toolCalls.any((tc) => tc.isPending);
          if (hasUnresolved) {
            throw const CompactionUnsafeException();
          }

          // Tool call results live inside the same MessageToolCallEntity
          // as the call itself — no need to scan for matching IDs.
        }
      }

      if (messages[i].isUser && i != tailStart) break;
    }

    return safeStart;
  }

  List<MessageEntity> _excludeUnsafeMessages(List<MessageEntity> messages) {
    return messages.where((m) {
      if (m.status == MessageStatus.error) return false;
      if (m.status == MessageStatus.sending) return false;
      if (m.status == MessageStatus.unfinished) return false;

      if (!m.isUser) {
        final toolCalls = m.metadata?.toolCalls;
        if (toolCalls != null) {
          final hasPendingApproval = toolCalls.any((tc) => tc.isPending);
          if (hasPendingApproval) return false;
        }
      }

      if (m.messageType == MessageType.system &&
          m.metadata?.isCompactionSummary == true) {
        return false;
      }

      return true;
    }).toList();
  }
}

final selectCompactionRangeUsecaseProvider =
    Provider<SelectCompactionRangeUsecase>((ref) {
      return const SelectCompactionRangeUsecase();
    });
