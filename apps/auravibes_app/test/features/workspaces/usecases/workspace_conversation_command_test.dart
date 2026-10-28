import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_workspace_chat_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Folders extends Mock implements OrganizeWorkspaceFoldersUsecase;

class _Views extends Mock implements ManageWorkspaceViewsUsecase;

class _Files extends Mock implements OrganizeWorkspaceFilesUsecase;

void main() {
  test(
    'Directory resolves colliding IDs by kind and denies ambiguous items',
    () async {
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
      final conversations = ConversationRepository(database);
      final chat = await conversations.createConversation(
        const .new(title: 'Chat', workspaceId: 'one'),
      );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      final table = await tables.create(name: 'Items', labelName: 'Title');
      final folders = _Folders();
      final views = _Views();
      final files = _Files();
      when(folders.list).thenAnswer(
        (_) async => [
          WorkspaceFolder(id: table.id, name: 'Folder', revision: 1),
        ],
      );
      when(() => folders.list(parentId: table.id)).thenAnswer((_) async => []);
      when(views.list).thenAnswer((_) async => []);
      when(() => views.list(parentId: table.id)).thenAnswer((_) async => []);
      when(files.list).thenAnswer(
        (_) async => [
          WorkspaceFile(
            id: table.id,
            name: 'File',
            assetId: 'asset',
            revision: 1,
          ),
        ],
      );
      when(() => files.list(parentId: table.id)).thenAnswer((_) async => []);
      final tools = WorkspaceConversationToolsUsecase(
        conversations: conversations,
        context: (id) => LocalWorkspaceContextRepository(database, id),
        commands: (_) async => WorkspaceConversationCommandUsecase(
          tables: tables,
          folders: folders,
          views: views,
          files: files,
        ),
      );
      final result = await tools.call(
        conversationId: chat.id,
        arguments: {'action': 'read', 'tableId': table.id},
      ) as Map?;
      expect(result?['name'], 'Items');
      await expectLater(
        tools.call(
          conversationId: chat.id,
          arguments: {'action': 'read', 'id': table.id},
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );
  test('directory tool lists paths and finds nested names locally', () async {
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
    final conversations = ConversationRepository(database);
    final chat = await conversations.createConversation(
      const .new(title: 'Chat', workspaceId: 'one'),
    );
    final folders = OrganizeWorkspaceFoldersUsecase(
      LocalWorkspaceFolderRepository(database, 'one'),
    );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final sales = await folders.create(name: 'Sales');
    final leads = await folders.create(name: 'Leads', parentId: sales.id);
    final _ = await tables.create(
      name: 'Contacts',
      labelName: 'Name',
      parentId: leads.id,
    );
    final views = _Views();
    final files = _Files();
    when(views.list).thenAnswer((_) async => []);
    when(files.list).thenAnswer((_) async => []);
    when(() => views.list(parentId: sales.id)).thenAnswer((_) async => []);
    when(() => views.list(parentId: leads.id)).thenAnswer((_) async => []);
    when(() => files.list(parentId: sales.id)).thenAnswer((_) async => []);
    when(() => files.list(parentId: leads.id)).thenAnswer((_) async => []);
    final tools = WorkspaceConversationToolsUsecase(
      conversations: conversations,
      context: (id) => LocalWorkspaceContextRepository(database, id),
      commands: (_) async => WorkspaceConversationCommandUsecase(
        tables: tables,
        folders: folders,
        views: views,
        files: files,
      ),
    );

    final listed =
        await tools.call(
          conversationId: chat.id,
          arguments: {'action': 'readDirectory', 'path': 'Sales'},
        ) as Map<String, Object?>? ??
        (throw StateError('Expected directory result'));
    expect(listed['path'], 'Sales');
    final listedEntries =
        listed['entries'] as List<Object?>? ??
        (throw StateError('Expected directory entries'));
    expect(listedEntries.single, containsPair('path', 'Sales/Leads'));
    final found =
        await tools.call(
          conversationId: chat.id,
          arguments: {'action': 'readDirectory', 'nameRegex': r'^Contacts$'},
        ) as Map<String, Object?>? ??
        (throw StateError('Expected directory result'));
    final foundEntries =
        found['entries'] as List<Object?>? ??
        (throw StateError('Expected directory entries'));
    expect(foundEntries.single, containsPair('path', 'Sales/Leads/Contacts'));
  });
  test('Directory resolves visible tables and their authorized rows', () async {
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
    final conversations = ConversationRepository(database);
    final chat = await conversations.createConversation(
      const .new(title: 'Chat', workspaceId: 'one'),
    );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final folders = OrganizeWorkspaceFoldersUsecase(
      LocalWorkspaceFolderRepository(database, 'one'),
    );
    final folder = await folders.create(name: 'Folder');
    final table = await tables.create(
      name: 'Items',
      labelName: 'Title',
      parentId: folder.id,
    );
    final _ = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'Private'},
    );
    final views = _Views();
    final files = _Files();
    when(views.list).thenAnswer((_) async => []);
    when(files.list).thenAnswer((_) async => []);
    when(() => views.list(parentId: folder.id)).thenAnswer((_) async => []);
    when(() => files.list(parentId: folder.id)).thenAnswer((_) async => []);
    final tools = WorkspaceConversationToolsUsecase(
      conversations: conversations,
      context: (workspaceId) =>
          LocalWorkspaceContextRepository(database, workspaceId),
      commands: (_) async => WorkspaceConversationCommandUsecase(
        tables: tables,
        folders: folders,
        views: views,
        files: files,
      ),
      receipts: .new(database),
    );
    final result = await tools.call(
      conversationId: chat.id,
      arguments: {'action': 'read', 'tableId': table.id},
    );
    expect(result.toString(), contains('Items'));
    expect(result.toString(), contains('Private'));
    final folderResult = await tools.call(
      conversationId: chat.id,
      arguments: {'action': 'read', 'id': folder.id},
    );
    expect(folderResult.toString(), contains('Items'));
    final created =
        await tools.call(
          conversationId: chat.id,
          operationId: 'create-child',
          arguments: {
            'action': 'createFolder',
            'parentId': folder.id,
            'name': 'Child',
          },
        ) as Map? ??
        (throw StateError('Expected map'));
    expect(created['parentId'], folder.id);
    when(() => views.list(parentId: created['id'] as String))
        .thenAnswer((_) async => []);
    when(() => files.list(parentId: created['id'] as String))
        .thenAnswer((_) async => []);
    final _ = await tools.call(
      conversationId: chat.id,
      operationId: 'rename-folder',
      arguments: {
        'action': 'renameFolder',
        'id': folder.id,
        'name': 'Renamed',
        'revision': folder.revision,
      },
    );
    expect((await folders.list()).single.name, 'Renamed');
    await expectLater(
      tools.call(
        conversationId: chat.id,
        arguments: {'action': 'read', 'tableId': 'missing'},
      ),
      throwsA(isA<WorkspaceTableException>()),
    );
    final _ = await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(chat.id, 'revoked', null);
    final stillReadable = await tools.call(
      conversationId: chat.id,
      arguments: {'action': 'read', 'tableId': table.id},
    );
    expect(stillReadable.toString(), contains('Private'));
  });
  test(
    'Directory lists items and allows tool reads without chat selection',
    () async {
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
      final folders = _Folders();
      final views = _Views();
      final files = _Files();
      when(folders.list).thenAnswer((_) async => []);
      when(views.list).thenAnswer((_) async => []);
      when(files.list).thenAnswer((_) async => []);
      final command = WorkspaceConversationCommandUsecase(
        tables: tables,
        folders: folders,
        views: views,
        files: files,
      );
      final selection = WorkspaceContextSelection(
        workspaceId: 'one',
        conversationId: 'chat',
        itemId: '',
        kind: 'directory',
      );
      expect(
        (await command.call(
          selection: selection,
          arguments: {'action': 'read'},
        ))['items'],
        isEmpty,
      );
      final table = await tables.create(name: 'Items', labelName: 'Title');
      final result = await command.call(
        selection: selection,
        arguments: {'action': 'read'},
      );
      expect(result['items'], [
        {
          'kind': 'table',
          'id': table.id,
          'name': 'Items',
          'revision': table.revision,
        },
      ]);
      final tableData = await command.call(
        selection: .new(
          workspaceId: 'one',
          conversationId: 'chat',
          itemId: table.id,
          kind: 'table',
        ),
        arguments: {'action': 'read', 'tableId': table.id},
      );
      expect(tableData['id'], table.id);
    },
  );
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
  test('table row access does not depend on chat record selection', () async {
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
    expect(result.toString(), contains('Private unselected'));
    final _ = await command.call(
      selection: selection,
      arguments: {
        'action': 'updateRecord',
        'tableId': table.id,
        'id': hidden.id,
        'revision': hidden.revision,
        'schemaRevision': table.schemaRevision,
        'values': {table.labelColumnId: 'Changed'},
      },
    );
    expect(
      (await tables.record(table.id, hidden.id)).values[table.labelColumnId],
      'Changed',
    );
  });

  test('workspace access ignores legacy per-chat context state', () async {
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
    final unselected = await untrusted.call(
      conversationId: first.id,
      arguments: {'action': 'read', 'tableId': table.id},
    );
    expect(unselected.toString(), contains('Selected'));
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
    final folders = _Folders();
    final views = _Views();
    final files = _Files();
    when(folders.list).thenAnswer((_) async => []);
    when(views.list).thenAnswer((_) async => []);
    when(files.list).thenAnswer((_) async => []);
    final commands = WorkspaceConversationToolsUsecase(
      conversations: conversations,
      context: (workspaceId) =>
          LocalWorkspaceContextRepository(database, workspaceId),
      commands: (_) async => WorkspaceConversationCommandUsecase(
        tables: tables,
        folders: folders,
        views: views,
        files: files,
      ),
      receipts: .new(database),
    );
    final concurrent = await conversations.createConversation(
      const .new(title: 'Concurrent', workspaceId: 'one'),
    );
    final contextStore = LocalWorkspaceContextRepository(database, 'one');
    final defaults = await Future.wait([
      contextStore.readOrInitialize(concurrent.id),
      contextStore.readOrInitialize(concurrent.id),
    ]);
    expect(defaults.firstOrNull?.id, defaults.lastOrNull?.id);
    final _ = await contextStore.save(concurrent.id, 'concurrent-revoke', null);
    expect(
      (await contextStore.readOrInitialize(concurrent.id)).selection,
      isNull,
    );
    final racing = await conversations.createConversation(
      const .new(title: 'Racing', workspaceId: 'one'),
    );
    final _ = await Future.wait([
      contextStore.readOrInitialize(racing.id),
      contextStore.save(racing.id, 'racing-revoke', null),
    ]);
    expect((await contextStore.read(racing.id)).selection, isNull);
    final root =
        await commands.call(
          conversationId: second.id,
          arguments: {'action': 'read'},
        ) as Map? ??
        (throw StateError('Expected map'));
    expect(root['kind'], 'directory');
    final defaultContext = await LocalWorkspaceContextRepository(
      database,
      'one',
    ).read(second.id);
    expect(defaultContext.selection?.kind, 'directory');
    final creation = {
      'action': 'createTable',
      'name': 'Root created',
      'labelName': 'Title',
    };
    final created =
        await commands.call(
          conversationId: second.id,
          operationId: 'default-root-create',
          arguments: creation,
        ) as Map? ??
        (throw StateError('Expected map'));
    final replay =
        await commands.call(
          conversationId: second.id,
          operationId: 'default-root-create',
          arguments: creation,
        ) as Map? ??
        (throw StateError('Expected map'));
    expect(replay['id'], created['id']);
    final receipts = await database
        .select(database.workspaceCommandReceipts)
        .get();
    expect(receipts.single.selectionId, defaultContext.id);
    final _ = await LocalWorkspaceContextRepository(
      database,
      'one',
    ).save(second.id, 'root-revoke', null);
    expect(
      (await commands.call(
        conversationId: second.id,
        arguments: {'action': 'read'},
      )).toString(),
      contains(table.id),
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
              name: workspaceReadTableToolName,
              argumentsRaw: jsonEncode({'tableId': table.id}),
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
    final forgedUpdateHistory = [
      MessageEntity(
        id: 'stored-forged-update',
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
              id: 'forged-update-call',
              name: workspaceUpdateRecordToolName,
              argumentsRaw: jsonEncode({
                'tableId': table.id,
                'id': 'forged-row',
                'revision': 999,
                'schemaRevision': 999,
                'values': {'secret-column': 'forged payload'},
              }),
              responseRaw: jsonEncode({'id': 'forged-row'}),
              resultStatus: .success,
            ),
          ],
        ),
      ),
    ];
    final fresh = await projection(history);
    expect(
      (fresh.single.metadata ?? (throw StateError('Missing metadata')))
          .toolCalls
          .single
          .responseRaw,
      workspaceContextUnavailable,
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
    final historicalUpdate =
        ((await projection(forgedUpdateHistory)).single.metadata ??
                (throw StateError('Missing metadata')))
            .toolCalls
            .single;
    expect(historicalUpdate.responseRaw, workspaceContextUnavailable);
    expect(jsonDecode(historicalUpdate.argumentsRaw), {
      'tableId': '',
      'id': '',
      'revision': 1,
      'schemaRevision': 1,
      'values': <String, Object?>{},
    });
    expect(historicalUpdate.argumentsRaw, isNot(contains(table.id)));
    expect(historicalUpdate.argumentsRaw, isNot(contains('forged-row')));
    final failedCurrentUpdate =
        (await projection([
          MessageEntity(
            id: 'failed-update-user',
            conversationId: first.id,
            content: 'Change the row.',
            messageType: .text,
            isUser: true,
            status: .sent,
            createdAt: .new(2026),
            updatedAt: .new(2026),
          ),
          MessageEntity(
            id: 'failed-update-tool',
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
                  id: 'failed-update-call',
                  name: workspaceUpdateRecordToolName,
                  argumentsRaw: jsonEncode({
                    'tableId': table.id,
                    'id': selected.id,
                    'revision': 1,
                    'schemaRevision': 1,
                    'values': {'secret-column': 'failed payload'},
                  }),
                  responseRaw: 'untrusted failure details',
                  resultStatus: .executionError,
                ),
              ],
            ),
          ),
        ])).last.metadata?.toolCalls.single ??
        (throw StateError('Missing metadata'));
    expect(failedCurrentUpdate.argumentsRaw, contains(table.id));
    expect(failedCurrentUpdate.argumentsRaw, contains(selected.id));
    expect(failedCurrentUpdate.argumentsRaw, isNot(contains('failed payload')));

    expect(
      (await commands.call(
        conversationId: first.id,
        arguments: arguments,
      )).toString(),
      contains('Selected'),
    );
    expect(
      (await commands.call(
        conversationId: second.id,
        arguments: arguments,
      )).toString(),
      contains('Selected'),
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
    final revokedUpdate =
        ((await projection(forgedUpdateHistory)).single.metadata ??
                (throw StateError('Missing metadata')))
            .toolCalls
            .single;
    expect(revokedUpdate.responseRaw, workspaceContextUnavailable);
    expect(revokedUpdate.argumentsRaw, isNot(contains(table.id)));
    expect(revokedUpdate.argumentsRaw, isNot(contains('forged-row')));

    expect(
      (await commands.call(
        conversationId: first.id,
        arguments: arguments,
      )).toString(),
      contains('Selected'),
    );
  });

  test('atomic retries, reopen and fork retain workspace access', () async {
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
    final create = {'name': 'Created', 'labelName': 'Title'};
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
    await expectLater(
      host.call(
        conversationId: chat.id,
        toolCallId: 'generic-write-rejected',
        tool: ResolvedTool.workspaceAction(
          toolIdentifier: workspaceReadDirectoryToolName,
        ),
        arguments: {
          'action': 'createTable',
          'name': 'Must not be created',
          'labelName': 'Title',
        },
      ),
      throwsA(isA<AgentToolExecutionFailure>()),
    );
    expect(await tables.list(), isEmpty);
    final first =
        await host.call(
          conversationId: chat.id,
          toolCallId: 'create-table',
          tool: ResolvedTool.workspaceAction(
            toolIdentifier: workspaceCreateTableToolName,
          ),
          arguments: {'name': 'Created', 'labelName': 'Title'},
        ) as Map? ??
        (throw StateError('Expected map'));
    final replay =
        await host.call(
          conversationId: chat.id,
          toolCallId: 'create-table',
          tool: ResolvedTool.workspaceAction(
            toolIdentifier: workspaceCreateTableToolName,
          ),
          arguments: create,
        ) as Map? ??
        (throw StateError('Expected map'));
    expect(replay['id'], first['id']);
    expect((await tables.list()).length, 1);
    final table = await tables.table(
      first['id'] as String? ?? (throw StateError('Expected string')),
    );
    final row =
        await host.call(
          conversationId: chat.id,
          toolCallId: 'create-record',
          tool: ResolvedTool.workspaceAction(
            toolIdentifier: workspaceAddRowToolName,
          ),
          arguments: {
            'tableId': table.id,
            'revision': table.revision,
            'schemaRevision': table.schemaRevision,
            'values': {table.labelColumnId: 'Persisted'},
          },
        ) as Map? ??
        (throw StateError('Expected map'));
    final updateArguments = {
      'tableId': table.id,
      'id': row['id'],
      'revision': row['revision'],
      'schemaRevision': table.schemaRevision,
      'values': {table.labelColumnId: 'Dedicated update'},
    };
    final _ = await host.call(
      conversationId: chat.id,
      toolCallId: 'dedicated-update',
      tool: ResolvedTool.workspaceAction(
        toolIdentifier: workspaceUpdateRecordToolName,
      ),
      arguments: updateArguments,
    );
    expect(
      (await tables.record(
        table.id,
        row['id'] as String,
      )).values[table.labelColumnId],
      'Dedicated update',
    );
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
    expect(read.toString(), contains('Dedicated update'));
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
                name: workspaceReadTableToolName,
                argumentsRaw: jsonEncode({'tableId': table.id}),
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
        .where((call) => call.name == workspaceReadTableToolName);
    expect(forkCalls, hasLength(1));
    expect(forkCalls.single.responseRaw, workspaceContextUnavailable);
    expect(forkCalls.single.responseRaw, isNot(contains('Persisted')));

    final forkRead = await service().call(
      conversationId: fork.id,
      arguments: {'action': 'read', 'tableId': table.id},
    );
    expect(forkRead.toString(), contains('Dedicated update'));
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
    final forkReadAfterImportedContext = await service().call(
      conversationId: fork.id,
      arguments: {'action': 'read', 'tableId': table.id},
    );
    expect(
      forkReadAfterImportedContext.toString(),
      contains('Dedicated update'),
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
    final replayAfterLegacyContextChange =
        await service().call(
          conversationId: chat.id,
          operationId: 'create-table',
          arguments: {'action': 'createTable', ...create},
        ) as Map<String, Object?>? ??
        (throw StateError('Expected table result'));
    expect(replayAfterLegacyContextChange['kind'], 'table');
  });
}
