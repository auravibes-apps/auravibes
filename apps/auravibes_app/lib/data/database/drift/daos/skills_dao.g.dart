// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skills_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $SkillCredentialDefinitionsTable get skillCredentialDefinitions =>
      attachedDatabase.skillCredentialDefinitions;
  $SkillsTable get skills => attachedDatabase.skills;
  SkillsDaoManager get managers => SkillsDaoManager(this);
}

class SkillsDaoManager {
  final _$SkillsDaoMixin _db;
  SkillsDaoManager(this._db);
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
}
