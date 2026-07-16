import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudCompactionUsecase {
  const CloudCompactionUsecase({
    required this.conversations,
    required this.turns,
    required this.execution,
  });

  final CloudConversationUsecase conversations;
  final CloudTurnUsecase turns;
  final CompactionExecutionRuntime execution;

  Future<CompactionExecutionState> call({
    required ConversationEntity conversation,
    required CompactionTrigger trigger,
  }) async {
    final startedAt = DateTime.now();
    execution.markRunning(
      CompactionExecutionState(
        conversationId: conversation.id,
        trigger: trigger,
        startedAt: startedAt,
        status: CompactionExecutionStatus.running,
      ),
    );
    try {
      final queued = await conversations.compact(conversation);
      final turnId = queued.turnId;
      if (turnId == null) throw const CompactionUnavailableException();

      final events = StreamIterator(turns.subscribe(turnId));
      try {
        var nextEvent = events.moveNext();
        var snapshot = await turns.get(turnId);
        while (!snapshot.terminal) {
          if (!await nextEvent) {
            snapshot = await turns.get(turnId);
            if (!snapshot.terminal) throw const CompactionFailedException();
            continue;
          }
          final event = events.current;
          nextEvent = events.moveNext();
          if (event.kind != LiveTurnEventKind.completed &&
              event.kind != LiveTurnEventKind.failed &&
              event.kind != LiveTurnEventKind.cancelled) {
            continue;
          }
          snapshot = await turns.get(turnId);
        }
        if (snapshot.turn.status != 'completed') {
          throw const CompactionFailedException();
        }
      } finally {
        await events.cancel();
      }
      execution.markSuccess(conversation.id);

      return CompactionExecutionState(
        conversationId: conversation.id,
        trigger: trigger,
        startedAt: startedAt,
        status: CompactionExecutionStatus.success,
      );
    } on Exception {
      execution.markFailure(conversation.id);
      rethrow;
    }
  }
}
