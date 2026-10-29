// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflows_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceWorkflowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorkspaceFoldersTable get workspaceFolders =>
      attachedDatabase.workspaceFolders;
  $WorkspaceWorkflowsTable get workspaceWorkflows =>
      attachedDatabase.workspaceWorkflows;
  WorkspaceWorkflowsDaoManager get managers =>
      WorkspaceWorkflowsDaoManager(this);
}

class WorkspaceWorkflowsDaoManager {
  final _$WorkspaceWorkflowsDaoMixin _db;
  WorkspaceWorkflowsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorkspaceFoldersTableTableManager get workspaceFolders =>
      $$WorkspaceFoldersTableTableManager(
        _db.attachedDatabase,
        _db.workspaceFolders,
      );
  $$WorkspaceWorkflowsTableTableManager get workspaceWorkflows =>
      $$WorkspaceWorkflowsTableTableManager(
        _db.attachedDatabase,
        _db.workspaceWorkflows,
      );
}
