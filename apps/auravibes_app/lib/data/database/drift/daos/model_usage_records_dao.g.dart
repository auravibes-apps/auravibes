// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_usage_records_dao.dart';

// ignore_for_file: type=lint
mixin _$ModelUsageRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  $WorkspaceModelSelectionsTable get workspaceModelSelections =>
      attachedDatabase.workspaceModelSelections;
  $AgentsTable get agents => attachedDatabase.agents;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  $ModelUsageRecordsTable get modelUsageRecords =>
      attachedDatabase.modelUsageRecords;
  ModelUsageRecordsDaoManager get managers => ModelUsageRecordsDaoManager(this);
}

class ModelUsageRecordsDaoManager {
  final _$ModelUsageRecordsDaoMixin _db;
  ModelUsageRecordsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ServiceConnectionsTableTableManager get serviceConnections =>
      $$ServiceConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.serviceConnections,
      );
  $$WorkspaceModelSelectionsTableTableManager get workspaceModelSelections =>
      $$WorkspaceModelSelectionsTableTableManager(
        _db.attachedDatabase,
        _db.workspaceModelSelections,
      );
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db.attachedDatabase, _db.agents);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db.attachedDatabase, _db.conversations);
  $$ModelUsageRecordsTableTableManager get modelUsageRecords =>
      $$ModelUsageRecordsTableTableManager(
        _db.attachedDatabase,
        _db.modelUsageRecords,
      );
}
