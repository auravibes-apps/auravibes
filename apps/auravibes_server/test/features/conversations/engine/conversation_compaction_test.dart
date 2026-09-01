import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('selects sent transcript before latest user and preserves its tail', () {
    final messages = [
      _message(1, 'user', 'first'),
      _message(2, 'assistant', 'answer'),
      _message(3, 'user', 'keep'),
      _message(4, 'assistant', '', status: 'queued'),
    ];

    final range = selectConversationCompactionRange(messages);

    expect(range, isA<AgentCompactionRangeSelected>());
    final selected = range as AgentCompactionRangeSelected;
    expect(selected.messageIds, ['1', '2']);
    expect(selected.keptTailMessageIds, ['3', '4']);
  });

  test('excludes prior summary and carries its boundary metadata', () {
    final messages = [
      _message(1, 'user', 'old'),
      _message(2, 'assistant', 'old answer'),
      _message(
        3,
        'system',
        'summary',
        metadata: {
          'isCompactionSummary': true,
          'compactedMessageIds': [1, 2],
        },
        compactedThroughMessageId: 2,
      ),
      _message(4, 'user', 'next'),
      _message(5, 'assistant', 'next answer'),
      _message(6, 'user', 'keep'),
    ];

    final range = selectConversationCompactionRange(
      messages,
    ) as AgentCompactionRangeSelected;

    expect(range.messageIds, ['1', '2', '4', '5']);
    expect(range.throughMessageId, '5');
    expect(range.keptTailMessageIds, ['6']);
  });
}

ConversationMessage _message(
  int id,
  String role,
  String content, {
  String status = 'sent',
  Map<String, dynamic>? metadata,
  int? compactedThroughMessageId,
}) => ConversationMessage(
  id: id,
  workspaceId: 1,
  conversationId: 1,
  stableId: 'message-$id',
  role: role,
  kind: role == 'system' ? 'system' : 'text',
  status: status,
  content: content,
  metadataJson: metadata == null ? null : jsonEncode(metadata),
  compactedThroughMessageId: compactedThroughMessageId,
  revision: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
