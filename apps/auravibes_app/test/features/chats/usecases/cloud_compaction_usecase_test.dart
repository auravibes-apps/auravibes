import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_compaction_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _Gateway extends Mock implements CloudChatGateway {}

void main() {
  final conversation = ConversationEntity(
    id: 'conversation-1',
    title: 'Chat',
    workspaceId: 'local',
    isPinned: false,
    createdAt: _date,
    updatedAt: _date,
    revision: 7,
  );

  test('manual compaction waits for a live terminal event', () async {
    final gateway = _Gateway();
    final events = StreamController<LiveTurnEvent>();
    var turnReads = 0;
    addTearDown(events.close);
    when(
      () => gateway.compactConversation(
        requestId: any(named: 'requestId'),
        conversationId: 'conversation-1',
        expectedConversationRevision: 7,
      ),
    ).thenAnswer(
      (_) async => ConversationMutationResult(
        turnId: 'turn-1',
        conversationId: 'conversation-1',
        revision: 8,
        status: 'queued',
      ),
    );
    when(() => gateway.getTurn(turnId: 'turn-1')).thenAnswer(
      (_) async => _snapshot(terminal: turnReads++ > 0),
    );
    when(
      () => gateway.subscribeTurn('turn-1'),
    ).thenAnswer((_) => events.stream);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final usecase = CloudCompactionUsecase(
      conversations: CloudConversationUsecase(gateway),
      turns: CloudTurnUsecase(gateway),
      execution: container.read(compactionExecutionRuntimeProvider),
    );

    final resultFuture = usecase(
      conversation: conversation,
      trigger: CompactionTrigger.manual,
    );
    await Future<void>.delayed(Duration.zero);
    events.add(
      LiveTurnEvent(
        workspaceId: 1,
        turnId: 'turn-1',
        sequence: 1,
        kind: LiveTurnEventKind.completed,
      ),
    );
    final result = await resultFuture;

    expect(result.status, CompactionExecutionStatus.success);
    verify(() => gateway.getTurn(turnId: 'turn-1')).called(2);
    verify(() => gateway.subscribeTurn('turn-1')).called(1);
  });
}

final _date = DateTime.utc(2026);

TurnSnapshot _snapshot({required bool terminal}) => TurnSnapshot(
  turn: ConversationTurnView(
    id: 'turn-1',
    conversationId: 'conversation-1',
    assistantMessageId: 'summary-1',
    status: terminal ? 'completed' : 'running',
    revision: 2,
    acceptedSequence: 1,
    terminalAt: _date,
    createdAt: _date,
    updatedAt: _date,
  ),
  messages: [
    ConversationMessageView(
      id: 'summary-1',
      conversationId: 'conversation-1',
      turnId: 'turn-1',
      role: 'system',
      kind: 'text',
      status: 'sent',
      content: 'Durable summary',
      toolCalls: const [],
      revision: 1,
      createdAt: _date,
      updatedAt: _date,
    ),
  ],
  toolCalls: const [],
  terminal: terminal,
);
