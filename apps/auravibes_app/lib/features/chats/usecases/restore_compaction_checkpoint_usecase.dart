import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
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
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/v7.dart';

typedef CompactionCheckpointRestoreRequest = ({
  String workspaceId,
  String conversationId,
  String checkpointMessageId,
  int? expectedConversationRevision,
  List<MessageEntity>? expectedMessages,
});

typedef _RestoreCloudCheckpoint = Future<bool> Function({
  required String workspaceId,
  required String conversationId,
  required String checkpointMessageId,
  int? expectedConversationRevision,
});

class const RestoreCompactionCheckpointUsecase({
  required final ConversationRepository conversationRepository,
  required final MessageRepository messageRepository,
  required final GetConversationBusyStateUsecase getConversationBusyState,
  required final bool Function(String conversationId) isCompacting,
  required final ConversationActivityGate conversationActivityGate,
  final _RestoreCloudCheckpoint? restoreCloudCheckpoint,
}) {
  Future<void> call(CompactionCheckpointRestoreRequest request) async {
    if (await _restoreCloud(request)) {
      return;
    }
    await _restoreLocally(request);
  }

  Future<bool> _restoreCloud(CompactionCheckpointRestoreRequest request) async {
    final restore = restoreCloudCheckpoint;
    if (restore == null) return false;
    try {
      return await restore(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        checkpointMessageId: request.checkpointMessageId,
        expectedConversationRevision: request.expectedConversationRevision,
      );
    } on CloudAppException catch (error, stackTrace) {
      _throwMappedCloudRestoreException(error, stackTrace);
    }
  }

  Future<void> _restoreLocally(CompactionCheckpointRestoreRequest request) =>
      conversationActivityGate.runCheckpointRestore(
        request.conversationId,
        () => _restoreLocalCheckpointWhileReserved(this, request),
      );

  Never _throwMappedCloudRestoreException(
    CloudAppException error,
    StackTrace stackTrace,
  ) {
    final mappedError = switch (error.code) {
      final code when code == ConversationErrorCode.staleRevision.name =>
        const CompactionStalePreviewException(),
      final code
          when code == ConversationErrorCode.checkpointRestoreConflict.name =>
        const CompactionCheckpointRestoreException(),
      _ => error,
    };
    Error.throwWithStackTrace(mappedError, stackTrace);
  }

  Future<void> _validateLocalCheckpointRestore(
    CompactionCheckpointRestoreRequest request,
    ConversationEntity? conversation,
    List<MessageEntity> messages,
  ) async {
    if (conversation == null) {
      throw const CompactionCheckpointRestoreException();
    }
    _ensureSourceTranscriptUnchanged(request, messages);
    _ensureLocalCheckpointExists(request, messages);
    await _ensureConversationIdle(request.conversationId);
  }

  void _ensureSourceTranscriptUnchanged(
    CompactionCheckpointRestoreRequest request,
    List<MessageEntity> messages,
  ) {
    final expectedMessages = request.expectedMessages;
    if (expectedMessages != null &&
        !const ListEquality<MessageEntity>().equals(
          expectedMessages,
          messages,
        )) {
      throw const CompactionStalePreviewException();
    }
  }

  void _ensureLocalCheckpointExists(
    CompactionCheckpointRestoreRequest request,
    List<MessageEntity> messages,
  ) {
    if (!_containsSentCompactionSummary(
      messages,
      request.conversationId,
      request.checkpointMessageId,
    )) {
      throw const CompactionCheckpointRestoreException();
    }
  }

  Future<void> _ensureConversationIdle(String conversationId) async {
    final busyState = await getConversationBusyState.call(
      conversationId: conversationId,
      isCompacting: isCompacting(conversationId),
    );
    if (busyState.isBusy) {
      throw const CompactionCheckpointRestoreException();
    }
  }
}

Future<void> _restoreLocalCheckpointWhileReserved(
  RestoreCompactionCheckpointUsecase usecase,
  CompactionCheckpointRestoreRequest request,
) async {
  final conversationId = request.conversationId;
  final conversation = await usecase.conversationRepository.getConversationById(
    conversationId,
  );
  final messages = await usecase.messageRepository.getMessagesByConversation(
    conversationId,
  );
  await usecase._validateLocalCheckpointRestore(
    request,
    conversation,
    messages,
  );

  final _ = await usecase.conversationRepository.patchConversation(
    conversationId,
    .new(activeCompactionCheckpointId: request.checkpointMessageId),
  );
}

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
              expectedConversationRevision,
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
                      expectedConversationRevision:
                          expectedConversationRevision ?? conversation.revision,
                    );

                return true;
              }

              return false;
            },
      );
    });
