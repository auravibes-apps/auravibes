import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_release.dart';

class const LocalWorkspaceAssetMutation(final AppDatabase database) {
  Future<T> conversation<T>(String id, Future<T> Function() action) async {
    final workspace = await _workspace(id);
    if (workspace == null) return await database.transaction(action);

    return await LocalWorkspaceAssetRelease(database, workspace).mutate(action);
  }

  Future<String?> _workspace(String id) async {
    final conversation = await database.conversationDao.getConversationById(id);
    if (conversation == null) return null;

    return await _local(conversation.workspaceId);
  }

  Future<String?> _local(String id) async {
    final query = database.select(database.workspaces)
      ..where((row) => row.id.equals(id));
    final workspace = await query.getSingleOrNull();

    return workspace?.type == .local ? id : null;
  }
}
