// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_connections_dao.dart';

// ignore_for_file: type=lint
mixin _$ModelConnectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ModelConnectionsTable get modelConnections =>
      attachedDatabase.modelConnections;
  ModelConnectionsDaoManager get managers => ModelConnectionsDaoManager(this);
}

class ModelConnectionsDaoManager {
  final _$ModelConnectionsDaoMixin _db;
  ModelConnectionsDaoManager(this._db);
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
}
