// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_template_tools_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillTemplateToolsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $SkillCredentialDefinitionsTable get skillCredentialDefinitions =>
      attachedDatabase.skillCredentialDefinitions;
  $SkillsTable get skills => attachedDatabase.skills;
  $SkillTemplateToolsTable get skillTemplateTools =>
      attachedDatabase.skillTemplateTools;
  SkillTemplateToolsDaoManager get managers =>
      SkillTemplateToolsDaoManager(this);
}

class SkillTemplateToolsDaoManager {
  final _$SkillTemplateToolsDaoMixin _db;
  SkillTemplateToolsDaoManager(this._db);
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
  $$SkillTemplateToolsTableTableManager get skillTemplateTools =>
      $$SkillTemplateToolsTableTableManager(
        _db.attachedDatabase,
        _db.skillTemplateTools,
      );
}
