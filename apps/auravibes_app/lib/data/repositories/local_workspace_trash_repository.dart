import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_reader.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_restorer.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_selection.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_store.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:uuid/v7.dart';

class const LocalWorkspaceTrashRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceTrashRepository {
  LocalWorkspaceTrashStore get _store => .new(database, workspaceId);
  @override
  Future<List<WorkspaceTrashBatch>> list() =>
      LocalWorkspaceTrashReader(_store).list();
  @override
  Future<WorkspaceDeletedReference?> deletedReference(
    String tableId,
    String recordId,
  ) => LocalWorkspaceTrashReader(_store).deletedReference(tableId, recordId);
  @override
  Future<WorkspaceTrashBatch> preview(WorkspaceTrashTarget target) =>
      database.transaction(() async {
        final selection = await LocalWorkspaceTrashSelection.load(
          _store,
          target,
        );

        return selection.impact(target);
      });
  @override
  Future<WorkspaceTrashBatch> trash(
    WorkspaceTrashTarget target, {
    required String planToken,
  }) => database.transaction(() => _trash(target, planToken));
  @override
  Future<WorkspaceTrashRestoration> restore(String batchId) => database
      .transaction(() => LocalWorkspaceTrashRestorer(_store).restore(batchId));

  Future<WorkspaceTrashBatch> _trash(
    WorkspaceTrashTarget target,
    String token,
  ) async {
    final selection = await LocalWorkspaceTrashSelection.load(_store, target);
    if (selection.token != token) {
      throw const WorkspaceTableException(conflict: true);
    }
    await selection.tombstone(_store);
    final batch = selection.impact(target, id: const UuidV7().generate());
    await _store.insertBatch(batch, selection.members);

    return batch;
  }
}
