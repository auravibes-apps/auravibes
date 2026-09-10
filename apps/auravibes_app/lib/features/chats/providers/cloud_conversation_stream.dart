import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_key.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

export 'cloud_conversation_key.dart';

final Logger _logger = .new('cloud_conversation');

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
  yield* CloudConversationStream.watch(.new(gateway), key);
}

/// Reconciles the local view from the authoritative snapshot after a stream
/// gap, stream error, or every durable semantic event.
abstract final class CloudConversationStream {
  static Stream<CloudConversationState> watch(
    CloudChatGateway chat,
    CloudConversationKey key, {
    Future<void> Function(Duration duration)? delay,
  }) => _CloudConversationStreamRunner(chat, key, delay).run();

  static Future<CloudConversationState> _applyEvent(
    CloudChatGateway chat,
    CloudConversationKey key,
    CloudConversationState state,
    ConversationStreamEvent event,
  ) async {
    _logEvent(key, event);
    final next = state.apply(event);
    if (!_needsSnapshot(next, event)) return next!;

    _logSnapshotRecovery(key, event, state);
    return CloudConversationState.fromSnapshot(
      await chat.getConversationSnapshot(key.conversationId),
    ).preserveTransientA2uiFrom(state);
  }

  static bool _needsSnapshot(
    CloudConversationState? next,
    ConversationStreamEvent event,
  ) =>
      next == null ||
      (event.transientTextDelta == null &&
          event.kind != ConversationEventType.a2uiMessage);

  static void _logEvent(
    CloudConversationKey key,
    ConversationStreamEvent event,
  ) {
    _logger.info(
      'Cloud conversation event: workspaceId=${key.workspaceId}, '
      'conversationId=${key.conversationId}, sequence=${event.sequence}, '
      'kind=${event.kind.name}, '
      'transientDelta=${event.transientTextDelta != null}.',
    );
  }

  static void _logSnapshotRecovery(
    CloudConversationKey key,
    ConversationStreamEvent event,
    CloudConversationState state,
  ) {
    _logger.info(
      'Cloud conversation snapshot recovery: '
      'conversationId=${key.conversationId}, '
      'eventSequence=${event.sequence}, '
      'stateSequence=${state.sequence}.',
    );
  }
}

class _CloudConversationStreamRunner {
  _CloudConversationStreamRunner(this._chat, this._key, this._delay);

  final CloudChatGateway _chat;
  final CloudConversationKey _key;
  final Future<void> Function(Duration duration)? _delay;
  late CloudConversationState _state;
  var _retryCount = 0;

  Stream<CloudConversationState> run() async* {
    _state = await _loadSnapshot();
    _logInitialSnapshot();
    yield _state;

    while (true) {
      yield* _subscribe();
      yield await _recoverAfterSubscription();
    }
  }

  Future<CloudConversationState> _recoverAfterSubscription() async {
    _retryCount++;
    _state = await _loadSnapshot().then(
      (state) => state.preserveTransientA2uiFrom(_state),
    );
    await (_delay ?? Future<void>.delayed)(
      .new(seconds: _retryCount.clamp(1, 8)),
    );

    return _state;
  }

  Future<CloudConversationState> _loadSnapshot() async =>
      CloudConversationState.fromSnapshot(
        await _chat.getConversationSnapshot(_key.conversationId),
      );

  Stream<CloudConversationState> _subscribe() async* {
    try {
      await for (final event in _chat.subscribeConversation(
        _key.conversationId,
        afterSequence: _state.sequence,
      )) {
        _state = await CloudConversationStream._applyEvent(
          _chat,
          _key,
          _state,
          event,
        );
        _retryCount = 0;
        yield _state;
      }
      _logClosedStream();
    } on Object catch (error, stackTrace) {
      _logFailedStream(error, stackTrace);
    }
  }

  void _logInitialSnapshot() {
    _logger.info(
      'Cloud conversation snapshot: workspaceId=${_key.workspaceId}, '
      'conversationId=${_key.conversationId}, sequence=${_state.sequence}, '
      'executionState=${_state.conversation.executionState}, '
      'activeExecutionId=${_state.activeExecution?.id}.',
    );
  }

  void _logClosedStream() {
    _logger.warning(
      'Cloud conversation stream closed: workspaceId=${_key.workspaceId}, '
      'conversationId=${_key.conversationId}, sequence=${_state.sequence}.',
    );
  }

  void _logFailedStream(Object error, StackTrace stackTrace) {
    _logger.warning(
      'Cloud conversation stream failed: workspaceId=${_key.workspaceId}, '
      'conversationId=${_key.conversationId}, sequence=${_state.sequence}.',
      error,
      stackTrace,
    );
  }
}
