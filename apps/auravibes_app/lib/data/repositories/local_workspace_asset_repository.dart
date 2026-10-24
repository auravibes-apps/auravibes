import 'dart:typed_data';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
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
    final mime = WorkspaceAssetInput.validate(name, bytes);
    final id = const UuidV7().generate();
    await database.transaction(() async {
      await _requireLocal();
      final _ = await database
          .into(database.workspaceAssets)
          .insert(
            WorkspaceAssetsCompanion.insert(
              id: .new(id),
              workspaceId: workspaceId,
              name: name.trim(),
              mimeType: mime,
              sizeBytes: bytes.length,
              checksum: sha256.convert(bytes).toString(),
            ),
          );
    });
    // Pending metadata makes interrupted writes discoverable for cleanup.
    await store.writeAsset(id, bytes);
    await database.transaction(() async {
      await _requireLocal();
      final _ =
          await (database.update(database.workspaceAssets)..where(
                (row) =>
                    row.id.equals(id) & row.workspaceId.equals(workspaceId),
              ))
              .write(const WorkspaceAssetsCompanion(status: .new('active')));
    });

    return await asset(id);
  }

  @override
  Future<WorkspaceAsset> asset(String id) async {
    await _requireLocal();
    final row =
        await (database.select(database.workspaceAssets)..where(
              (row) =>
                  row.id.equals(id) &
                  row.workspaceId.equals(workspaceId) &
                  row.status.equals('active'),
            ))
            .getSingleOrNull();
    if (row == null) throw const WorkspaceAssetException(.denied);

    return WorkspaceAsset(
      id: row.id,
      name: row.name,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes,
      checksum: row.checksum,
    );
  }

  @override
  Future<Uint8List> bytes(String id) async {
    final readable = await asset(id);

    return await store.readAsset(readable.id);
  }

  Future<void> _requireLocal() async {
    final workspace = await (database.select(
      database.workspaces,
    )..where((row) => row.id.equals(workspaceId))).getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceAssetException(.denied);
    }
  }
}
