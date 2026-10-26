import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'unselected references stay hidden and reject guessed targets',
    () async {
      final fixture = await _create();
      addTearDown(fixture.database.close);
      final target = await fixture.tables.create(
        name: 'Target',
        labelName: 'Title',
      );
      final retained = await fixture.tables.createRecord(
        table: target,
        values: {target.labelColumnId: 'Retained secret'},
      );
      final guessed = await fixture.tables.createRecord(
        table: target,
        values: {target.labelColumnId: 'Unselected secret'},
      );
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('two'),
              name: 'Two',
              type: .local,
            ),
          );
      final otherTables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(fixture.database, 'two'),
      );
      final otherTarget = await otherTables.create(
        name: 'Other target',
        labelName: 'Title',
      );
      final otherRecord = await otherTables.createRecord(
        table: otherTarget,
        values: {otherTarget.labelColumnId: 'Other workspace secret'},
      );
      var source = await fixture.tables.create(
        name: 'Source',
        labelName: 'Title',
      );
      source = await fixture.tables.saveColumn(
        table: source,
        column: .new(
          id: '',
          name: 'Related',
          type: .reference,
          defaultValue: retained.id,
          targetTableId: target.id,
        ),
      );
      final reference = source.columns.singleWhere(
        (column) => column.type == .reference,
      );
      final row = await fixture.tables.createRecord(
        table: source,
        values: {source.labelColumnId: 'Selected', reference.id: retained.id},
      );
      final _ = await fixture.context.save(
        fixture.chatId,
        'selected-source',
        .new(
          workspaceId: 'one',
          conversationId: fixture.chatId,
          itemId: source.id,
          kind: 'table',
          recordIds: [row.id],
        ),
      );
      final read = await fixture.tools.call(
        conversationId: fixture.chatId,
        arguments: {'action': 'read', 'tableId': source.id},
      );
      expect(read.toString(), isNot(contains(retained.id)));
      expect(read.toString(), isNot(contains(target.id)));
      expect(read.toString(), isNot(contains('Retained secret')));
      expect(read.toString(), isNot(contains('Unselected secret')));
      expect(read.toString(), contains('restrictedReferenceColumns'));
      expect(read.toString(), contains(reference.id));
      var failureIndex = 0;
      for (final input in [
        {
          'action': 'saveColumn',
          'column': {
            'id': '',
            'name': 'Guessed',
            'type': 'reference',
            'targetTableId': target.id,
          },
        },
        {
          'action': 'saveColumn',
          'column': {
            'id': '',
            'name': 'Foreign workspace',
            'type': 'reference',
            'targetTableId': otherTarget.id,
          },
        },
        {
          'action': 'saveColumn',
          'column': {
            'id': reference.id,
            'name': 'Related',
            'type': 'reference',
            'defaultValue': guessed.id,
          },
        },
        {
          'action': 'createRecord',
          'values': {source.labelColumnId: 'Guessed', reference.id: guessed.id},
        },
        {
          'action': 'createRecord',
          'values': {
            source.labelColumnId: 'Foreign workspace',
            reference.id: otherRecord.id,
          },
        },
        {
          'action': 'updateRecord',
          'id': row.id,
          'values': {source.labelColumnId: 'Guessed', reference.id: guessed.id},
        },
      ]) {
        await expectLater(
          fixture.tools.call(
            conversationId: fixture.chatId,
            operationId: '${input['action']}-reference-${failureIndex++}',
            arguments: {
              'tableId': source.id,
              'revision': row.revision,
              'schemaRevision': source.schemaRevision,
              ...input,
              if (input['action'] == 'saveColumn' ||
                  input['action'] == 'createRecord')
                'revision': source.revision,
            },
          ),
          throwsA(
            isA<WorkspaceTableException>().having(
              (error) => error.denied,
              'denied',
              isTrue,
            ),
          ),
        );
      }
      final _ = await fixture.tools.call(
        conversationId: fixture.chatId,
        operationId: 'preserve-hidden-reference',
        arguments: {
          'action': 'updateRecord',
          'tableId': source.id,
          'id': row.id,
          'revision': row.revision,
          'schemaRevision': source.schemaRevision,
          'values': {source.labelColumnId: 'Edited'},
        },
      );
      final updated = await fixture.tables.record(source.id, row.id);
      expect(updated.values[source.labelColumnId], 'Edited');
      expect(updated.values[reference.id], retained.id);
      expect(
        (await fixture.tables.table(source.id)).schemaRevision,
        source.schemaRevision,
      );
      expect(await fixture.tables.records(source.id), hasLength(1));
      final _ = await fixture.tools.call(
        conversationId: fixture.chatId,
        operationId: 'rename-retained-reference',
        arguments: {
          'action': 'saveColumn',
          'tableId': source.id,
          'revision': source.revision,
          'schemaRevision': source.schemaRevision,
          'column': {
            'id': reference.id,
            'type': 'reference',
            'name': 'Renamed',
          },
        },
      );
      final renamed = await fixture.tables.table(source.id);
      expect(
        renamed.columns
            .singleWhere((column) => column.id == reference.id)
            .targetTableId,
        target.id,
      );
    },
  );
  test(
    'verified same-epoch creations support cross-table relationships',
    () async {
      final fixture = await _create();
      addTearDown(fixture.database.close);
      final _ = await fixture.context.save(
        fixture.chatId,
        'root-destination',
        .new(
          workspaceId: 'one',
          conversationId: fixture.chatId,
          itemId: '',
          kind: 'directory',
        ),
      );
      var sequence = 0;
      Future<Map<String, Object?>> command(
        Map<String, Object?> arguments,
      ) async {
        final result = await fixture.tools.call(
          conversationId: fixture.chatId,
          operationId: 'create-${sequence++}',
          arguments: arguments,
        );
        if (result is! Map<String, Object?>) {
          throw StateError('Expected command result');
        }

        return result;
      }

      final targetResult = await command({
        'action': 'createTable',
        'name': 'Target',
        'labelName': 'Title',
      });
      final target = await fixture.tables.table(_resultId(targetResult));
      final targetRow = await command({
        'action': 'createRecord',
        'tableId': target.id,
        'revision': target.revision,
        'schemaRevision': target.schemaRevision,
        'values': {target.labelColumnId: 'Related'},
      });
      final sourceResult = await command({
        'action': 'createTable',
        'name': 'Source',
        'labelName': 'Title',
      });
      var source = await fixture.tables.table(_resultId(sourceResult));
      final _ = await command({
        'action': 'saveColumn',
        'tableId': source.id,
        'revision': source.revision,
        'schemaRevision': source.schemaRevision,
        'column': {
          'id': '',
          'name': 'Related',
          'type': 'reference',
          'targetTableId': target.id,
        },
      });
      source = await fixture.tables.table(source.id);
      final reference = source.columns.singleWhere(
        (column) => column.type == .reference,
      );
      final created = await command({
        'action': 'createRecord',
        'tableId': source.id,
        'revision': source.revision,
        'schemaRevision': source.schemaRevision,
        'values': {
          source.labelColumnId: 'Selected',
          reference.id: targetRow['id'],
        },
      });
      final current = await fixture.tables.record(
        source.id,
        _resultId(created),
      );
      expect(current.values[reference.id], targetRow['id']);
      final read = await command({'action': 'read', 'tableId': source.id});
      expect(read.toString(), contains(targetRow['id']));
    },
  );
}

typedef _Fixture = ({
  AppDatabase database,
  String chatId,
  OrganizeWorkspaceTablesUsecase tables,
  LocalWorkspaceContextRepository context,
  WorkspaceConversationToolsUsecase tools,
});

Future<_Fixture> _create() async {
  final database = AppDatabase(connection: NativeDatabase.memory());
  final _ = await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: const .new('one'),
          name: 'One',
          type: .local,
        ),
      );
  final conversations = ConversationRepository(database);
  final chat = await conversations.createConversation(
    const .new(title: 'Chat', workspaceId: 'one'),
  );
  final tables = OrganizeWorkspaceTablesUsecase(
    LocalWorkspaceTableRepository(database, 'one'),
  );
  final context = LocalWorkspaceContextRepository(database, 'one');
  final tools = WorkspaceConversationToolsUsecase(
    conversations: conversations,
    context: (_) => context,
    commands: (_) async => WorkspaceConversationCommandUsecase(tables: tables),
    receipts: .new(database),
  );

  return (
    database: database,
    chatId: chat.id,
    tables: tables,
    context: context,
    tools: tools,
  );
}

String _resultId(Map<String, Object?> result) {
  final id = result['id'];
  if (id is! String) throw StateError('Missing result identity');

  return id;
}
