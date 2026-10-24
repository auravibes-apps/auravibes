import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'database_test_utils.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      );
    }),
  );
}

final class _DatabaseFixture(final QueryExecutor Function() createConnection) {
  AppDatabase? _database;

  AppDatabase get database =>
      _database ??= .new(connection: createConnection());

  Future<void> reset() => clearAppDatabase(database);

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('AppDatabase', () {
    final fixture = _DatabaseFixture(createTestConnection);

    setUp(fixture.reset);

    tearDownAll(fixture.close);

    test('has correct schema version', () {
      expect(fixture.database.schemaVersion, 39);
    });

    test(
      'schema38 migration preserves stored data and adds batch receipts',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 38
          ..execute('CREATE TABLE workspaces (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO workspaces VALUES (?)', ['existing']);
        final database = _MigrationAppDatabase<_MigrationCaseRecordBatch>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);
        expect(
          await database.select(database.workspaceRecordBatchReceipts).get(),
          isEmpty,
        );
        expect(
          (await database.customSelect('SELECT id FROM workspaces').getSingle())
              .read<String>('id'),
          'existing',
        );
      },
    );

    test(
      'migration from schema37 preserves Views and adds recoverable trash',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 37
          ..execute('CREATE TABLE workspaces (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO workspaces VALUES (?)', ['existing'])
          ..execute(
            'CREATE TABLE workspace_views (id TEXT PRIMARY KEY, '
            'workspace_id TEXT NOT NULL, data TEXT NOT NULL, '
            'revision INTEGER NOT NULL, mutations TEXT NOT NULL, '
            'history TEXT NOT NULL, created_at INTEGER NOT NULL, '
            'updated_at INTEGER NOT NULL)',
          )
          ..execute(
            'INSERT INTO workspace_views VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              'view',
              'existing',
              '{"name":"Retained"}',
              5,
              '{"op":5}',
              '[{"revision":5}]',
              1,
              1,
            ],
          );
        final database = _MigrationAppDatabase<_MigrationCaseTrash>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);
        final view =
            (await database.select(database.workspaceViews).get()).single;
        expect(view.id, 'view');
        expect(view.data, '{"name":"Retained"}');
        expect(view.history, '[{"revision":5}]');
        expect(view.mutations, '{"op":5}');
        expect(view.revision, 5);
        expect(view.deletedAt, isNull);
        expect(
          await database.select(database.workspaceTrashBatches).get(),
          isEmpty,
        );
      },
    );

    test(
      'migration from schema36 preserves data and creates View storage',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 36
          ..execute('CREATE TABLE workspaces (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO workspaces VALUES (?)', ['existing']);
        final database = _MigrationAppDatabase<_MigrationCaseViews>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);
        expect(await database.select(database.workspaceViews).get(), isEmpty);
        expect(
          (await database.customSelect('SELECT id FROM workspaces').getSingle())
              .read<String>('id'),
          'existing',
        );
      },
    );

    test(
      'migration from schema 32 keeps existing bookmark snapshots',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 32
          ..execute('CREATE TABLE conversations (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO conversations VALUES (?)', ['conversation'])
          ..execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            content TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            is_bookmarked INTEGER NOT NULL
          )
        ''')
          ..execute(
            '''
          INSERT INTO messages VALUES (?, ?, ?, ?, ?, ?)
        ''',
            [
              'saved-message',
              'conversation',
              'Saved excerpt',
              1,
              1767225600,
              1,
            ],
          );
        final database = _MigrationAppDatabase<_MigrationCase16>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final bookmark = await database.customSelect('''
            SELECT id, conversation_id, content_snapshot, is_user,
                   message_created_at
            FROM message_bookmarks
          ''').getSingle();

        expect(bookmark.read<String>('id'), 'saved-message');
        expect(bookmark.read<String>('conversation_id'), 'conversation');
        expect(bookmark.read<String>('content_snapshot'), 'Saved excerpt');
        expect(bookmark.read<bool>('is_user'), isTrue);
        expect(
          bookmark.read<DateTime>('message_created_at').millisecondsSinceEpoch,
          1767225600000,
        );
      },
    );

    test(
      'migration from schema 34 preserves workspace and creates table storage',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 34
          ..execute('CREATE TABLE workspaces (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO workspaces VALUES (?)', ['existing']);
        final database = _MigrationAppDatabase<_MigrationCase16>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);
        expect(await database.select(database.workspaceTables).get(), isEmpty);
        expect(
          await database.select(database.workspaceTableRecords).get(),
          isEmpty,
        );
        expect(
          (await database.customSelect('SELECT id FROM workspaces').getSingle())
              .read<String>('id'),
          'existing',
        );
      },
    );

    test(
      'migration from schema 33 preserves data and creates folders',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 33
          ..execute('CREATE TABLE workspaces (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO workspaces VALUES (?)', ['existing']);
        final database = _MigrationAppDatabase<_MigrationCase16>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);
        final _ = await database
            .into(database.workspaceFolders)
            .insert(
              WorkspaceFoldersCompanion.insert(
                workspaceId: 'existing',
                name: 'Documents',
              ),
            );
        expect(
          (await database.select(database.workspaceFolders).get()).single.name,
          'Documents',
        );
        expect(
          (await database.customSelect('SELECT id FROM workspaces').getSingle())
              .read<String>('id'),
          'existing',
        );
      },
    );

    test('migration from schema 29 adds unbookmarked messages', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 29
        ..execute('CREATE TABLE messages (id TEXT PRIMARY KEY)')
        ..execute('INSERT INTO messages VALUES (?)', ['existing']);
      final database = _MigrationAppDatabase<_MigrationCase16>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final row = await database
          .customSelect(
            'SELECT is_bookmarked FROM messages WHERE id = ?',
            variables: [const Variable<String>('existing')],
          )
          .getSingle();

      expect(row.read<bool>('is_bookmarked'), isFalse);
    });

    test('migration from schema 30 adds empty Connector references', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 30
        ..execute('CREATE TABLE skills (id TEXT PRIMARY KEY)')
        ..execute('INSERT INTO skills VALUES (?)', ['existing']);
      final database = _MigrationAppDatabase<_MigrationCase16>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final row = await database
          .customSelect(
            'SELECT connector_tool_ids_json FROM skills WHERE id = ?',
            variables: [const Variable<String>('existing')],
          )
          .getSingle();

      expect(row.read<String>('connector_tool_ids_json'), '[]');
    });

    test('migration from schema 31 retires Skill-owned storage', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 31
        ..execute(
          'CREATE TABLE service_connections '
          '(id TEXT PRIMARY KEY, kind TEXT, encrypted_auth_value TEXT)',
        )
        ..execute('INSERT INTO service_connections VALUES (?, ?, ?)', [
          'skill',
          'skillCredential',
          'encrypted',
        ])
        ..execute('INSERT INTO service_connections VALUES (?, ?, ?)', [
          'app-skill',
          'appSkillCredential',
          'encrypted',
        ])
        ..execute('INSERT INTO service_connections VALUES (?, ?, ?)', [
          'notion',
          'customHttp',
          'encrypted',
        ])
        ..execute('CREATE TABLE skill_template_tools (id TEXT PRIMARY KEY)')
        ..execute(
          'CREATE TABLE skill_credential_definitions (id TEXT PRIMARY KEY)',
        );
      final database = _MigrationAppDatabase<_MigrationCase16>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final connections = await database
          .customSelect('SELECT id, kind FROM service_connections')
          .get();
      final retiredTables = await database.customSelect('''
SELECT name FROM sqlite_master WHERE type = 'table'
AND name IN ('skill_template_tools', 'skill_credential_definitions')
''').get();

      expect(connections.map((row) => row.read<String>('id')), ['notion']);
      expect(connections.single.read<String>('kind'), 'customHttp');
      expect(retiredTables, isEmpty);
    });

    test(
      'migration from schema 25 preserves conversations with mode off',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 25
          ..execute('CREATE TABLE conversations (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO conversations VALUES (?)', ['existing']);
        final database = _MigrationAppDatabase<_MigrationCase16>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);
        final row = await database
            .customSelect(
              'SELECT tool_access_mode FROM conversations WHERE id = ?',
              variables: [const Variable<String>('existing')],
            )
            .getSingle();
        expect(row.read<String>('tool_access_mode'), 'default');
      },
    );

    test(
      'schema 26 backfills modes, removes boolean, and adds child link',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 26
          ..execute(
            'CREATE TABLE conversations (id TEXT PRIMARY KEY, '
            'auto_approve_tools INTEGER NOT NULL DEFAULT 0)',
          )
          ..execute('CREATE TABLE background_works (id TEXT PRIMARY KEY)')
          ..execute('INSERT INTO conversations VALUES (?, ?), (?, ?)', [
            'off',
            0,
            'on',
            1,
          ]);
        final database = _MigrationAppDatabase<_MigrationCase16>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);
        final rows = await database
            .customSelect(
              'SELECT tool_access_mode FROM conversations ORDER BY id',
            )
            .get();
        expect(rows.map((row) => row.read<String>('tool_access_mode')), [
          'default',
          'allow_all',
        ]);
        final columns = await database
            .customSelect('PRAGMA table_info(conversations)')
            .get();
        expect(
          columns.map((row) => row.read<String>('name')),
          isNot(contains('auto_approve_tools')),
        );
        final backgroundWorkColumns = await database
            .customSelect('PRAGMA table_info(background_works)')
            .get();
        expect(
          backgroundWorkColumns.map((row) => row.read<String>('name')),
          contains('child_conversation_id'),
        );
      },
    );

    test('schema 26 with child link adds default tool access mode', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 26
        ..execute('CREATE TABLE conversations (id TEXT PRIMARY KEY)')
        ..execute(
          'CREATE TABLE background_works (id TEXT PRIMARY KEY, '
          'child_conversation_id TEXT)',
        )
        ..execute('INSERT INTO conversations VALUES (?)', ['existing']);
      final database = _MigrationAppDatabase<_MigrationCase16>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final conversation = await database
          .customSelect('SELECT tool_access_mode FROM conversations')
          .getSingle();
      expect(conversation.read<String>('tool_access_mode'), 'default');

      final backgroundWorkColumns = await database
          .customSelect('PRAGMA table_info(background_works)')
          .get();
      expect(
        backgroundWorkColumns.map((row) => row.read<String>('name')),
        contains('child_conversation_id'),
      );
    });

    test('schema 27 adds background work child link', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 27
        ..execute(
          'CREATE TABLE conversations (id TEXT PRIMARY KEY, '
          '''tool_access_mode TEXT NOT NULL DEFAULT 'default')''',
        )
        ..execute('CREATE TABLE background_works (id TEXT PRIMARY KEY)');
      final database = _MigrationAppDatabase<_MigrationCase16>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final backgroundWorkColumns = await database
          .customSelect('PRAGMA table_info(background_works)')
          .get();
      expect(
        backgroundWorkColumns.map((row) => row.read<String>('name')),
        contains('child_conversation_id'),
      );
    });

    test('migration from schema 24 creates background work storage', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()..userVersion = 24;
      final database = _MigrationAppDatabase<_MigrationCase16>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final table = await database
          .customSelect(
            'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
            variables: [
              const Variable<String>('table'),
              const Variable<String>('background_works'),
            ],
          )
          .get();

      expect(table, hasLength(1));
    });

    test(
      'migration from schema 25 adds tool-call attachment association',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 25
          ..execute('CREATE TABLE message_attachments (id TEXT PRIMARY KEY)');
        final database = _MigrationAppDatabase<_MigrationCase16>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final columns = await database
            .customSelect('PRAGMA table_info(message_attachments)')
            .get();

        expect(
          columns.map((row) => row.read<String>('name')),
          contains('tool_call_id'),
        );
      },
    );

    test('migration defaults advanced capabilities to false', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 19
        ..execute('CREATE TABLE api_models (id TEXT PRIMARY KEY)')
        ..execute('INSERT INTO api_models VALUES (?)', ['existing']);
      final database = _MigrationAppDatabase<_MigrationCase1>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);
      final row = await database
          .customSelect(
            'SELECT * FROM api_models WHERE id = ?',
            variables: [const Variable<String>('existing')],
          )
          .getSingle();
      for (final column in [
        'supports_prompt_cache_markers',
        'supports_mid_conversation_system_messages',
        'supports_tool_deltas',
        'supports_deferred_tools',
      ]) {
        expect(row.read<bool>(column), isFalse, reason: column);
      }
    });

    test('migration adds MCP columns to the PR version 21 schema', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 21
        ..execute('''
          CREATE TABLE api_models (
            id TEXT PRIMARY KEY,
            supports_prompt_cache_markers INTEGER NOT NULL DEFAULT 0,
            supports_mid_conversation_system_messages INTEGER NOT NULL DEFAULT 0,
            supports_tool_deltas INTEGER NOT NULL DEFAULT 0,
            supports_deferred_tools INTEGER NOT NULL DEFAULT 0,
            cost_cache_write REAL
          );
        ''')
        ..execute('CREATE TABLE model_usage_records (id TEXT PRIMARY KEY)')
        ..execute('CREATE TABLE mcp_servers (id TEXT PRIMARY KEY)');
      final database = _MigrationAppDatabase<_MigrationCase2>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final columns = await database
          .customSelect('PRAGMA table_info(mcp_servers)')
          .get();

      expect(
        columns.map((row) => row.read<String>('name')),
        containsAll(['catalog_snapshot_json', 'test_summary_json']),
      );
    });

    test(
      'migration adds model columns to the main version 21 schema',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 21
          ..execute('CREATE TABLE api_models (id TEXT PRIMARY KEY)')
          ..execute('''
          CREATE TABLE mcp_servers (
            id TEXT PRIMARY KEY,
            catalog_snapshot_json TEXT,
            test_summary_json TEXT
          );
        ''');
        final database = _MigrationAppDatabase<_MigrationCase3>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final modelColumns = await database
            .customSelect('PRAGMA table_info(api_models)')
            .get();
        final usageTables = await database
            .customSelect(
              'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
              variables: [
                const Variable<String>('table'),
                const Variable<String>('model_usage_records'),
              ],
            )
            .get();

        expect(
          modelColumns.map((row) => row.read<String>('name')),
          containsAll([
            'supports_prompt_cache_markers',
            'supports_mid_conversation_system_messages',
            'supports_tool_deltas',
            'supports_deferred_tools',
            'cost_cache_write',
          ]),
        );
        expect(usageTables, isNotEmpty);
      },
    );

    test('creates successfully with in-memory connection', () {
      expect(fixture.database, isNotNull);
    });

    test('DAOs are accessible', () {
      expect(fixture.database.workspaceDao, isNotNull);
      expect(fixture.database.modelConnectionsDao, isNotNull);
      expect(fixture.database.workspaceModelSelectionsDao, isNotNull);
      expect(fixture.database.apiModelProvidersDao, isNotNull);
      expect(fixture.database.apiModelsDao, isNotNull);
      expect(fixture.database.conversationDao, isNotNull);
      expect(fixture.database.messageDao, isNotNull);
      expect(fixture.database.modelUsageRecordsDao, isNotNull);
      expect(fixture.database.conversationToolsDao, isNotNull);
      expect(fixture.database.skillsDao, isNotNull);
      expect(fixture.database.conversationSkillsDao, isNotNull);
      expect(fixture.database.appSkillWorkspaceSettingsDao, isNotNull);
      expect(fixture.database.recentModelSelectionsDao, isNotNull);
    });

    test('all DAO getters return non-null', () {
      expect(fixture.database.workspaceToolsDao, isNotNull);
      expect(fixture.database.toolsGroupsDao, isNotNull);
      expect(fixture.database.mcpServersDao, isNotNull);
    });

    test('migration onCreate creates all tables', () async {
      final strategy = fixture.database.migration;
      final _ = await fixture.database.customSelect('SELECT 1').getSingle();
      expect(strategy, isNotNull);
    });

    test(
      'migration from schema 19 adds nullable tool sampling policy',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 19
          ..execute('''
          CREATE TABLE workspace_model_selections (
            id TEXT PRIMARY KEY NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            model_id TEXT NOT NULL,
            model_connection_id TEXT NOT NULL
          )
        ''')
          ..execute('''
          INSERT INTO workspace_model_selections
            (id, created_at, updated_at, model_id, model_connection_id)
          VALUES ('selection-1', 1, 1, 'gpt-4o', 'connection-1')
        ''');
        final database = _MigrationAppDatabase<_MigrationCase4>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final selection = await database
            .customSelect(
              'SELECT tool_sampling_policy FROM workspace_model_selections '
              'WHERE id = ?',
              variables: [const Variable<String>('selection-1')],
            )
            .getSingle();

        expect(selection.read<String?>('tool_sampling_policy'), isNull);
      },
    );

    test(
      'migration adds MCP output schema without changing existing tools',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 16
          ..execute(
            'CREATE TABLE tools (id TEXT PRIMARY KEY, input_schema TEXT)',
          )
          ..execute(
            'INSERT INTO tools VALUES (\'tool-1\', \'{"type":"object"}\')',
          );
        final database = _MigrationAppDatabase<_MigrationCase5>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final row = await database
            .customSelect(
              'SELECT input_schema, output_schema FROM tools WHERE id = ?',
              variables: [const Variable<String>('tool-1')],
            )
            .getSingle();

        expect(row.read<String>('input_schema'), '{"type":"object"}');
        expect(row.read<String?>('output_schema'), isNull);
      },
    );

    test(
      'migration from schema 20 preserves tool policy and adds MCP fields',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 20
          ..execute('''
          CREATE TABLE mcp_servers (
            id TEXT NOT NULL PRIMARY KEY
          );
        ''')
          ..execute('''
          CREATE TABLE workspace_model_selections (
            id TEXT NOT NULL PRIMARY KEY,
            tool_sampling_policy TEXT
          );
        ''');
        final database = _MigrationAppDatabase<_MigrationCase6>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final mcpColumns = await database
            .customSelect('PRAGMA table_info(mcp_servers)')
            .get();
        final selectionColumns = await database
            .customSelect('PRAGMA table_info(workspace_model_selections)')
            .get();

        expect(
          mcpColumns.map((row) => row.read<String>('name')),
          containsAll(['catalog_snapshot_json', 'test_summary_json']),
        );
        expect(
          selectionColumns.map((row) => row.read<String>('name')),
          contains('tool_sampling_policy'),
        );
      },
    );

    test(
      'migration from schema 21 adds tool policy to MCP-upgraded database',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 21
          ..execute('''
            CREATE TABLE mcp_servers (
              id TEXT NOT NULL PRIMARY KEY,
              catalog_snapshot_json TEXT,
              test_summary_json TEXT
            );
          ''')
          ..execute('''
            CREATE TABLE workspace_model_selections (
              id TEXT NOT NULL PRIMARY KEY
            );
          ''');
        final database = _MigrationAppDatabase<_MigrationCase7>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final columns = await database
            .customSelect('PRAGMA table_info(workspace_model_selections)')
            .get();

        expect(
          columns.map((row) => row.read<String>('name')),
          contains('tool_sampling_policy'),
        );
      },
    );

    test('workspace deletion cascades to sensitive child records', () async {
      final workspace = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'Private workspace', type: WorkspaceType.local),
      );
      final conversation = await fixture.database.conversationDao
          .insertConversation(
            .insert(workspaceId: workspace.id, title: 'Private conversation'),
          );
      final _ = await fixture.database.messageDao.insertMessage(
        .insert(
          conversationId: conversation.id,
          content: 'Sensitive message',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );

      expect(
        await fixture.database.workspaceDao.deleteWorkspace(workspace.id),
        isTrue,
      );

      final conversations = await fixture.database
          .customSelect(
            'SELECT id FROM conversations WHERE workspace_id = ?',
            variables: [Variable<String>(workspace.id)],
          )
          .get();
      final messages = await fixture.database
          .customSelect(
            'SELECT id FROM messages WHERE conversation_id = ?',
            variables: [Variable<String>(conversation.id)],
          )
          .get();
      expect(conversations, isEmpty);
      expect(messages, isEmpty);
    });

    test('migration retires skill-owned tool and credential storage', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 11
        ..execute('''
          CREATE TABLE agents (
            id TEXT NOT NULL PRIMARY KEY,
            workspace_id TEXT NOT NULL,
            name TEXT NOT NULL
          );
        ''')
        ..execute('''
          CREATE TABLE skill_template_tools (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            skill_id TEXT NOT NULL,
            template_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            slug TEXT NOT NULL,
            template_json TEXT NOT NULL,
            inputs_json TEXT NOT NULL,
            requires_credential INTEGER NOT NULL DEFAULT 0,
            is_enabled INTEGER NOT NULL DEFAULT 1
          );
        ''')
        ..execute('''
          INSERT INTO skill_template_tools (
            id, created_at, updated_at, skill_id, template_type, title,
            description, slug, template_json, inputs_json
          ) VALUES (
            'tool-1', 0, 0, 'skill-1', 'url', 'Search', 'Search', 'search',
            '{"url":"https://example.com","method":"GET"}',
            '{"query":{"type":"string","description":"Query"}}'
          );
        ''')
        ..execute('''
          CREATE TABLE service_connections (
            id TEXT NOT NULL PRIMARY KEY,
            kind TEXT NOT NULL
          );
        ''')
        ..execute('''
          INSERT INTO service_connections (id, kind) VALUES
            ('skill-credential', 'skillCredential'),
            ('app-skill-credential', 'appSkillCredential'),
            ('connector', 'connector');
        ''')
        ..execute('''
          CREATE TABLE skill_credential_definitions (
            id TEXT NOT NULL PRIMARY KEY
          );
        ''');
      final database = _MigrationAppDatabase<_MigrationCase8>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final legacyTables = await database
          .customSelect(
            'SELECT name FROM sqlite_master WHERE type = ? AND name IN (?, ?)',
            variables: [
              const Variable<String>('table'),
              const Variable<String>('skill_template_tools'),
              const Variable<String>('skill_credential_definitions'),
            ],
          )
          .get();
      final connectionKinds = await database
          .customSelect('SELECT kind FROM service_connections')
          .get();

      expect(legacyTables, isEmpty);
      expect(connectionKinds.map((row) => row.read<String>('kind')), [
        'connector',
      ]);
    });

    test('migration strategy has onCreate callback', () {
      final strategy = fixture.database.migration;
      expect(strategy.onCreate, isNotNull);
    });

    test(
      'migration adds cache-write pricing and request usage records',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 20
          ..execute('CREATE TABLE api_models (id TEXT NOT NULL PRIMARY KEY)')
          ..execute(
            'CREATE TABLE conversations (id TEXT NOT NULL PRIMARY KEY)',
          );
        final database = _MigrationAppDatabase<_MigrationCase9>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final modelColumns = await database
            .customSelect('PRAGMA table_info(api_models)')
            .get();
        final usageTable = await database
            .customSelect(
              'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
              variables: [
                const Variable<String>('table'),
                const Variable<String>('model_usage_records'),
              ],
            )
            .get();

        expect(
          modelColumns.map((row) => row.read<String>('name')),
          contains('cost_cache_write'),
        );
        expect(usageTable, hasLength(1));
      },
    );

    test('migration repairs the legacy api model modalities column', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 13
        ..execute('''
          CREATE TABLE api_models (
            id TEXT NOT NULL PRIMARY KEY,
            modalities_ouput TEXT NULL
          );
        ''')
        ..execute('''
          INSERT INTO api_models (id, modalities_ouput)
          VALUES ('model-1', '["text"]');
        ''')
        ..execute('''
          CREATE TABLE agents (
            id TEXT NOT NULL PRIMARY KEY,
            workspace_id TEXT NOT NULL,
            name TEXT NOT NULL
          );
        ''');
      final database = _MigrationAppDatabase<_MigrationCase10>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final columns = await database
          .customSelect('PRAGMA table_info(api_models)')
          .get();
      final model = await database
          .customSelect(
            'SELECT modalities_output FROM api_models WHERE id = ?',
            variables: [const Variable<String>('model-1')],
          )
          .getSingle();

      expect(
        columns.map((column) => column.read<String>('name')),
        contains('modalities_output'),
      );
      expect(model.read<String>('modalities_output'), '["text"]');
    });

    test(
      'migration converts legacy streaming messages to unfinished',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 14
          ..execute('''
          CREATE TABLE agents (
            id TEXT NOT NULL PRIMARY KEY,
            workspace_id TEXT NOT NULL,
            name TEXT NOT NULL
          );
        ''')
          ..execute('''
          CREATE TABLE messages (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            conversation_id TEXT NOT NULL,
            content TEXT NOT NULL,
            message_type TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            status TEXT NOT NULL,
            metadata TEXT
          );
        ''')
          ..execute('''
          INSERT INTO messages (
            id, created_at, updated_at, conversation_id, content,
            message_type, is_user, status
          ) VALUES ('message-1', 0, 0, 'conversation-1', 'Partial response',
            'text', 0, 'streaming');
        ''');
        final database = _MigrationAppDatabase<_MigrationCase11>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final message = await database.messageDao.getMessageById('message-1');

        expect(message?.status, MessageTableStatus.unfinished);
      },
    );

    test(
      'migration from schema 6 preserves agents and adds catalog index',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 6
          ..execute('''
          CREATE TABLE agents (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            workspace_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            content TEXT NOT NULL,
            is_enabled INTEGER NOT NULL DEFAULT 1,
            visibility TEXT NOT NULL DEFAULT 'both'
          );
        ''')
          ..execute('''
          INSERT INTO agents (
            id, created_at, updated_at, workspace_id, name, description,
            content, is_enabled, visibility
          ) VALUES ('agent-1', 0, 0, 'workspace-1', 'Agent', 'Description',
            'Prompt', 1, 'both')
        ''');
        final database = _MigrationAppDatabase<_MigrationCase12>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final agent = await database.customSelect(
          '''SELECT id FROM agents WHERE id = 'agent-1' ''',
        ).getSingle();
        final indexes = await database.customSelect(
          '''PRAGMA index_list('agents')''',
        ).get();

        expect(agent.read<String>('id'), 'agent-1');
        expect(
          indexes.map((row) => row.read<String>('name')),
          contains('agents_workspace_name_id'),
        );
      },
    );

    test('migration from schema 4 backfills agent defaults', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 4
        ..execute('''
          CREATE TABLE workspaces (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            url TEXT NULL
          );
        ''')
        ..execute('''
          CREATE TABLE agents (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            workspace_id TEXT NOT NULL,
            name TEXT NOT NULL,
            content TEXT NOT NULL
          );
        ''')
        ..execute(
          'INSERT INTO workspaces '
          '(id, created_at, updated_at, name, type) '
          'VALUES (?, 0, 0, ?, ?)',
          ['ws-1', 'Workspace', 'local'],
        )
        ..execute(
          'INSERT INTO agents '
          '(id, created_at, updated_at, workspace_id, name, content) '
          'VALUES (?, 0, 0, ?, ?, ?)',
          ['agent-1', 'ws-1', 'Agent', '  Prompt text  '],
        );
      final database = _MigrationAppDatabase<_MigrationCase13>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final agent = await database
          .customSelect(
            'SELECT description, is_enabled, visibility FROM agents '
            'WHERE id = ?',
            variables: [const Variable<String>('agent-1')],
          )
          .getSingle();

      expect(agent.read<String>('description'), 'Prompt text');
      expect(agent.read<bool>('is_enabled'), isTrue);
      expect(agent.read<String>('visibility'), 'both');
    });

    test('migration from schema 4 adds attachment display names', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory()
        ..userVersion = 4
        ..execute('''
          CREATE TABLE workspaces (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            url TEXT NULL
          );
        ''')
        ..execute('''
          CREATE TABLE message_attachments (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            message_id TEXT NOT NULL,
            local_path TEXT NOT NULL,
            file_name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            modality TEXT NOT NULL,
            size_bytes INTEGER NOT NULL
          );
        ''')
        ..execute('''
          CREATE TABLE agents (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            workspace_id TEXT NOT NULL,
            name TEXT NOT NULL,
            content TEXT NOT NULL
          );
        ''')
        ..execute(
          'INSERT INTO message_attachments '
          '(id, created_at, updated_at, message_id, local_path, file_name, '
          'mime_type, modality, size_bytes) '
          'VALUES (?, 0, 0, ?, ?, ?, ?, ?, ?)',
          [
            'attachment-1',
            'message-1',
            '/tmp/image.png',
            'image.png',
            'image/png',
            'image',
            10,
          ],
        );
      final database = _MigrationAppDatabase<_MigrationCase14>(
        connection: NativeDatabase.opened(sqliteDb),
      );
      addTearDown(database.close);

      final columns = await database
          .customSelect('PRAGMA table_info(message_attachments)')
          .get();
      final attachment = await database
          .customSelect(
            'SELECT display_name FROM message_attachments WHERE id = ?',
            variables: [const Variable<String>('attachment-1')],
          )
          .getSingle();

      expect(
        columns.map((column) => column.read<String>('name')),
        contains('display_name'),
      );
      expect(attachment.read<String>('display_name'), 'image.png');
    });

    test(
      'migration from schema 3 adds child conversations and agent defaults',
      () async {
        final sqliteDb = sqlite.sqlite3.openInMemory()
          ..userVersion = 3
          ..execute('''
          CREATE TABLE workspaces (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            url TEXT NULL
          );
        ''')
          ..execute('''
          CREATE TABLE agents (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            workspace_id TEXT NOT NULL,
            name TEXT NOT NULL,
            content TEXT NOT NULL
          );
        ''')
          ..execute('''
          CREATE TABLE conversations (
            id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            workspace_id TEXT NOT NULL,
            title TEXT NOT NULL,
            model_id TEXT NULL,
            agent_id TEXT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0
          );
        ''')
          ..execute(
            'INSERT INTO workspaces '
            '(id, created_at, updated_at, name, type) '
            'VALUES (?, 0, 0, ?, ?)',
            ['ws-1', 'Workspace', 'local'],
          )
          ..execute(
            'INSERT INTO agents '
            '(id, created_at, updated_at, workspace_id, name, content) '
            'VALUES (?, 0, 0, ?, ?, ?)',
            ['agent-1', 'ws-1', 'Agent', '  Prompt text  '],
          );
        final database = _MigrationAppDatabase<_MigrationCase15>(
          connection: NativeDatabase.opened(sqliteDb),
        );
        addTearDown(database.close);

        final agent = await database
            .customSelect(
              'SELECT description, is_enabled, visibility FROM agents '
              'WHERE id = ?',
              variables: [const Variable<String>('agent-1')],
            )
            .getSingle();
        final columns = await database
            .customSelect('PRAGMA table_info(conversations)')
            .get();

        expect(agent.read<String>('description'), 'Prompt text');
        expect(agent.read<bool>('is_enabled'), isTrue);
        expect(agent.read<String>('visibility'), 'both');
        expect(
          columns.map((column) => column.read<String>('name')),
          contains('parent_conversation_id'),
        );
      },
    );

    test('can insert workspace and query back', () async {
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(name: 'Test Workspace', type: .local),
          );

      final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(1));
      expect(workspaces.firstOrNull?.name, 'Test Workspace');
      expect(workspaces.firstOrNull?.type, WorkspaceType.local);
    });

    test('can insert multiple workspaces', () async {
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(name: 'Workspace 1', type: .local),
          );
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(name: 'Workspace 2', type: .local),
          );

      final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(2));
    });

    test('database can be closed and recreated', () async {
      final original = _DatabaseBeforeRecreation(createTestConnection());
      await original.close();

      final db2 = _RecreatedDatabase(createTestConnection());
      final workspaces = await db2.workspaceDao.getAllWorkspaces();
      expect(workspaces, isEmpty);
      await db2.close();
    });
  });
}

final class _MigrationAppDatabase<Scenario> extends AppDatabase {
  new({required super.connection});
}

final class _MigrationCase1;

final class _MigrationCase2;

final class _MigrationCase3;

final class _MigrationCase4;

final class _MigrationCase5;

final class _MigrationCase6;

final class _MigrationCase7;

final class _MigrationCase8;

final class _MigrationCase9;

final class _MigrationCase10;

final class _MigrationCase11;

final class _MigrationCase12;

final class _MigrationCase13;

final class _MigrationCase14;

final class _MigrationCase15;

final class _MigrationCase16;

final class _RecreatedDatabase extends AppDatabase {
  new(QueryExecutor connection) : super(connection: connection);
}

final class _DatabaseBeforeRecreation extends AppDatabase {
  new(QueryExecutor connection) : super(connection: connection);
}

final class _MigrationCaseViews;

final class _MigrationCaseTrash;

final class _MigrationCaseRecordBatch;
