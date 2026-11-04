// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_archive_state_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationArchiveStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $ConversationArchiveStatesTable get conversationArchiveStates =>
      attachedDatabase.conversationArchiveStates;
  ConversationArchiveStateDaoManager get managers =>
      ConversationArchiveStateDaoManager(this);
}

class ConversationArchiveStateDaoManager {
  final _$ConversationArchiveStateDaoMixin _db;
  ConversationArchiveStateDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$ConversationArchiveStatesTableTableManager get conversationArchiveStates =>
      $$ConversationArchiveStatesTableTableManager(
        _db.attachedDatabase,
        _db.conversationArchiveStates,
      );
}
