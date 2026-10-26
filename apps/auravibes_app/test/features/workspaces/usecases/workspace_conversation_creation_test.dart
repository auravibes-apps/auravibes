import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  }) async {
    final _ = await super.create(
      name: name,
      labelName: labelName,
      parentId: parentId,
    );
    throw StateError('Simulated interruption before receipt commit');
  }
}
