import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/v7.dart';

typedef _RestoreCloudCheckpoint = Future<bool> Function({
  required String workspaceId,
  required String conversationId,
  required String checkpointMessageId,
});

class const RestoreCompactionCheckpointUsecase({
  required final ConversationRepository conversationRepository,
  required final MessageRepository messageRepository,
  required final GetConversationBusyStateUsecase getConversationBusyState,
  required final bool Function(String conversationId) isCompacting,
  final _RestoreCloudCheckpoint? restoreCloudCheckpoint,
}) {
  Future<void> call({
    required String workspaceId,
    required String conversationId,
    required String checkpointMessageId,
  }) async {
    if (restoreCloudCheckpoint case final restoreCloudCheckpoint?) {
      CloudAppException? restoreError;
      try {
        final restored = await restoreCloudCheckpoint(
          workspaceId: workspaceId,
          conversationId: conversationId,
          checkpointMessageId: checkpointMessageId,
        );

        if (restored) return;
      } on CloudAppException catch (error) {
        if (error.code ==
                ConversationErrorCode.checkpointRestoreConflict.name ||
            error.code == ConversationErrorCode.staleRevision.name) {
          restoreError = error;
        } else {
          rethrow;
        }
      }

      if (restoreError != null) {
        throw const CompactionCheckpointRestoreException();
      }
    }

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
        restoreCloudCheckpoint:
            ({
              required workspaceId,
              required conversationId,
              required checkpointMessageId,
            }) async {
              final session = await ref.read(
                workspaceSessionForRouteProvider(workspaceId).future,
              );
              if (session.cloud case final cloud?) {
                final conversation = await ref.read(
                  conversationByIdStreamProvider(
                    workspaceId,
                    conversationId: conversationId,
                  ).future,
                );
                if (conversation == null) {
                  throw const CompactionCheckpointRestoreException();
                }

                final gateway = await ref.read(
                  cloudWorkspaceStateGatewayForWorkspaceProvider(
                    cloud.localWorkspaceId,
                  ).future,
                );
                if (gateway == null) {
                  throw const CompactionCheckpointRestoreException();
                }
                final _ = await CloudChatGateway(gateway)
                    .restoreCompactionCheckpoint(
                      requestId: const UuidV7().generate(),
                      conversationId: conversationId,
                      checkpointMessageId: checkpointMessageId,
                      expectedConversationRevision: conversation.revision,
                    );

                return true;
              }

              return false;
            },
      );
    });
