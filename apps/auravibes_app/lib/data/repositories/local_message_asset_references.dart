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
  Future<void> validate(
    String messageId,
    MessageAttachmentToCreate attachment,
  ) async {
    final location = WorkspaceAssetLocation.parse(attachment.localPath);
    final id = attachment.assetId;
    if (location == null && id == null) return;
    if (location == null ||
        id != location.assetId ||
        namespace != location.namespace) {
      throw const WorkspaceAssetException(.denied);
    }
    final workspaceId = await _workspace(messageId);
    if (location.workspaceId != workspaceId) {
      throw const WorkspaceAssetException(.denied);
    }
    final asset = await _asset(workspaceId, id!);
    if (asset == null ||
        asset.mimeType != attachment.mimeType ||
        asset.sizeBytes != attachment.sizeBytes) {
      throw const WorkspaceAssetException(.denied);
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
    final message = await (database.select(
      database.messages,
    )..where((row) => row.id.equals(messageId))).getSingle();
    final conversation = await (database.select(
      database.conversations,
    )..where((row) => row.id.equals(message.conversationId))).getSingle();
    final workspace = await (database.select(
      database.workspaces,
    )..where((row) => row.id.equals(conversation.workspaceId))).getSingle();
    if (workspace.type != .local) throw const WorkspaceAssetException(.denied);
    return workspace.id;
  }
}
