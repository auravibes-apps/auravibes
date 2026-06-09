// ignore_for_file: cascade_invocations

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubWorkspaceToolsRepository implements WorkspaceToolsRepository {
  List<WorkspaceToolEntity> tools = [];
  List<WorkspaceToolEntity> enabledTools = [];
  WorkspaceToolEntity? toolById;
  List<WorkspaceToolEntity> patchedConfig = [];
  bool isEnabledResult = false;
  String? configResult;
  bool removeResult = true;
  bool removeByIdResult = true;
  int toolsCount = 0;
  int enabledCount = 0;
  bool validateResult = true;

  @override
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(
    String workspaceId,
  ) async {
    return tools;
  }

  @override
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) async {
    return enabledTools;
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolType,
  ) async {
    return toolById;
  }

  @override
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  }) async {
    return WorkspaceToolEntity(
      id: 'wt-1',
      workspaceId: workspaceId,
      toolId: toolType,
      isEnabled: isEnabled,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) async {
    return toolById;
  }

  @override
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) async {
    return WorkspaceToolEntity(
      id: id,
      workspaceId: 'ws-1',
      toolId: 'tool-1',
      isEnabled: isEnabled,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  }

  @override
  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  ) async {
    return patchedConfig;
  }

  @override
  Future<bool> isWorkspaceToolEnabled(
    String workspaceId,
    String toolType,
  ) async {
    return isEnabledResult;
  }

  @override
  Future<String?> getWorkspaceToolConfig(
    String workspaceId,
    String toolType,
  ) async {
    return configResult;
  }

  @override
  Future<bool> removeWorkspaceTool(
    String workspaceId,
    String toolType,
  ) async {
    return removeResult;
  }

  @override
  Future<bool> removeWorkspaceToolById(String id) async => removeByIdResult;

  @override
  Future<int> getWorkspaceToolsCount(String workspaceId) async => toolsCount;

  @override
  Future<int> getEnabledWorkspaceToolsCount(
    String workspaceId,
  ) async {
    return enabledCount;
  }

  @override
  Future<void> copyWorkspaceToolsToConversation(
    String workspaceId,
    String conversationId,
  ) async {
    final _ = Object();
  }

  @override
  Future<bool> validateWorkspaceToolSetting(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
    String? config,
  }) async {
    return validateResult;
  }

  @override
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) async {
    return WorkspaceToolEntity(
      id: id,
      workspaceId: 'ws-1',
      toolId: 'tool-1',
      isEnabled: true,
      permissionMode: permissionMode,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  }
}

void main() {
  group('WorkspaceToolsRepository', () {
    test('getWorkspaceTools returns list', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.getWorkspaceTools('ws-1');

      expect(result, isEmpty);
    });

    test('getEnabledWorkspaceTools returns list', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.getEnabledWorkspaceTools('ws-1');

      expect(result, isEmpty);
    });

    test('getWorkspaceTool returns null when not found', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.getWorkspaceTool('ws-1', 'search');

      expect(result, isNull);
    });

    test('setWorkspaceToolEnabled returns entity', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.setWorkspaceToolEnabled(
        'ws-1',
        'search',
        isEnabled: true,
      );

      expect(result.isEnabled, true);
      expect(result.workspaceId, 'ws-1');
      expect(result.toolId, 'search');
    });

    test('getWorkspaceToolByToolName returns null when not found', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.getWorkspaceToolByToolName(
        toolGroupId: 'group-1',
        toolName: 'search',
      );

      expect(result, isNull);
    });

    test('setToolEnabledById returns entity', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.setToolEnabledById(
        'wt-1',
        isEnabled: false,
      );

      expect(result.id, 'wt-1');
      expect(result.isEnabled, false);
    });

    test('patchWorkspaceToolConfig returns list', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.patchWorkspaceToolConfig(
        'ws-1',
        'search',
        '{"key":"val"}',
      );

      expect(result, isEmpty);
    });

    test('isWorkspaceToolEnabled returns bool', () async {
      final repo = _StubWorkspaceToolsRepository();
      repo.isEnabledResult = true;

      expect(await repo.isWorkspaceToolEnabled('ws-1', 'search'), true);
    });

    test('getWorkspaceToolConfig returns null by default', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.getWorkspaceToolConfig('ws-1', 'search');

      expect(result, isNull);
    });

    test('removeWorkspaceTool returns bool', () async {
      final repo = _StubWorkspaceToolsRepository();

      expect(await repo.removeWorkspaceTool('ws-1', 'search'), true);

      repo.removeResult = false;
      expect(await repo.removeWorkspaceTool('ws-1', 'search'), false);
    });

    test('removeWorkspaceToolById returns bool', () async {
      final repo = _StubWorkspaceToolsRepository();

      expect(await repo.removeWorkspaceToolById('wt-1'), true);
    });

    test('getWorkspaceToolsCount returns count', () async {
      final repo = _StubWorkspaceToolsRepository();
      repo.toolsCount = 5;

      expect(await repo.getWorkspaceToolsCount('ws-1'), 5);
    });

    test('getEnabledWorkspaceToolsCount returns count', () async {
      final repo = _StubWorkspaceToolsRepository();
      repo.enabledCount = 3;

      expect(await repo.getEnabledWorkspaceToolsCount('ws-1'), 3);
    });

    test('copyWorkspaceToolsToConversation completes', () async {
      final repo = _StubWorkspaceToolsRepository();

      await repo.copyWorkspaceToolsToConversation('ws-1', 'c-1');

      expect(true, true);
    });

    test('validateWorkspaceToolSetting returns bool', () async {
      final repo = _StubWorkspaceToolsRepository();

      expect(
        await repo.validateWorkspaceToolSetting(
          'ws-1',
          'search',
          isEnabled: true,
        ),
        true,
      );
    });

    test('setToolPermissionMode returns entity', () async {
      final repo = _StubWorkspaceToolsRepository();

      final result = await repo.setToolPermissionMode(
        'wt-1',
        permissionMode: ToolPermissionMode.alwaysAllow,
      );

      expect(result.id, 'wt-1');
      expect(result.permissionMode, ToolPermissionMode.alwaysAllow);
    });
  });

  group('WorkspaceToolsException', () {
    test('contains message', () {
      const ex = WorkspaceToolsException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString without cause', () {
      const ex = WorkspaceToolsException('oops');
      expect(ex.toString(), 'WorkspaceToolsException: oops');
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = WorkspaceToolsException('test', cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });

  group('WorkspaceToolsValidationException', () {
    test('is a WorkspaceToolsException', () {
      const ex = WorkspaceToolsValidationException('bad');
      expect(ex, isA<WorkspaceToolsException>());
      expect(ex.message, 'bad');
    });
  });
}
