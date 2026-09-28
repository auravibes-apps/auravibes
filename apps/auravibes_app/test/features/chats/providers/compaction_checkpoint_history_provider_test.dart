import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/providers/compaction_checkpoint_history_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('loads workspace-scoped history and active checkpoint', () async {
    const workspaceId = 'workspace-1';
    const conversationId = 'conversation-1';
    final now = DateTime.utc(2026);
    final conversation = ConversationEntity(
      id: conversationId,
      title: 'Conversation',
      workspaceId: workspaceId,
      isPinned: false,
      createdAt: now,
      updatedAt: now,
      activeCompactionCheckpointId: 'summary-2',
    );
    final messages = [
      _summary('summary-2', now.add(const Duration(seconds: 2))),
      _summary('summary-1', now),
      _summary('unsent-summary', now, status: .sending),
    ];
    final container = ProviderContainer(
      overrides: [
        conversationByIdStreamProvider(
          workspaceId,
          conversationId: conversationId,
        ).overrideWith((_) => Stream.value(conversation)),
        chatMessagesByConversationProvider(
          workspaceId,
          conversationId,
        ).overrideWith((_) => Stream.value(messages)),
      ],
    );
    addTearDown(container.dispose);
    final historyProvider = compactionCheckpointHistoryProvider((
      workspaceId: workspaceId,
      conversationId: conversationId,
    ));
    final subscription = container.listen(
      historyProvider,
      (_, next) => expect(next.hasError, isFalse),
    );
    addTearDown(subscription.close);

    final history = await container.read(historyProvider.future);

    expect(history.activeCheckpointId, 'summary-2');
    expect(history.summaries.map((message) => message.id), [
      'summary-1',
      'summary-2',
    ]);
  });
}

MessageEntity _summary(
  String id,
  DateTime createdAt, {
  MessageStatus status = .sent,
}) => MessageEntity(
  id: id,
  conversationId: 'conversation-1',
  content: 'Summary $id',
  messageType: .system,
  isUser: false,
  status: status,
  createdAt: createdAt,
  updatedAt: createdAt,
  metadata: const MessageMetadataEntity(isCompactionSummary: true),
);
