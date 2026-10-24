import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_retention.dart';
import 'package:drift/drift.dart';

/// Queues byte release atomically with content changes; performs no file I/O.
class const LocalWorkspaceAssetRelease(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<T> mutate<T>(Future<T> Function() action) =>
      database.transaction(() async {
        final retention = LocalWorkspaceAssetRetention(database, workspaceId);
        final before = await retention.ids();
        final value = await action();
        final after = await retention.ids();
        for (final id in before.difference(after)) {
          await _queue(id);
        }

        return value;
      });

  Future<void> _queue(String id) async {
    final query = database.update(database.workspaceAssets)
      ..where(
        (row) =>
            row.id.equals(id) &
            row.workspaceId.equals(workspaceId) &
            row.status.equals('active'),
      );
    final _ = await query.write(
      const WorkspaceAssetsCompanion(status: .new('deleting')),
    );
  }
}
