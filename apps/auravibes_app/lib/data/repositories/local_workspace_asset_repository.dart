import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_assets.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_access.dart';
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
    // Pending metadata makes interrupted writes discoverable for cleanup.
    await store.writeAsset(metadata.id, bytes);
    await rows.activate(metadata.id);

    return await asset(metadata.id);
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

  Future<void> _markActive(String id) async {
    final query = database.update(database.workspaceAssets)
      ..where((row) => _scope(row, id));
    final _ = await query.write(
      const WorkspaceAssetsCompanion(status: .new('active')),
    );
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
