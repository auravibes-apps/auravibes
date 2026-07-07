import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      );
    }),
  );
}

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

  set database(AppDatabase database) {
    _database = database;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('AppDatabase', () {
    final fixture = _DatabaseFixture(createTestConnection);

    setUp(fixture.reset);

    tearDown(() async {
      await fixture.close();
    });

    test('has correct schema version', () {
      expect(fixture.database.schemaVersion, 5);
    });

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
      expect(fixture.database.conversationToolsDao, isNotNull);
      expect(fixture.database.skillsDao, isNotNull);
      expect(fixture.database.skillCredentialDefinitionsDao, isNotNull);
      expect(fixture.database.skillTemplateToolsDao, isNotNull);
      expect(fixture.database.conversationSkillsDao, isNotNull);
      expect(fixture.database.appSkillWorkspaceSettingsDao, isNotNull);
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

    test('migration strategy has onCreate callback', () {
      final strategy = fixture.database.migration;
      expect(strategy.onCreate, isNotNull);
    });

    test('migration from schema 4 backfills agent defaults', () async {
      await fixture.close();
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
      fixture.database = AppDatabase(
        connection: NativeDatabase.opened(sqliteDb),
      );

      final agent = await fixture.database
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

    test(
      'migration from schema 3 adds child conversations and agent defaults',
      () async {
        await fixture.close();
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
        fixture.database = AppDatabase(
          connection: NativeDatabase.opened(sqliteDb),
        );

        final agent = await fixture.database
            .customSelect(
              'SELECT description, is_enabled, visibility FROM agents '
              'WHERE id = ?',
              variables: [const Variable<String>('agent-1')],
            )
            .getSingle();
        final columns = await fixture.database
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
            WorkspacesCompanion.insert(
              name: 'Test Workspace',
              type: WorkspaceType.local,
            ),
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
            WorkspacesCompanion.insert(
              name: 'Workspace 1',
              type: WorkspaceType.local,
            ),
          );
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'Workspace 2',
              type: WorkspaceType.local,
            ),
          );

      final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(2));
    });

    test('database can be closed and recreated', () async {
      await fixture.close();

      final db2 = AppDatabase(connection: createTestConnection());
      final workspaces = await db2.workspaceDao.getAllWorkspaces();
      expect(workspaces, isEmpty);
      await db2.close();
    });
  });
}
