// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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
    authenticationType: const McpAuthenticationType.none(),
    isEnabled: Value(isEnabled),
  );
}

void main() {
  group('McpServersDao', () {
    late AppDatabase database;
    late String workspaceId;

    setUp(() async {
      database = AppDatabase(connection: createTestConnection());
      final ws = await database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await database.close();
    });

    test('insertMcpServer creates and returns server', () async {
      final inserted = await database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      expect(inserted.name, equals('Test MCP'));
      expect(inserted.workspaceId, equals(workspaceId));
    });

    test('getMcpServerById returns server', () async {
      final created = await database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      final found = await database.mcpServersDao.getMcpServerById(created.id);
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).name,
        equals('Test MCP'),
      );
    });

    test('getMcpServerById returns null for nonexistent', () async {
      final found = await database.mcpServersDao.getMcpServerById('missing');
      expect(found, isNull);
    });

    test('getMcpServersForWorkspace returns servers for workspace', () async {
      final _ = await database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId, name: 'Server 1'),
      );
      final _ = await database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId, name: 'Server 2'),
      );
      final servers = await database.mcpServersDao.getMcpServersForWorkspace(
        workspaceId,
      );
      expect(servers.length, equals(2));
    });

    test(
      'getMcpServersForWorkspace returns empty for other workspace',
      () async {
        final _ = await database.mcpServersDao.insertMcpServer(
          _testServer(workspaceId: workspaceId),
        );
        final servers = await database.mcpServersDao.getMcpServersForWorkspace(
          'other-ws',
        );
        expect(servers, isEmpty);
      },
    );

    test('getEnabledMcpServersForWorkspace returns only enabled', () async {
      final _ = await database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId, name: 'Enabled'),
      );
      final _ = await database.mcpServersDao.insertMcpServer(
        _testServer(
          workspaceId: workspaceId,
          name: 'Disabled',
          isEnabled: false,
        ),
      );
      final enabled = await database.mcpServersDao
          .getEnabledMcpServersForWorkspace(
            workspaceId,
          );
      expect(enabled.length, equals(1));
      expect(enabled.firstOrNull?.name, equals('Enabled'));
    });

    test('deleteMcpServer deletes server with tool group and tools', () async {
      final server = await database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      final group = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          mcpServerId: Value(server.id),
          name: 'Group',
          permissions: PermissionAccess.ask,
        ),
      );
      await database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'tool1',
        ),
      ]);
      final deleted = await database.mcpServersDao.deleteMcpServer(server.id);
      expect(deleted, isTrue);
      expect(
        await database.mcpServersDao.getMcpServerById(server.id),
        isNull,
      );
    });

    test('deleteMcpServer returns false when no tool group', () async {
      final deleted = await database.mcpServersDao.deleteMcpServer('missing');
      expect(deleted, isFalse);
    });

    test('toggleMcpServerEnabled updates enabled state', () async {
      final server = await database.mcpServersDao.insertMcpServer(
        _testServer(workspaceId: workspaceId),
      );
      final toggled = await database.mcpServersDao.toggleMcpServerEnabled(
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
