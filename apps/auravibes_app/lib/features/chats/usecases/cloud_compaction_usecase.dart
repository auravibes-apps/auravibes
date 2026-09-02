import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';

class const CloudCompactionUsecase({
  required final CloudConversationUsecase conversations,
  required final CloudTurnUsecase turns,
  required final CompactionExecutionRuntime execution,
}) {
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

      var snapshot = await turns.get(turnId);
      while (!snapshot.terminal) {
        await Future<void>.delayed(const Duration(seconds: 1));
        snapshot = await turns.get(turnId);
      }
      if (snapshot.turn.status != 'completed') {
        throw const CompactionFailedException();
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
