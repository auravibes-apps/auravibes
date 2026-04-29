// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model_selections_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceModelSelectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ModelConnectionsTable get modelConnections =>
      attachedDatabase.modelConnections;
  $WorkspaceModelSelectionsTable get workspaceModelSelections =>
      attachedDatabase.workspaceModelSelections;
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
  $$ApiModelsTableTableManager get apiModels =>
      $$ApiModelsTableTableManager(_db.attachedDatabase, _db.apiModels);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ModelConnectionsTableTableManager get modelConnections =>
      $$ModelConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.modelConnections,
      );
  $$WorkspaceModelSelectionsTableTableManager get workspaceModelSelections =>
      $$WorkspaceModelSelectionsTableTableManager(
        _db.attachedDatabase,
        _db.workspaceModelSelections,
      );
}
