import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

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

    return await Future.wait(rows.map(_file));
  }

  @override
  Future<WorkspaceFile> file(String id) async => await _file(await _row(id));

  @override
  Future<WorkspaceFile> create({
    required String id,
    required String name,
    required String assetId,
    String? parentId,
    bool sharingApproved = false,
  }) => database.transaction(() async {
    final _ = await assets.asset(assetId);
    final digest = sha256
        .convert(utf8.encode(jsonEncode([name, assetId, parentId])))
        .toString();
    final existing = await (database.select(
      database.workspaceFiles,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      if (existing.workspaceId != workspaceId ||
          existing.deletedAt != null ||
          existing.creationHash != digest) {
        throw const WorkspaceAssetException(.conflict);
      }

      return await _file(existing);
    }
    await _parent(parentId);
    final row = await database
        .into(database.workspaceFiles)
        .insertReturning(
          WorkspaceFilesCompanion.insert(
            id: .new(id),
            workspaceId: workspaceId,
            name: name,
            parentId: .new(parentId),
            assetId: assetId,
            creationHash: digest,
          ),
        );

    return await _file(row);
  });

  @override
  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  }) => database.transaction(() async {
    final existing = await _row(file.id);
    if (existing.revision != file.revision) {
      throw const WorkspaceAssetException(.conflict);
    }
    await _parent(parentId);
    final _ =
        await (database.update(database.workspaceFiles)..where(
              (row) =>
                  row.id.equals(file.id) & row.workspaceId.equals(workspaceId),
            ))
            .write(
              WorkspaceFilesCompanion(
                updatedAt: .new(DateTime.now()),
                name: .new(name),
                parentId: .new(parentId),
                revision: .new(existing.revision + 1),
              ),
            );

    return await this.file(file.id);
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

  Future<WorkspaceFile> _file(WorkspaceFileRow row) async {
    WorkspaceAsset? asset;
    try {
      asset = await assets.asset(row.assetId);
    } on WorkspaceAssetException catch (error) {
      if (error.failure != .denied && error.failure != .unavailable) rethrow;
    }

    return WorkspaceFile(
      id: row.id,
      name: row.name,
      assetId: row.assetId,
      revision: row.revision,
      asset: asset,
      parentId: row.parentId,
    );
  }

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
