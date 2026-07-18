import 'package:auravibes_app/features/chats/models/cloud_live_turn_state.dart';
import 'package:auravibes_app/features/chats/providers/cloud_live_turn_state_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('retains active turn identity across route listeners', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const turn = CloudLiveTurnState(
      turnId: 'turn-1',
      revision: 3,
      sequence: 2,
      state: CloudLiveTurnLifecycle.thinking,
    );

    container.read(cloudActiveTurnStatesProvider.notifier).set('chat-1', turn);

    expect(
      container.read(cloudActiveTurnStateProvider('chat-1')),
      same(turn),
    );
    expect(
      container.read(cloudActiveTurnStateProvider('chat-1'))?.isBusy,
      isTrue,
    );
  });

  test('updates active turn state without losing its revision', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final _ = container.read(cloudActiveTurnStatesProvider.notifier)
      ..set(
        'chat-1',
        const CloudLiveTurnState(
          turnId: 'turn-1',
          revision: 3,
          sequence: 1,
          state: CloudLiveTurnLifecycle.queued,
        ),
      )
      ..update(
        'chat-1',
        const CloudLiveTurnState(
          turnId: 'turn-1',
          revision: 0,
          sequence: 2,
          state: CloudLiveTurnLifecycle.cancelled,
        ),
      );

    final turn = container.read(cloudActiveTurnStateProvider('chat-1'));
    expect(turn?.revision, 3);
    expect(turn?.state, CloudLiveTurnLifecycle.cancelled);
    expect(turn?.isBusy, isFalse);
  });

  test('cloud busy state does not require local message runtime', () async {
    final container = ProviderContainer(
      overrides: [
        conversationSelectedProvider.overrideWithValue('chat-1'),
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(_workspace),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(cloudActiveTurnStatesProvider.notifier)
        .set(
          'chat-1',
          const CloudLiveTurnState(
            turnId: 'turn-1',
            revision: 3,
            sequence: 1,
            state: CloudLiveTurnLifecycle.awaitingApproval,
          ),
        );

    final busy = await container.read(
      conversationBusyStateProvider('local', 'chat-1').future,
    );

    expect(busy.isBusy, isTrue);
    expect(busy.cloudTurn?.state, CloudLiveTurnLifecycle.awaitingApproval);
  });
}

const _workspace = CloudWorkspaceRef(
  localWorkspaceId: 'local',
  serverUrl: 'https://example.com',
  accountId: 'account',
  cloudWorkspaceId: 7,
);
