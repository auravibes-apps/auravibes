// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_agent_hook_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceAgentHookSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorkspaceAgentHookSettingsTable get workspaceAgentHookSettings =>
      attachedDatabase.workspaceAgentHookSettings;
  WorkspaceAgentHookSettingsDaoManager get managers =>
      WorkspaceAgentHookSettingsDaoManager(this);
}

class WorkspaceAgentHookSettingsDaoManager {
  final _$WorkspaceAgentHookSettingsDaoMixin _db;
  WorkspaceAgentHookSettingsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorkspaceAgentHookSettingsTableTableManager
  get workspaceAgentHookSettings =>
      $$WorkspaceAgentHookSettingsTableTableManager(
        _db.attachedDatabase,
        _db.workspaceAgentHookSettings,
      );
}
