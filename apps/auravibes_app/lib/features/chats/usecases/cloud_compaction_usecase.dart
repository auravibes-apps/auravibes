import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudCompactionUsecase({
  required final CloudConversationUsecase conversations,
  required final CloudTurnUsecase turns,
  required final CompactionExecutionRuntime execution,
}) {
  Future<CompactionExecutionState> call({
    required ConversationEntity conversation,
    required CompactionTrigger trigger,
  }) => _executeCompaction((
    conversation: conversation,
    trigger: trigger,
    conversations: conversations,
    turns: turns,
    execution: execution,
  ));
}

typedef _CloudCompactionRequest = ({
  ConversationEntity conversation,
  CompactionTrigger trigger,
  CloudConversationUsecase conversations,
  CloudTurnUsecase turns,
  CompactionExecutionRuntime execution,
});

Future<CompactionExecutionState> _executeCompaction(
  _CloudCompactionRequest request,
) async {
  final startedAt = DateTime.now();
  final executionState = _runningState(request, startedAt);
  if (!request.execution.tryMarkRunning(executionState)) {
    return executionState;
  }

  try {
    await _completeCompaction(request);
    request.execution.markSuccess(request.conversation.id);

    return _successfulCompaction(request, startedAt);
  } on Exception {
    request.execution.markFailure(request.conversation.id);
    rethrow;
  }
}

Future<void> _completeCompaction(_CloudCompactionRequest request) async {
  final result = await request.conversations.compact(request.conversation);
  final turnId = result.turnId;
  if (turnId == null) throw const CompactionUnavailableException();

  final snapshot = await _waitForCompaction(request.turns, turnId);
  if (snapshot.turn.status != 'completed') {
    throw const CompactionFailedException();
  }
}

CompactionExecutionState _runningState(
  _CloudCompactionRequest request,
  DateTime startedAt,
) => .new(
  conversationId: request.conversation.id,
  trigger: request.trigger,
  startedAt: startedAt,
  status: CompactionExecutionStatus.running,
);

Future<TurnSnapshot> _waitForCompaction(
  CloudTurnUsecase turns,
  String turnId,
) async {
  var snapshot = await turns.get(turnId);
  while (!snapshot.terminal) {
    await Future<void>.delayed(const Duration(seconds: 1));
    snapshot = await turns.get(turnId);
  }

  return snapshot;
}

CompactionExecutionState _successfulCompaction(
  _CloudCompactionRequest request,
  DateTime startedAt,
) => CompactionExecutionState(
  conversationId: request.conversation.id,
  trigger: request.trigger,
  startedAt: startedAt,
  status: .success,
);
