import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/legacy_api_key_storage.dart';

/// Queues and retries deletion of local secure-store credentials.
class LocalWorkspaceCredentialErasure(
  final AppDatabase database,
  final EncryptionService encryptionService, {
  LegacyApiKeyStorage? legacyApiKeyStorage,
}) {
  final LegacyApiKeyStorage _legacyApiKeyStorage =
      legacyApiKeyStorage ?? LegacyApiKeyStorage();

  /// Captures credential references before their connection rows cascade away.
  Future<void> capture(String workspaceId) async {
    final references = await _references(workspaceId);
    if (references.isEmpty) return;

    await _enqueue(workspaceId, references);
  }

  /// Deletes unreferenced credentials and retains failed jobs for retry.
  Future<void> flush() async {
    final jobs = await database
        .select(database.workspaceCredentialDeletions)
        .get();
    for (final job in jobs) {
      await _flushOne(job.credentialReference);
    }
  }

  Future<bool> hasPendingForWorkspace(String workspaceId) async {
    final jobs = await (database.select(
      database.workspaceCredentialDeletions,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();

    return jobs.isNotEmpty;
  }

  Future<void> _enqueue(String workspaceId, Set<String> references) async {
    await database.batch((batch) {
      batch.insertAll(
        database.workspaceCredentialDeletions,
        references.map((reference) => _job(workspaceId, reference)).toList(),
        mode: .insertOrIgnore,
      );
    });
  }

  Future<Set<String>> _references(String workspaceId) async {
    final rows = await (database.select(
      database.serviceConnections,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();

    return rows
        .map((row) => row.encryptedAuthValue)
        .whereType<String>()
        .where(_notEmpty)
        .toSet();
  }

  Future<void> _flushOne(String reference) async {
    if (await _isReferenced(reference)) {
      await _forgetReference(reference);

      return;
    }
    try {
      if (_legacyApiKeyStorage.isLegacyReference(reference)) {
        await _legacyApiKeyStorage.delete(reference);
      }
      await encryptionService.deleteCredential(reference);
      await _forgetReference(reference);
    } on Object {
      // Keep the durable reference queued for the next cleanup pass.
    }
  }

  Future<bool> _isReferenced(String reference) async {
    final query = database.select(database.serviceConnections)
      ..where((row) => row.encryptedAuthValue.equals(reference));

    return (await query.get()).isNotEmpty;
  }

  Future<void> _forgetReference(String reference) async {
    final _ = await (database.delete(
      database.workspaceCredentialDeletions,
    )..where((row) => row.credentialReference.equals(reference))).go();
  }
}

bool _notEmpty(String reference) => reference.isNotEmpty;

WorkspaceCredentialDeletionsCompanion _job(
  String workspaceId,
  String reference,
) => WorkspaceCredentialDeletionsCompanion.insert(
  workspaceId: workspaceId,
  credentialReference: reference,
);
