import 'package:drift/drift.dart';

/// Durable references to secure-store credentials queued by workspace erasure.
/// This table intentionally has no workspace foreign key so retries survive the
/// workspace cascade.
class WorkspaceCredentialDeletions extends Table {
  /// Scalar ID only; cleanup receipts outlive workspace cascade deletion.
  TextColumn get workspaceId => text()();

  TextColumn get credentialReference => text()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId, credentialReference};
}
