// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_connections_dao.dart';

// ignore_for_file: type=lint
mixin _$ModelConnectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  ModelConnectionsDaoManager get managers => ModelConnectionsDaoManager(this);
}

class ModelConnectionsDaoManager {
  final _$ModelConnectionsDaoMixin _db;
  ModelConnectionsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ServiceConnectionsTableTableManager get serviceConnections =>
      $$ServiceConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.serviceConnections,
      );
}
