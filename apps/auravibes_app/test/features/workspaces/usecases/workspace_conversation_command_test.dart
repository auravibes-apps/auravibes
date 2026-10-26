import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_workspace_chat_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cross-chat stable records and stale revisions', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('one'),
            name: 'One',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final table = await tables.create(name: 'Items', labelName: 'Title');
    final record = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'Original'},
    );
    final command = WorkspaceConversationCommandUsecase(tables: tables);
    for (final conversation in ['first', 'second']) {
      final current = await tables.record(table.id, record.id);
      final result = await command.call(
        selection: .new(
          workspaceId: 'one',
          conversationId: conversation,
          itemId: table.id,
          kind: 'table',
          recordIds: [record.id],
        ),
        arguments: {
          'action': 'updateRecord',
          'tableId': table.id,
          'id': record.id,
          'revision': current.revision,
          'schemaRevision': table.schemaRevision,
          'values': {table.labelColumnId: conversation},
        },
      );
      expect(result['id'], record.id);
    }
    expect(
      (await tables.record(table.id, record.id)).values[table.labelColumnId],
      'second',
    );
    await expectLater(
      command.call(
        selection: .new(
          workspaceId: 'one',
          conversationId: 'first',
          itemId: table.id,
          kind: 'table',
          recordIds: [record.id],
        ),
        arguments: {
          'action': 'updateRecord',
          'tableId': table.id,
          'id': record.id,
          'revision': 1,
          'schemaRevision': table.schemaRevision,
          'values': {table.labelColumnId: 'Stale'},
        },
      ),
      throwsA(isA<Object>()),
    );
  });
  test('selected-only reads and denied writes', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('one'),
            name: 'One',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final table = await tables.create(name: 'Items', labelName: 'Title');
    final selected = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'Selected'},
    );
    final hidden = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'Private unselected'},
    );
    final command = WorkspaceConversationCommandUsecase(tables: tables);
    final selection = WorkspaceContextSelection(
      workspaceId: 'one',
      conversationId: 'chat',
      itemId: table.id,
      kind: 'table',
      recordIds: [selected.id],
    );
    final result = await command.call(
      selection: selection,
      arguments: {'action': 'read', 'tableId': table.id},
    );
    expect(result.toString(), contains('Selected'));
    expect(result.toString(), isNot(contains('Private unselected')));
    await expectLater(
      command.call(
        selection: selection,
        arguments: {
          'action': 'updateRecord',
          'tableId': table.id,
          'id': hidden.id,
          'revision': hidden.revision,
          'schemaRevision': table.schemaRevision,
          'values': {table.labelColumnId: 'Changed'},
        },
      ),
      throwsA(isA<Object>()),
    );
    expect(
      (await tables.record(table.id, hidden.id)).values[table.labelColumnId],
      'Private unselected',
    );
  });

  test('protected context survives reopen and revokes', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace-chat-context',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/items.sqlite');
    var database = AppDatabase(connection: NativeDatabase(file));
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('one'),
            name: 'One',
            type: .local,
          ),
        );
    var conversations = ConversationRepository(database);
    var messages = MessageRepository(database);
    final first = await conversations.createConversation(
      const .new(title: 'First', workspaceId: 'one', toolAccessMode: .allowAll),
    );
    final second = await conversations.createConversation(
      const .new(title: 'Second', workspaceId: 'one'),
    );
    var tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final table = await tables.create(name: 'Durable', labelName: 'Title');
    final selected = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'Selected'},
    );
    final selection = WorkspaceContextSelection(
      workspaceId: 'one',
      conversationId: first.id,
      itemId: table.id,
      kind: 'table',
      recordIds: [selected.id],
    );
    final _ = await messages.createMessage(
      .new(
        conversationId: first.id,
        content: 'Share selection',
        messageType: .text,
        isUser: true,
        status: .sent,
        metadata: jsonEncode(
          MessageMetadataEntity(
            modelMetadata: {'workspaceContextSelection': selection.toJson()},
          ).toJson(),
        ),
      ),
    );
    final untrusted = WorkspaceConversationToolsUsecase(
      conversations: conversations,
      context: (workspaceId) =>
          LocalWorkspaceContextRepository(database, workspaceId),
      commands: (_) async =>
          WorkspaceConversationCommandUsecase(tables: tables),
    );
    await expectLater(
      untrusted.call(
        conversationId: first.id,
        arguments: {'action': 'read', 'tableId': table.id},
      ),
      throwsA(isA<Object>()),
    );
    final _ = await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(first.id, 'trusted-first', selection);
    await database.close();
    database = AppDatabase(connection: NativeDatabase(file));
    addTearDown(database.close);
    conversations = ConversationRepository(database);
    messages = MessageRepository(database);
    tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final commands = WorkspaceConversationToolsUsecase(
      conversations: conversations,
      context: (workspaceId) =>
          LocalWorkspaceContextRepository(database, workspaceId),
      commands: (_) async =>
          WorkspaceConversationCommandUsecase(tables: tables),
    );
    final arguments = {'action': 'read', 'tableId': table.id};
    final history = [
      MessageEntity(
        id: 'stored-response',
        conversationId: first.id,
        content: '',
        messageType: .toolCall,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        metadata: .new(
          toolCalls: [
            MessageToolCallEntity(
              id: 'old-call',
              name: workspaceCommandToolName,
              argumentsRaw: jsonEncode({
                'action': 'read',
                'tableId': table.id,
                'values': 'Raw secret',
              }),
              responseRaw: jsonEncode({
                'records': ['Archived secret'],
              }),
              resultStatus: .success,
            ),
          ],
        ),
      ),
    ];
    final projection = ProjectWorkspaceChatContextUsecase(commands);
    final fresh = await projection(history);
    expect(
      (fresh.single.metadata ?? (throw StateError('Missing metadata')))
          .toolCalls
          .single
          .responseRaw,
      contains('Selected'),
    );
    expect(
      (fresh.single.metadata ?? (throw StateError('Missing metadata')))
          .toolCalls
          .single
          .responseRaw,
      isNot(contains('Archived secret')),
    );
    expect(
      (fresh.single.metadata ?? (throw StateError('Missing metadata')))
          .toolCalls
          .single
          .argumentsRaw,
      isNot(contains('Raw secret')),
    );

    expect(
      (await commands.call(
        conversationId: first.id,
        arguments: arguments,
      )).toString(),
      contains('Selected'),
    );
    await expectLater(
      commands.call(conversationId: second.id, arguments: arguments),
      throwsA(isA<Object>()),
    );
    final _ = await messages.createMessage(
      .new(
        conversationId: first.id,
        content: 'Stop sharing',
        messageType: .text,
        isUser: true,
        status: .sent,
        metadata: jsonEncode(
          const MessageMetadataEntity(
            modelMetadata: {'workspaceContextSelection': null},
          ).toJson(),
        ),
      ),
    );
    final _ = await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(first.id, 'trusted-revoke', null);
    final revoked = await projection(history);
    expect(
      (revoked.single.metadata ?? (throw StateError('Missing metadata')))
          .toolCalls
          .single
          .responseRaw,
      workspaceContextUnavailable,
    );
    expect(
      (revoked.single.metadata ?? (throw StateError('Missing metadata')))
          .toolCalls
          .single
          .responseRaw,
      isNot(contains('Selected')),
    );

    await expectLater(
      commands.call(conversationId: first.id, arguments: arguments),
      throwsA(isA<Object>()),
    );
  });

  test('atomic retries, reopen and fork consent denial', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace-chat-receipts',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/items.sqlite');
    var database = AppDatabase(connection: NativeDatabase(file));
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('one'),
            name: 'One',
            type: .local,
          ),
        );
    var conversations = ConversationRepository(database);
    var messages = MessageRepository(database);
    final chat = await conversations.createConversation(
      const .new(title: 'First', workspaceId: 'one'),
    );
    final grant = WorkspaceContextSelection(
      workspaceId: 'one',
      conversationId: chat.id,
      itemId: '',
      kind: 'directory',
    );
    final _ = await messages.createMessage(
      .new(
        conversationId: chat.id,
        content: 'Share destination',
        messageType: .text,
        isUser: true,
        status: .sent,
        metadata: jsonEncode(
          MessageMetadataEntity(
            modelMetadata: {'workspaceContextSelection': grant.toJson()},
          ).toJson(),
        ),
      ),
    );
    var tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    WorkspaceConversationToolsUsecase service() =>
        WorkspaceConversationToolsUsecase(
          conversations: conversations,
          context: (workspaceId) =>
              LocalWorkspaceContextRepository(database, workspaceId),
          commands: (_) async =>
              WorkspaceConversationCommandUsecase(tables: tables),
          receipts: .new(database),
        );
    final _ = await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(chat.id, 'trusted-create', grant);
    final create = {
      'action': 'createTable',
      'name': 'Created',
      'labelName': 'Title',
    };
    final host = ResolvedToolService(
      agentCancellationRuntime: .new(),
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => fail('Workspace edits must not use MCP'),
      workspaceConversationTools: service(),
    );
    final first =
        await host.call(
          conversationId: chat.id,
          toolCallId: 'create-table',
          tool: ResolvedTool.workspaceCommand(),
          arguments: create,
        ) as Map? ??
        (throw StateError('Expected map'));
    final replay =
        await service().call(
          conversationId: chat.id,
          operationId: 'create-table',
          arguments: create,
        ) as Map? ??
        (throw StateError('Expected map'));
    expect(replay['id'], first['id']);
    expect((await tables.list()).length, 1);
    final table = await tables.table(
      first['id'] as String? ?? (throw StateError('Expected string')),
    );
    final row =
        await service().call(
          conversationId: chat.id,
          operationId: 'create-record',
          arguments: {
            'action': 'createRecord',
            'tableId': table.id,
            'revision': table.revision,
            'schemaRevision': table.schemaRevision,
            'values': {table.labelColumnId: 'Persisted'},
          },
        ) as Map? ??
        (throw StateError('Expected map'));
    await database.close();
    database = AppDatabase(connection: NativeDatabase(file));
    addTearDown(database.close);
    conversations = ConversationRepository(database);
    messages = MessageRepository(database);
    tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final read = await service().call(
      conversationId: chat.id,
      arguments: {'action': 'read', 'tableId': table.id},
    );
    expect(read.toString(), contains(row['id']));
    expect(read.toString(), contains('Persisted'));
    final _ = await messages.createMessage(
      .new(
        conversationId: chat.id,
        content: 'Selected item read',
        messageType: .text,
        isUser: false,
        status: .sent,
        metadata: jsonEncode(
          MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'archived-read',
                name: workspaceCommandToolName,
                argumentsRaw: jsonEncode({
                  'action': 'read',
                  'tableId': table.id,
                }),
                responseRaw: jsonEncode(read),
                resultStatus: .success,
              ),
            ],
          ).toJson(),
        ),
      ),
    );
    final fork = await conversations.forkConversation(chat.id);
    final forkHistory = await messages.getMessagesByConversation(fork.id);
    final forkProjection = await ProjectWorkspaceChatContextUsecase(service())(
      forkHistory,
    );
    final forkCalls = forkProjection
        .expand(
          (message) => message.metadata?.toolCalls ?? <MessageToolCallEntity>[],
        )
        .where((call) => call.name == workspaceCommandToolName);
    expect(forkCalls, hasLength(1));
    expect(forkCalls.single.responseRaw, workspaceContextUnavailable);
    expect(forkCalls.single.responseRaw, isNot(contains('Persisted')));

    expect(
      (await LocalWorkspaceContextRepository(database, 'one').read(fork.id))
          .selection,
      isNull,
    );
    await expectLater(
      service().call(
        conversationId: fork.id,
        arguments: {'action': 'read', 'tableId': table.id},
      ),
      throwsA(isA<Object>()),
    );
    final _ = await messages.createMessage(
      .new(
        conversationId: fork.id,
        content: 'Imported share grant',
        messageType: .text,
        isUser: true,
        status: .sent,
        metadata: jsonEncode(
          MessageMetadataEntity(
            modelMetadata: {
              'workspaceContextSelection': {
                ...grant.toJson(),
                'conversationId': fork.id,
              },
            },
          ).toJson(),
        ),
      ),
    );
    await expectLater(
      service().call(
        conversationId: fork.id,
        arguments: {'action': 'read', 'tableId': table.id},
      ),
      throwsA(isA<Object>()),
    );

    final _ = await messages.createMessage(
      .new(
        conversationId: chat.id,
        content: 'Stop sharing',
        messageType: .text,
        isUser: true,
        status: .sent,
        metadata: jsonEncode(
          const MessageMetadataEntity(
            modelMetadata: {'workspaceContextSelection': null},
          ).toJson(),
        ),
      ),
    );
    final _ = await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(chat.id, 'trusted-create-revoke', null);
    await expectLater(
      service().call(
        conversationId: chat.id,
        operationId: 'create-table',
        arguments: create,
      ),
      throwsA(isA<Object>()),
    );
  });
}
