// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_credentials_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillCredentialsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  SkillCredentialsDaoManager get managers => SkillCredentialsDaoManager(this);
}

class SkillCredentialsDaoManager {
  final _$SkillCredentialsDaoMixin _db;
  SkillCredentialsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ServiceConnectionsTableTableManager get serviceConnections =>
      $$ServiceConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.serviceConnections,
      );
}
