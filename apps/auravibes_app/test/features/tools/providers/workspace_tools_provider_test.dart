// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: provider_dependencies
// Required: provider unit tests read scoped providers directly.

import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

WorkspaceToolEntity _tool({
  String id = 'tool-1',
  String toolId = 'calculator',
  bool isEnabled = true,
  ToolPermissionMode permissionMode = ToolPermissionMode.alwaysAsk,
  String? config,
}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: 'ws1',
    toolId: toolId,
    isEnabled: isEnabled,
    permissionMode: permissionMode,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    config: config,
  );
}

class _FakeWorkspaceToolsRepository implements WorkspaceToolsRepository {
  List<WorkspaceToolEntity> tools = [];
  List<String> removedIds = [];
  Map<String, WorkspaceToolEntity> updatedTools = {};
  bool removeResult = true;

  @override
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(
    String workspaceId,
  ) async => tools;

  @override
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  }) async {
    final tool = tools.firstWhere((t) => t.toolId == toolType);
    final updated = tool.copyWith(isEnabled: isEnabled);
    tools = tools.map((t) => t.id == tool.id ? updated : t).toList();

    return updated;
  }

  @override
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) async {
    final tool = tools.firstWhere((t) => t.id == id);
    final updated = tool.copyWith(isEnabled: isEnabled);
    updatedTools[id] = updated;

    return updated;
  }

  @override
  Future<bool> removeWorkspaceToolById(String id) async {
    removedIds.add(id);

    return removeResult;
  }

  @override
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) async {
    final tool = tools.firstWhere((t) => t.id == id);
    final updated = tool.copyWith(permissionMode: permissionMode);
    updatedTools[id] = updated;

    return updated;
  }

  @override
  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  ) async {
    final tool = tools.firstWhere((t) => t.toolId == toolType);
    final updated = tool.copyWith(config: config);
    updatedTools[tool.id] = updated;

    return [updated];
  }

  @override
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) async => tools.where((t) => t.isEnabled).toList();

  @override
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolType,
  ) async => tools.where((t) => t.toolId == toolType).firstOrNull;

  @override
  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) async => null;

  @override
  Future<bool> isWorkspaceToolEnabled(String workspaceId, String toolType) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getWorkspaceToolConfig(
    String workspaceId,
    String toolType,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeWorkspaceTool(
    String workspaceId,
    String toolType,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getWorkspaceToolsCount(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<int> getEnabledWorkspaceToolsCount(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateWorkspaceToolSetting(
    String workspaceId,
    String toolType,
  ) {
    throw UnimplementedError();
  }
}

@Dependencies([workspaceToolRow])
void main() {
  group('workspaceToolRowProvider', () {
    final fixture = _WorkspaceToolsProviderFixture(
      includeWorkspaceToolIndex: true,
    );

    setUp(fixture.setUp);

    tearDown(fixture.dispose);

    test('returns null when workspace tools is loading', () {
      final container = fixture.container;
      final result = container.read(workspaceToolRowProvider('ws1'));
      expect(result, isNull);
    });

    test('returns null when index is negative', () {
      final repository = fixture.repository;
      final container2 = ProviderContainer(
        overrides: [
          workspaceToolsRepositoryProvider.overrideWithValue(repository),
          workspaceToolIndexProvider.overrideWithValue(-1),
        ],
      );
      addTearDown(container2.dispose);

      final result = container2.read(workspaceToolRowProvider('ws1'));
      expect(result, isNull);
    });
  });

  group('WorkspaceToolsNotifier', () {
    final fixture = _WorkspaceToolsProviderFixture();

    setUp(fixture.setUp);

    tearDown(fixture.dispose);

    test('build loads workspace tools from repository', () async {
      final repository = fixture.repository;
      final container = fixture.container;
      repository.tools = [_tool(id: 't1'), _tool(id: 't2', toolId: 'search')];

      final result = await container.read(
        workspaceToolsProvider('ws1').future,
      );
      expect(result.length, 2);
      expect(result.firstOrNull?.id, 't1');
    });

    test('setToolEnabled updates tool in state', () async {
      final repository = fixture.repository;
      final container = fixture.container;
      repository.tools = [_tool(id: 't1')];

      final _ = container.listen(
        workspaceToolsProvider('ws1'),
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      final _ = await container.read(workspaceToolsProvider('ws1').future);

      await container
          .read(workspaceToolsProvider('ws1').notifier)
          .setToolEnabled('t1', isEnabled: false);

      final result = await container.read(
        workspaceToolsProvider('ws1').future,
      );
      expect(result.firstOrNull?.isEnabled, isFalse);
    });

    test('removeToolById removes tool from state', () async {
      final repository = fixture.repository;
      final container = fixture.container;
      repository.tools = [_tool(id: 't1'), _tool(id: 't2')];

      final _ = container.listen(
        workspaceToolsProvider('ws1'),
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      final _ = await container.read(workspaceToolsProvider('ws1').future);

      final success = await container
          .read(workspaceToolsProvider('ws1').notifier)
          .removeToolById('t1');

      expect(success, isTrue);
      expect(repository.removedIds, ['t1']);
    });

    test('setToolPermissionMode updates permission', () async {
      final repository = fixture.repository;
      final container = fixture.container;
      repository.tools = [_tool(id: 't1')];

      final _ = container.listen(
        workspaceToolsProvider('ws1'),
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      final _ = await container.read(workspaceToolsProvider('ws1').future);

      await container
          .read(workspaceToolsProvider('ws1').notifier)
          .setToolPermissionMode(
            't1',
            permissionMode: ToolPermissionMode.alwaysAllow,
          );

      expect(
        repository.updatedTools['t1']?.permissionMode,
        ToolPermissionMode.alwaysAllow,
      );
    });

    test('addTool enables tool and invalidates self', () async {
      final repository = fixture.repository;
      final container = fixture.container;
      repository.tools = [_tool(id: 't1', isEnabled: false)];

      final _ = container.listen(
        workspaceToolsProvider('ws1'),
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      final _ = await container.read(workspaceToolsProvider('ws1').future);

      await container
          .read(workspaceToolsProvider('ws1').notifier)
          .addTool(UserToolType.calculator);

      expect(repository.tools.first.isEnabled, isTrue);
    });

    test('updateToolConfig patches config and replaces tool', () async {
      final repository = fixture.repository;
      final container = fixture.container;
      repository.tools = [_tool(id: 't1')];

      final _ = container.listen(
        workspaceToolsProvider('ws1'),
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      final _ = await container.read(workspaceToolsProvider('ws1').future);

      await container
          .read(workspaceToolsProvider('ws1').notifier)
          .updateToolConfig('calculator', '{"key":"val"}');

      expect(repository.updatedTools['t1']?.config, '{"key":"val"}');
    });

    test('removeToolById returns false when repository fails', () async {
      final failRepo = _FakeWorkspaceToolsRepository()
        ..tools = [_tool(id: 't1')]
        ..removeResult = false;

      final failContainer = ProviderContainer(
        overrides: [
          workspaceToolsRepositoryProvider.overrideWithValue(failRepo),
        ],
      );
      addTearDown(failContainer.dispose);

      final _ = failContainer.listen(
        workspaceToolsProvider('ws1'),
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      final _ = await failContainer.read(workspaceToolsProvider('ws1').future);

      final success = await failContainer
          .read(workspaceToolsProvider('ws1').notifier)
          .removeToolById('t1');

      expect(success, isFalse);
    });
  });

  group('workspaceToolRowProvider', () {
    test('returns null when index equals list length', () {
      final repository = _FakeWorkspaceToolsRepository()
        ..tools = [_tool(id: 't1')];
      final container2 = ProviderContainer(
        overrides: [
          workspaceToolsRepositoryProvider.overrideWithValue(repository),
          workspaceToolIndexProvider.overrideWithValue(1),
        ],
      );
      addTearDown(container2.dispose);

      final result = container2.read(workspaceToolRowProvider('ws1'));
      expect(result, isNull);
    });

    test('returns tool at valid index', () async {
      final repository = _FakeWorkspaceToolsRepository()
        ..tools = [_tool(id: 't1'), _tool(id: 't2')];
      final container2 = ProviderContainer(
        overrides: [
          workspaceToolsRepositoryProvider.overrideWithValue(repository),
          workspaceToolIndexProvider.overrideWithValue(0),
        ],
      );
      addTearDown(container2.dispose);

      final _ = await container2.read(workspaceToolsProvider('ws1').future);
      final result = container2.read(workspaceToolRowProvider('ws1'));
      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).id, 't1');
    });
  });

  group('availableToolsToAddProvider', () {
    test('excludes already-added built-in tools', () async {
      final repository = _FakeWorkspaceToolsRepository()
        ..tools = [_tool(id: 't1')];
      final container = ProviderContainer(
        overrides: [
          workspaceToolsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        availableToolsToAddProvider('ws1').future,
      );
      expect(result, isEmpty);
    });

    test('includes tools not yet added', () async {
      final repository = _FakeWorkspaceToolsRepository()
        ..tools = [_tool(id: 't1', toolId: 'search')];
      final container = ProviderContainer(
        overrides: [
          workspaceToolsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        availableToolsToAddProvider('ws1').future,
      );
      expect(result, contains(UserToolType.calculator));
    });
  });
}

class _WorkspaceToolsProviderFixture {
  _WorkspaceToolsProviderFixture({
    this.includeWorkspaceToolIndex = false,
  });

  final bool includeWorkspaceToolIndex;
  _FakeWorkspaceToolsRepository? _repository;
  ProviderContainer? _container;

  _FakeWorkspaceToolsRepository get repository =>
      _repository ?? fail('Expected repository to be initialized');

  ProviderContainer get container =>
      _container ?? fail('Expected container to be initialized');

  void setUp() {
    final repository = _FakeWorkspaceToolsRepository();
    _repository = repository;
    _container = ProviderContainer(
      overrides: [
        workspaceToolsRepositoryProvider.overrideWithValue(repository),
        if (includeWorkspaceToolIndex)
          workspaceToolIndexProvider.overrideWithValue(0),
      ],
    );
  }

  void dispose() {
    _container?.dispose();
    _container = null;
    _repository = null;
  }
}
