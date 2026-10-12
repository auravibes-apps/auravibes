// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflows_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkflowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorkflowsTable get workflows => attachedDatabase.workflows;
  WorkflowsDaoManager get managers => WorkflowsDaoManager(this);
}

class WorkflowsDaoManager {
  final _$WorkflowsDaoMixin _db;
  WorkflowsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorkflowsTableTableManager get workflows =>
      $$WorkflowsTableTableManager(_db.attachedDatabase, _db.workflows);
}
