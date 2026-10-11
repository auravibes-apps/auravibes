// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_works_dao.dart';

// ignore_for_file: type=lint
mixin _$BackgroundWorksDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  $WorkspaceModelSelectionsTable get workspaceModelSelections =>
      attachedDatabase.workspaceModelSelections;
  $AgentsTable get agents => attachedDatabase.agents;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  $MessagesTable get messages => attachedDatabase.messages;
  $BackgroundWorksTable get backgroundWorks => attachedDatabase.backgroundWorks;
  BackgroundWorksDaoManager get managers => BackgroundWorksDaoManager(this);
}

class BackgroundWorksDaoManager {
  final _$BackgroundWorksDaoMixin _db;
  BackgroundWorksDaoManager(this._db);
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
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
  $$BackgroundWorksTableTableManager get backgroundWorks =>
      $$BackgroundWorksTableTableManager(
        _db.attachedDatabase,
        _db.backgroundWorks,
      );
}
