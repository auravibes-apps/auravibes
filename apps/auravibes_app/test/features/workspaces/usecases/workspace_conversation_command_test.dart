import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two authorized Conversations edit one stable record and reject stale revision', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database.into(database.workspaces).insert(
      WorkspacesCompanion.insert(id: const .new('one'), name: 'One', type: .local));
    final tables = OrganizeWorkspaceTablesUsecase(LocalWorkspaceTableRepository(database, 'one'));
    final table = await tables.create(name: 'Items', labelName: 'Title');
    final record = await tables.createRecord(table: table, values: {table.labelColumnId: 'Original'});
    final command = WorkspaceConversationCommandUsecase(tables: tables);
    for (final conversation in ['first', 'second']) {
      final current = await tables.record(table.id, record.id);
      final result = await command.call(
        selection: WorkspaceContextSelection(workspaceId: 'one', conversationId: conversation, itemId: table.id,
          kind: 'table', recordIds: [record.id]),
        arguments: {'action': 'updateRecord', 'tableId': table.id, 'id': record.id,
          'revision': current.revision, 'schemaRevision': table.schemaRevision,
          'values': {table.labelColumnId: conversation}},
      );
      expect(result['id'], record.id);
    }
    expect((await tables.record(table.id, record.id)).values[table.labelColumnId], 'second');
    await expectLater(command.call(
      selection: WorkspaceContextSelection(workspaceId: 'one', conversationId: 'first', itemId: table.id,
        kind: 'table', recordIds: [record.id]),
      arguments: {'action': 'updateRecord', 'tableId': table.id, 'id': record.id,
        'revision': 1, 'schemaRevision': table.schemaRevision,
        'values': {table.labelColumnId: 'Stale'}},
    ), throwsA(isA<Object>()));
  });
  test('read includes only explicitly selected records and denied selection cannot write', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database.into(database.workspaces).insert(
      WorkspacesCompanion.insert(id: const .new('one'), name: 'One', type: .local));
    final tables = OrganizeWorkspaceTablesUsecase(LocalWorkspaceTableRepository(database, 'one'));
    final table = await tables.create(name: 'Items', labelName: 'Title');
    final selected = await tables.createRecord(table: table, values: {table.labelColumnId: 'Selected'});
    final hidden = await tables.createRecord(table: table, values: {table.labelColumnId: 'Private unselected'});
    final command = WorkspaceConversationCommandUsecase(tables: tables);
    final selection = WorkspaceContextSelection(workspaceId: 'one', conversationId: 'chat',
      itemId: table.id, kind: 'table', recordIds: [selected.id]);
    final result = await command.call(selection: selection,
      arguments: {'action': 'read', 'tableId': table.id});
    expect(result.toString(), contains('Selected'));
    expect(result.toString(), isNot(contains('Private unselected')));
    await expectLater(command.call(selection: selection,
      arguments: {'action': 'updateRecord', 'tableId': table.id, 'id': hidden.id,
        'revision': hidden.revision, 'schemaRevision': table.schemaRevision,
        'values': {table.labelColumnId: 'Changed'}}), throwsA(isA<Object>()));
    expect((await tables.record(table.id, hidden.id)).values[table.labelColumnId], 'Private unselected');
  });

}
