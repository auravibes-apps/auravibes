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
          await _DeletionMetadata(database).purge(workspaceId);
        }

        return deleted;
      });

  Future<void> flush() async {
    await credentialErasure?.flush();
    await _AttachmentCleanup(database, store).flush();
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

    return await _DeletionJobs(database).pending(workspaceId);
  }

  /// Reports queued cleanup belonging to a workspace that no longer exists.
  Future<bool> hasPendingDeletedWorkspaceCleanup() =>
      _DeletionJobs(database).orphans();

  Future<void> recoverUntrackedWrite(
    String id, {
    required String workspaceId,
  }) => database.transaction(() async {
    if (await _metadataExists(id)) return;
    final _ = await database
        .into(database.workspaceAssetDeletions)
        .insert(_pendingAsset(id, workspaceId), mode: .insertOrIgnore);
  });

  Future<void> _capture(String id) async {
    final workspace = await database.workspaceDao.getWorkspaceById(id);
    if (workspace?.type != .local) return;
    await _AssetQueue(database).capture(id);
    await credentialErasure?.capture(id);
    await _AttachmentCleanup(database, store).enqueue(id);
  }

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

class const _DeletionJobs(final AppDatabase database) {
  Future<bool> pending(String workspaceId) async {
    final assets = await (database.select(
      database.workspaceAssetDeletions,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();
    if (assets.isNotEmpty) return true;

    return await _hasAttachments(workspaceId);
  }

  Future<bool> orphans() async {
    final ids = await _workspaceIds();
    for (final id in ids) {
      if (await database.workspaceDao.getWorkspaceById(id) == null) return true;
    }

    return false;
  }

  Future<bool> _hasAttachments(String workspaceId) async {
    final query = database.select(database.workspaceAttachmentDeletions)
      ..where((row) => row.workspaceId.equals(workspaceId));

    return (await query.get()).isNotEmpty;
  }

  Future<Set<String>> _workspaceIds() async {
    final assets = await database
        .select(database.workspaceAssetDeletions)
        .get();

    return {
      ...assets.map((job) => job.workspaceId).whereType<String>(),
      ...await _otherWorkspaceIds(),
    };
  }

  Future<Set<String>> _otherWorkspaceIds() async {
    final attachments = await database
        .select(database.workspaceAttachmentDeletions)
        .get();
    final credentials = await database
        .select(database.workspaceCredentialDeletions)
        .get();

    return {
      ...attachments.map((job) => job.workspaceId),
      ...credentials.map((job) => job.workspaceId),
    };
  }
}

class const _AssetQueue(final AppDatabase database) {
  Future<void> capture(String workspaceId) async =>
      await _enqueue(await _assets(workspaceId), workspaceId: workspaceId);

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
}

class const _DeletionMetadata(final AppDatabase database) {
  Future<void> purge(String workspaceId) async {
    final _ = await (database.delete(
      database.workspaceContentReports,
    )..where((row) => row.workspaceId.equals(workspaceId))).go();
    final _ = await (database.delete(
      database.recentModelSelections,
    )..where((row) => row.workspaceId.equals(workspaceId))).go();
  }
}

class const _AttachmentCleanup(
  final AppDatabase database,
  final AttachmentFileStore store,
) {
  Future<void> enqueue(String workspaceId) async {
    final paths = await _paths(workspaceId);
    if (paths.isEmpty) return;
    await _queue(workspaceId, paths);
  }

  Future<void> flush() async {
    final jobs = await database
        .select(database.workspaceAttachmentDeletions)
        .get();
    for (final job in jobs) {
      await _flushOne(job);
    }
  }

  Future<Set<String>> _paths(String workspaceId) async {
    final query = _attachmentQuery(database)
      ..where(database.conversations.workspaceId.equals(workspaceId));
    final rows = await query.get();

    return rows
        .map((row) => row.readTable(database.messageAttachments).localPath)
        .toSet();
  }

  Future<void> _queue(String workspaceId, Set<String> paths) async {
    await database.batch((batch) {
      batch.insertAll(
        database.workspaceAttachmentDeletions,
        paths.map((path) => _attachmentJob(workspaceId, path)).toList(),
        mode: .insertOrIgnore,
      );
    });
  }

  Future<void> _flushOne(WorkspaceAttachmentDeletion job) async {
    if (await _hasReferences(job.localPath)) {
      await _forgetAttachment(job.workspaceId, job.localPath);

      return;
    }

    try {
      await store.deleteFile(job.localPath);
      await _forgetAttachment(job.workspaceId, job.localPath);
    } on Object {
      // Keep the durable job; the next local cleanup pass retries the path.
    }
  }

  Future<bool> _hasReferences(String path) async {
    final query = database.select(database.messageAttachments)
      ..where((row) => row.localPath.equals(path));

    return (await query.get()).isNotEmpty;
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
}

WorkspaceAssetDeletionsCompanion _job(
  WorkspaceAssetRow row, {
  required String workspaceId,
}) => WorkspaceAssetDeletionsCompanion.insert(
  assetId: row.id,
  workspaceId: .new(workspaceId),
);

WorkspaceAssetDeletionsCompanion _pendingAsset(String id, String workspaceId) =>
    WorkspaceAssetDeletionsCompanion.insert(
      assetId: id,
      workspaceId: .new(workspaceId),
    );

WorkspaceAttachmentDeletionsCompanion _attachmentJob(
  String workspaceId,
  String path,
) => WorkspaceAttachmentDeletionsCompanion.insert(
  workspaceId: workspaceId,
  localPath: path,
);

JoinedSelectStatement<HasResultSet, dynamic> _attachmentQuery(
  AppDatabase database,
) => database.select(database.messageAttachments).join([
  innerJoin(
    database.messages,
    database.messages.id.equalsExp(database.messageAttachments.messageId),
  ),
  innerJoin(
    database.conversations,
    database.conversations.id.equalsExp(database.messages.conversationId),
  ),
]);
