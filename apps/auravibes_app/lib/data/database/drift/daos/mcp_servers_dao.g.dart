// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_servers_dao.dart';

// ignore_for_file: type=lint
mixin _$McpServersDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $McpServersTable get mcpServers => attachedDatabase.mcpServers;
  $ToolsGroupsTable get toolsGroups => attachedDatabase.toolsGroups;
  $ToolsTable get tools => attachedDatabase.tools;
  McpServersDaoManager get managers => McpServersDaoManager(this);
}

class McpServersDaoManager {
  final _$McpServersDaoMixin _db;
  McpServersDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$McpServersTableTableManager get mcpServers =>
      $$McpServersTableTableManager(_db.attachedDatabase, _db.mcpServers);
  $$ToolsGroupsTableTableManager get toolsGroups =>
      $$ToolsGroupsTableTableManager(_db.attachedDatabase, _db.toolsGroups);
  $$ToolsTableTableManager get tools =>
      $$ToolsTableTableManager(_db.attachedDatabase, _db.tools);
}
