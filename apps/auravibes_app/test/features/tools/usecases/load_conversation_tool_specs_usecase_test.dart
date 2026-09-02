// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

class _FakeConversationToolsRepository(final List<WorkspaceToolEntity> _tools)
    implements ConversationToolsRepository {
  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async => _tools;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBuildCombinedToolSpecsUseCase.candidates(
  final List<ToolCatalogCandidate<ResolvedTool>> _result,
) extends BuildCombinedToolSpecsUseCase {
  new(List<ToolSpec> specs)
    : this.candidates([
        for (final spec in specs)
          ToolCatalogCandidate.reserved(
            spec: spec,
            target: ResolvedTool.skillControl(toolIdentifier: spec.name),
          ),
      ]);

  this
    : super(
        getToolsGroupById: (_) async => null,
        getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
      );

  @override
  Future<List<ToolCatalogCandidate<ResolvedTool>>> call(
    List<WorkspaceToolEntity> enabledTools,
  ) async => _result;
}

class _FakeBuildDynamicSkillToolSpecsUsecase(final List<ToolSpec> _result)
    extends BuildDynamicSkillToolSpecsUsecase {
  this
    : super(
        (_) => ListAvailableSkillsUsecase(
          _NeverSkillsRepository(),
          _NeverConversationSkillsRepository(),
          _NeverAppSkillSettingsRepository(),
          const AppSkillRegistry(),
        ),
        const AppSkillRegistry(),
        const _NoAppSkillCandidates(),
      );

  @override
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async => _result;
}

class _FakeBuildSkillTemplateToolSpecsUsecase
    implements BuildSkillTemplateToolSpecsUsecase {
  List<ToolSpec> result = const [];

  @override
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => result;
}

class _FakeBuildAppSkillNativeToolSpecsUsecase
    implements BuildAppSkillNativeToolSpecsUsecase {
  List<ToolSpec> result = const [];

  @override
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => result;
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

class const _NoAppSkillCandidates()
    implements ListAppSkillCredentialCandidatesUsecase {
  @override
  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    return const [];
  }

  @override
  bool isCredentialRequired(AppSkillDefinition skill) => false;

  @override
  Future<bool> hasUsableNativeTool({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    return true;
  }
}

class _CapturingRepo({
  required final Future<List<WorkspaceToolEntity>> Function(String, String)
  onGetTools,
}) implements ConversationToolsRepository {
  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) => onGetTools(conversationId, workspaceId);

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('LoadConversationToolSpecsUsecase', () {
    setUpAll(registerTestFallbackValues);

    test('returns always-on run_sub_agent when no tools', () async {
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
      expect(result.map((spec) => spec.name), [runSubAgentToolName]);
    });

    test(
      'calls syncSkillToolPermissionsUsecase before loading specs',
      () async {
        final syncUsecase = MockSyncSkillToolPermissionsUsecase();
        when(
          () => syncUsecase.call(conversationId: 'conv-1', workspaceId: 'ws-1'),
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

        expect(result.map((spec) => spec.name), [runSubAgentToolName]);
        verify(
          () => syncUsecase.call(conversationId: 'conv-1', workspaceId: 'ws-1'),
        ).called(1);
      },
    );

    test('returns tool specs from build combined usecase', () async {
      final specs = [
        ToolSpec(name: 'tool-1', description: 'desc', inputJsonSchema: {}),
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
      expect(result, hasLength(2));
      expect(result.firstOrNull?.name, 'tool-1');
    });

    test(
      'keeps colliding tools from every source exactly addressable',
      () async {
        ToolCatalogCandidate<ResolvedTool> external(
          String name,
          String sourceId,
          ResolvedTool target,
        ) => ToolCatalogCandidate.external(
          spec: ToolSpec(
            name: name,
            description: name,
            inputJsonSchema: const {},
          ),
          target: target,
          sourceId: sourceId,
        );

        final calculatorA = ResolvedTool.builtIn(
          tableId: 'calculator-row-a',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        );
        final calculatorB = ResolvedTool.builtIn(
          tableId: 'calculator-row-b',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        );
        final githubSearch = ResolvedTool.mcp(
          tableId: 'github-search-row',
          toolIdentifier: 'search',
          mcpServerId: 'github-server',
          mcpSlug: 'github',
        );
        final linearSearch = ResolvedTool.mcp(
          tableId: 'linear-search-row',
          toolIdentifier: 'search',
          mcpServerId: 'linear-server',
          mcpSlug: 'linear',
        );
        final usecase = LoadConversationToolSpecsUsecase(
          conversationToolsRepository: _FakeConversationToolsRepository([]),
          buildCombinedToolSpecsUseCase:
              _FakeBuildCombinedToolSpecsUseCase.candidates([
                external('calculator', 'user:calculator-row-a', calculatorA),
                external('calculator', 'user:calculator-row-b', calculatorB),
                external(
                  'mcp_search',
                  'mcp:github-server:github-search-row:search',
                  githubSearch,
                ),
                external(
                  'mcp_search',
                  'mcp:linear-server:linear-search-row:search',
                  linearSearch,
                ),
              ]),
          buildDynamicSkillToolSpecsUsecase:
              _FakeBuildDynamicSkillToolSpecsUsecase(
                buildSkillCommandToolSpecs(),
              ),
          syncSkillToolPermissionsUsecase:
              NoopSyncSkillToolPermissionsUsecase(),
        );

        final catalog = await usecase.buildCatalog(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
        );
        final names = catalog.specs.map((spec) => spec.name).toList();
        final githubSearchSuffix = stableExternalToolNameSuffix(
          'mcp:github-server:github-search-row:search',
          'mcp_search',
        );
        final linearSearchSuffix = stableExternalToolNameSuffix(
          'mcp:linear-server:linear-search-row:search',
          'mcp_search',
        );
        final calculatorASuffix = stableExternalToolNameSuffix(
          'user:calculator-row-a',
          'calculator',
        );
        final calculatorBSuffix = stableExternalToolNameSuffix(
          'user:calculator-row-b',
          'calculator',
        );
        final externalTargets = {
          'calculator_$calculatorASuffix': calculatorA,
          'calculator_$calculatorBSuffix': calculatorB,
          'mcp_search_$githubSearchSuffix': githubSearch,
          'mcp_search_$linearSearchSuffix': linearSearch,
        };

        expect(
          names,
          containsAll({...skillCommandToolNames, runSubAgentToolName}),
        );
        expect(names, containsAll(externalTargets.keys));
        expect(names.toSet(), hasLength(catalog.specs.length));
        final providerToolName = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
        for (final name in names) {
          expect(providerToolName.hasMatch(name), isTrue, reason: name);
          expect(name.length, lessThanOrEqualTo(64), reason: name);
        }
        for (final entry in externalTargets.entries) {
          expect(catalog.resolve(entry.key), same(entry.value));
        }
        expect(names, isNot(contains('skill__user__github__create_issue')));
        expect(names.any((name) => name.startsWith('skill__')), isFalse);
        expect(
          names.where(skillCommandToolNames.contains).toSet(),
          skillCommandToolNames,
        );
        for (final name in skillCommandToolNames) {
          final target = catalog.resolve(name);
          expect(target?.isSkillCommand, isTrue);
          expect(target?.toolIdentifier, name);
        }
        final subAgentTarget = catalog.resolve(runSubAgentToolName);
        expect(subAgentTarget?.isSkillNative, isTrue);
        expect(subAgentTarget?.skillSlug, agentsSkillSlug);
        expect(subAgentTarget?.toolIdentifier, runSubAgentToolName);
      },
    );

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
        ToolSpec(name: 't1', description: 'd1', inputJsonSchema: {}),
        ToolSpec(name: 't2', description: 'd2', inputJsonSchema: {}),
        ToolSpec(name: 't3', description: 'd3', inputJsonSchema: {}),
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
      expect(result, hasLength(4));
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
      expect(usecase, isA<LoadConversationToolSpecsUsecase>());
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
        ToolSpec(
          name: loadSkillToolName,
          description: 'load skill',
          inputJsonSchema: {},
        ),
        ToolSpec(
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
        runSubAgentToolName,
      ]);
    });

    test('skill load state does not change provider tool schemas', () async {
      final dynamicSkillSpecs = _FakeBuildDynamicSkillToolSpecsUsecase(
        buildSkillCommandToolSpecs(),
      );
      final templateSkillSpecs = _FakeBuildSkillTemplateToolSpecsUsecase();
      final nativeSkillSpecs = _FakeBuildAppSkillNativeToolSpecsUsecase();
      final researchSearchSpec = ToolSpec(
        name: 'skill__user__research__search',
        description: 'Search primary sources.',
        inputJsonSchema: const {'type': 'object'},
      );
      final researchFetchSpec = ToolSpec(
        name: 'skill__user__research__fetch',
        description: 'Fetch a primary source.',
        inputJsonSchema: const {'type': 'object'},
      );
      final braveSearchSpec = ToolSpec(
        name: 'skill__app__brave__search',
        description: 'Search with Brave.',
        inputJsonSchema: const {'type': 'object'},
      );
      templateSkillSpecs.result = [researchSearchSpec];
      nativeSkillSpecs.result = [braveSearchSpec];
      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([
          for (final name in [
            researchSearchSpec.name,
            researchFetchSpec.name,
            braveSearchSpec.name,
          ])
            WorkspaceToolEntity(
              id: name,
              workspaceId: 'workspace-1',
              toolId: name,
              isEnabled: true,
              permissionMode: ToolPermissionMode.alwaysAsk,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
        ]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
        buildDynamicSkillToolSpecsUsecase: dynamicSkillSpecs,
        syncSkillToolPermissionsUsecase: NoopSyncSkillToolPermissionsUsecase(),
        buildSkillTemplateToolSpecsUsecase: templateSkillSpecs,
        buildAppSkillNativeToolSpecsUsecase: nativeSkillSpecs,
      );

      final first = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      templateSkillSpecs.result = [researchSearchSpec, researchFetchSpec];
      nativeSkillSpecs.result = const [];

      final second = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(first, second);
      expect(first.map((spec) => spec.name), contains(callSkillToolName));
      expect(first.any((spec) => spec.name.startsWith('skill__')), isFalse);
    });

    test('keeps dynamic skill control specs available for the agent', () async {
      final skillSpecs = [
        ToolSpec(
          name: loadSkillToolName,
          description: 'load skill',
          inputJsonSchema: {},
        ),
        ToolSpec(
          name: unloadSkillToolName,
          description: 'unload skill',
          inputJsonSchema: {},
        ),
        ToolSpec(
          name: SkillToolNames.listCredentials,
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
        SkillToolNames.listCredentials,
        runSubAgentToolName,
      ]);
    });
  });
}

class _CapturingBuildCombined({
  required final Future<List<ToolCatalogCandidate<ResolvedTool>>> Function(
    List<WorkspaceToolEntity>,
  )
  onCall,
}) extends BuildCombinedToolSpecsUseCase {
  this
    : super(
        getToolsGroupById: (_) async => null,
        getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
      );

  @override
  Future<List<ToolCatalogCandidate<ResolvedTool>>> call(
    List<WorkspaceToolEntity> tools,
  ) => onCall(tools);
}
