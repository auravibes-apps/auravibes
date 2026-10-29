import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_assets.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_access.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_erasure.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_retention.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_input.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

class const LocalWorkspaceAssetRepository(
  final AppDatabase database,
  final String workspaceId,
  final AttachmentFileStore store,
) implements WorkspaceAssetRepository {
  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) async {
    final metadata = _Metadata.upload(name, bytes);
    final rows = _AssetRows(database, workspaceId);
    await rows.insert(metadata);

    return await _LocalAssetUpload(this).call(metadata, bytes);
  }

  @override
  Future<WorkspaceAsset> asset(String id) async {
    await LocalWorkspaceAssetRetention(database, workspaceId).authorize();
    final row = await _AssetRows(database, workspaceId).active(id);
    if (row == null ||
        !await LocalWorkspaceAssetAccess(database, workspaceId).allows(id)) {
      throw const WorkspaceAssetException(.denied);
    }

    return _Metadata.read(row);
  }

  @override
  Future<Uint8List> bytes(String id) async {
    final readable = await asset(id);

    return await store.readAsset(readable.id);
  }
}

class const _LocalAssetUpload(final LocalWorkspaceAssetRepository owner) {
  Future<WorkspaceAsset> call(WorkspaceAsset metadata, Uint8List bytes) async {
    try {
      return await _write(metadata, bytes);
    } on Object {
      await _AssetRows(owner.database, owner.workspaceId).failed(metadata.id);
      await LocalWorkspaceAssetErasure(
        owner.database,
        owner.store,
      ).recoverUntrackedWrite(metadata.id, workspaceId: owner.workspaceId);
      rethrow;
    }
  }

  Future<WorkspaceAsset> _write(
    WorkspaceAsset metadata,
    Uint8List bytes,
  ) async {
    // Pending metadata makes interrupted writes discoverable for cleanup.
    await owner.store.writeAsset(metadata.id, bytes);
    await _AssetRows(owner.database, owner.workspaceId).activate(metadata.id);

    return await owner.asset(metadata.id);
  }
}

class const _AssetRows(final AppDatabase database, final String workspaceId) {
  Future<void> insert(WorkspaceAsset asset) => database.transaction(() async {
    await LocalWorkspaceAssetRetention(database, workspaceId).authorize();
    final _ = await database
        .into(database.workspaceAssets)
        .insert(_pending(asset));
  });

  Future<void> activate(String id) => database.transaction(() async {
    await LocalWorkspaceAssetRetention(database, workspaceId).authorize();
    await _markActive(id);
  });

  Future<WorkspaceAssetRow?> active(String id) {
    final query = database.select(database.workspaceAssets)
      ..where((row) => _scope(row, id) & row.status.equals('active'));

    return query.getSingleOrNull();
  }

  Future<void> failed(String id) async {
    final query = database.update(database.workspaceAssets)
      ..where((row) => _activatable(row, id));
    final _ = await query.write(
      const WorkspaceAssetsCompanion(status: .new('deleting')),
    );
  }

  Future<void> _markActive(String id) async {
    final query = database.update(database.workspaceAssets)
      ..where((row) => _activatable(row, id));
    final updated = await query.write(
      const WorkspaceAssetsCompanion(status: .new('active')),
    );
    _requireActivation(updated);
  }

  Expression<bool> _activatable(WorkspaceAssets row, String id) =>
      _scope(row, id) & row.status.equals('pending');

  static void _requireActivation(int count) {
    if (count != 1) throw const WorkspaceAssetException(.denied);
  }

  Expression<bool> _scope(WorkspaceAssets row, String id) =>
      row.id.equals(id) & row.workspaceId.equals(workspaceId);

  WorkspaceAssetsCompanion _pending(WorkspaceAsset asset) =>
      WorkspaceAssetsCompanion.insert(
        id: .new(asset.id),
        workspaceId: workspaceId,
        name: asset.name,
        mimeType: asset.mimeType,
        sizeBytes: asset.sizeBytes,
        checksum: asset.checksum,
      );
}

abstract final class _Metadata {
  static WorkspaceAsset upload(String name, Uint8List bytes) {
    final mime = WorkspaceAssetInput.validate(name, bytes);

    return WorkspaceAsset(
      id: const UuidV7().generate(),
      name: name.trim(),
      mimeType: mime,
      sizeBytes: bytes.length,
      checksum: sha256.convert(bytes).toString(),
    );
  }

  static WorkspaceAsset read(WorkspaceAssetRow row) => WorkspaceAsset(
    id: row.id,
    name: row.name,
    mimeType: row.mimeType,
    sizeBytes: row.sizeBytes,
    checksum: row.checksum,
  );
}
