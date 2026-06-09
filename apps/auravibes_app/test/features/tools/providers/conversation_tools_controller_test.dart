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
    var conversationToolsRepository = _FakeConversationToolsRepository();
    var workspaceToolsRepository = _FakeWorkspaceToolsRepository();
    var container = ProviderContainer(
      overrides: [
        conversationToolsRepositoryProvider.overrideWithValue(
          conversationToolsRepository,
        ),
        workspaceToolsRepositoryProvider.overrideWithValue(
          workspaceToolsRepository,
        ),
      ],
    );

    setUp(() {
      conversationToolsRepository = _FakeConversationToolsRepository();
      workspaceToolsRepository = _FakeWorkspaceToolsRepository();
      container = ProviderContainer(
        overrides: [
          conversationToolsRepositoryProvider.overrideWithValue(
            conversationToolsRepository,
          ),
          workspaceToolsRepositoryProvider.overrideWithValue(
            workspaceToolsRepository,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'overlays conversation-specific tool state on workspace defaults',
      () async {
        final createdAt = DateTime(2026);
        workspaceToolsRepository.workspaceTools = [
          WorkspaceToolEntity(
            id: 'tool-1',
            workspaceId: 'workspace-1',
            toolId: 'calculator',
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
          WorkspaceToolEntity(
            id: 'tool-2',
            workspaceId: 'workspace-1',
            toolId: 'web_search',
            isEnabled: false,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ];
        conversationToolsRepository.conversationTools = [
          ConversationToolEntity(
            conversationId: 'conversation-1',
            toolId: 'tool-1',
            isEnabled: false,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ];

        final result = await container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conversation-1',
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
        expect(result.last.tool.id, 'tool-2');
        expect(result.last.isEnabled, isFalse);
        expect(result.last.permissionMode, ToolPermissionMode.alwaysAsk);
        expect(
          conversationToolsRepository.lastConversationId,
          'conversation-1',
        );
      },
    );

    test('returns workspace defaults when conversationId is missing', () async {
      final createdAt = DateTime(2026);
      workspaceToolsRepository.workspaceTools = [
        WorkspaceToolEntity(
          id: 'tool-1',
          workspaceId: 'workspace-1',
          toolId: 'calculator',
          isEnabled: true,
          permissionMode: ToolPermissionMode.alwaysAllow,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ];

      final result = await container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
        ).future,
      );

      expect(result.single.isEnabled, isTrue);
      expect(result.single.permissionMode, ToolPermissionMode.alwaysAllow);
      expect(conversationToolsRepository.lastConversationId, isNull);
    });

    test('returns empty list when no workspace tools exist', () async {
      workspaceToolsRepository.workspaceTools = [];

      final result = await container.read(
        conversationToolsProvider(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
        ).future,
      );

      expect(result, isEmpty);
    });

    test(
      'uses workspace tool isWorkspaceEnabled from workspace tool state',
      () async {
        final createdAt = DateTime(2026);
        workspaceToolsRepository.workspaceTools = [
          WorkspaceToolEntity(
            id: 'tool-1',
            workspaceId: 'workspace-1',
            toolId: 'calculator',
            isEnabled: false,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ];

        final result = await container.read(
          conversationToolsProvider(
            workspaceId: 'workspace-1',
          ).future,
        );

        expect(result.single.isWorkspaceEnabled, isFalse);
      },
    );
  });
}

class _FakeConversationToolsRepository implements ConversationToolsRepository {
  List<ConversationToolEntity> conversationTools = const [];
  String? lastConversationId;

  @override
  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  ) async {
    lastConversationId = conversationId;

    return conversationTools;
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
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) {
    throw UnimplementedError();
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
  Future<bool> setConversationToolEnabled(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) {
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
