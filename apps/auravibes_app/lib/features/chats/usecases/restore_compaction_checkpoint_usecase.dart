import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_activity_gate.dart';
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
  required final ConversationActivityGate conversationActivityGate,
  final _RestoreCloudCheckpoint? restoreCloudCheckpoint,
}) {
  Future<void> call({
    required String workspaceId,
    required String conversationId,
    required String checkpointMessageId,
  }) async {
    if (await _restoreCloud(workspaceId, conversationId, checkpointMessageId)) {
      return;
    }
    await _restoreLocally(conversationId, checkpointMessageId);
  }

  Future<bool> _restoreCloud(
    String workspaceId,
    String conversationId,
    String checkpointMessageId,
  ) async {
    final restore = restoreCloudCheckpoint;
    if (restore == null) return false;
    try {
      return await restore(
        workspaceId: workspaceId,
        conversationId: conversationId,
        checkpointMessageId: checkpointMessageId,
      );
    } on CloudAppException catch (error, stackTrace) {
      if (_isCheckpointRestoreConflict(error)) {
        Error.throwWithStackTrace(
          const CompactionCheckpointRestoreException(),
          stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<void> _restoreLocally(
    String conversationId,
    String checkpointMessageId,
  ) => conversationActivityGate.runCheckpointRestore(
    conversationId,
    () => _restoreLocalCheckpointWhileReserved(
      this,
      conversationId,
      checkpointMessageId,
    ),
  );

  Future<bool> _hasLocalRestoreCheckpoint(
    String conversationId,
    String checkpointMessageId,
  ) async =>
      await conversationRepository.getConversationById(conversationId) !=
          null &&
      _containsSentCompactionSummary(
        await messageRepository.getMessagesByConversation(conversationId),
        conversationId,
        checkpointMessageId,
      );
}

Future<void> _restoreLocalCheckpointWhileReserved(
  RestoreCompactionCheckpointUsecase usecase,
  String conversationId,
  String checkpointMessageId,
) async {
  if (!await usecase._hasLocalRestoreCheckpoint(
        conversationId,
        checkpointMessageId,
      ) ||
      (await usecase.getConversationBusyState.call(
        conversationId: conversationId,
        isCompacting: usecase.isCompacting(conversationId),
      )).isBusy) {
    throw const CompactionCheckpointRestoreException();
  }

  final _ = await usecase.conversationRepository.patchConversation(
    conversationId,
    .new(activeCompactionCheckpointId: checkpointMessageId),
  );
}

bool _isCheckpointRestoreConflict(CloudAppException error) =>
    error.code == ConversationErrorCode.checkpointRestoreConflict.name ||
    error.code == ConversationErrorCode.staleRevision.name;

bool _containsSentCompactionSummary(
  List<MessageEntity> messages,
  String conversationId,
  String checkpointMessageId,
) => messages.any(
  (message) =>
      message.id == checkpointMessageId &&
      message.conversationId == conversationId &&
      _isSentCompactionSummary(message),
);

bool _isSentCompactionSummary(MessageEntity message) =>
    message.status == MessageStatus.sent &&
    message.metadata?.isCompactionSummary == true;

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
        conversationActivityGate: ref.watch(conversationActivityGateProvider),
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
