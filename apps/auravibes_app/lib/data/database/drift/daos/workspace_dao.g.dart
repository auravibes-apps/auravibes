// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  WorkspaceDaoManager get managers => WorkspaceDaoManager(this);
}

class WorkspaceDaoManager {
  final _$WorkspaceDaoMixin _db;
  WorkspaceDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
}
