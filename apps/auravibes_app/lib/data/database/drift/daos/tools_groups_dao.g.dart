// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tools_groups_dao.dart';

// ignore_for_file: type=lint
mixin _$ToolsGroupsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $McpServersTable get mcpServers => attachedDatabase.mcpServers;
  $ToolsGroupsTable get toolsGroups => attachedDatabase.toolsGroups;
  ToolsGroupsDaoManager get managers => ToolsGroupsDaoManager(this);
}

class ToolsGroupsDaoManager {
  final _$ToolsGroupsDaoMixin _db;
  ToolsGroupsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$McpServersTableTableManager get mcpServers =>
      $$McpServersTableTableManager(_db.attachedDatabase, _db.mcpServers);
  $$ToolsGroupsTableTableManager get toolsGroups =>
      $$ToolsGroupsTableTableManager(_db.attachedDatabase, _db.toolsGroups);
}
