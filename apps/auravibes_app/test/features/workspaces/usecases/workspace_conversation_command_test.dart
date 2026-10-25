import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';

import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/features/workspaces/usecases/project_workspace_chat_context_usecase.dart';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_command_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
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
        selection: WorkspaceContextSelection(
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
        selection: WorkspaceContextSelection(
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
  test('read includes only explicitly selected records and denied selection cannot write', () async {
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

  test('trusted selected context survives local reopen and revokes independently of approval mode', () async {
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
      .new(title: 'First', workspaceId: 'one', toolAccessMode: .allowAll),
    );
    final second = await conversations.createConversation(
      .new(title: 'Second', workspaceId: 'one'),
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
            modelMetadata: {workspaceContextMetadataKey: selection.toJson()},
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
    await LocalWorkspaceContextRepository(
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
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        metadata: MessageMetadataEntity(
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
      fresh.single.metadata!.toolCalls.single.responseRaw,
      contains('Selected'),
    );
    expect(
      fresh.single.metadata!.toolCalls.single.responseRaw,
      isNot(contains('Archived secret')),
    );
    expect(
      fresh.single.metadata!.toolCalls.single.argumentsRaw,
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
          MessageMetadataEntity(
            modelMetadata: {workspaceContextMetadataKey: null},
          ).toJson(),
        ),
      ),
    );
    await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(first.id, 'trusted-revoke', null);
    final revoked = await projection(history);
    expect(
      revoked.single.metadata!.toolCalls.single.responseRaw,
      workspaceContextUnavailable,
    );
    expect(
      revoked.single.metadata!.toolCalls.single.responseRaw,
      isNot(contains('Selected')),
    );

    await expectLater(
      commands.call(conversationId: first.id, arguments: arguments),
      throwsA(isA<Object>()),
    );
  });

  test('created scope and atomic create receipts survive retry and reopen, then revoke', () async {
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
      .new(title: 'First', workspaceId: 'one'),
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
            modelMetadata: {workspaceContextMetadataKey: grant.toJson()},
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
          receipts: LocalWorkspaceCommandRepository(database),
          commands: (_) async =>
              WorkspaceConversationCommandUsecase(tables: tables),
        );
    await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(chat.id, 'trusted-create', grant);
    final create = {
      'action': 'createTable',
      'name': 'Created',
      'labelName': 'Title',
    };
    final host = ResolvedToolService(
      agentCancellationRuntime: AgentCancellationRuntime(),
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => fail('Workspace edits must not use MCP'),
      workspaceConversationTools: service(),
    );
    final first = await host.call(
      conversationId: chat.id,
      toolCallId: 'create-table',
      tool: ResolvedTool.workspaceCommand(),
      arguments: create,
    ) as Map;
    final replay = await service().call(
      conversationId: chat.id,
      operationId: 'create-table',
      arguments: create,
    ) as Map;
    expect(replay['id'], first['id']);
    expect((await tables.list()).length, 1);
    final table = await tables.table(first['id'] as String);
    final row = await service().call(
      conversationId: chat.id,
      operationId: 'create-record',
      arguments: {
        'action': 'createRecord',
        'tableId': table.id,
        'revision': table.revision,
        'schemaRevision': table.schemaRevision,
        'values': {table.labelColumnId: 'Persisted'},
      },
    ) as Map;
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
        content: 'Stop sharing',
        messageType: .text,
        isUser: true,
        status: .sent,
        metadata: jsonEncode(
          MessageMetadataEntity(
            modelMetadata: {workspaceContextMetadataKey: null},
          ).toJson(),
        ),
      ),
    );
    await LocalWorkspaceContextRepository(
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
