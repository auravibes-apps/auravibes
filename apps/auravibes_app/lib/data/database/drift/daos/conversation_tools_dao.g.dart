// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_tools_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationToolsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  $CredentialsTable get credentials => attachedDatabase.credentials;
  $CredentialModelsTable get credentialModels =>
      attachedDatabase.credentialModels;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  $McpServersTable get mcpServers => attachedDatabase.mcpServers;
  $ToolsGroupsTable get toolsGroups => attachedDatabase.toolsGroups;
  $ToolsTable get tools => attachedDatabase.tools;
  $ConversationToolsTable get conversationTools =>
      attachedDatabase.conversationTools;
  ConversationToolsDaoManager get managers => ConversationToolsDaoManager(this);
}

class ConversationToolsDaoManager {
  final _$ConversationToolsDaoMixin _db;
  ConversationToolsDaoManager(this._db);
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
  $$McpServersTableTableManager get mcpServers =>
      $$McpServersTableTableManager(_db.attachedDatabase, _db.mcpServers);
  $$ToolsGroupsTableTableManager get toolsGroups =>
      $$ToolsGroupsTableTableManager(_db.attachedDatabase, _db.toolsGroups);
  $$ToolsTableTableManager get tools =>
      $$ToolsTableTableManager(_db.attachedDatabase, _db.tools);
  $$ConversationToolsTableTableManager get conversationTools =>
      $$ConversationToolsTableTableManager(
        _db.attachedDatabase,
        _db.conversationTools,
      );
}
