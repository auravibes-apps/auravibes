// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_models_dao.dart';

// ignore_for_file: type=lint
mixin _$CredentialModelsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $CredentialsTable get credentials => attachedDatabase.credentials;
  $CredentialModelsTable get credentialModels =>
      attachedDatabase.credentialModels;
  CredentialModelsDaoManager get managers => CredentialModelsDaoManager(this);
}

class CredentialModelsDaoManager {
  final _$CredentialModelsDaoMixin _db;
  CredentialModelsDaoManager(this._db);
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
  $$CredentialModelsTableTableManager get credentialModels =>
      $$CredentialModelsTableTableManager(
        _db.attachedDatabase,
        _db.credentialModels,
      );
}
