// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_tools_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationToolsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  $WorkspaceModelSelectionsTable get workspaceModelSelections =>
      attachedDatabase.workspaceModelSelections;
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
  $$ServiceConnectionsTableTableManager get serviceConnections =>
      $$ServiceConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.serviceConnections,
      );
  $$WorkspaceModelSelectionsTableTableManager get workspaceModelSelections =>
      $$WorkspaceModelSelectionsTableTableManager(
        _db.attachedDatabase,
        _db.workspaceModelSelections,
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
