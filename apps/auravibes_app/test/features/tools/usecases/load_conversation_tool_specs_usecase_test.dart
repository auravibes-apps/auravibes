// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

class _FakeConversationToolsRepository implements ConversationToolsRepository {
  _FakeConversationToolsRepository(this._tools);
  final List<WorkspaceToolEntity> _tools;

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async => _tools;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBuildCombinedToolSpecsUseCase extends BuildCombinedToolSpecsUseCase {
  _FakeBuildCombinedToolSpecsUseCase(this._result)
    : super(
        getToolsGroupById: (_) async => null,
        getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
      );
  final List<ToolSpec> _result;

  @override
  Future<List<ToolSpec>> call(List<WorkspaceToolEntity> enabledTools) async =>
      _result;
}

class _FakeBuildDynamicSkillToolSpecsUsecase
    extends BuildDynamicSkillToolSpecsUsecase {
  _FakeBuildDynamicSkillToolSpecsUsecase(this._result)
    : super(
        ListAvailableSkillsUsecase(
          _NeverSkillsRepository(),
          _NeverConversationSkillsRepository(),
          _NeverAppSkillSettingsRepository(),
          const AppSkillRegistry(),
        ),
      );

  final List<ToolSpec> _result;

  @override
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async => _result;
}

class _NeverSkillsRepository implements SkillsRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NeverConversationSkillsRepository
    implements ConversationSkillsRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NeverAppSkillSettingsRepository
    implements AppSkillWorkspaceSettingsRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _CapturingRepo implements ConversationToolsRepository {
  _CapturingRepo({required this.onGetTools});

  final Future<List<WorkspaceToolEntity>> Function(String, String) onGetTools;

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async => onGetTools(conversationId, workspaceId);

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('LoadConversationToolSpecsUsecase', () {
    setUpAll(registerTestFallbackValues);

    test('returns empty list when no tools', () async {
      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase([]),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );
      expect(result, isEmpty);
    });

    test(
      'calls syncSkillToolPermissionsUsecase before loading specs',
      () async {
        final syncUsecase = MockSyncSkillToolPermissionsUsecase();
        when(
          () => syncUsecase.call(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
          ),
        ).thenAnswer((_) => Future<void>.value());
        final usecase = LoadConversationToolSpecsUsecase(
          conversationToolsRepository: _FakeConversationToolsRepository([]),
          buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
          buildDynamicSkillToolSpecsUsecase:
              _FakeBuildDynamicSkillToolSpecsUsecase([]),
          syncSkillToolPermissionsUsecase: syncUsecase,
        );

        final result = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        );

        expect(result, isEmpty);
        verify(
          () => syncUsecase.call(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
          ),
        ).called(1);
      },
    );

    test('returns tool specs from build combined usecase', () async {
      final specs = [
        const ToolSpec(
          name: 'tool-1',
          description: 'desc',
          inputJsonSchema: {},
        ),
      ];

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase(
          specs,
        ),
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase([]),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );
      expect(result, hasLength(1));
      expect(result.firstOrNull?.name, 'tool-1');
    });

    test('passes correct conversationId and workspaceId', () async {
      String? capturedConvId;
      String? capturedWsId;

      final repo = _CapturingRepo(
        onGetTools: (convId, wsId) async {
          capturedConvId = convId;
          capturedWsId = wsId;

          return <WorkspaceToolEntity>[];
        },
      );

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: repo,
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase([]),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );

      final _ = await usecase(
        conversationId: 'conv-abc',
        workspaceId: 'ws-xyz',
      );

      expect(capturedConvId, 'conv-abc');
      expect(capturedWsId, 'ws-xyz');
    });

    test('returns multiple tool specs', () async {
      final specs = [
        const ToolSpec(name: 't1', description: 'd1', inputJsonSchema: {}),
        const ToolSpec(name: 't2', description: 'd2', inputJsonSchema: {}),
        const ToolSpec(name: 't3', description: 'd3', inputJsonSchema: {}),
      ];

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase(
          specs,
        ),
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase([]),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );
      expect(result, hasLength(3));
    });

    test('constructor stores dependencies', () {
      final repo = _FakeConversationToolsRepository([]);
      final buildUseCase = _FakeBuildCombinedToolSpecsUseCase([]);
      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: repo,
        buildCombinedToolSpecsUseCase: buildUseCase,
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase([]),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );
      expect(
        usecase,
        isA<LoadConversationToolSpecsUsecase>(),
      );
    });

    test('passes tools from repo to build usecase', () async {
      final tools = [
        WorkspaceToolEntity(
          id: 'w1',
          workspaceId: 'ws-1',
          toolId: 'tool1',
          isEnabled: true,
          permissionMode: ToolPermissionMode.alwaysAllow,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];

      List<WorkspaceToolEntity>? capturedTools;
      final buildUseCase = _CapturingBuildCombined(
        onCall: (t) async {
          capturedTools = t;

          return [];
        },
      );

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository(tools),
        buildCombinedToolSpecsUseCase: buildUseCase,
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase([]),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );

      final _ = await usecase(conversationId: 'conv-1', workspaceId: 'ws-1');

      expect(capturedTools, isNotNull);
      expect(
        (capturedTools ?? fail('Expected capturedTools to be non-null')).length,
        1,
      );
      expect(
        (capturedTools ?? fail('Expected capturedTools to be non-null'))
            .first
            .toolId,
        'tool1',
      );
    });

    test('appends dynamic skill tool specs', () async {
      final skillSpecs = [
        const ToolSpec(
          name: loadSkillToolName,
          description: 'load skill',
          inputJsonSchema: {},
        ),
        const ToolSpec(
          name: unloadSkillToolName,
          description: 'unload skill',
          inputJsonSchema: {},
        ),
      ];

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([
          WorkspaceToolEntity(
            id: 'load-tool-id',
            workspaceId: 'ws-1',
            toolId: loadSkillToolName,
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            workspaceToolsGroupId: 'skills-group',
          ),
          WorkspaceToolEntity(
            id: 'unload-tool-id',
            workspaceId: 'ws-1',
            toolId: unloadSkillToolName,
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            workspaceToolsGroupId: 'skills-group',
          ),
        ]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase(skillSpecs),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );

      expect(result.map((spec) => spec.name), [
        loadSkillToolName,
        unloadSkillToolName,
      ]);
    });

    test('keeps dynamic skill control specs available for the agent', () async {
      final skillSpecs = [
        const ToolSpec(
          name: loadSkillToolName,
          description: 'load skill',
          inputJsonSchema: {},
        ),
        const ToolSpec(
          name: unloadSkillToolName,
          description: 'unload skill',
          inputJsonSchema: {},
        ),
        const ToolSpec(
          name: listSkillCredentialsToolName,
          description: 'list credentials',
          inputJsonSchema: {},
        ),
      ];

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
        buildDynamicSkillToolSpecsUsecase:
            _FakeBuildDynamicSkillToolSpecsUsecase(skillSpecs),
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );

      expect(result.map((spec) => spec.name), [
        loadSkillToolName,
        unloadSkillToolName,
        listSkillCredentialsToolName,
      ]);
    });
  });
}

class _CapturingBuildCombined extends BuildCombinedToolSpecsUseCase {
  _CapturingBuildCombined({required this.onCall})
    : super(
        getToolsGroupById: (_) async => null,
        getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
      );

  final Future<List<ToolSpec>> Function(List<WorkspaceToolEntity>) onCall;

  @override
  Future<List<ToolSpec>> call(List<WorkspaceToolEntity> tools) => onCall(tools);
}
