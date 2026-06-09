// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model_selection_with_connection.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceModelSelectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  $WorkspaceModelSelectionsTable get workspaceModelSelections =>
      attachedDatabase.workspaceModelSelections;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  WorkspaceModelSelectionsDaoManager get managers =>
      WorkspaceModelSelectionsDaoManager(this);
}

class WorkspaceModelSelectionsDaoManager {
  final _$WorkspaceModelSelectionsDaoMixin _db;
  WorkspaceModelSelectionsDaoManager(this._db);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(
        _db.attachedDatabase,
        _db.apiModelProviders,
      );
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
  $$ApiModelsTableTableManager get apiModels =>
      $$ApiModelsTableTableManager(_db.attachedDatabase, _db.apiModels);
}
