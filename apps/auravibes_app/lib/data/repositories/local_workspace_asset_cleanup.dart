import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_assets.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_erasure.dart';
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
    await LocalWorkspaceAssetErasure(database, store).flush();
    for (final row in await _pending()) {
      if (await _removeBytes(row.id)) await _removeMetadata(row.id);
    }
  }

  Future<List<WorkspaceAssetRow>> _pending() {
    final query = database.select(database.workspaceAssets)
      ..where(
        (row) =>
            row.workspaceId.equals(workspaceId) & row.status.equals('deleting'),
      );

    return query.get();
  }

  Future<void> _removeMetadata(String id) async {
    final query = database.delete(database.workspaceAssets)
      ..where((row) => _deleting(row, id));
    final _ = await query.go();
  }

  Expression<bool> _deleting(WorkspaceAssets row, String id) =>
      row.id.equals(id) &
      row.workspaceId.equals(workspaceId) &
      row.status.equals('deleting');

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
