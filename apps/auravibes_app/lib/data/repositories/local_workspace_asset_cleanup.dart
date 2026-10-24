import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_retention.dart';
import 'package:drift/drift.dart';

/// Explicit content deletion releases only references removed by that mutation.
/// Failed byte removals remain queued for the next workspace access.
class const LocalWorkspaceAssetCleanup(
  final AppDatabase database,
  final String workspaceId,
  final AttachmentFileStore store,
) {
  Future<void> flush() async {
    await LocalWorkspaceAssetRetention(database, workspaceId).authorize();
    final query = database.select(database.workspaceAssets)
      ..where(
        (row) =>
            row.workspaceId.equals(workspaceId) & row.status.equals('deleting'),
      );
    for (final row in await query.get()) {
      if (!await _removeBytes(row.id)) continue;
      final deletion = database.delete(database.workspaceAssets)
        ..where(
          (asset) =>
              asset.id.equals(row.id) &
              asset.workspaceId.equals(workspaceId) &
              asset.status.equals('deleting'),
        );
      final _ = await deletion.go();
    }
  }

  Future<bool> _removeBytes(String id) async {
    try {
      await store.deleteAsset(id);

      return true;
    } on Object {
      // Keep the durable deletion marker; never reactivate or expose the bytes.
      return false;
    }
  }
}
