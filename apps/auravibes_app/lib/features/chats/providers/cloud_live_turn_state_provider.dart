import 'package:auravibes_app/features/chats/models/cloud_live_turn_state.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

// The stream crosses the scoped cloud gateway boundary.
// ignore: specify_nonobvious_property_types
final cloudLiveTurnEventsProvider = Provider.autoDispose
    .family<Stream<CloudLiveTurnState>, String>(
      _watchLiveTurn,
      dependencies: [cloudWorkspaceStateGatewayProvider],
    );

@Dependencies([cloudWorkspaceStateGateway])
Stream<CloudLiveTurnState> _watchLiveTurn(Ref ref, String turnId) async* {
  final gateway = await ref.watch(cloudWorkspaceStateGatewayProvider.future);
  if (gateway == null) return;

  await for (final event in CloudChatGateway(gateway).subscribeTurn(turnId)) {
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
