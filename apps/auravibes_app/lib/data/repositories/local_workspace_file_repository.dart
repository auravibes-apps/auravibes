import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

class const LocalWorkspaceFileRepository(
  final AppDatabase database,
  final String workspaceId,
  final WorkspaceAssetRepository assets,
) implements WorkspaceFileRepository {
  @override
  Future<List<WorkspaceFile>> list({String? parentId}) async {
    final rows =
        await (database.select(database.workspaceFiles)
              ..where(
                (row) =>
                    row.workspaceId.equals(workspaceId) &
                    row.deletedAt.isNull() &
                    (parentId == null
                        ? row.parentId.isNull()
                        : row.parentId.equals(parentId)),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();
    return Future.wait(rows.map(_file));
  }

  @override
  Future<WorkspaceFile> file(String id) async => _file(await _row(id));

  @override
  Future<WorkspaceFile> create({
    required String name,
    required String assetId,
    String? parentId,
    bool sharingApproved = false,
  }) => database.transaction(() async {
    final _ = await assets.asset(assetId);
    await _parent(parentId);
    final row = await database
        .into(database.workspaceFiles)
        .insertReturning(
          WorkspaceFilesCompanion.insert(
            id: .new(const UuidV7().generate()),
            workspaceId: workspaceId,
            name: name,
            assetId: assetId,
            parentId: .new(parentId),
          ),
        );
    return _file(row);
  });

  @override
  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  }) => database.transaction(() async {
    final existing = await _row(file.id);
    if (existing.revision != file.revision)
      throw const WorkspaceAssetException(.conflict);
    await _parent(parentId);
    final _ =
        await (database.update(database.workspaceFiles)..where(
              (row) =>
                  row.id.equals(file.id) & row.workspaceId.equals(workspaceId),
            ))
            .write(
              WorkspaceFilesCompanion(
                name: .new(name),
                parentId: .new(parentId),
                revision: .new(existing.revision + 1),
                updatedAt: .new(DateTime.now()),
              ),
            );
    return this.file(file.id);
  });

  Future<WorkspaceFileRow> _row(String id) async {
    final row =
        await (database.select(database.workspaceFiles)..where(
              (row) =>
                  row.id.equals(id) &
                  row.workspaceId.equals(workspaceId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) throw const WorkspaceAssetException(.denied);
    return row;
  }

  Future<WorkspaceFile> _file(WorkspaceFileRow row) async => WorkspaceFile(
    id: row.id,
    name: row.name,
    parentId: row.parentId,
    revision: row.revision,
    asset: await assets.asset(row.assetId),
  );

  Future<void> _parent(String? id) async {
    if (id == null) return;
    final row =
        await (database.select(database.workspaceFolders)..where(
              (row) =>
                  row.id.equals(id) &
                  row.workspaceId.equals(workspaceId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) throw const WorkspaceAssetException(.invalid);
  }
}
