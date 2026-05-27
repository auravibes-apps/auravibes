// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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

void main() {
  group('ConversationToolsDao', () {
    late AppDatabase database;
    late String conversationId;
    late String toolId;

    setUp(() async {
      database = AppDatabase(connection: createTestConnection());
      final ws = await database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final conv = await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: ws.id, title: 'Conv'),
      );
      conversationId = conv.id;
      final tool = await database.workspaceToolsDao
          .insertToolsBatch([
            ToolsCompanion.insert(workspaceId: ws.id, toolId: 'web_search'),
          ])
          .then((_) async {
            final t = await database.workspaceToolsDao.getWorkspaceTools(ws.id);
            return t.firstOrNull;
          });
      toolId = tool!.id;
    });

    tearDown(() async {
      await database.close();
    });

    test('upsertConversationTool inserts new', () async {
      final result = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      expect(result.isEnabled, isTrue);
      expect(result.permissions, equals(PermissionAccess.ask));
    });

    test('upsertConversationTool updates on conflict', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      final updated = await database.conversationToolsDao
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
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      final found = await database.conversationToolsDao.getConversationTool(
        conversationId,
        toolId,
      );
      expect(found, isNotNull);
    });

    test('getConversationTool returns null for nonexistent', () async {
      final found = await database.conversationToolsDao.getConversationTool(
        conversationId,
        'missing',
      );
      expect(found, isNull);
    });

    test('getConversationTools returns all tools for conversation', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      final tools = await database.conversationToolsDao.getConversationTools(
        conversationId,
      );
      expect(tools.length, equals(1));
    });

    test('setConversationToolEnabled inserts when not exists', () async {
      final result = await database.conversationToolsDao
          .setConversationToolEnabled(
            conversationId,
            toolId,
            isEnabled: true,
          );
      expect(result.isEnabled, isTrue);
    });

    test('setConversationToolEnabled updates when exists', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      final result = await database.conversationToolsDao
          .setConversationToolEnabled(
            conversationId,
            toolId,
            isEnabled: false,
          );
      expect(result.isEnabled, isFalse);
    });

    test('setConversationToolPermission inserts when not exists', () async {
      final result = await database.conversationToolsDao
          .setConversationToolPermission(
            conversationId,
            toolId,
            permission: PermissionAccess.granted,
          );
      expect(result.permissions, equals(PermissionAccess.granted));
    });

    test('setConversationToolPermission updates when exists', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      final result = await database.conversationToolsDao
          .setConversationToolPermission(
            conversationId,
            toolId,
            permission: PermissionAccess.granted,
          );
      expect(result.permissions, equals(PermissionAccess.granted));
    });

    test('deleteConversationTool removes tool', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      final deleted = await database.conversationToolsDao
          .deleteConversationTool(
            conversationId,
            toolId,
          );
      expect(deleted, isTrue);
      expect(
        await database.conversationToolsDao.getConversationTool(
          conversationId,
          toolId,
        ),
        isNull,
      );
    });

    test('deleteConversationTool returns false for nonexistent', () async {
      final deleted = await database.conversationToolsDao
          .deleteConversationTool(
            conversationId,
            'missing',
          );
      expect(deleted, isFalse);
    });

    test('isConversationToolEnabled returns true when no override', () async {
      final enabled = await database.conversationToolsDao
          .isConversationToolEnabled(
            conversationId,
            toolId,
          );
      expect(enabled, isTrue);
    });

    test('isConversationToolEnabled returns false when disabled', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: false,
        permission: PermissionAccess.ask,
      );
      final enabled = await database.conversationToolsDao
          .isConversationToolEnabled(
            conversationId,
            toolId,
          );
      expect(enabled, isFalse);
    });

    test('getConversationToolsCount returns correct count', () async {
      expect(
        await database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(0),
      );
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      expect(
        await database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(1),
      );
    });

    test('removeToolsForConversation removes all', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      await database.conversationToolsDao.removeToolsForConversation(
        conversationId,
      );
      expect(
        await database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(0),
      );
    });

    test('copyConversationTools copies tools between conversations', () async {
      final ws = await database.workspaceDao.getAllWorkspaces();
      final conv2 = await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          workspaceId: ws.firstOrNull!.id,
          title: 'Conv2',
        ),
      );
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: false,
        permission: PermissionAccess.granted,
      );
      await database.conversationToolsDao.copyConversationTools(
        conversationId,
        conv2.id,
      );
      final copied = await database.conversationToolsDao.getConversationTool(
        conv2.id,
        toolId,
      );
      expect(copied, isNotNull);
      expect(copied!.isEnabled, isFalse);
      expect(copied.permissions, equals(PermissionAccess.granted));
    });

    test('toggleConversationTool toggles state', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      final _ = await database.conversationToolsDao.toggleConversationTool(
        conversationId,
        toolId,
      );
      final tool = await database.conversationToolsDao.getConversationTool(
        conversationId,
        toolId,
      );
      expect(tool!.isEnabled, isFalse);
    });

    test('isConversationToolDisabled returns opposite of enabled', () async {
      expect(
        await database.conversationToolsDao.isConversationToolDisabled(
          conversationId,
          toolId,
        ),
        isFalse,
      );
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: false,
        permission: PermissionAccess.ask,
      );
      expect(
        await database.conversationToolsDao.isConversationToolDisabled(
          conversationId,
          toolId,
        ),
        isTrue,
      );
    });

    test('getDisabledConversationTools returns only disabled', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: false,
        permission: PermissionAccess.ask,
      );
      final disabled = await database.conversationToolsDao
          .getDisabledConversationTools(
            conversationId,
          );
      expect(disabled.length, equals(1));
    });

    test('getDisabledConversationToolsCount returns count', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: false,
        permission: PermissionAccess.ask,
      );
      expect(
        await database.conversationToolsDao.getDisabledConversationToolsCount(
          conversationId,
        ),
        equals(1),
      );
    });

    test('disableConversationTools batch disables', () async {
      final ws = await database.workspaceDao.getAllWorkspaces();
      final tool2 = await database.workspaceToolsDao
          .insertToolsBatch([
            ToolsCompanion.insert(
              workspaceId: ws.firstOrNull!.id,
              toolId: 'tool2',
            ),
          ])
          .then((_) async {
            final t = await database.workspaceToolsDao.getWorkspaceTools(
              ws.firstOrNull!.id,
            );
            return t.firstWhere((e) => e.toolId == 'tool2');
          });
      await database.conversationToolsDao.disableConversationTools(
        conversationId,
        [toolId, tool2.id],
      );
      expect(
        await database.conversationToolsDao.getDisabledConversationToolsCount(
          conversationId,
        ),
        equals(2),
      );
    });

    test('enableConversationTool deletes override', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: false,
        permission: PermissionAccess.ask,
      );
      final enabled = await database.conversationToolsDao
          .enableConversationTool(
            conversationId,
            toolId,
          );
      expect(enabled, isTrue);
    });

    test('removeDisabledToolsForConversation removes all', () async {
      final _ = await database.conversationToolsDao.upsertConversationTool(
        conversationId,
        toolId,
        isEnabled: false,
        permission: PermissionAccess.ask,
      );
      await database.conversationToolsDao.removeDisabledToolsForConversation(
        conversationId,
      );
      expect(
        await database.conversationToolsDao.getConversationToolsCount(
          conversationId,
        ),
        equals(0),
      );
    });
  });
}
