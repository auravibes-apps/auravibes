import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_credential_erasure.dart';
import 'package:drift/drift.dart';

/// Explicit workspace deletion queues stable IDs without filesystem I/O.
/// Call [flush] after commit; failed jobs survive workspace metadata cascades.
class const LocalWorkspaceAssetErasure(
  final AppDatabase database,
  final AttachmentFileStore store, {
  final LocalWorkspaceCredentialErasure? credentialErasure,
}) {
  Future<bool> delete(String workspaceId, Future<bool> Function() action) =>
      database.transaction(() async {
        await _capture(workspaceId);
        final deleted = await action();
        if (deleted) {
          final _ = await (database.delete(
            database.workspaceContentReports,
          )..where((row) => row.workspaceId.equals(workspaceId))).go();
          final _ = await (database.delete(
            database.recentModelSelections,
          )..where((row) => row.workspaceId.equals(workspaceId))).go();
        }

        return deleted;
      });

  Future<void> flush() async {
    await credentialErasure?.flush();
    await _flushAttachments();
    final jobs = await database.select(database.workspaceAssetDeletions).get();
    for (final job in jobs) {
      await _remove(job.assetId);
    }
  }

  Future<bool> hasPendingCleanup(String workspaceId) async {
    if (await (credentialErasure?.hasPendingForWorkspace(workspaceId) ??
        Future.value(false))) {
      return true;
    }
    final assetJobs = await (database.select(
      database.workspaceAssetDeletions,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();
    if (assetJobs.isNotEmpty) return true;

    final attachmentJobs = await (database.select(
      database.workspaceAttachmentDeletions,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();

    return attachmentJobs.isNotEmpty;
  }

  /// Reports queued cleanup belonging to a workspace that no longer exists.
  Future<bool> hasPendingDeletedWorkspaceCleanup() async {
    final assets = await database
        .select(database.workspaceAssetDeletions)
        .get();
    final attachments = await database
        .select(database.workspaceAttachmentDeletions)
        .get();
    final credentials = await database
        .select(database.workspaceCredentialDeletions)
        .get();
    final ids = <String>{
      ...assets.map((job) => job.workspaceId).whereType<String>(),
      ...attachments.map((job) => job.workspaceId),
      ...credentials.map((job) => job.workspaceId),
    };
    for (final id in ids) {
      if (await database.workspaceDao.getWorkspaceById(id) == null) return true;
    }

    return false;
  }

  Future<void> recoverUntrackedWrite(
    String id, {
    required String workspaceId,
  }) => database.transaction(() async {
    if (await _metadataExists(id)) return;
    final _ = await database
        .into(database.workspaceAssetDeletions)
        .insert(
          WorkspaceAssetDeletionsCompanion.insert(
            assetId: id,
            workspaceId: .new(workspaceId),
          ),
          mode: .insertOrIgnore,
        );
  });

  Future<void> _capture(String id) async {
    final workspace = await database.workspaceDao.getWorkspaceById(id);
    if (workspace?.type != .local) return;
    await _enqueue(await _assets(id), workspaceId: id);
    await credentialErasure?.capture(id);
    await _enqueueAttachments(id);
  }

  Future<void> _enqueueAttachments(String workspaceId) async {
    final query = database.select(database.messageAttachments).join([
      innerJoin(
        database.messages,
        database.messages.id.equalsExp(database.messageAttachments.messageId),
      ),
      innerJoin(
        database.conversations,
        database.conversations.id.equalsExp(database.messages.conversationId),
      ),
    ])..where(database.conversations.workspaceId.equals(workspaceId));
    final rows = await query.get();
    final paths = rows
        .map((row) => row.readTable(database.messageAttachments).localPath)
        .toSet();
    if (paths.isEmpty) return;

    await database.batch((batch) {
      batch.insertAll(
        database.workspaceAttachmentDeletions,
        paths
            .map(
              (localPath) => WorkspaceAttachmentDeletionsCompanion.insert(
                workspaceId: workspaceId,
                localPath: localPath,
              ),
            )
            .toList(),
        mode: .insertOrIgnore,
      );
    });
  }

  Future<void> _flushAttachments() async {
    final jobs = await database
        .select(database.workspaceAttachmentDeletions)
        .get();
    for (final job in jobs) {
      final references = await (database.select(
        database.messageAttachments,
      )..where((row) => row.localPath.equals(job.localPath))).get();
      if (references.isNotEmpty) {
        await _forgetAttachment(job.workspaceId, job.localPath);
        continue;
      }

      try {
        await store.deleteFile(job.localPath);
        await _forgetAttachment(job.workspaceId, job.localPath);
      } on Object {
        // Keep the durable job; the next local cleanup pass retries the path.
      }
    }
  }

  Future<void> _forgetAttachment(String workspaceId, String localPath) async {
    final _ =
        await (database.delete(database.workspaceAttachmentDeletions)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.localPath.equals(localPath),
            ))
            .go();
  }

  Future<List<WorkspaceAssetRow>> _assets(String workspaceId) {
    final query = database.select(database.workspaceAssets)
      ..where((row) => row.workspaceId.equals(workspaceId));

    return query.get();
  }

  Future<void> _enqueue(
    List<WorkspaceAssetRow> rows, {
    required String workspaceId,
  }) => database.batch((batch) {
    batch.insertAll(
      database.workspaceAssetDeletions,
      rows.map((row) => _job(row, workspaceId: workspaceId)).toList(),
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

WorkspaceAssetDeletionsCompanion _job(
  WorkspaceAssetRow row, {
  required String workspaceId,
}) => WorkspaceAssetDeletionsCompanion.insert(
  assetId: row.id,
  workspaceId: .new(workspaceId),
);
