// ignore_for_file: implementation_imports
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';

import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_chat_attachment_provider.dart';

import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentIterationContext, AgentIterationDecision, AgentIterationOrigin;

import 'package:logging/logging.dart';
import 'package:riverpod/src/providers/provider.dart';
import 'package:uuid/v7.dart';

final _logger = Logger('cloud_conversation_send');

typedef ContinueAgentTurn =
    Future<AgentIterationDecision> Function({
      required String conversationId,
      required AgentIterationContext context,
    });

class SendMessageUsecase {
  const SendMessageUsecase({
    required ContinueAgentTurn this.continueAgentTurn,
    required this.messageRepository,
    required this.getConversationBusyStateUsecase,
    required this.sendQueueRuntime,
  }) : cloudSend = null;

  const SendMessageUsecase.cloud(
    Future<void> Function(String conversationId, ChatDraft draft)
    this.cloudSend,
  ) : continueAgentTurn = null,
      messageRepository = null,
      getConversationBusyStateUsecase = null,
      sendQueueRuntime = null;

  final ContinueAgentTurn? continueAgentTurn;
  final MessageRepository? messageRepository;
  final GetConversationBusyStateUsecase? getConversationBusyStateUsecase;
  final ConversationSendQueueRuntime? sendQueueRuntime;
  final Future<void> Function(String conversationId, ChatDraft draft)?
  cloudSend;

  Future<void> call({
    required String conversationId,
    required ChatDraft draft,
  }) async {
    if (draft.isEmpty) return;
    if (cloudSend case final send?) {
      final _ = await send(conversationId, draft);

      return;
    }

    final getBusyState = getConversationBusyStateUsecase;
    final queue = sendQueueRuntime;
    if (getBusyState == null || queue == null) {
      throw StateError('Local send dependencies unavailable');
    }
    final busyState = await getBusyState.call(conversationId: conversationId);
    if (busyState.isBusy) {
      final _ = queue.enqueue(conversationId: conversationId, draft: draft);

      return;
    }

    await _sendNow(conversationId: conversationId, draft: draft);
  }

  Future<MessageEntity> createUserMessage({
    required String conversationId,
    required ChatDraft draft,
  }) {
    if (draft.isEmpty) return Future.error(ArgumentError('Draft is empty'));

    final repository = messageRepository;
    if (repository == null) {
      return Future.error(StateError('Local message repository unavailable'));
    }

    return repository.createMessage(
      .new(
        conversationId: conversationId,
        content: draft.text,
        messageType: .text,
        isUser: true,
        status: .sending,
        attachments: draft.attachments,
      ),
    );
  }

  Future<void> continueFromUserMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final continueTurn = continueAgentTurn;
    if (continueTurn == null) {
      throw StateError('Local agent runtime unavailable');
    }
    final _ = await continueTurn(
      conversationId: conversationId,
      context: AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
        ackMessageIds: [messageId],
      ),
    );
  }

  Future<void> _sendNow({
    required String conversationId,
    required ChatDraft draft,
  }) async {
    final createdMessage = await createUserMessage(
      conversationId: conversationId,
      draft: draft,
    );
    await continueFromUserMessage(
      conversationId: conversationId,
      messageId: createdMessage.id,
    );
  }
}

extension SendMessageUsecaseNewConversation on SendMessageUsecase {
  Future<void> sendFirstMessage({
    required String conversationId,
    required ChatDraft draft,
    required void Function(Object error, StackTrace stackTrace) onContinueError,
  }) async {
    if (draft.isEmpty) return;
    if (cloudSend case final send?) {
      final _ = await send(conversationId, draft);

      return;
    }

    final createdMessage = await createUserMessage(
      conversationId: conversationId,
      draft: draft,
    );

    unawaited(
      continueFromUserMessage(
        conversationId: conversationId,
        messageId: createdMessage.id,
      ).catchError(onContinueError),
    );
  }
}

final ProviderFamily<SendMessageUsecase, String>
sendMessageUsecaseProvider = Provider.family<SendMessageUsecase, String>(
  (ref, workspaceId) {
    final session = ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue;
    session.capabilities.require(
      supported: session.capabilities.agentExecution,
    );
    if (session.cloud != null) {
      return SendMessageUsecase.cloud((conversationId, draft) async {
        session.capabilities.require(
          supported:
              draft.attachments.isEmpty || session.capabilities.attachments,
        );
        final gateway = await ref.read(
          cloudWorkspaceStateGatewayProvider(session).future,
        );
        final attachments = await ref.read(
          cloudChatAttachmentUsecaseProvider(workspaceId).future,
        );
        if (gateway == null) {
          throw const UnsupportedWorkspaceCapabilityException();
        }
        final chat = CloudChatGateway(gateway);
        final projection = await chat.getConversationSnapshot(conversationId);
        _logger.info(
          'Cloud send snapshot: conversationId=$conversationId, '
          'sequence=${projection.sequence}, '
          'projectionRevision=${projection.conversation.projectionRevision}, '
          'executionState=${projection.conversation.executionState}.',
        );
        final requestId = const UuidV7().generate();
        final uploadedObjects =
            await attachments?.uploadDraftResults(
              attachments: draft.attachments,
            ) ??
            const [];
        final snapshot = await (() async {
          try {
            final queued = await chat.queueConversationMessage(
              requestId: requestId,
              conversationId: conversationId,
              expectedProjectionRevision:
                  projection.conversation.projectionRevision,
              clientMessageId: const UuidV7().generate(),
              content: draft.text,
              attachmentIds: uploadedObjects
                  .map((object) => '${object.objectId}')
                  .toList(growable: false),
            );
            _logger.info(
              'Cloud message queued: conversationId=$conversationId, '
              'sequence=${queued.sequence}, '
              'projectionRevision='
              '${queued.conversation.projectionRevision}, '
              'executionState=${queued.conversation.executionState}, '
              'attachmentCount=${uploadedObjects.length}.',
            );

            return queued;
          } on Object catch (error, stackTrace) {
            await attachments?.deleteUploaded(uploadedObjects);
            Error.throwWithStackTrace(error, stackTrace);
          }
        })();
        if (snapshot.conversation.executionState == 'idle') {
          _logger.info(
            'Cloud execution start requested: '
            'conversationId=$conversationId, '
            'projectionRevision=${snapshot.conversation.projectionRevision}.',
          );
          final execution = await chat.continueConversation(
            requestId: const UuidV7().generate(),
            conversationId: conversationId,
            expectedProjectionRevision:
                snapshot.conversation.projectionRevision,
          );
          _logger.info(
            'Cloud execution start acknowledged: '
            'conversationId=$conversationId, sequence=${execution.sequence}, '
            'executionState=${execution.conversation.executionState}, '
            'activeExecutionId=${execution.activeExecution?.id}.',
          );
        }
        ref.invalidate(
          chatMessagesByConversationProvider(workspaceId, conversationId),
        );

        return;
      });
    }
    final agentService = ref.watch(auraAgentServiceProvider);

    return SendMessageUsecase(
      continueAgentTurn: agentService.agent.continueTurn,
      messageRepository: ref.watch(messageRepositoryProvider),
      getConversationBusyStateUsecase: ref.watch(
        getConversationBusyStateUsecaseProvider,
      ),
      sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    );
  },
  dependencies: [auraAgentServiceProvider],
);
