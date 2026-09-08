import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/riverpod.dart';

Future<CloudChatGateway?> cloudChatGatewayForWorkspace(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );

  return gateway == null ? null : CloudChatGateway(gateway);
}
