// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_tools_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentToolsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $AgentsTable get agents => attachedDatabase.agents;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  $McpServersTable get mcpServers => attachedDatabase.mcpServers;
  $ToolsGroupsTable get toolsGroups => attachedDatabase.toolsGroups;
  $ToolsTable get tools => attachedDatabase.tools;
  $AgentToolsTable get agentTools => attachedDatabase.agentTools;
  AgentToolsDaoManager get managers => AgentToolsDaoManager(this);
}

class AgentToolsDaoManager {
  final _$AgentToolsDaoMixin _db;
  AgentToolsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db.attachedDatabase, _db.agents);
  $$ServiceConnectionsTableTableManager get serviceConnections =>
      $$ServiceConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.serviceConnections,
      );
  $$McpServersTableTableManager get mcpServers =>
      $$McpServersTableTableManager(_db.attachedDatabase, _db.mcpServers);
  $$ToolsGroupsTableTableManager get toolsGroups =>
      $$ToolsGroupsTableTableManager(_db.attachedDatabase, _db.toolsGroups);
  $$ToolsTableTableManager get tools =>
      $$ToolsTableTableManager(_db.attachedDatabase, _db.tools);
  $$AgentToolsTableTableManager get agentTools =>
      $$AgentToolsTableTableManager(_db.attachedDatabase, _db.agentTools);
}
