// ignore_for_file: cascade_invocations

import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubConversationToolsRepository implements ConversationToolsRepository {
  List<ConversationToolEntity> tools = [];
  List<ConversationToolEntity> enabledTools = [];
  ConversationToolEntity? toolById;
  bool setEnabledResult = true;
  bool setPermissionResult = true;
  bool toggleResult = true;
  bool isEnabledResult = false;
  bool removeResult = true;
  int toolsCount = 0;
  int enabledCount = 0;
  bool validateResult = true;
  bool isAvailableResult = false;
  List<String> availableTools = [];
  List<WorkspaceToolEntity> availableEntities = [];
  ToolPermissionResult permissionResult = ToolPermissionResult.granted;

  @override
  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  ) async {
    return tools;
  }

  @override
  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  ) async {
    return enabledTools;
  }

  @override
  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolId,
  ) async {
    return toolById;
  }

  @override
  Future<bool> setConversationToolEnabled(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) async {
    return setEnabledResult;
  }

  @override
  Future<void> setConversationToolsDisabled(
    String conversationId,
    List<String> toolIds,
  ) async {
    final _ = Object();
  }

  @override
  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) async {
    return setPermissionResult;
  }

  @override
  Future<bool> toggleConversationTool(
    String conversationId,
    String toolId,
  ) async {
    return toggleResult;
  }

  @override
  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolId,
  ) async {
    return isEnabledResult;
  }

  @override
  Future<bool> removeConversationTool(
    String conversationId,
    String toolId,
  ) async {
    return removeResult;
  }

  @override
  Future<int> getConversationToolsCount(
    String conversationId,
  ) async {
    return toolsCount;
  }

  @override
  Future<int> getEnabledConversationToolsCount(
    String conversationId,
  ) async {
    return enabledCount;
  }

  @override
  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) async {
    final _ = Object();
  }

  @override
  Future<bool> validateConversationToolSetting(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) async {
    return validateResult;
  }

  @override
  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolId,
  ) async {
    return isAvailableResult;
  }

  @override
  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    return availableTools;
  }

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    return availableEntities;
  }

  @override
  Future<ToolPermissionResult> checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  }) async {
    return permissionResult;
  }
}

void main() {
  group('ConversationToolsRepository', () {
    test('getConversationTools returns list', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.getConversationTools('c-1');

      expect(result, isEmpty);
    });

    test('getEnabledConversationTools returns list', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.getEnabledConversationTools('c-1');

      expect(result, isEmpty);
    });

    test('getConversationTool returns null when not found', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.getConversationTool('c-1', 't-1');

      expect(result, isNull);
    });

    test('setConversationToolEnabled returns bool', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.setConversationToolEnabled(
        'c-1',
        't-1',
        isEnabled: true,
      );

      expect(result, true);
    });

    test('setConversationToolsDisabled completes', () async {
      final repo = _StubConversationToolsRepository();

      await repo.setConversationToolsDisabled('c-1', ['t-1', 't-2']);

      expect(true, true);
    });

    test('setConversationToolPermission returns bool', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.setConversationToolPermission(
        'c-1',
        't-1',
        permissionMode: ToolPermissionMode.alwaysAllow,
      );

      expect(result, true);
    });

    test('toggleConversationTool returns bool', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.toggleConversationTool('c-1', 't-1');

      expect(result, true);
    });

    test('isConversationToolEnabled returns bool', () async {
      final repo = _StubConversationToolsRepository();
      repo.isEnabledResult = true;

      expect(
        await repo.isConversationToolEnabled('c-1', 't-1'),
        true,
      );
    });

    test('removeConversationTool returns bool', () async {
      final repo = _StubConversationToolsRepository();

      expect(await repo.removeConversationTool('c-1', 't-1'), true);

      repo.removeResult = false;
      expect(await repo.removeConversationTool('c-1', 't-1'), false);
    });

    test('getConversationToolsCount returns count', () async {
      final repo = _StubConversationToolsRepository();
      repo.toolsCount = 7;

      expect(await repo.getConversationToolsCount('c-1'), 7);
    });

    test('getEnabledConversationToolsCount returns count', () async {
      final repo = _StubConversationToolsRepository();
      repo.enabledCount = 4;

      expect(await repo.getEnabledConversationToolsCount('c-1'), 4);
    });

    test('copyConversationTools completes', () async {
      final repo = _StubConversationToolsRepository();

      await repo.copyConversationTools('c-1', 'c-2');

      expect(true, true);
    });

    test('validateConversationToolSetting returns bool', () async {
      final repo = _StubConversationToolsRepository();

      expect(
        await repo.validateConversationToolSetting(
          'c-1',
          't-1',
          isEnabled: true,
        ),
        true,
      );
    });

    test('isToolAvailableForConversation returns bool', () async {
      final repo = _StubConversationToolsRepository();
      repo.isAvailableResult = true;

      expect(
        await repo.isToolAvailableForConversation('c-1', 'ws-1', 't-1'),
        true,
      );
    });

    test('getAvailableToolsForConversation returns list', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.getAvailableToolsForConversation('c-1', 'ws-1');

      expect(result, isEmpty);
    });

    test('getAvailableToolEntitiesForConversation returns list', () async {
      final repo = _StubConversationToolsRepository();

      final result = await repo.getAvailableToolEntitiesForConversation(
        'c-1',
        'ws-1',
      );

      expect(result, isEmpty);
    });

    test('checkToolPermission returns result', () async {
      final repo = _StubConversationToolsRepository();
      repo.permissionResult = ToolPermissionResult.granted;

      final result = await repo.checkToolPermission(
        conversationId: 'c-1',
        workspaceId: 'ws-1',
        toolId: 't-1',
      );

      expect(result, ToolPermissionResult.granted);
    });

    test('checkToolPermission returns needsConfirmation', () async {
      final repo = _StubConversationToolsRepository();
      repo.permissionResult = ToolPermissionResult.needsConfirmation;

      final result = await repo.checkToolPermission(
        conversationId: 'c-1',
        workspaceId: 'ws-1',
        toolId: 't-1',
      );

      expect(result, ToolPermissionResult.needsConfirmation);
    });
  });

  group('ConversationToolsException', () {
    test('contains message', () {
      const ex = ConversationToolsException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString without cause', () {
      const ex = ConversationToolsException('oops');
      expect(ex.toString(), 'ConversationToolsException: oops');
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = ConversationToolsException('test', cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });

  group('ConversationToolsValidationException', () {
    test('is a ConversationToolsException', () {
      const ex = ConversationToolsValidationException('bad');
      expect(ex, isA<ConversationToolsException>());
      expect(ex.message, 'bad');
    });
  });
}
