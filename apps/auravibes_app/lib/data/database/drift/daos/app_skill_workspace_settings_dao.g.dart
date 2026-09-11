// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_skill_workspace_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$AppSkillWorkspaceSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $AppSkillWorkspaceSettingsTable get appSkillWorkspaceSettings =>
      attachedDatabase.appSkillWorkspaceSettings;
  AppSkillWorkspaceSettingsDaoManager get managers =>
      AppSkillWorkspaceSettingsDaoManager(this);
}

class AppSkillWorkspaceSettingsDaoManager {
  final _$AppSkillWorkspaceSettingsDaoMixin _db;
  AppSkillWorkspaceSettingsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$AppSkillWorkspaceSettingsTableTableManager get appSkillWorkspaceSettings =>
      $$AppSkillWorkspaceSettingsTableTableManager(
        _db.attachedDatabase,
        _db.appSkillWorkspaceSettings,
      );
}
