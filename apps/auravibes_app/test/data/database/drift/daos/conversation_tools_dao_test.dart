import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
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
  group('ConversationToolsDao', () {
    final fixture = _DatabaseFixture(createTestConnection);
    var conversationId = '';
    var toolId = '';

    setUp(() async {
      fixture.reset();
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final conv = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: ws.id, title: 'Conv'),
      );
      conversationId = conv.id;
      await fixture.database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(workspaceId: ws.id, toolId: 'web_search'),
      ]);
      final tools = await fixture.database.workspaceToolsDao.getWorkspaceTools(
        ws.id,
      );
      final tool = tools.firstOrNull;
      toolId = (tool ?? fail('Expected tool to be non-null')).id;
    });

    tearDown(() async {
      await fixture.close();
    });

    test('upsertConversationTool inserts new', () async {
      final result = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      expect(result.isEnabled, isTrue);
      expect(result.permissions, equals(PermissionAccess.ask));
    });

    test('upsertConversationTool updates on conflict', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final updated = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.granted,
          );
      expect(updated.isEnabled, isFalse);
      expect(updated.permissions, equals(PermissionAccess.granted));
    });

    test('getConversationTool returns tool', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final found = await fixture.database.conversationToolsDao
          .getConversationTool(
            conversationId,
            toolId,
          );
      expect(found, isNotNull);
    });

    test('getConversationTool returns null for nonexistent', () async {
      final found = await fixture.database.conversationToolsDao
          .getConversationTool(
            conversationId,
            'missing',
          );
      expect(found, isNull);
    });

    test('getConversationTools returns all tools for conversation', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final tools = await fixture.database.conversationToolsDao
          .getConversationTools(
            conversationId,
          );
      expect(tools.length, equals(1));
    });

    test('setConversationToolEnabled inserts when not exists', () async {
      final result = await fixture.database.conversationToolsDao
          .setConversationToolEnabled(
            conversationId,
            toolId,
            isEnabled: true,
          );
      expect(result.isEnabled, isTrue);
    });

    test('setConversationToolEnabled updates when exists', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final result = await fixture.database.conversationToolsDao
          .setConversationToolEnabled(
            conversationId,
            toolId,
            isEnabled: false,
          );
      expect(result.isEnabled, isFalse);
    });

    test('setConversationToolPermission inserts when not exists', () async {
      final result = await fixture.database.conversationToolsDao
          .setConversationToolPermission(
            conversationId,
            toolId,
            permission: PermissionAccess.granted,
          );
      expect(result.permissions, equals(PermissionAccess.granted));
    });

    test('setConversationToolPermission updates when exists', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final result = await fixture.database.conversationToolsDao
          .setConversationToolPermission(
            conversationId,
            toolId,
            permission: PermissionAccess.granted,
          );
      expect(result.permissions, equals(PermissionAccess.granted));
    });

    test('deleteConversationTool removes tool', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final deleted = await fixture.database.conversationToolsDao
          .deleteConversationTool(
            conversationId,
            toolId,
          );
      expect(deleted, isTrue);
      expect(
        await fixture.database.conversationToolsDao.getConversationTool(
          conversationId,
          toolId,
        ),
        isNull,
      );
    });

    test('deleteConversationTool returns false for nonexistent', () async {
      final deleted = await fixture.database.conversationToolsDao
          .deleteConversationTool(
            conversationId,
            'missing',
          );
      expect(deleted, isFalse);
    });

    test('isConversationToolEnabled returns true when no override', () async {
      final enabled = await fixture.database.conversationToolsDao
          .isConversationToolEnabled(
            conversationId,
            toolId,
          );
      expect(enabled, isTrue);
    });

    test('isConversationToolEnabled returns false when disabled', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.ask,
          );
      final enabled = await fixture.database.conversationToolsDao
          .isConversationToolEnabled(
            conversationId,
            toolId,
          );
      expect(enabled, isFalse);
    });

    test('getConversationToolsCount returns correct count', () async {
      expect(
        await fixture.database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(0),
      );
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      expect(
        await fixture.database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(1),
      );
    });

    test('removeToolsForConversation removes all', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      await fixture.database.conversationToolsDao.removeToolsForConversation(
        conversationId,
      );
      expect(
        await fixture.database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(0),
      );
    });

    test('copyConversationTools copies tools between conversations', () async {
      final ws = await fixture.database.workspaceDao.getAllWorkspaces();
      final conv2 = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          workspaceId:
              (ws.firstOrNull ?? fail('Expected ws.firstOrNull to be non-null'))
                  .id,
          title: 'Conv2',
        ),
      );
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.granted,
          );
      await fixture.database.conversationToolsDao.copyConversationTools(
        conversationId,
        conv2.id,
      );
      final copied = await fixture.database.conversationToolsDao
          .getConversationTool(
            conv2.id,
            toolId,
          );
      expect(copied, isNotNull);
      expect(
        (copied ?? fail('Expected copied to be non-null')).isEnabled,
        isFalse,
      );
      expect(copied.permissions, equals(PermissionAccess.granted));
    });

    test('toggleConversationTool toggles state', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final _ = await fixture.database.conversationToolsDao
          .toggleConversationTool(
            conversationId,
            toolId,
          );
      final tool = await fixture.database.conversationToolsDao
          .getConversationTool(
            conversationId,
            toolId,
          );
      expect((tool ?? fail('Expected tool to be non-null')).isEnabled, isFalse);
    });

    test('isConversationToolDisabled returns opposite of enabled', () async {
      expect(
        await fixture.database.conversationToolsDao.isConversationToolDisabled(
          conversationId,
          toolId,
        ),
        isFalse,
      );
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.ask,
          );
      expect(
        await fixture.database.conversationToolsDao.isConversationToolDisabled(
          conversationId,
          toolId,
        ),
        isTrue,
      );
    });

    test('getDisabledConversationTools returns only disabled', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.ask,
          );
      final disabled = await fixture.database.conversationToolsDao
          .getDisabledConversationTools(
            conversationId,
          );
      expect(disabled.length, equals(1));
    });

    test('getDisabledConversationToolsCount returns count', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.ask,
          );
      expect(
        await fixture.database.conversationToolsDao
            .getDisabledConversationToolsCount(
              conversationId,
            ),
        equals(1),
      );
    });

    test('disableConversationTools batch disables', () async {
      final ws = await fixture.database.workspaceDao.getAllWorkspaces();
      final workspace =
          ws.firstOrNull ?? fail('Expected ws.firstOrNull to be non-null');
      await fixture.database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspace.id,
          toolId: 'tool2',
        ),
      ]);
      final tools = await fixture.database.workspaceToolsDao.getWorkspaceTools(
        workspace.id,
      );
      final tool2 = tools.firstWhere((e) => e.toolId == 'tool2');
      await fixture.database.conversationToolsDao.disableConversationTools(
        conversationId,
        [toolId, tool2.id],
      );
      expect(
        await fixture.database.conversationToolsDao
            .getDisabledConversationToolsCount(
              conversationId,
            ),
        equals(2),
      );
    });

    test('enableConversationTool deletes override', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.ask,
          );
      final enabled = await fixture.database.conversationToolsDao
          .enableConversationTool(
            conversationId,
            toolId,
          );
      expect(enabled, isTrue);
    });

    test('removeDisabledToolsForConversation removes all', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            conversationId,
            toolId,
            isEnabled: false,
            permission: PermissionAccess.ask,
          );
      await fixture.database.conversationToolsDao
          .removeDisabledToolsForConversation(
            conversationId,
          );
      expect(
        await fixture.database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(0),
      );
    });
  });
}
