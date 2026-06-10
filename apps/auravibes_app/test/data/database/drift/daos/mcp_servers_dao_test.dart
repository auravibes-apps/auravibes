import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

McpServersCompanion _testServer({
  required String workspaceId,
  String name = 'Test MCP',
  String url = 'http://localhost:8080',
  bool isEnabled = true,
}) {
  return McpServersCompanion.insert(
    workspaceId: workspaceId,
    name: name,
    url: url,
    transport: const McpTransportTypeSSE(),
    isEnabled: Value(isEnabled),
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

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('McpServersDao', () {
    final fixture = _DatabaseFixture(createTestConnection);
    var workspaceId = '';

    setUp(() async {
      fixture.reset();
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await fixture.close();
    });

    test('insertMcpServer creates and returns server', () async {
      final inserted = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      expect(inserted.name, equals('Test MCP'));
      expect(inserted.workspaceId, equals(workspaceId));
    });

    test('getMcpServerById returns server', () async {
      final created = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      final found = await fixture.database.mcpServersDao.getMcpServerById(
        created.id,
      );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).name,
        equals('Test MCP'),
      );
    });

    test('getMcpServerById returns null for nonexistent', () async {
      final found = await fixture.database.mcpServersDao.getMcpServerById(
        'missing',
      );
      expect(found, isNull);
    });

    test('getMcpServersForWorkspace returns servers for workspace', () async {
      final _ = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId, name: 'Server 1'),
      );
      final _ = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId, name: 'Server 2'),
      );
      final servers = await fixture.database.mcpServersDao
          .getMcpServersForWorkspace(
            workspaceId,
          );
      expect(servers.length, equals(2));
    });

    test(
      'getMcpServersForWorkspace returns empty for other workspace',
      () async {
        final _ = await fixture.database.mcpServersDao.insertMcpServer(
          _testServer(workspaceId: workspaceId),
        );
        final servers = await fixture.database.mcpServersDao
            .getMcpServersForWorkspace(
              'other-ws',
            );
        expect(servers, isEmpty);
      },
    );

    test('getEnabledMcpServersForWorkspace returns only enabled', () async {
      final _ = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId, name: 'Enabled'),
      );
      final _ = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(
          workspaceId: workspaceId,
          name: 'Disabled',
          isEnabled: false,
        ),
      );
      final enabled = await fixture.database.mcpServersDao
          .getEnabledMcpServersForWorkspace(
            workspaceId,
          );
      expect(enabled.length, equals(1));
      expect(enabled.firstOrNull?.name, equals('Enabled'));
    });

    test('deleteMcpServer deletes server with tool group and tools', () async {
      final server = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      final group = await fixture.database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          mcpServerId: Value(server.id),
          name: 'Group',
          permissions: PermissionAccess.ask,
        ),
      );
      await fixture.database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'tool1',
        ),
      ]);
      final deleted = await fixture.database.mcpServersDao.deleteMcpServer(
        server.id,
      );
      expect(deleted, isTrue);
      expect(
        await fixture.database.mcpServersDao.getMcpServerById(server.id),
        isNull,
      );
    });

    test('deleteMcpServer returns false when no tool group', () async {
      final deleted = await fixture.database.mcpServersDao.deleteMcpServer(
        'missing',
      );
      expect(deleted, isFalse);
    });

    test('toggleMcpServerEnabled updates enabled state', () async {
      final server = await fixture.database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      final toggled = await fixture.database.mcpServersDao
          .toggleMcpServerEnabled(
            server.id,
            isEnabled: false,
          );
      expect(toggled, isNotNull);
      expect(
        (toggled ?? fail('Expected toggled to be non-null')).isEnabled,
        isFalse,
      );
    });
  });
}
