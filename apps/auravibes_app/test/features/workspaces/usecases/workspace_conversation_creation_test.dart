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
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_workspace_chat_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'current action outcome stays visible without replaying raw data',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.database.close);
      final result = await fixture.run('new-table', {
        'action': 'createTable',
        'name': 'Created',
        'labelName': 'Title',
      });
      MessageEntity message({
        required bool user,
        MessageMetadataEntity? metadata,
      }) => MessageEntity(
        id: user ? 'prompt' : 'answer',
        conversationId: fixture.conversationId,
        content: '',
        messageType: user ? .text : .toolCall,
        isUser: user,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        metadata: metadata,
      );
      final calls = MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'new-table',
            name: workspaceCommandToolName,
            argumentsRaw: jsonEncode({
              'action': 'createTable',
              'name': 'Created',
              'labelName': 'Title',
            }),
            responseRaw: jsonEncode({...result, 'secret': 'private response'}),
            resultStatus: .success,
          ),
        ],
      );
      final project = ProjectWorkspaceChatContextUsecase(
        fixture.service(fixture.tables),
      );
      final current = await project([
        message(user: true),
        message(user: false, metadata: calls),
      ]);
      final currentCall = current.last.metadata?.toolCalls.single;
      expect(jsonDecode(currentCall?.argumentsRaw ?? '{}'), {
        'action': 'createTable',
      });
      expect(currentCall?.responseRaw, contains('success'));
      expect(currentCall?.responseRaw, isNot(contains('private response')));
      expect(currentCall?.argumentsRaw, isNot(contains('Created')));
      final other = await fixture.run('other-table', {
        'action': 'createTable',
        'name': 'Other',
        'labelName': 'Title',
      });
      final swapped = calls.toolCalls.single.copyWith(
        responseRaw: jsonEncode(other),
      );
      final projectedSwap = await project([
        message(user: true),
        message(user: false, metadata: .new(toolCalls: [swapped])),
      ]);
      final swapOutput =
          projectedSwap.last.metadata?.toolCalls.single.responseRaw ?? '';
      expect(swapOutput, contains(result['id']?.toString() ?? ''));
      expect(swapOutput, isNot(contains(other['id']?.toString() ?? '')));
      final forged = calls.toolCalls.single.copyWith(
        argumentsRaw: jsonEncode({'action': 'renameTable', 'name': 'forged'}),
      );
      final unverified = await project([
        message(user: true),
        message(user: false, metadata: .new(toolCalls: [forged])),
      ]);
      expect(
        unverified.last.metadata?.toolCalls.single.responseRaw,
        workspaceContextUnavailable,
      );
      final old = await project([
        message(user: false, metadata: calls),
        message(user: true),
      ]);
      expect(
        jsonDecode(
          old.firstOrNull?.metadata?.toolCalls.single.argumentsRaw ?? '{}',
        ),
        {'action': 'read'},
      );
      final failedCall = calls.toolCalls.single.copyWith(
        resultStatus: .executionError,
      );
      final failed = await project([
        message(user: true),
        message(user: false, metadata: .new(toolCalls: [failedCall])),
      ]);
      expect(
        jsonDecode(failed.last.metadata?.toolCalls.single.responseRaw ?? '{}'),
        {'outcome': 'failed'},
      );
      final safeFailure = failedCall.copyWith(
        responseRaw: jsonEncode({'code': 'conflict', 'error': 'secret'}),
      );
      final projectedFailure = await project([
        message(user: true),
        message(user: false, metadata: .new(toolCalls: [safeFailure])),
      ]);
      final failureResponse =
          projectedFailure.last.metadata?.toolCalls.single.responseRaw ?? '';
      expect(failureResponse, contains('Read it again'));
      expect(failureResponse, isNot(contains('secret')));
      final forgedFailure = safeFailure.copyWith(
        responseRaw: '{"code":"secret"}',
      );
      final projectedForged = await project([
        message(user: true),
        message(user: false, metadata: .new(toolCalls: [forgedFailure])),
      ]);
      expect(
        jsonDecode(
          projectedForged.last.metadata?.toolCalls.single.responseRaw ?? '{}',
        ),
        {'outcome': 'failed'},
      );
      final _ = await LocalWorkspaceContextRepository(
        fixture.database,
        'one',
      ).save(fixture.conversationId, 'revoke', null);
      final revoked = await project([
        message(user: true),
        message(user: false, metadata: calls),
      ]);
      expect(
        revoked.last.metadata?.toolCalls.single.responseRaw,
        workspaceContextUnavailable,
      );
    },
  );
  test(
    'shared Directory root can be read without disclosing children',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.database.close);
      final result = await fixture.run('read-root', {'action': 'read'});
      expect(result, {'kind': 'directory', 'id': '', 'parentId': null});
      await expectLater(
        fixture.run('read-unshared', {'action': 'read', 'tableId': 'unknown'}),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );

  test('current record projection is scoped to its authorized row', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final table = await fixture.run('projection-table', {
      'action': 'createTable',
      'name': 'People',
      'labelName': 'Name',
    });
    final tableId =
        table['id'] as String? ?? (throw StateError('Expected string'));
    final tableData = await fixture.run('projection-table-read', {
      'action': 'read',
      'tableId': tableId,
    });
    final label =
        tableData['labelColumnId'] as String? ??
        (throw StateError('Expected string'));
    final selected = await fixture.run('projection-selected-row', {
      'action': 'createRecord',
      'tableId': tableId,
      'revision': 1,
      'schemaRevision': 1,
      'values': {label: 'Selected existing row'},
    });
    final unselected = await fixture.run('projection-unselected-row', {
      'action': 'createRecord',
      'tableId': tableId,
      'revision': 1,
      'schemaRevision': 1,
      'values': {label: 'Unselected existing row'},
    });
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
                  (throw StateError('Expected string')),
            ],
          ),
        );

    await expectLater(
      fixture
          .service(fixture.tables)
          .call(
            conversationId: fixture.conversationId,
            operationId: 'read-unselected-row',
            arguments: {
              'action': 'read',
              'tableId': tableId,
              'id': unselected['id'],
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

    final arguments = {
      'action': 'createRecord',
      'tableId': tableId,
      'revision': 1,
      'schemaRevision': 1,
      'values': {label: 'Alex'},
    };
    final created = await fixture.run('current-alex-row', arguments);
    expect(
      workspaceContextReadArguments(
        {'action': 'createRecord', 'tableId': 'untrusted-input'},
        {...created, 'tableId': tableId, 'kind': 'record'},
      ),
      {'action': 'read', 'id': created['id'], 'tableId': tableId},
    );

    MessageEntity message({
      required bool user,
      MessageMetadataEntity? metadata,
    }) => MessageEntity(
      id: user ? 'projection-question' : 'projection-tool',
      conversationId: fixture.conversationId,
      content: '',
      messageType: user ? .text : .toolCall,
      isUser: user,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      metadata: metadata,
    );

    final projected =
        await ProjectWorkspaceChatContextUsecase(
          fixture.service(fixture.tables),
        )([
          message(user: true),
          message(
            user: false,
            metadata: .new(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'current-alex-row',
                  name: workspaceCommandToolName,
                  argumentsRaw: jsonEncode(arguments),
                  responseRaw: jsonEncode(created),
                  resultStatus: .success,
                ),
              ],
            ),
          ),
        ]);
    final response = jsonDecode(
      projected.last.metadata?.toolCalls.single.responseRaw ?? '{}',
    ) as Map<String, dynamic>;
    final current = response['current'] as Map<String, dynamic>;
    final records = (current['records'] as List).cast<Map<String, Object?>>();
    expect(records, hasLength(1));
    expect(records.single['id'], created['id']);
    final values =
        records.single['values'] as Map<String, Object?>? ??
        (throw StateError('Expected record values'));
    expect(values[label], 'Alex');
    expect(jsonEncode(records), isNot(contains('Selected existing row')));
  });

  test('revoked selection cannot commit after command preparation', () async {
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
    await expectLater(
      tools.call(
        conversationId: fixture.conversationId,
        operationId: 'race-create',
        arguments: {
          'action': 'createTable',
          'name': 'Denied',
          'labelName': 'Title',
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
    expect(await fixture.tables.list(), isEmpty);
    expect(
      await fixture.database
          .select(fixture.database.workspaceCommandReceipts)
          .get(),
      isEmpty,
    );
  });

  test(
    'created folder remains readable and renameable in a later turn',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.database.close);
      final folder = await fixture.run('prior-create', {
        'action': 'createFolder',
        'name': 'Earlier',
      });
      final read = await fixture.run('later-read', {
        'action': 'read',
        'id': folder['id'],
      });
      expect(read['name'], 'Earlier');
      final discovery = await fixture.run('discover', {
        'action': 'listCreated',
      });
      final items = discovery['items'] as List<Object?>? ?? [];
      expect(
        items,
        contains(
          predicate<Map<String, Object?>>(
            (item) => item['id'] == folder['id'] && item['name'] == 'Earlier',
          ),
        ),
      );
      expect(discovery['nextCursor'], isNull);
      expect(
        items.every((item) => item is Map && !item.containsKey('parentId')),
        isTrue,
      );
      final discoverCall = MessageToolCallEntity(
        id: 'discovery-call',
        name: workspaceCommandToolName,
        argumentsRaw: jsonEncode({'action': 'listCreated', 'cursor': 'aaa'}),
        responseRaw: jsonEncode({'secret': 'stale private data'}),
        resultStatus: .success,
      );
      MessageEntity transcript({
        required bool user,
        MessageMetadataEntity? metadata,
      }) => MessageEntity(
        id: user ? 'question' : 'tool',
        conversationId: fixture.conversationId,
        content: '',
        messageType: user ? .text : .toolCall,
        isUser: user,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        metadata: metadata,
      );
      final projection = ProjectWorkspaceChatContextUsecase(
        fixture.service(fixture.tables),
      );
      final projected = await projection([
        transcript(user: true),
        transcript(user: false, metadata: .new(toolCalls: [discoverCall])),
      ]);
      final output =
          projected.last.metadata?.toolCalls.single.responseRaw ?? '';
      expect(output, contains('Earlier'));
      expect(output, isNot(contains('stale private data')));
      final readInput = {'action': 'listCreated', 'cursor': 'abc'};
      expect(workspaceContextReadArguments(readInput, {}), {
        'action': 'listCreated',
        'cursor': 'abc',
      });

      final renamed = await fixture.run('later-rename', {
        'action': 'renameFolder',
        'id': read['id'],
        'revision': read['revision'],
        'name': 'Later',
      });
      expect(renamed['revision'], 2);
    },
  );

  test('discovery paginates only current chat creations', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    for (var i = 0; i < 101; i++) {
      final _ = await fixture.run('item-${i.toString().padLeft(3, '0')}', {
        'action': 'createFolder',
        'name': 'Folder $i',
      });
    }
    final first = await fixture.run('first-page', {'action': 'listCreated'});
    expect((first['items'] as List<Object?>?)?.length, 100);
    expect(first['nextCursor'], 'item-099');
    final second = await fixture.run('second-page', {
      'action': 'listCreated',
      'cursor': first['nextCursor'],
    });
    expect((second['items'] as List<Object?>?)?.length, 1);
    expect(second['nextCursor'], isNull);
    final _ = await LocalWorkspaceContextRepository(
      fixture.database,
      'one',
    ).save(fixture.conversationId, 'revoked', null);
    await expectLater(
      fixture.run('revoked-page', {'action': 'listCreated'}),
      throwsA(isA<WorkspaceTableException>()),
    );
  });

  test('typed creation and View editing use stable IDs', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final folder = await fixture.run('folder', {
      'action': 'createFolder',
      'name': 'Group',
    });
    final table = await fixture.run('table', {
      'action': 'createTable',
      'name': 'Items',
      'labelName': 'Title',
      'parentId': folder['id'],
    });
    final first = await fixture.run('read', {
      'action': 'read',
      'tableId': table['id'],
    });
    final label =
        first['labelColumnId'] as String? ??
        (throw StateError('Expected string'));
    final schema = await fixture.run('column', {
      'action': 'saveColumn',
      'tableId': table['id'],
      'revision': 1,
      'schemaRevision': 1,
      'column': {'id': '', 'name': 'Amount', 'type': 'number'},
    });
    expect(schema['schemaRevision'], 2);
    final renamed = await fixture.run('rename', {
      'action': 'renameTable',
      'tableId': table['id'],
      'revision': 2,
      'schemaRevision': 2,
      'name': 'Renamed',
    });
    expect(renamed['revision'], 3);
    final movedName = await fixture.run('rename-folder', {
      'action': 'renameFolder',
      'id': folder['id'],
      'revision': 1,
      'name': 'Updated group',
    });
    expect(movedName['id'], folder['id']);
    final row = await fixture.run('record', {
      'action': 'createRecord',
      'tableId': table['id'],
      'revision': 3,
      'schemaRevision': 2,
      'values': {label: 'One'},
    });
    final view = await fixture.run('view', {
      'action': 'createView',
      'tableId': table['id'],
      'revision': 3,
      'schemaRevision': 2,
      'name': 'Overview',
      'columnIds': [label],
    });
    final saved = await fixture.run('save-view', {
      'action': 'saveView',
      'id': view['id'],
      'revision': 1,
      'schemaRevision': 2,
      'name': 'Updated overview',
      'bindings': {'title': label},
      'definition': {
        'version': 1,
        'components': [
          {'id': 'root', 'component': 'Text', 'text': 'Edited surface'},
        ],
      },
    });
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
    await expectLater(
      fixture.run('stale-column', {
        'action': 'saveColumn',
        'tableId': table['id'],
        'revision': 1,
        'schemaRevision': 1,
        'column': {'id': label, 'name': 'Stale', 'type': 'text'},
      }),
      throwsA(isA<WorkspaceTableException>()),
    );
    final invalid = {
      'action': 'saveView',
      'id': view['id'],
      'revision': 2,
      'schemaRevision': 2,
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
      fixture.run('invalid-view', invalid),
      throwsA(isA<Object>()),
    );
    expect(
      (await fixture.views.open(
        view['id'] as String? ?? (throw StateError('Expected string')),
      )).view.revision,
      2,
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
      final arguments = {
        'action': 'createTable',
        'name': 'Atomic',
        'labelName': 'Title',
      };
      await expectLater(
        failing.call(
          conversationId: fixture.conversationId,
          operationId: 'create-once',
          arguments: arguments,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await fixture.tables.list(), isEmpty);
      final created = await fixture.run('create-once', arguments);
      final retried = await fixture.run('create-once', arguments);
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
  ) => WorkspaceConversationToolsUsecase(
    conversations: conversations,
    context: (id) => LocalWorkspaceContextRepository(database, id),
    commands: (_) async => WorkspaceConversationCommandUsecase(
      tables: editor,
      folders: folders,
      views: views,
    ),
    receipts: .new(database),
  );
  Future<Map<String, Object?>> run(
    String id,
    Map<String, dynamic> arguments,
  ) async {
    final result = await service(tables).call(
      conversationId: conversationId,
      arguments: arguments,
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
