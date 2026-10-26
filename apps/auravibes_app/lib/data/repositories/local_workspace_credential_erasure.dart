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
    final rows = await (database.select(
      database.serviceConnections,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();
    final references = rows
        .map((row) => row.encryptedAuthValue)
        .whereType<String>()
        .where((reference) => reference.isNotEmpty)
        .toSet();
    if (references.isEmpty) return;

    await database.batch((batch) {
      batch.insertAll(
        database.workspaceCredentialDeletions,
        references
            .map(
              (reference) => WorkspaceCredentialDeletionsCompanion.insert(
                workspaceId: workspaceId,
                credentialReference: reference,
              ),
            )
            .toList(),
        mode: .insertOrIgnore,
      );
    });
  }

  /// Deletes unreferenced credentials and retains failed jobs for retry.
  Future<void> flush() async {
    final jobs = await database
        .select(database.workspaceCredentialDeletions)
        .get();
    for (final job in jobs) {
      final stillReferenced =
          await (database.select(database.serviceConnections)..where(
                (row) => row.encryptedAuthValue.equals(job.credentialReference),
              ))
              .get();
      if (stillReferenced.isNotEmpty) {
        await _forgetReference(job.credentialReference);
        continue;
      }

      try {
        if (_legacyApiKeyStorage.isLegacyReference(job.credentialReference)) {
          await _legacyApiKeyStorage.delete(job.credentialReference);
        }
        await encryptionService.deleteCredential(job.credentialReference);
        await _forgetReference(job.credentialReference);
      } on Object {
        // Keep the durable reference queued for the next cleanup pass.
      }
    }
  }

  Future<bool> hasPendingForWorkspace(String workspaceId) async {
    final jobs = await (database.select(
      database.workspaceCredentialDeletions,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();

    return jobs.isNotEmpty;
  }

  Future<void> _forgetReference(String reference) async {
    final _ = await (database.delete(
      database.workspaceCredentialDeletions,
    )..where((row) => row.credentialReference.equals(reference))).go();
  }
}
