import 'package:drift/drift.dart';

/// Durable paths queued when deleting a workspace with chat attachments.
///
/// This table intentionally has no workspace foreign key so failed file
/// deletion can be retried after the workspace rows cascade away.
class WorkspaceAttachmentDeletions extends Table {
  TextColumn get workspaceId => text()();

  TextColumn get localPath => text()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId, localPath};
}
