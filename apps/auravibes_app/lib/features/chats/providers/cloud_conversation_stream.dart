import 'dart:async';
import 'dart:math';

import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_key.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream_failure.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

export 'cloud_conversation_key.dart';
export 'cloud_conversation_stream_failure.dart';

final Logger _logger = .new('cloud_conversation');
const _serverErrorStatusThreshold = 500;

final StreamProviderFamily<CloudConversationState, CloudConversationKey>
cloudConversationStateProvider = StreamProvider.autoDispose
    .family<CloudConversationState, CloudConversationKey>(
      _watchCloudConversation,
      retry: _retryCloudConversationProvider,
    );

Duration? _retryCloudConversationProvider(int retryCount, Object error) {
  if (_isTerminalCloudConversationError(error)) return null;

  return ProviderContainer.defaultRetry(retryCount, error);
}

bool _isTerminalCloudConversationError(Object error) => switch (error) {
  CloudConversationStreamFailure() => true,
  CloudAppException(:final code) when code != null => true,
  CloudAppException(:final httpStatusCode)
      when httpStatusCode != null &&
          httpStatusCode < _serverErrorStatusThreshold =>
    true,
  ServerpodClientHttpException(:final statusCode)
      when statusCode < _serverErrorStatusThreshold =>
    true,
  _ => false,
};

bool _isRetryableStreamFailure(Object error) {
  if (_isTerminalCloudConversationError(error)) return false;

  return switch (error) {
    MethodStreamException() ||
    ServerpodClientNetworkException() ||
    TimeoutException() ||
    ServerpodClientHttpException() ||
    CloudAppException() => true,
    _ => false,
  };
}

void _throwIfTerminalStreamFailure(Object error, StackTrace stackTrace) {
  if (_isRetryableStreamFailure(error)) return;

  Error.throwWithStackTrace(
    CloudConversationStreamFailure(
      localizationKey: _terminalStreamErrorLocalizationKey(error),
    ),
    stackTrace,
  );
}

Future<CloudConversationState> _loadCloudConversationSnapshot(
  CloudChatGateway chat,
  CloudConversationKey key,
) async => CloudConversationState.fromSnapshot(
  await chat.getConversationSnapshot(key.conversationId),
);

Duration _retryDelay(int retryCount, Random random) {
  final exponent = (retryCount - 1).clamp(0, 3);
  final maximumDelay = Duration(seconds: 1 << exponent);

  return Duration(
    milliseconds: (random.nextDouble() * maximumDelay.inMilliseconds).round(),
  );
}

void _handleSnapshotFailure(
  CloudConversationKey key,
  Object error,
  StackTrace stackTrace,
) {
  _logger.warning(
    'Cloud conversation snapshot failed: '
    'workspaceId=${key.workspaceId}, '
    'conversationId=${key.conversationId}.',
    error,
    stackTrace,
  );
  _throwIfTerminalStreamFailure(error, stackTrace);
}

void _handleFailedStream(
  CloudConversationKey key,
  CloudConversationState state,
  Object error,
  StackTrace stackTrace,
) {
  _logger.warning(
    'Cloud conversation stream failed: workspaceId=${key.workspaceId}, '
    'conversationId=${key.conversationId}, '
    'sequence=${state.sequence}.',
    error,
    stackTrace,
  );
  _throwIfTerminalStreamFailure(error, stackTrace);
}

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
    Random? random,
  }) => _CloudConversationStreamRunner(chat, key, delay, random).run();

  static Future<CloudConversationState> _applyEvent(
    CloudChatGateway chat,
    CloudConversationKey key,
    CloudConversationState state,
    ConversationStreamEvent event,
  ) async {
    _logEvent(key, event);
    final next = state.apply(event);
    if (next != null && !_needsSnapshot(next, event)) return next;

    _logSnapshotRecovery(key, event, state);

    return CloudConversationState.fromSnapshot(
      await chat.getConversationSnapshot(key.conversationId),
    ).preserveTransientA2uiFrom(state);
  }

  static bool _needsSnapshot(
    CloudConversationState next,
    ConversationStreamEvent event,
  ) =>
      event.transientTextDelta == null &&
      event.kind != ConversationEventType.a2uiMessage;

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
  new(this._chat, this._key, this._delay, Random? random)
    : _random = random ?? Random();

  final CloudChatGateway _chat;
  final CloudConversationKey _key;
  final Future<void> Function(Duration duration)? _delay;
  final Random _random;
  CloudConversationState? _state;
  var _retryCount = 0;

  CloudConversationState get _currentState =>
      _state ?? (throw StateError('Conversation snapshot not loaded'));

  Stream<CloudConversationState> run() async* {
    _state = await _loadInitialSnapshot();
    _logInitialSnapshot();
    yield _currentState;

    while (true) {
      yield* _subscribe();
      yield await _recoverAfterSubscription();
    }
  }

  Future<CloudConversationState> _loadInitialSnapshot() async {
    while (true) {
      try {
        return await _loadCloudConversationSnapshot(_chat, _key);
      } on Object catch (error, stackTrace) {
        _handleSnapshotFailure(_key, error, stackTrace);
        await _waitBeforeRetry();
      }
    }
  }

  Future<CloudConversationState> _recoverAfterSubscription() async {
    while (true) {
      CloudConversationState state;
      try {
        state = await _loadCloudConversationSnapshot(_chat, _key);
      } on Object catch (error, stackTrace) {
        _handleSnapshotFailure(_key, error, stackTrace);
        await _waitBeforeRetry();
        continue;
      }

      _state = state.preserveTransientA2uiFrom(_currentState);
      await _waitBeforeRetry();

      return _currentState;
    }
  }

  Future<void> _waitBeforeRetry() async {
    _retryCount++;
    await (_delay ?? Future<void>.delayed)(_retryDelay(_retryCount, _random));
  }

  Stream<CloudConversationState> _subscribe() async* {
    try {
      await for (final event in _chat.subscribeConversation(
        _key.conversationId,
        afterSequence: _currentState.sequence,
      )) {
        _state = await CloudConversationStream._applyEvent(
          _chat,
          _key,
          _currentState,
          event,
        );
        _retryCount = 0;
        yield _currentState;
      }
      _logClosedStream();
    } on Object catch (error, stackTrace) {
      _handleFailedStream(_key, _currentState, error, stackTrace);
    }
  }

  void _logInitialSnapshot() {
    _logger.info(
      'Cloud conversation snapshot: workspaceId=${_key.workspaceId}, '
      'conversationId=${_key.conversationId}, '
      'sequence=${_currentState.sequence}, '
      'executionState=${_currentState.conversation.executionState}, '
      'activeExecutionId=${_currentState.activeExecution?.id}.',
    );
  }

  void _logClosedStream() {
    _logger.warning(
      'Cloud conversation stream closed: workspaceId=${_key.workspaceId}, '
      'conversationId=${_key.conversationId}, '
      'sequence=${_currentState.sequence}.',
    );
  }
}

String _terminalStreamErrorLocalizationKey(Object error) {
  try {
    CloudAppErrors.translateException(error, .conversation);
  } on Object catch (translatedError) {
    return switch (translatedError) {
      CloudAppException(:final localizationKey) => localizationKey,
      _ => CloudAppErrors.localizationKey(error),
    };
  }
}
