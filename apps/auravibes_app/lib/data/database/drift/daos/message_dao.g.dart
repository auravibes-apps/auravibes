// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dao.dart';

// ignore_for_file: type=lint
mixin _$MessageDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  $CredentialsTable get credentials => attachedDatabase.credentials;
  $CredentialModelsTable get credentialModels =>
      attachedDatabase.credentialModels;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  $MessagesTable get messages => attachedDatabase.messages;
  MessageDaoManager get managers => MessageDaoManager(this);
}

class MessageDaoManager {
  final _$MessageDaoMixin _db;
  MessageDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(
        _db.attachedDatabase,
        _db.apiModelProviders,
      );
  $$ApiModelsTableTableManager get apiModels =>
      $$ApiModelsTableTableManager(_db.attachedDatabase, _db.apiModels);
  $$CredentialsTableTableManager get credentials =>
      $$CredentialsTableTableManager(_db.attachedDatabase, _db.credentials);
  $$CredentialModelsTableTableManager get credentialModels =>
      $$CredentialModelsTableTableManager(
        _db.attachedDatabase,
        _db.credentialModels,
      );
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db.attachedDatabase, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
}
