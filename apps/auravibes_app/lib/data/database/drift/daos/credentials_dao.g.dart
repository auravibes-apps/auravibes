// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_dao.dart';

// ignore_for_file: type=lint
mixin _$CredentialsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $CredentialsTable get credentials => attachedDatabase.credentials;
  CredentialsDaoManager get managers => CredentialsDaoManager(this);
}

class CredentialsDaoManager {
  final _$CredentialsDaoMixin _db;
  CredentialsDaoManager(this._db);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(
        _db.attachedDatabase,
        _db.apiModelProviders,
      );
  $$ApiModelsTableTableManager get apiModels =>
      $$ApiModelsTableTableManager(_db.attachedDatabase, _db.apiModels);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$CredentialsTableTableManager get credentials =>
      $$CredentialsTableTableManager(_db.attachedDatabase, _db.credentials);
}
