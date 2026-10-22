import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudMessageBookmarkGateway(final Client _client) {
  Future<List<MessageBookmarkView>> listForWorkspace(int workspaceId) =>
      CloudAppErrors.guardCall(
        .conversation,
        () => _client.conversation.listMessageBookmarks(
          .new(workspaceId: workspaceId),
        ),
      );
}
