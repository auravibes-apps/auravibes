import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not subscribe after state gateway disposal', () async {
    final stateGateway = CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'local',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
      readState: (_) => throw UnimplementedError(),
      subscribe: (_) => const Stream.empty(),
    );
    var calls = 0;
    final gateway = CloudChatGateway.forTesting(
      stateGateway: stateGateway,
      subscribeTurn: (_) {
        calls++;

        return const Stream.empty();
      },
    );
    stateGateway.dispose();

    await gateway.subscribeTurn('turn').drain<void>();

    expect(calls, 0);
  });
}
