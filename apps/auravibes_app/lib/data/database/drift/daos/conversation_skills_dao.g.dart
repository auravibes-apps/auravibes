// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_skills_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationSkillsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ServiceConnectionsTable get serviceConnections =>
      attachedDatabase.serviceConnections;
  $WorkspaceModelSelectionsTable get workspaceModelSelections =>
      attachedDatabase.workspaceModelSelections;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  $SkillCredentialDefinitionsTable get skillCredentialDefinitions =>
      attachedDatabase.skillCredentialDefinitions;
  $SkillsTable get skills => attachedDatabase.skills;
  $ConversationSkillsTable get conversationSkills =>
      attachedDatabase.conversationSkills;
  ConversationSkillsDaoManager get managers =>
      ConversationSkillsDaoManager(this);
}

class ConversationSkillsDaoManager {
  final _$ConversationSkillsDaoMixin _db;
  ConversationSkillsDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(
        _db.attachedDatabase,
        _db.apiModelProviders,
      );
  $$ServiceConnectionsTableTableManager get serviceConnections =>
      $$ServiceConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.serviceConnections,
      );
  $$WorkspaceModelSelectionsTableTableManager get workspaceModelSelections =>
      $$WorkspaceModelSelectionsTableTableManager(
        _db.attachedDatabase,
        _db.workspaceModelSelections,
      );
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db.attachedDatabase, _db.conversations);
  $$SkillCredentialDefinitionsTableTableManager
  get skillCredentialDefinitions =>
      $$SkillCredentialDefinitionsTableTableManager(
        _db.attachedDatabase,
        _db.skillCredentialDefinitions,
      );
  $$SkillsTableTableManager get skills =>
      $$SkillsTableTableManager(_db.attachedDatabase, _db.skills);
  $$ConversationSkillsTableTableManager get conversationSkills =>
      $$ConversationSkillsTableTableManager(
        _db.attachedDatabase,
        _db.conversationSkills,
      );
}
