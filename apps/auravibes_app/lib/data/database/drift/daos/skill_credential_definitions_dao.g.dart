// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_credential_definitions_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillCredentialDefinitionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $SkillCredentialDefinitionsTable get skillCredentialDefinitions =>
      attachedDatabase.skillCredentialDefinitions;
  SkillCredentialDefinitionsDaoManager get managers =>
      SkillCredentialDefinitionsDaoManager(this);
}

class SkillCredentialDefinitionsDaoManager {
  final _$SkillCredentialDefinitionsDaoMixin _db;
  SkillCredentialDefinitionsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$SkillCredentialDefinitionsTableTableManager
  get skillCredentialDefinitions =>
      $$SkillCredentialDefinitionsTableTableManager(
        _db.attachedDatabase,
        _db.skillCredentialDefinitions,
      );
}
