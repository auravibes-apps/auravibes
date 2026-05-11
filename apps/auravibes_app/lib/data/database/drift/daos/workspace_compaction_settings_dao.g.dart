// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_compaction_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceCompactionSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorkspaceCompactionSettingsTable get workspaceCompactionSettings =>
      attachedDatabase.workspaceCompactionSettings;
  WorkspaceCompactionSettingsDaoManager get managers =>
      WorkspaceCompactionSettingsDaoManager(this);
}

class WorkspaceCompactionSettingsDaoManager {
  final _$WorkspaceCompactionSettingsDaoMixin _db;
  WorkspaceCompactionSettingsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorkspaceCompactionSettingsTableTableManager
  get workspaceCompactionSettings =>
      $$WorkspaceCompactionSettingsTableTableManager(
        _db.attachedDatabase,
        _db.workspaceCompactionSettings,
      );
}
