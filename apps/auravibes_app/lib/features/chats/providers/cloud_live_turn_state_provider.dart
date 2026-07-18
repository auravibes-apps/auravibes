// ignore_for_file: implementation_imports
import 'package:auravibes_app/features/chats/models/cloud_live_turn_state.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/providers/provider.dart';

typedef CloudLiveTurnKey = ({String workspaceId, String turnId});

final ProviderFamily<Stream<CloudLiveTurnState>, CloudLiveTurnKey>
cloudLiveTurnEventsProvider = Provider.autoDispose
    .family<Stream<CloudLiveTurnState>, CloudLiveTurnKey>(
      _watchLiveTurn,
    );

Stream<CloudLiveTurnState> _watchLiveTurn(
  Ref ref,
  CloudLiveTurnKey key,
) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(key.workspaceId).future,
  );
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (gateway == null) return;

  await for (final event in CloudChatGateway(
    gateway,
  ).subscribeTurn(key.turnId)) {
    final state = CloudLiveTurnState.fromEvent(event);
    yield state;
    if (state.isTerminal) return;
  }
}

final NotifierProvider<CloudActiveTurnStates, Map<String, CloudLiveTurnState>>
cloudActiveTurnStatesProvider =
    NotifierProvider<CloudActiveTurnStates, Map<String, CloudLiveTurnState>>(
      CloudActiveTurnStates.new,
    );

// The family type is inferred from the Riverpod factory.
// ignore: specify_nonobvious_property_types
final cloudActiveTurnStateProvider =
    Provider.family<CloudLiveTurnState?, String>(
      (ref, conversationId) =>
          ref.watch(cloudActiveTurnStatesProvider)[conversationId],
    );

class CloudActiveTurnStates extends Notifier<Map<String, CloudLiveTurnState>> {
  @override
  Map<String, CloudLiveTurnState> build() => const {};

  void set(String conversationId, CloudLiveTurnState turn) {
    state = {...state, conversationId: turn};
  }

  void update(String conversationId, CloudLiveTurnState turn) {
    final current = state[conversationId];
    if (current == null ||
        current.turnId != turn.turnId ||
        turn.sequence <= current.sequence) {
      return;
    }

    set(
      conversationId,
      CloudLiveTurnState(
        turnId: current.turnId,
        revision: current.revision,
        sequence: turn.sequence,
        state: turn.state,
        text: turn.text,
        messageId: turn.messageId,
        errorCode: turn.errorCode,
      ),
    );
  }
}
