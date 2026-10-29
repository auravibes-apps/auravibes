import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_history_redaction.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _EmptyFiles extends Mock implements OrganizeWorkspaceFilesUsecase;

void main() {
  test('archived workspace tool output is not re-read or injected', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final message = MessageEntity(
      id: 'old-tool-result',
      conversationId: fixture.conversationId,
      content: '',
      messageType: .toolCall,
      isUser: false,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      metadata: const .new(
        toolCalls: [
          .new(
            id: 'old-read',
            name: workspaceReadTableToolName,
            argumentsRaw: '{"tableId":"private-table"}',
            responseRaw: '{"records":["private row"]}',
            resultStatus: .success,
          ),
        ],
      ),
    );
    final result = redactWorkspaceToolHistory([message]);
    final call = result.single.metadata?.toolCalls.single;
    expect(call?.responseRaw, workspaceContextUnavailable);
    expect(call?.argumentsRaw, isNot(contains('private-table')));
    expect(call?.responseRaw, isNot(contains('private row')));
  });
  test('empty Directory root returns an empty list', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final result = await fixture.run('read-root', {'action': 'read'});
    expect(result, {
      'kind': 'directory',
      'id': '',
      'parentId': null,
      'items': <Object?>[],
    });
    await expectLater(
      fixture.run('read-unshared', {'action': 'read', 'tableId': 'unknown'}),
      throwsA(isA<WorkspaceTableException>()),
    );
  });

  test('AI table reads include all rows without chat selection', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final projectionTableArguments = {'name': 'People', 'labelName': 'Name'};
    final table = await fixture.run(
      'projection-table',
      projectionTableArguments,
      toolName: workspaceCreateTableToolName,
    );
    final tableId =
        table['id'] as String? ?? (throw StateError('Expected string'));
    final tableData = await fixture.run('projection-table-read', {
      'action': 'read',
      'tableId': tableId,
    });
    final label =
        tableData['labelColumnId'] as String? ??
        (throw StateError('Expected string'));
    final firstRowArguments = {
      'tableId': tableId,
      'revision': 1,
      'schemaRevision': 1,
      'values': {label: 'First row'},
    };
    final selected = await fixture.run(
      'projection-first-row',
      firstRowArguments,
      toolName: workspaceAddRowToolName,
    );
    final secondRowArguments = {
      'tableId': tableId,
      'revision': 1,
      'schemaRevision': 1,
      'values': {label: 'Second row'},
    };
    final unselected = await fixture.run(
      'projection-second-row',
      secondRowArguments,
      toolName: workspaceAddRowToolName,
    );
    final _ = await LocalWorkspaceContextRepository(fixture.database, 'one')
        .save(
          fixture.conversationId,
          'selected-table-context',
          .new(
            workspaceId: 'one',
            conversationId: fixture.conversationId,
            itemId: tableId,
            kind: 'table',
            recordIds: [
              selected['id'] as String? ??
                  (throw StateError('Expected record ID')),
            ],
          ),
        );

    final read = await fixture.run('read-all-rows', {
      'action': 'read',
      'tableId': tableId,
    });
    final records =
        (read['records'] as List<Object?>? ??
                (throw StateError('Expected records')))
            .cast<Map<String, Object?>>();
    expect(
      records.map((row) => row['id']),
      containsAll([selected['id'], unselected['id']]),
    );
    expect(jsonEncode(records), contains('First row'));
    expect(jsonEncode(records), contains('Second row'));
  });

  test('legacy selection changes do not block workspace commands', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final tools = WorkspaceConversationToolsUsecase(
      conversations: fixture.conversations,
      context: (id) => LocalWorkspaceContextRepository(fixture.database, id),
      commands: (_) async {
        final _ = await LocalWorkspaceContextRepository(
          fixture.database,
          'one',
        ).save(fixture.conversationId, 'revoke-during-prepare', null);

        return WorkspaceConversationCommandUsecase(tables: fixture.tables);
      },
      receipts: .new(fixture.database),
    );
    final created =
        (await tools.call(
          conversationId: fixture.conversationId,
          operationId: 'race-create',
          arguments: {
            'action': 'createTable',
            'name': 'Denied',
            'labelName': 'Title',
          },
        )) as Map<String, Object?>? ??
        (throw StateError('Expected table result'));
    expect(created['kind'], 'table');
    expect(await fixture.tables.list(), hasLength(1));
    expect(
      await fixture.database
          .select(fixture.database.workspaceCommandReceipts)
          .get(),
      hasLength(1),
    );
  });

  test(
    'created folder remains readable and renameable in a later turn',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.database.close);
      final priorCreateArguments = {'name': 'Earlier'};
      final folder = await fixture.run(
        'prior-create',
        priorCreateArguments,
        toolName: workspaceCreateFolderToolName,
      );
      final laterReadArguments = {
        'itemId': folder['id'] as String? ?? (throw StateError('Expected id')),
      };
      final read = await fixture.run(
        'later-read',
        laterReadArguments,
        toolName: workspaceReadItemToolName,
      );
      expect(read['name'], 'Earlier');
      final laterRenameArguments = {
        'id': read['id'],
        'revision': read['revision'],
        'name': 'Later',
      };
      final renamed = await fixture.run(
        'later-rename',
        laterRenameArguments,
        toolName: workspaceRenameFolderToolName,
      );
      expect(renamed['revision'], 2);
    },
  );

  test('typed creation and View editing use stable IDs', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final folderArguments = {'name': 'Group'};
    final folder = await fixture.run(
      'folder',
      folderArguments,
      toolName: workspaceCreateFolderToolName,
    );
    final tableArguments = {
      'name': 'Items',
      'labelName': 'Title',
      'parentId': folder['id'],
    };
    final table = await fixture.run(
      'table',
      tableArguments,
      toolName: workspaceCreateTableToolName,
    );
    final first = await fixture.run('read', {
      'action': 'read',
      'tableId': table['id'],
    });
    final label =
        first['labelColumnId'] as String? ??
        (throw StateError('Expected string'));
    final columnArguments = {
      'tableId': table['id'],
      'revision': 1,
      'schemaRevision': 1,
      'column': {'id': '', 'name': 'Amount', 'type': 'number'},
    };
    final schema = await fixture.run(
      'column',
      columnArguments,
      toolName: workspaceSaveColumnToolName,
    );
    expect(schema['schemaRevision'], 2);
    final afterColumnCreation = await fixture.run('read-column-created', {
      'action': 'read',
      'tableId': table['id'],
    });
    final amount =
        ((afterColumnCreation['columns'] as List?) ??
                (throw StateError('Expected columns')))
            .cast<Map<String, dynamic>>()
            .singleWhere((column) => column['name'] == 'Amount')['id'];
    final columnRenameArguments = {
      'tableId': table['id'],
      'revision': afterColumnCreation['revision'],
      'schemaRevision': afterColumnCreation['schemaRevision'],
      'column': {'id': amount, 'name': 'Total', 'type': 'number'},
    };
    final _ = await fixture.run(
      'rename-column',
      columnRenameArguments,
      toolName: workspaceSaveColumnToolName,
    );
    final afterColumnRename = await fixture.run('read-column-renamed', {
      'action': 'read',
      'tableId': table['id'],
    });
    expect(
      ((afterColumnRename['columns'] as List?) ??
              (throw StateError('Expected columns')))
          .cast<Map<String, dynamic>>()
          .singleWhere((column) => column['id'] == amount)['name'],
      'Total',
    );
    final tableRenameArguments = {
      'tableId': table['id'],
      'revision': afterColumnRename['revision'],
      'schemaRevision': afterColumnRename['schemaRevision'],
      'name': 'Renamed',
    };
    final renamed = await fixture.run(
      'rename',
      tableRenameArguments,
      toolName: workspaceRenameTableToolName,
    );
    expect(renamed['revision'], 4);
    final folderRenameArguments = {
      'id': folder['id'],
      'revision': 1,
      'name': 'Updated group',
    };
    final movedName = await fixture.run(
      'rename-folder',
      folderRenameArguments,
      toolName: workspaceRenameFolderToolName,
    );
    expect(movedName['id'], folder['id']);
    final recordArguments = {
      'tableId': table['id'],
      'revision': renamed['revision'],
      'schemaRevision': renamed['schemaRevision'],
      'values': {label: 'One'},
    };
    final row = await fixture.run(
      'record',
      recordArguments,
      toolName: workspaceAddRowToolName,
    );
    final viewArguments = {
      'tableId': table['id'],
      'revision': renamed['revision'],
      'schemaRevision': renamed['schemaRevision'],
      'name': 'Overview',
      'columnIds': [label],
    };
    final view = await fixture.run(
      'view',
      viewArguments,
      toolName: workspaceCreateViewToolName,
    );
    final savedViewArguments = {
      'id': view['id'],
      'revision': 1,
      'schemaRevision': renamed['schemaRevision'],
      'name': 'Updated overview',
      'bindings': {'title': label},
      'definition': {
        'version': 1,
        'components': [
          {'id': 'root', 'component': 'Text', 'text': 'Edited surface'},
        ],
      },
    };
    final saved = await fixture.run(
      'save-view',
      savedViewArguments,
      toolName: workspaceSaveViewToolName,
    );
    expect(saved['revision'], 2);
    final current = await fixture.run('read-view', {
      'action': 'read',
      'id': view['id'],
    });
    expect(current.toString(), contains('Edited surface'));
    expect(
      (await fixture.tables.record(
        table['id'] as String? ?? (throw StateError('Expected string')),
        row['id'] as String? ?? (throw StateError('Expected string')),
      )).values[label],
      'One',
    );
    final staleColumnArguments = {
      'tableId': table['id'],
      'revision': 1,
      'schemaRevision': 1,
      'column': {'id': label, 'name': 'Stale', 'type': 'text'},
    };
    await expectLater(
      fixture.run(
        'stale-column',
        staleColumnArguments,
        toolName: workspaceSaveColumnToolName,
      ),
      throwsA(isA<WorkspaceTableException>()),
    );
    final invalid = {
      'id': view['id'],
      'revision': 2,
      'schemaRevision': renamed['schemaRevision'],
      'name': 'Unsafe',
      'bindings': {'title': label},
      'definition': {
        'version': 1,
        'components': [
          {
            'id': 'root',
            'component': 'Image',
            'url': 'https://example.invalid',
          },
        ],
      },
    };
    await expectLater(
      fixture.run('invalid-view', invalid, toolName: workspaceSaveViewToolName),
      throwsA(isA<Object>()),
    );
    expect(
      (await fixture.views.open(
        view['id'] as String? ?? (throw StateError('Expected string')),
      )).view.revision,
      2,
    );

    final patchedViewArguments = {
      'id': view['id'],
      'revision': 2,
      'schemaRevision': renamed['schemaRevision'],
      'bindings': {'title': label, 'total': amount},
      'summaryColumnIds': [amount],
      'query': {
        'search': 'One',
        'sortColumnId': label,
        'descending': true,
        'limit': 10,
      },
      'viewAction': {
        'version': 1,
        'type': 'updateSelectedRecord',
        'inputs': {label: '/title'},
      },
      'updateComponents': [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['title_input'],
        },
        {
          'id': 'title_input',
          'component': 'TextField',
          'label': {'path': '/fieldLabels/title'},
          'value': {'path': '/title'},
        },
      ],
    };
    final patched = await fixture.run(
      'patch-view',
      patchedViewArguments,
      toolName: workspaceSaveViewToolName,
    );
    expect(patched['revision'], 3);
    final patchedData = await fixture.views.open(
      view['id'] as String? ?? (throw StateError('Expected string')),
    );
    expect(patchedData.view.name, 'Updated overview');
    expect(patchedData.view.summaryColumnIds, [amount]);
    expect(patchedData.view.query.search, 'One');
    expect(patchedData.view.query.limit, 10);
    expect(
      patchedData.view.action?.type,
      A2uiSavedActionType.updateSelectedRecord,
    );
  });

  test('dedicated folder tool creates a discoverable folder', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final arguments = {'name': 'Dedicated folder'};
    final created = await fixture.run(
      'dedicated-folder',
      arguments,
      toolName: workspaceCreateFolderToolName,
    );
    expect(created['kind'], 'folder');
    final listed = await fixture.run(
      'directory-root',
      const {},
      toolName: workspaceReadDirectoryToolName,
    );
    expect(
      ((listed['entries'] as List?) ?? (throw StateError('Expected entries')))
          .cast<Map<String, dynamic>>()
          .map((item) => item['id']),
      contains(created['id']),
    );
  });

  test(
    'interrupted completion rolls back both new item and receipt before retry',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.database.close);
      final failing = fixture.service(
        .new(_InterruptedTableRepository(fixture.database)),
      );
      final arguments = {'name': 'Atomic', 'labelName': 'Title'};
      final commandArguments = workspaceCommandArgumentsForTool(
        workspaceCreateTableToolName,
        arguments,
      );
      await expectLater(
        failing.call(
          conversationId: fixture.conversationId,
          operationId: 'create-once',
          arguments: commandArguments,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await fixture.tables.list(), isEmpty);
      final created = await fixture.run(
        'create-once',
        arguments,
        toolName: workspaceCreateTableToolName,
      );
      final retried = await fixture.run(
        'create-once',
        arguments,
        toolName: workspaceCreateTableToolName,
      );
      expect(retried['id'], created['id']);
      expect(await fixture.tables.list(), hasLength(1));
    },
  );
}

class _Fixture {
  new(
    this.database,
    this.conversations,
    this.conversationId,
    this.tables,
    this.views,
    this.folders,
  );
  final AppDatabase database;
  final ConversationRepository conversations;
  final String conversationId;
  final OrganizeWorkspaceTablesUsecase tables;
  final ManageWorkspaceViewsUsecase views;
  final OrganizeWorkspaceFoldersUsecase folders;
  static Future<_Fixture> create() async {
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
    final conversation = await conversations.createConversation(
      const .new(title: 'Create', workspaceId: 'one'),
    );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final views = ManageWorkspaceViewsUsecase(
      LocalWorkspaceViewRepository(database, 'one'),
      tables,
      .new(LocalWorkspaceRecordQueryRepository(database, 'one')),
      .new(LocalWorkspaceReferenceRepository(database, 'one')),
    );
    final _ = await LocalWorkspaceContextRepository(database, 'one').save(
      conversation.id,
      'explicit-root',
      .new(
        workspaceId: 'one',
        conversationId: conversation.id,
        itemId: '',
        kind: 'directory',
      ),
    );

    return _Fixture(
      database,
      conversations,
      conversation.id,
      tables,
      views,
      .new(LocalWorkspaceFolderRepository(database, 'one')),
    );
  }

  WorkspaceConversationToolsUsecase service(
    OrganizeWorkspaceTablesUsecase editor,
  ) {
    final files = _EmptyFiles();
    when(() => files.list(parentId: any(named: 'parentId')))
        .thenAnswer((_) async => []);

    return WorkspaceConversationToolsUsecase(
      conversations: conversations,
      context: (id) => LocalWorkspaceContextRepository(database, id),
      commands: (_) async => WorkspaceConversationCommandUsecase(
        tables: editor,
        folders: folders,
        views: views,
        files: files,
      ),
      receipts: .new(database),
    );
  }

  Future<Map<String, Object?>> run(
    String id,
    Map<String, dynamic> arguments, {
    String? toolName,
  }) async {
    final result = await service(tables).call(
      conversationId: conversationId,
      arguments: toolName == null
          ? arguments
          : workspaceToolArgumentsForExecution(toolName, arguments),
      operationId: id,
    );
    if (result is! Map<String, Object?>) throw StateError('Expected result');

    return result;
  }
}

class _InterruptedTableRepository extends LocalWorkspaceTableRepository {
  const new(AppDatabase database) : super(database, 'one');
  @override
  Future<WorkspaceTable> create({
    required String name,
    required String labelName,
    String? parentId,
    String? aiConversationId,
  }) async {
    final _ = await super.create(
      name: name,
      labelName: labelName,
      parentId: parentId,
      aiConversationId: aiConversationId,
    );
    throw StateError('Simulated interruption before receipt commit');
  }
}
