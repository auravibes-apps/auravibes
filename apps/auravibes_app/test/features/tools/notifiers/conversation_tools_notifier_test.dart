// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('ConversationToolsNotifier', () {
    var fixture = _ConversationToolsNotifierFixture();

    final createdAt = DateTime(2026);

    final tool1 = WorkspaceToolEntity(
      id: 'tool-1',
      workspaceId: 'workspace-1',
      toolId: 'calculator',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAllow,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final tool2 = WorkspaceToolEntity(
      id: 'tool-2',
      workspaceId: 'workspace-1',
      toolId: 'web_search',
      isEnabled: false,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    setUp(() {
      fixture = _ConversationToolsNotifierFixture();
    });

    tearDown(() {
      fixture.dispose();
    });

    test(
      'overlays conversation-specific tool state on workspace defaults',
      () async {
        fixture.workspaceToolsRepository.workspaceTools = [tool1, tool2];
        fixture.conversationToolsRepository.conversationTools = [
          ConversationToolEntity(
            conversationId: 'conv-1',
            toolId: 'tool-1',
            isEnabled: false,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ];

        final result = await fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).future,
        );

        expect(result, hasLength(2));
        expect(result.firstOrNull?.tool.id, 'tool-1');
        expect(result.firstOrNull?.isEnabled, isFalse);
        expect(
          result.firstOrNull?.permissionMode,
          ToolPermissionMode.alwaysAsk,
        );
        expect(result.firstOrNull?.isWorkspaceEnabled, isTrue);
        expect(result.lastOrNull?.tool.id, 'tool-2');
        expect(result.lastOrNull?.isEnabled, isFalse);
        expect(result.lastOrNull?.isWorkspaceEnabled, isFalse);
      },
    );

    test(
      'returns workspace defaults when conversationId is missing',
      () async {
        fixture.workspaceToolsRepository.workspaceTools = [tool1];

        final result = await fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
          ).future,
        );

        expect(result.single.isEnabled, isTrue);
        expect(
          result.single.permissionMode,
          ToolPermissionMode.alwaysAllow,
        );
        expect(fixture.conversationToolsRepository.lastConversationId, isNull);
      },
    );

    test('getEnabledToolIds returns only enabled tools', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1, tool2];

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).future,
      );

      expect(notifier.getEnabledToolIds(), ['tool-1']);
    });

    test('getEnabledToolIds returns empty when state is loading', () {
      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).notifier,
      );

      expect(notifier.getEnabledToolIds(), isEmpty);
    });

    test('getToolStates returns empty list when state is loading', () {
      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).notifier,
      );

      expect(notifier.getToolStates(), isEmpty);
    });

    test('toggleTool returns false when no conversationId', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1];

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).future,
      );

      final result = await notifier.toggleTool('tool-1');
      expect(result, isFalse);
    });

    test('setToolEnabled returns false when no conversationId', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1];

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).future,
      );

      final result = await notifier.setToolEnabled(
        'tool-1',
        isEnabled: true,
      );
      expect(result, isFalse);
    });

    test('setToolPermission returns false when no conversationId', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1];

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).future,
      );

      final result = await notifier.setToolPermission(
        'tool-1',
        permissionMode: ToolPermissionMode.alwaysAllow,
      );
      expect(result, isFalse);
    });

    test(
      'setToolEnabled updates state when conversationId is set',
      () async {
        fixture.workspaceToolsRepository.workspaceTools = [tool1, tool2];
        fixture.conversationToolsRepository.setEnabledResult = true;

        final notifier = fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).notifier,
        );
        final _ = await fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).future,
        );

        final result = await notifier.setToolEnabled(
          'tool-2',
          isEnabled: true,
        );
        expect(result, isTrue);

        final state = fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ),
        );
        final tool2State =
            (state.value ?? fail('Expected state.value to be non-null'))
                .singleWhere(
                  (t) => t.tool.id == 'tool-2',
                );
        expect(tool2State.isEnabled, isTrue);
      },
    );

    test('toggleTool flips enabled state', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1];
      fixture.conversationToolsRepository.setEnabledResult = true;

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).future,
      );

      final result = await notifier.toggleTool('tool-1');
      expect(result, isTrue);

      final state = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ),
      );
      expect(
        (state.value ?? fail('Expected state.value to be non-null'))
            .first
            .isEnabled,
        isFalse,
      );
    });

    test('getToolStates returns loaded tools', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1, tool2];

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).future,
      );

      final states = notifier.getToolStates();
      expect(states, hasLength(2));
      expect(states.firstOrNull?.tool.id, 'tool-1');
    });

    test('setToolPermission updates state with conversationId', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1];
      fixture.conversationToolsRepository.setPermissionResult = true;

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).future,
      );

      final result = await notifier.setToolPermission(
        'tool-1',
        permissionMode: ToolPermissionMode.alwaysAsk,
      );
      expect(result, isTrue);

      final state = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ),
      );
      expect(
        (state.value ?? fail('Expected state.value to be non-null'))
            .first
            .permissionMode,
        ToolPermissionMode.alwaysAsk,
      );
    });

    test('toggleTool returns false for unknown tool', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1];
      fixture.conversationToolsRepository.setEnabledResult = true;

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).future,
      );

      final result = await notifier.toggleTool('unknown');
      expect(result, isFalse);
    });

    test(
      'setToolEnabled returns true but no state change for unknown tool id',
      () async {
        fixture.workspaceToolsRepository.workspaceTools = [tool1];
        fixture.conversationToolsRepository.setEnabledResult = true;

        final notifier = fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).notifier,
        );
        final _ = await fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).future,
        );

        final result = await notifier.setToolEnabled(
          'unknown',
          isEnabled: true,
        );
        expect(result, isTrue);

        final state = fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ),
        );
        expect(
          (state.value ?? fail('Expected state.value to be non-null')).length,
          1,
        );
      },
    );

    test('setToolEnabled returns false when persist fails', () async {
      fixture.workspaceToolsRepository.workspaceTools = [tool1];
      fixture.conversationToolsRepository.setEnabledResult = false;

      final notifier = fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conv-1',
        ).future,
      );

      final result = await notifier.setToolEnabled(
        'tool-1',
        isEnabled: false,
      );
      expect(result, isFalse);
    });

    test(
      'ignores conversation tool for unknown workspace tool id',
      () async {
        fixture.workspaceToolsRepository.workspaceTools = [tool1];
        fixture.conversationToolsRepository.conversationTools = [
          ConversationToolEntity(
            conversationId: 'conv-1',
            toolId: 'unknown-tool',
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ];

        final result = await fixture.container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).future,
        );

        expect(result, hasLength(1));
        expect(result.firstOrNull?.tool.id, 'tool-1');
        expect(result.firstOrNull?.isEnabled, isTrue);
      },
    );

    test(
      'conversationToolsRepositoryProvider returns impl',
      () {
        final repo = fixture.container.read(
          conversationToolsRepositoryProvider,
        );
        expect(repo, isNotNull);
      },
    );
  });

  group('ContextAwareToolsNotifier', () {
    var fixture = _ConversationToolsNotifierFixture();

    setUp(() {
      fixture = _ConversationToolsNotifierFixture();
    });

    tearDown(() {
      fixture.dispose();
    });

    test('returns available tools for conversation', () async {
      fixture.conversationToolsRepository.availableTools = ['tool-1', 'tool-2'];

      final result = await fixture.container.read(
        contextAwareToolsProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).future,
      );

      expect(result, ['tool-1', 'tool-2']);
    });

    test('refresh reloads tools', () async {
      fixture.conversationToolsRepository.availableTools = ['tool-1'];

      final notifier = fixture.container.read(
        contextAwareToolsProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        contextAwareToolsProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).future,
      );

      fixture.conversationToolsRepository.availableTools = ['tool-1', 'tool-2'];
      await notifier.refresh();

      final state = fixture.container.read(
        contextAwareToolsProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ),
      );
      expect(state.value, ['tool-1', 'tool-2']);
    });

    test('refresh handles error', () async {
      fixture.conversationToolsRepository.availableTools = ['tool-1'];

      final notifier = fixture.container.read(
        contextAwareToolsProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        contextAwareToolsProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).future,
      );

      fixture.conversationToolsRepository.availableToolsThrow = true;
      await notifier.refresh();

      final state = fixture.container.read(
        contextAwareToolsProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ),
      );
      expect(state.hasError, isTrue);
    });
  });

  group('ContextAwareToolEntitiesNotifier', () {
    var fixture = _ConversationToolsNotifierFixture();

    setUp(() {
      fixture = _ConversationToolsNotifierFixture();
    });

    tearDown(() {
      fixture.dispose();
    });

    test('returns available tool entities for conversation', () async {
      final entity = WorkspaceToolEntity(
        id: 'tool-1',
        workspaceId: 'ws-1',
        toolId: 'calculator',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAllow,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      fixture.conversationToolsRepository.availableToolEntities = [entity];

      final result = await fixture.container.read(
        contextAwareToolEntitiesProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).future,
      );

      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, 'tool-1');
    });

    test('refresh reloads entities', () async {
      final entity1 = WorkspaceToolEntity(
        id: 'tool-1',
        workspaceId: 'ws-1',
        toolId: 'calculator',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAllow,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      fixture.conversationToolsRepository.availableToolEntities = [entity1];

      final notifier = fixture.container.read(
        contextAwareToolEntitiesProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).notifier,
      );
      final _ = await fixture.container.read(
        contextAwareToolEntitiesProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ).future,
      );

      final entity2 = WorkspaceToolEntity(
        id: 'tool-2',
        workspaceId: 'ws-1',
        toolId: 'search',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAllow,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      fixture.conversationToolsRepository.availableToolEntities = [
        entity1,
        entity2,
      ];
      await notifier.refresh();

      final state = fixture.container.read(
        contextAwareToolEntitiesProvider(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        ),
      );
      expect(state.value, hasLength(2));
    });
  });
}

class _ConversationToolsNotifierFixture {
  factory _ConversationToolsNotifierFixture() {
    final conversationToolsRepository = _FakeConversationToolsRepository();
    final workspaceToolsRepository = _FakeWorkspaceToolsRepository();

    return _ConversationToolsNotifierFixture._(
      conversationToolsRepository: conversationToolsRepository,
      workspaceToolsRepository: workspaceToolsRepository,
      container: ProviderContainer(
        overrides: [
          conversationToolsRepositoryProvider.overrideWithValue(
            conversationToolsRepository,
          ),
          workspaceToolsRepositoryProvider.overrideWithValue(
            workspaceToolsRepository,
          ),
        ],
      ),
    );
  }

  const _ConversationToolsNotifierFixture._({
    required this.conversationToolsRepository,
    required this.workspaceToolsRepository,
    required this.container,
  });

  final _FakeConversationToolsRepository conversationToolsRepository;
  final _FakeWorkspaceToolsRepository workspaceToolsRepository;
  final ProviderContainer container;

  void dispose() {
    container.dispose();
  }
}

class _FakeConversationToolsRepository implements ConversationToolsRepository {
  List<ConversationToolEntity> conversationTools = const [];
  String? lastConversationId;
  bool setEnabledResult = true;
  bool setPermissionResult = true;
  List<String> availableTools = const [];
  bool availableToolsThrow = false;
  List<WorkspaceToolEntity> availableToolEntities = const [];

  @override
  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  ) async {
    lastConversationId = conversationId;

    return conversationTools;
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
  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) async {
    return setPermissionResult;
  }

  @override
  Future<ToolPermissionResult> checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    if (availableToolsThrow) {
      throw Exception('failed');
    }

    return availableTools;
  }

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    return availableToolEntities;
  }

  @override
  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getConversationToolsCount(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getEnabledConversationToolsCount(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isConversationToolEnabled(String conversationId, String toolId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeConversationTool(String conversationId, String toolId) {
    throw UnimplementedError();
  }

  @override
  Future<void> setConversationToolsDisabled(
    String conversationId,
    List<String> toolIds,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> toggleConversationTool(String conversationId, String toolId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateConversationToolSetting(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) {
    throw UnimplementedError();
  }
}

class _FakeWorkspaceToolsRepository implements WorkspaceToolsRepository {
  List<WorkspaceToolEntity> workspaceTools = const [];

  @override
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(
    String workspaceId,
  ) async {
    return workspaceTools;
  }

  @override
  Future<void> copyWorkspaceToolsToConversation(
    String workspaceId,
    String conversationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getEnabledWorkspaceToolsCount(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolType,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getWorkspaceToolConfig(String workspaceId, String toolType) {
    throw UnimplementedError();
  }

  @override
  Future<int> getWorkspaceToolsCount(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isWorkspaceToolEnabled(String workspaceId, String toolType) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeWorkspaceTool(String workspaceId, String toolType) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeWorkspaceToolById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateWorkspaceToolSetting(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
    String? config,
  }) {
    throw UnimplementedError();
  }
}
