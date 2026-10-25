import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_assets.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_folders.dart';
import 'package:auravibes_app/data/repositories/local_workspace_purge_guard.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceFileRepository(
  final AppDatabase database,
  final String workspaceId,
  final WorkspaceAssetRepository assets,
) implements WorkspaceFileRepository {
  _Rows get _rows => .new(this);
  _Projection get _projection => .new(assets);

  @override
  Future<List<WorkspaceFile>> list({String? parentId}) async {
    final rows = await _rows.list(parentId);

    return await Future.wait(rows.map(_projection.file));
  }

  @override
  Future<WorkspaceFile> file(String id) async =>
      await _projection.file(await _rows.read(id));

  @override
  Future<WorkspaceFile> create(
    WorkspaceFileDraft draft, {
    bool sharingApproved = false,
  }) => database.transaction(() => _Creator(this).call(draft));

  @override
  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  }) => database.transaction(() => _Editor(this).call(file, name, parentId));
}

class const _Rows(final LocalWorkspaceFileRepository owner) {
  AppDatabase get _database => owner.database;

  Future<List<WorkspaceFileRow>> list(String? parentId) {
    final query = _database.select(_database.workspaceFiles)
      ..where((row) => _folder(row, parentId))
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);

    return query.get();
  }

  Future<WorkspaceFileRow> read(String id) async {
    final query = _database.select(_database.workspaceFiles)
      ..where((row) => _live(row) & row.id.equals(id));

    return _Policy.found(await query.getSingleOrNull());
  }

  Future<WorkspaceFileRow?> existing(String id) {
    final query = _database.select(_database.workspaceFiles)
      ..where((row) => row.id.equals(id));

    return query.getSingleOrNull();
  }

  Future<void> parent(String? id) async {
    if (id == null) return;
    final query = _database.select(_database.workspaceFolders)
      ..where((row) => _Policy.parent(row, id, owner.workspaceId));
    if (await query.getSingleOrNull() == null) {
      throw const WorkspaceAssetException(.invalid);
    }
  }

  Future<WorkspaceFileRow> insert(WorkspaceFileDraft draft) => _database
      .into(_database.workspaceFiles)
      .insertReturning(_Changes.create(owner.workspaceId, draft));

  Future<void> update(
    WorkspaceFileRow row,
    String name,
    String? parentId,
  ) async {
    final query = _database.update(_database.workspaceFiles)
      ..where((item) => _key(item, row.id));
    final _ = await query.write(_Changes.update(row, name, parentId));
  }

  Expression<bool> _key(WorkspaceFiles row, String id) =>
      row.id.equals(id) & row.workspaceId.equals(owner.workspaceId);

  Expression<bool> _folder(WorkspaceFiles row, String? parentId) =>
      _live(row) &
      (parentId == null
          ? row.parentId.isNull()
          : row.parentId.equals(parentId));

  Expression<bool> _live(WorkspaceFiles row) =>
      row.workspaceId.equals(owner.workspaceId) & row.deletedAt.isNull();
}

class const _Creator(final LocalWorkspaceFileRepository owner) {
  Future<WorkspaceFile> call(WorkspaceFileDraft draft) async {
    await _authorize(draft);
    final existing = await _existing(draft);
    if (existing != null) return await owner._projection.file(existing);

    return await _new(draft);
  }

  Future<void> _authorize(WorkspaceFileDraft draft) async {
    await LocalWorkspacePurgeGuard(
      owner.database,
      owner.workspaceId,
    ).resource('file', draft.id);
    final _ = await owner.assets.asset(draft.assetId);
  }

  Future<WorkspaceFileRow?> _existing(WorkspaceFileDraft draft) async {
    final row = await owner._rows.existing(draft.id);
    if (row != null) _Policy.replay(row, owner.workspaceId, draft);

    return row;
  }

  Future<WorkspaceFile> _new(WorkspaceFileDraft draft) async {
    await owner._rows.parent(draft.parentId);
    final row = await owner._rows.insert(draft);

    return await owner._projection.file(row);
  }
}

class const _Editor(final LocalWorkspaceFileRepository owner) {
  Future<WorkspaceFile> call(
    WorkspaceFile file,
    String name,
    String? parentId,
  ) async {
    final existing = await owner._rows.read(file.id);
    _Policy.revision(existing, file);
    await _write(existing, name, parentId);

    return await owner.file(file.id);
  }

  Future<void> _write(
    WorkspaceFileRow row,
    String name,
    String? parentId,
  ) async {
    await owner._rows.parent(parentId);
    await owner._rows.update(row, name, parentId);
  }
}

class const _Projection(final WorkspaceAssetRepository assets) {
  Future<WorkspaceFile> file(WorkspaceFileRow row) async {
    final asset = await _metadata(row.assetId);

    return WorkspaceFile(
      id: row.id,
      name: row.name,
      assetId: row.assetId,
      revision: row.revision,
      asset: asset,
      parentId: row.parentId,
    );
  }

  Future<WorkspaceAsset?> _metadata(String id) async {
    try {
      return await assets.asset(id);
    } on WorkspaceAssetException catch (error) {
      if (error.failure != .denied && error.failure != .unavailable) rethrow;

      return null;
    }
  }
}

abstract final class _Changes {
  static WorkspaceFilesCompanion create(
    String workspaceId,
    WorkspaceFileDraft draft,
  ) => WorkspaceFilesCompanion.insert(
    id: .new(draft.id),
    workspaceId: workspaceId,
    name: draft.name,
    parentId: .new(draft.parentId),
    assetId: draft.assetId,
    creationHash: _Policy.digest(draft),
  );

  static WorkspaceFilesCompanion update(
    WorkspaceFileRow row,
    String name,
    String? parentId,
  ) => WorkspaceFilesCompanion(
    updatedAt: .new(DateTime.now()),
    name: .new(name),
    parentId: .new(parentId),
    revision: .new(row.revision + 1),
  );
}

abstract final class _Policy {
  static WorkspaceFileRow found(WorkspaceFileRow? row) =>
      row ?? (throw const WorkspaceAssetException(.denied));

  static void replay(
    WorkspaceFileRow row,
    String workspaceId,
    WorkspaceFileDraft draft,
  ) {
    if (row.workspaceId != workspaceId ||
        row.deletedAt != null ||
        row.creationHash != digest(draft)) {
      throw const WorkspaceAssetException(.conflict);
    }
  }

  static void revision(WorkspaceFileRow row, WorkspaceFile expected) {
    if (row.revision != expected.revision) {
      throw const WorkspaceAssetException(.conflict);
    }
  }

  static Expression<bool> parent(
    WorkspaceFolders row,
    String id,
    String workspaceId,
  ) =>
      row.id.equals(id) &
      row.workspaceId.equals(workspaceId) &
      row.deletedAt.isNull();

  static String digest(WorkspaceFileDraft draft) => sha256
      .convert(
        utf8.encode(jsonEncode([draft.name, draft.assetId, draft.parentId])),
      )
      .toString();
}
