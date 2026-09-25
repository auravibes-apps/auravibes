import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:riverpod/riverpod.dart';

class const RestoreCompactionCheckpointUsecase({
  required final ConversationRepository conversationRepository,
  required final MessageRepository messageRepository,
  required final GetConversationBusyStateUsecase getConversationBusyState,
  required final bool Function(String conversationId) isCompacting,
}) {
  Future<void> call({
    required String conversationId,
    required String checkpointMessageId,
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw const CompactionCheckpointRestoreException();
    }

    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );
    final checkpoint = messages.where(
      (message) =>
          message.id == checkpointMessageId &&
          message.conversationId == conversationId &&
          message.status == MessageStatus.sent &&
          message.metadata?.isCompactionSummary == true,
    );
    if (checkpoint.isEmpty) {
      throw const CompactionCheckpointRestoreException();
    }

    final busyState = await getConversationBusyState.call(
      conversationId: conversationId,
      isCompacting: isCompacting(conversationId),
    );
    if (busyState.isBusy) {
      throw const CompactionCheckpointRestoreException();
    }

    final _ = await conversationRepository.patchConversation(
      conversationId,
      .new(activeCompactionCheckpointId: checkpointMessageId),
    );
  }
}

final restoreCompactionCheckpointUsecaseProvider =
    Provider<RestoreCompactionCheckpointUsecase>((ref) {
      return RestoreCompactionCheckpointUsecase(
        conversationRepository: ref.watch(conversationRepositoryProvider),
        messageRepository: ref.watch(messageRepositoryProvider),
        getConversationBusyState: ref.watch(
          getConversationBusyStateUsecaseProvider,
        ),
        isCompacting: ref
            .watch(compactionExecutionProvider.notifier)
            .isCompacting,
      );
    });
