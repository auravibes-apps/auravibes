import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_location.dart';
import 'package:drift/drift.dart';

/// Called inside the same transaction that inserts a message attachment.
class const LocalMessageAssetReferences(
  final AppDatabase database,
  final String namespace,
) {
  static const _denied = WorkspaceAssetException(.denied);

  Future<void> validate(
    String messageId,
    MessageAttachmentToCreate attachment,
  ) async {
    final location = _shared(attachment);
    if (location == null) return;
    await _scope(messageId, location);
    final asset = await _asset(location.workspaceId, location.assetId);
    _requireMetadata(asset, attachment);
  }

  WorkspaceAssetLocation? _shared(MessageAttachmentToCreate attachment) {
    final location = WorkspaceAssetLocation.parse(attachment.localPath);
    if (location == null && attachment.assetId == null) return null;
    if (location == null || !_matchesLocation(location, attachment)) {
      throw _denied;
    }

    return location;
  }

  bool _matchesLocation(
    WorkspaceAssetLocation location,
    MessageAttachmentToCreate attachment,
  ) =>
      location.namespace == namespace && location.assetId == attachment.assetId;

  Future<void> _scope(String messageId, WorkspaceAssetLocation location) async {
    if (location.workspaceId != await _workspace(messageId)) throw _denied;
  }

  static void _requireMetadata(
    WorkspaceAssetRow? asset,
    MessageAttachmentToCreate attachment,
  ) {
    if (asset == null ||
        asset.mimeType != attachment.mimeType ||
        asset.sizeBytes != attachment.sizeBytes) {
      throw _denied;
    }
  }

  Future<WorkspaceAssetRow?> _asset(String workspaceId, String id) =>
      (database.select(database.workspaceAssets)..where(
            (row) =>
                row.workspaceId.equals(workspaceId) &
                row.id.equals(id) &
                row.status.equals('active'),
          ))
          .getSingleOrNull();

  Future<String> _workspace(String messageId) async {
    final conversation = await _conversation(messageId);
    if (conversation == null) throw _denied;

    return await _localWorkspace(conversation.workspaceId);
  }

  Future<ConversationsTable?> _conversation(String messageId) async {
    final message = await database.messageDao.getMessageById(messageId);
    if (message == null) return null;

    return await database.conversationDao.getConversationById(
      message.conversationId,
    );
  }

  Future<String> _localWorkspace(String id) async {
    final query = database.select(database.workspaces)
      ..where((row) => row.id.equals(id));
    final workspace = await query.getSingleOrNull();
    if (workspace == null || workspace.type != .local) throw _denied;

    return workspace.id;
  }
}
