// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agents_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $AgentsTable get agents => attachedDatabase.agents;
  $SkillCredentialDefinitionsTable get skillCredentialDefinitions =>
      attachedDatabase.skillCredentialDefinitions;
  $SkillsTable get skills => attachedDatabase.skills;
  $AgentSkillsTable get agentSkills => attachedDatabase.agentSkills;
  AgentsDaoManager get managers => AgentsDaoManager(this);
}

class AgentsDaoManager {
  final _$AgentsDaoMixin _db;
  AgentsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db.attachedDatabase, _db.agents);
  $$SkillCredentialDefinitionsTableTableManager
  get skillCredentialDefinitions =>
      $$SkillCredentialDefinitionsTableTableManager(
        _db.attachedDatabase,
        _db.skillCredentialDefinitions,
      );
  $$SkillsTableTableManager get skills =>
      $$SkillsTableTableManager(_db.attachedDatabase, _db.skills);
  $$AgentSkillsTableTableManager get agentSkills =>
      $$AgentSkillsTableTableManager(_db.attachedDatabase, _db.agentSkills);
}
