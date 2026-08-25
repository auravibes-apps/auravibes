import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_key.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

export 'cloud_conversation_key.dart';

final Logger _logger = Logger('cloud_conversation');

// ignore: specify_nonobvious_property_types, Riverpod hides family types.
final cloudConversationStateProvider = StreamProvider.autoDispose
    .family<CloudConversationState, CloudConversationKey>(
      _watchCloudConversation,
    );

Stream<CloudConversationState> _watchCloudConversation(
  Ref ref,
  CloudConversationKey key,
) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(key.workspaceId).future,
  );
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (gateway == null) return;
  yield* CloudConversationStream.watch(
    CloudChatGateway(gateway),
    key,
  );
}

/// Reconciles the local view from the authoritative snapshot after a stream
/// gap, stream error, or every durable semantic event.
abstract final class CloudConversationStream {
  static Stream<CloudConversationState> watch(
    CloudChatGateway chat,
    CloudConversationKey key, {
    Future<void> Function(Duration duration)? delay,
  }) async* {
    final wait = delay ?? Future<void>.delayed;
    var retryCount = 0;
    var state = CloudConversationState.fromSnapshot(
      await chat.getConversationSnapshot(key.conversationId),
    );
    _logger.info(
      'Cloud conversation snapshot: workspaceId=${key.workspaceId}, '
      'conversationId=${key.conversationId}, sequence=${state.sequence}, '
      'executionState=${state.conversation.executionState}, '
      'activeExecutionId=${state.activeExecution?.id}.',
    );
    yield state;

    while (true) {
      try {
        await for (final event in chat.subscribeConversation(
          key.conversationId,
          afterSequence: state.sequence,
        )) {
          _logger.info(
            'Cloud conversation event: workspaceId=${key.workspaceId}, '
            'conversationId=${key.conversationId}, sequence=${event.sequence}, '
            'kind=${event.kind.name}, '
            'transientDelta=${event.transientTextDelta != null}.',
          );
          final next = state.apply(event);
          final needsSnapshot =
              next == null || event.transientTextDelta == null;
          if (needsSnapshot) {
            _logger.info(
              'Cloud conversation snapshot recovery: '
              'conversationId=${key.conversationId}, '
              'eventSequence=${event.sequence}, '
              'stateSequence=${state.sequence}.',
            );
          }
          state = needsSnapshot
              ? CloudConversationState.fromSnapshot(
                  await chat.getConversationSnapshot(key.conversationId),
                )
              : next;
          retryCount = 0;
          yield state;
        }
        _logger.warning(
          'Cloud conversation stream closed: workspaceId=${key.workspaceId}, '
          'conversationId=${key.conversationId}, sequence=${state.sequence}.',
        );
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Cloud conversation stream failed: workspaceId=${key.workspaceId}, '
          'conversationId=${key.conversationId}, sequence=${state.sequence}.',
          error,
          stackTrace,
        );
      }

      retryCount++;
      state = CloudConversationState.fromSnapshot(
        await chat.getConversationSnapshot(key.conversationId),
      );
      yield state;
      await wait(Duration(seconds: retryCount.clamp(1, 8)));
    }
  }
}
