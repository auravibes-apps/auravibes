// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  $WorkspaceModelSelectionsTable get workspaceModelSelections =>
      attachedDatabase.workspaceModelSelections;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  ConversationDaoManager get managers => ConversationDaoManager(this);
}

class ConversationDaoManager {
  final _$ConversationDaoMixin _db;
  ConversationDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(
        _db.attachedDatabase,
        _db.apiModelProviders,
      );
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
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db.attachedDatabase, _db.conversations);
}
