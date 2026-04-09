import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_controller.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/providers/mcp_connection_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('GroupedToolsController', () {
    late _FakeToolsGroupsRepository toolsGroupsRepository;
    late _FakeSelectedWorkspace selectedWorkspace;
    late _FakeWorkspaceToolsNotifier workspaceToolsNotifier;
    late _FakeMcpConnectionController mcpController;
    late ProviderContainer container;

    setUp(() {
      toolsGroupsRepository = _FakeToolsGroupsRepository();
      selectedWorkspace = _FakeSelectedWorkspace(_workspace);
      workspaceToolsNotifier = _FakeWorkspaceToolsNotifier(const []);
      mcpController = _FakeMcpConnectionController();

      container = ProviderContainer(
        overrides: [
          toolsGroupsRepositoryProvider.overrideWithValue(
            toolsGroupsRepository,
          ),
          selectedWorkspaceProvider.overrideWith(() => selectedWorkspace),
          workspaceToolsProvider.overrideWith(() => workspaceToolsNotifier),
          mcpConnectionControllerProvider.overrideWith(() => mcpController),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'setMcpGroupEnabled disconnects even when controller state is loading',
      () async {
        toolsGroupsRepository.groupById['group-1'] = _mcpGroup;

        final notifier = container.read(groupedToolsControllerProvider.notifier)
          ..state = const AsyncLoading();

        await notifier.setMcpGroupEnabled('group-1', isEnabled: false);

        expect(toolsGroupsRepository.lastSetGroupId, 'group-1');
        expect(toolsGroupsRepository.lastIsEnabled, isFalse);
        expect(mcpController.disconnectedServerIds, ['server-1']);
      },
    );

    test(
      'deleteMcpGroup deletes by repository lookup when controller state is '
      'loading',
      () async {
        toolsGroupsRepository.groupById['group-1'] = _mcpGroup;

        final notifier = container.read(groupedToolsControllerProvider.notifier)
          ..state = const AsyncLoading();

        await notifier.deleteMcpGroup('group-1');

        expect(mcpController.deletedServerIds, ['server-1']);
      },
    );
  });
}

final _workspace = WorkspaceEntity(
  id: 'workspace-1',
  name: 'Workspace',
  type: WorkspaceType.local,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _mcpGroup = ToolsGroupEntity(
  id: 'group-1',
  workspaceId: 'workspace-1',
  name: 'Group',
  isEnabled: true,
  permissions: PermissionAccess.ask,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  mcpServerId: 'server-1',
);

class _FakeSelectedWorkspace extends SelectedWorkspace {
  _FakeSelectedWorkspace(this.workspace);

  final WorkspaceEntity workspace;

  @override
  Future<WorkspaceEntity> build() async => workspace;
}

class _FakeWorkspaceToolsNotifier extends WorkspaceToolsNotifier {
  _FakeWorkspaceToolsNotifier(this.tools);

  final List<WorkspaceToolEntity> tools;

  @override
  Future<List<WorkspaceToolEntity>> build() async => tools;
}

class _FakeMcpConnectionController extends McpConnectionController {
  final List<String> disconnectedServerIds = [];
  final List<String> reconnectedServerIds = [];
  final List<String> deletedServerIds = [];

  @override
  List<McpConnectionState> build() => const [];

  @override
  void disconnectMcpServer(String serverId) {
    disconnectedServerIds.add(serverId);
  }

  @override
  Future<void> reconnectMcpServer(String serverId) async {
    reconnectedServerIds.add(serverId);
  }

  @override
  Future<void> deleteMcpServer(String serverId) async {
    deletedServerIds.add(serverId);
  }
}

class _FakeToolsGroupsRepository implements ToolsGroupsRepository {
  final Map<String, ToolsGroupEntity> groupById = {};
  String? lastSetGroupId;
  bool? lastIsEnabled;

  @override
  Future<ToolsGroupEntity?> getToolsGroupById(String id) async => groupById[id];

  @override
  Future<bool> setToolsGroupEnabled(
    String groupId, {
    required bool isEnabled,
  }) async {
    lastSetGroupId = groupId;
    lastIsEnabled = isEnabled;
    return true;
  }

  @override
  Future<bool> deleteToolsGroup(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(
    String workspaceId,
  ) async {
    return groupById.values.toList();
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(String mcpServerId) {
    throw UnimplementedError();
  }
}
