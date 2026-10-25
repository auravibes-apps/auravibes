import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';

/// Explicit workspace deletion queues stable IDs without filesystem I/O.
/// Call [flush] after commit; failed jobs survive workspace metadata cascades.
class const LocalWorkspaceAssetErasure(
  final AppDatabase database,
  final AttachmentFileStore store,
) {
  Future<bool> delete(String workspaceId, Future<bool> Function() action) =>
      database.transaction(() async {
        await _capture(workspaceId);

        return await action();
      });

  Future<void> flush() async {
    final jobs = await database.select(database.workspaceAssetDeletions).get();
    for (final job in jobs) {
      await _remove(job.assetId);
    }
  }

  Future<void> recoverUntrackedWrite(String id) =>
      database.transaction(() async {
        if (await _metadataExists(id)) return;
        final _ = await database
            .into(database.workspaceAssetDeletions)
            .insert(
              WorkspaceAssetDeletionsCompanion.insert(assetId: id),
              mode: .insertOrIgnore,
            );
      });

  Future<void> _capture(String id) async {
    final workspace = await database.workspaceDao.getWorkspaceById(id);
    if (workspace?.type != .local) return;
    await _enqueue(await _assets(id));
  }

  Future<List<WorkspaceAssetRow>> _assets(String workspaceId) {
    final query = database.select(database.workspaceAssets)
      ..where((row) => row.workspaceId.equals(workspaceId));

    return query.get();
  }

  Future<void> _enqueue(List<WorkspaceAssetRow> rows) =>
      database.batch((batch) {
        batch.insertAll(
          database.workspaceAssetDeletions,
          rows.map(_job).toList(),
          mode: .insertOrIgnore,
        );
      });

  Future<void> _remove(String id) async {
    if (await _metadataExists(id) || !await _removeBytes(id)) return;
    await _forget(id);
  }

  Future<bool> _metadataExists(String id) async {
    final query = database.select(database.workspaceAssets)
      ..where((row) => row.id.equals(id));

    return await query.getSingleOrNull() != null;
  }

  Future<bool> _removeBytes(String id) async {
    try {
      await store.deleteAsset(id);

      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _forget(String id) async {
    final query = database.delete(database.workspaceAssetDeletions)
      ..where((row) => row.assetId.equals(id));
    final _ = await query.go();
  }
}

WorkspaceAssetDeletionsCompanion _job(WorkspaceAssetRow row) =>
    WorkspaceAssetDeletionsCompanion.insert(assetId: row.id);
