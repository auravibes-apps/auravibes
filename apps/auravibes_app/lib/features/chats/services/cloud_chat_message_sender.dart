import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:logging/logging.dart';
import 'package:uuid/v7.dart';

typedef LoadCloudChatGateway = Future<CloudChatGateway?> Function();
typedef LoadCloudChatAttachments =
    Future<CloudChatAttachmentUsecase?> Function();

final _logger = Logger('cloud_conversation_send');

class const CloudChatMessageSender({
  required final LoadCloudChatGateway _gateway,
  required final LoadCloudChatAttachments _attachments,
  required final WorkspaceCapabilities _capabilities,
  required final void Function(String conversationId) _invalidateMessages,
}) {
  Future<void> call(String conversationId, ChatDraft draft) async {
    _capabilities.require(
      supported: draft.attachments.isEmpty || _capabilities.attachments,
    );
    final chat = await _gateway();
    final attachments = await _attachments();
    if (chat == null) {
      throw const UnsupportedWorkspaceCapabilityException();
    }
    final projection = await chat.getConversationSnapshot(conversationId);
    _logger.info(
      'Cloud send snapshot: conversationId=$conversationId, '
      'sequence=${projection.sequence}, '
      'projectionRevision=${projection.conversation.projectionRevision}, '
      'executionState=${projection.conversation.executionState}.',
    );
    final uploadedObjects =
        await attachments?.uploadDraftResults(attachments: draft.attachments) ??
        const [];
    final snapshot = await (() async {
      try {
        final queued = await chat.queueConversationMessage(
          requestId: const UuidV7().generate(),
          conversationId: conversationId,
          expectedProjectionRevision:
              projection.conversation.projectionRevision,
          clientMessageId: const UuidV7().generate(),
          content: draft.text,
          attachmentIds: uploadedObjects
              .map((object) => '${object.objectId}')
              .toList(growable: false),
          metadataJson: draft.metadataJson,
        );
        _logger.info(
          'Cloud message queued: conversationId=$conversationId, '
          'sequence=${queued.sequence}, '
          'projectionRevision=${queued.conversation.projectionRevision}, '
          'executionState=${queued.conversation.executionState}, '
          'attachmentCount=${uploadedObjects.length}.',
        );

        return queued;
      } on Object catch (error, stackTrace) {
        await attachments?.deleteUploaded(uploadedObjects);
        Error.throwWithStackTrace(error, stackTrace);
      }
    })();
    if (snapshot.conversation.executionState == 'idle' ||
        snapshot.conversation.executionState == 'awaitingUserAction') {
      _logger.info(
        'Cloud execution start requested: '
        'conversationId=$conversationId, '
        'projectionRevision=${snapshot.conversation.projectionRevision}.',
      );
      final execution = await chat.continueConversation(
        requestId: const UuidV7().generate(),
        conversationId: conversationId,
        expectedProjectionRevision: snapshot.conversation.projectionRevision,
      );
      _logger.info(
        'Cloud execution start acknowledged: '
        'conversationId=$conversationId, sequence=${execution.sequence}, '
        'executionState=${execution.conversation.executionState}, '
        'activeExecutionId=${execution.activeExecution?.id}.',
      );
    }
    _invalidateMessages(conversationId);
  }
}
