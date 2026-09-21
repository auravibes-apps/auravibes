// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_resources_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillResourcesDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $SkillCredentialDefinitionsTable get skillCredentialDefinitions =>
      attachedDatabase.skillCredentialDefinitions;
  $SkillsTable get skills => attachedDatabase.skills;
  $SkillResourcesTable get skillResources => attachedDatabase.skillResources;
  SkillResourcesDaoManager get managers => SkillResourcesDaoManager(this);
}

class SkillResourcesDaoManager {
  final _$SkillResourcesDaoMixin _db;
  SkillResourcesDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$SkillCredentialDefinitionsTableTableManager
  get skillCredentialDefinitions =>
      $$SkillCredentialDefinitionsTableTableManager(
        _db.attachedDatabase,
        _db.skillCredentialDefinitions,
      );
  $$SkillsTableTableManager get skills =>
      $$SkillsTableTableManager(_db.attachedDatabase, _db.skills);
  $$SkillResourcesTableTableManager get skillResources =>
      $$SkillResourcesTableTableManager(
        _db.attachedDatabase,
        _db.skillResources,
      );
}
