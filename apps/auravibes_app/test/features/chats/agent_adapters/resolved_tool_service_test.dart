// Required: Existing test and UI helpers keep compact return flow.

import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_app_skill_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skills_manager_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../../../test_mocks.dart';

class _MockLoadConversationSkillUsecase extends Mock
    implements LoadConversationSkillUsecase;

class _MockUnloadConversationSkillUsecase extends Mock
    implements UnloadConversationSkillUsecase;

class _MockRunSkillTemplateToolUsecase extends Mock
    implements RunSkillTemplateToolUsecase;

class _MockRunAppSkillToolUsecase extends Mock
    implements RunAppSkillToolUsecase;

class _MockRunSkillsManagerToolUsecase extends Mock
    implements RunSkillsManagerToolUsecase;

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase;

class _MockListAppSkillCandidatesUsecase extends Mock
    implements ListAppSkillCredentialCandidatesUsecase;

class _MockSkillCredentialsRepository extends Mock
    implements SkillCredentialsRepository;

class _MockBuildAppSkillNativeToolSpecsUsecase extends Mock
    implements BuildAppSkillNativeToolSpecsUsecase;

class _MockBuildLoadedSkillManifestsUsecase extends Mock
    implements BuildLoadedSkillManifestsUsecase;

class _MockBuildSkillTemplateToolSpecsUsecase extends Mock
    implements BuildSkillTemplateToolSpecsUsecase;

class _FakeSubAgentCatalog implements SubAgentCatalog {
  @override
  Future<SubAgentCatalogEntry?> getSubAgent(String agentId) async => null;

  @override
  Future<SubAgentCatalogPage> listSubAgents(SubAgentCatalogQuery query) async =>
      const SubAgentCatalogPage(
        agents: [
          SubAgentCatalogEntry(
            id: 'agent-1',
            workspaceId: 'workspace-1',
            name: 'Agent',
            description: 'Description',
            types: ['sub_agent'],
          ),
        ],
      );
}

class _FakeSubAgentConversationStore implements SubAgentConversationStore {
  @override
  Future<SubAgentConversationRecord?> getConversation(
    String conversationId,
  ) async => const SubAgentConversationRecord(
    id: 'parent-1',
    workspaceId: 'workspace-1',
    modelId: 'model-1',
    parentConversationId: null,
  );

  @override
  Future<SubAgentConversationRecord> createChildConversation(
    SubAgentChildConversationRequest request,
  ) async => const SubAgentConversationRecord(
    id: 'child-1',
    workspaceId: 'workspace-1',
    modelId: 'model-1',
    parentConversationId: 'parent-1',
  );
}

class _FakeSubAgentMessageStore implements SubAgentMessageStore {
  @override
  Future<SubAgentMessageRecord> createUserPrompt({
    required String conversationId,
    required String prompt,
  }) async => const SubAgentMessageRecord(id: 'message-1');

  @override
  Future<String> latestAssistantContent(String conversationId) async => '';
}

class _FakeSubAgentRequestHandle implements SubAgentRequestHandle {
  @override
  Future<SubAgentCompletionStatus> get completion =>
      Future.value(SubAgentCompletionStatus.done);

  @override
  bool get isStopped => false;

  @override
  void finish([
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  ]) {
    if (status != SubAgentCompletionStatus.done) return;
  }
}

SubAgentRunner _subAgentRunner() {
  return SubAgentRunner(
    agentCatalog: _FakeSubAgentCatalog(),
    conversationStore: _FakeSubAgentConversationStore(),
    messageStore: _FakeSubAgentMessageStore(),
    startRequest: ({required parentId, required childId}) =>
        _FakeSubAgentRequestHandle(),
    continueAgentTurn: ({required conversationId, required context}) async =>
        AgentIterationDecision.done,
  );
}

AvailableSkill _appAvailableSkill(String slug) {
  return AvailableSkill(
    source: SkillSource.app,
    id: slug,
    slug: slug,
    title: slug,
    description: '',
    content: '',
    kind: .native,
  );
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  var cancellationRuntime = AgentCancellationRuntime();
  var mcpCalls = <({String serverId, String toolIdentifier})>[];
  var usecase = ResolvedToolService(
    agentCancellationRuntime: cancellationRuntime,
    mcpToolCaller:
        ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
        }) async {
          mcpCalls.add((serverId: mcpServerId, toolIdentifier: toolIdentifier));

          return 'mcp result';
        },
  );

  setUp(() {
    cancellationRuntime = AgentCancellationRuntime();
    mcpCalls = [];
    usecase = ResolvedToolService(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) async {
            mcpCalls.add((
              serverId: mcpServerId,
              toolIdentifier: toolIdentifier,
            ));

            return 'mcp result';
          },
    );
  });

  test('runs built-in calculator tools', () async {
    final result = await usecase(
      conversationId: 'conversation-1',
      tool: ResolvedTool.builtIn(
        tableId: 'tool-1',
        toolIdentifier: 'calculator',
        tooltype: .calculator,
      ),
      arguments: {'input': '2 + 3'},
    );

    expect(result, '5.0');
  });

  test('rejects built-in tools without input', () {
    expect(
      () => usecase(
        conversationId: 'conversation-1',
        tool: ResolvedTool.builtIn(
          tableId: 'tool-1',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        arguments: {},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects native tools without input', () {
    expect(
      () => usecase(
        conversationId: 'conversation-1',
        tool: ResolvedTool.native(tableId: 'tool-1', nativeToolType: .url),
        arguments: {},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('runs MCP tools through the injected caller', () async {
    final result = await usecase(
      conversationId: 'conversation-1',
      tool: ResolvedTool.mcp(
        tableId: 'tool-1',
        toolIdentifier: 'remote-tool',
        mcpServerId: 'server-1',
        mcpSlug: 'server-1',
      ),
      arguments: {'value': 1},
    );

    expect(result, 'mcp result');
    expect(mcpCalls, [(serverId: 'server-1', toolIdentifier: 'remote-tool')]);
  });

  test('rejects cloud tool execution on the client', () {
    expect(
      () => ResolvedToolService.cloud()(
        conversationId: 'conversation-1',
        tool: ResolvedTool.mcp(
          tableId: 'tool-1',
          toolIdentifier: 'remote-tool',
          mcpServerId: 'server-1',
          mcpSlug: 'server-1',
        ),
        arguments: const {},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects MCP tools without a server binding', () {
    expect(
      () => usecase(
        conversationId: 'conversation-1',
        tool: ResolvedTool.mcp(
          tableId: 'tool-1',
          toolIdentifier: 'remote-tool',
          mcpServerId: '',
          mcpSlug: 'server-1',
        ),
        arguments: {'value': 1},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('maps resolved tools to agent descriptors', () {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
    );

    final descriptors = [
      provider
          .toExecution(
            .builtIn(
              tableId: 'calc',
              toolIdentifier: 'calculator',
              tooltype: UserToolType.calculator,
            ),
          )
          .descriptor,
      provider
          .toExecution(
            .native(tableId: 'url', nativeToolType: NativeToolType.url),
          )
          .descriptor,
      provider
          .toExecution(.skillControl(toolIdentifier: loadSkillToolName))
          .descriptor,
      provider
          .toExecution(.skillCommand(commandName: callSkillToolName))
          .descriptor,
      provider
          .toExecution(
            .skillTemplate(
              tableId: 'template-1',
              skillSlug: 'skill-1',
              toolIdentifier: 'tool-1',
            ),
          )
          .descriptor,
      provider
          .toExecution(
            .skillNative(
              tableId: 'native-1',
              skillSlug: 'app-skill',
              toolIdentifier: 'app-tool',
            ),
          )
          .descriptor,
    ];

    expect(descriptors.map((descriptor) => descriptor.kind), [
      AgentResolvedToolKind.builtIn,
      AgentResolvedToolKind.native,
      AgentResolvedToolKind.skillControl,
      AgentResolvedToolKind.skillControl,
      AgentResolvedToolKind.skillTemplate,
      AgentResolvedToolKind.skillNative,
    ]);
    expect(descriptors[3].kind, AgentResolvedToolKind.skillControl);
    expect(descriptors[4].skillSlug, 'skill-1');
    expect(descriptors[5].skillToolSlug, 'app-tool');
  });

  test('loads workspace id through injected conversation repository', () async {
    final conversationRepository = MockConversationRepository();
    when(() => conversationRepository.getConversationById('conversation-1'))
        .thenAnswer(
          (_) async => ConversationEntity(
            id: 'conversation-1',
            title: 'Conversation',
            workspaceId: 'workspace-1',
            isPinned: false,
            createdAt: .new(2026),
            updatedAt: .new(2026),
          ),
        );
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      conversationRepository: conversationRepository,
    );

    expect(
      await provider.getConversationWorkspaceId('conversation-1'),
      'workspace-1',
    );
  });

  test('throws when workspace lookup is not configured or missing', () {
    final missingRepository = MockConversationRepository();
    when(() => missingRepository.getConversationById('conversation-1'))
        .thenAnswer((_) async => null);

    expect(
      () => AppResolvedToolProvider(
        agentCancellationRuntime: cancellationRuntime,
        mcpToolCaller: ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
        }) => Future.value('mcp result'),
      ).getConversationWorkspaceId('conversation-1'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => AppResolvedToolProvider(
        agentCancellationRuntime: cancellationRuntime,
        mcpToolCaller: ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
        }) => Future.value('mcp result'),
        conversationRepository: missingRepository,
      ).getConversationWorkspaceId('conversation-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('runs skill load and unload control tools', () async {
    final loadSkill = _MockLoadConversationSkillUsecase();
    final unloadSkill = _MockUnloadConversationSkillUsecase();
    when(
      () => loadSkill.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        slug: 'skill-1',
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => unloadSkill.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        slug: 'skill-1',
      ),
    ).thenAnswer((_) => Future<void>.value());
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      loadConversationSkillUsecase: (_) => loadSkill,
      unloadConversationSkillUsecase: (_) => unloadSkill,
    );

    expect(
      await provider.runSkillControlTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: loadSkillToolName,
        arguments: {'slug': 'skill-1'},
      )),
      'Skill "skill-1" loaded.',
    );
    expect(
      await provider.runSkillControlTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: unloadSkillToolName,
        arguments: {'slug': 'skill-1'},
      )),
      'Skill "skill-1" unloaded.',
    );
  });

  test('rejects skill control calls without a slug', () {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
    );

    expect(
      () => provider.runSkillControlTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: loadSkillToolName,
        arguments: {},
      )),
      throwsA(isA<FormatException>()),
    );
  });

  test('lists app skill credential ids and names', () async {
    final listSkills = _MockListAvailableSkillsUsecase();
    final appCandidates = _MockListAppSkillCandidatesUsecase();
    final appSkill = serviceSkillDefinitions.singleWhere(
      (skill) => skill.slug == 'openai',
    );
    when(
      () => listSkills.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loaded,
      ),
    ).thenAnswer((_) async => [_appAvailableSkill('openai')]);
    when(
      () => appCandidates.call(workspaceId: 'workspace-1', skill: appSkill),
    ).thenAnswer(
      (_) async => const [
        AppSkillCredentialCandidate(id: 'model:openai-1', name: 'OpenAI key'),
      ],
    );
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      listAvailableSkillsUsecase: (_) => listSkills,
      listAppSkillCredentialCandidatesUsecase: appCandidates,
      appSkillRegistry: const AppSkillRegistry(),
      skillCredentialsRepository: _MockSkillCredentialsRepository(),
    );

    final result = await provider.runSkillControlTool((
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      toolIdentifier: SkillToolNames.listCredentials,
      arguments: {'skillSlug': 'openai'},
    ));

    expect(result, {
      'skillSlug': 'openai',
      'credentials': [
        {'id': 'model:openai-1', 'name': 'OpenAI key'},
      ],
    });
  });

  test('lists user skill credential ids and names', () async {
    final listSkills = _MockListAvailableSkillsUsecase();
    final credentialsRepository = _MockSkillCredentialsRepository();
    const skill = AvailableSkill(
      source: SkillSource.user,
      id: 'skill-1',
      slug: 'skill-1',
      title: 'Skill',
      description: '',
      content: '',
      kind: .template,
      credentialDefinitionId: 'definition-1',
    );
    when(
      () => listSkills.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loaded,
      ),
    ).thenAnswer((_) async => [skill]);
    when(
      () => credentialsRepository.getCredentialsForDefinition(
        workspaceId: 'workspace-1',
        credentialDefinitionId: 'definition-1',
      ),
    ).thenAnswer(
      (_) async => [
        SkillCredentialEntity(
          id: 'credential-1',
          workspaceId: 'workspace-1',
          credentialDefinitionId: 'definition-1',
          name: 'Credential',
          attributes: const {},
          isEnabled: true,
          createdAt: .new(2026),
          updatedAt: .new(2026),
        ),
      ],
    );
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      listAvailableSkillsUsecase: (_) => listSkills,
      skillCredentialsRepository: credentialsRepository,
    );

    expect(
      await provider.runSkillControlTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: SkillToolNames.listCredentials,
        arguments: const {'skillSlug': 'skill-1'},
      )),
      {
        'skillSlug': 'skill-1',
        'credentials': [
          {'id': 'credential-1', 'name': 'Credential'},
        ],
      },
    );
  });

  test(
    'uses the combined skill command runner when fully configured',
    () async {
      final listSkills = _MockListAvailableSkillsUsecase();
      final appCandidates = _MockListAppSkillCandidatesUsecase();
      final appSkill = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'openai',
      );
      when(
        () => listSkills.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loadable,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => listSkills.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loaded,
        ),
      ).thenAnswer((_) async => [_appAvailableSkill('openai')]);
      when(
        () => appCandidates.call(workspaceId: 'workspace-1', skill: appSkill),
      ).thenAnswer(
        (_) async => const [
          AppSkillCredentialCandidate(id: 'model:openai-1', name: 'OpenAI key'),
        ],
      );
      final provider = AppResolvedToolProvider(
        agentCancellationRuntime: cancellationRuntime,
        mcpToolCaller: ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
        }) async => 'mcp result',
        loadConversationSkillUsecase: (_) =>
            _MockLoadConversationSkillUsecase(),
        unloadConversationSkillUsecase: (_) =>
            _MockUnloadConversationSkillUsecase(),
        runSkillTemplateToolUsecase: _MockRunSkillTemplateToolUsecase(),
        runAppSkillToolUsecase: _MockRunAppSkillToolUsecase(),
        buildLoadedSkillManifestsUsecase:
            _MockBuildLoadedSkillManifestsUsecase(),
        buildSkillTemplateToolSpecsUsecase:
            _MockBuildSkillTemplateToolSpecsUsecase(),
        buildAppSkillNativeToolSpecsUsecase:
            _MockBuildAppSkillNativeToolSpecsUsecase(),
        listAvailableSkillsUsecase: (_) => listSkills,
        listAppSkillCredentialCandidatesUsecase: appCandidates,
        appSkillRegistry: const AppSkillRegistry(),
        skillCredentialsRepository: _MockSkillCredentialsRepository(),
      );

      expect(
        await provider.runSkillControlTool((
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolIdentifier: listSkillsToolName,
          arguments: const {},
        )),
        {
          'loadable': const <Map<String, Object?>>[],
          'loaded': <Map<String, Object?>>[
            {'slug': 'openai', 'title': 'openai'},
          ],
        },
      );
      expect(
        await provider.runSkillControlTool((
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolIdentifier: listSkillCredentialsToolName,
          arguments: const {'skillSlug': 'openai'},
        )),
        {
          'skillSlug': 'openai',
          'credentials': [
            {'id': 'model:openai-1', 'name': 'OpenAI key'},
          ],
        },
      );
    },
  );

  test('runs and rejects sub-agent tools', () async {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      subAgentRunner: _subAgentRunner(),
    );

    expect(
      await provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: agentsSkillSlug,
        toolSlug: listAgentsToolName,
        arguments: const {},
      )),
      contains('agent-1'),
    );
    expect(
      await provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: agentsSkillSlug,
        toolSlug: runSubAgentToolName,
        arguments: const {'title': 'Child', 'prompt': 'Run task'},
      )),
      contains('child-1'),
    );
    await expectLater(
      () => provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: agentsSkillSlug,
        toolSlug: 'unknown',
        arguments: const {},
      )),
      throwsA(isA<StateError>()),
    );
  });

  test('delegates skill template, manager, and app native tools', () async {
    final templateTool = _MockRunSkillTemplateToolUsecase();
    final appSkillTool = _MockRunAppSkillToolUsecase();
    final nativeTool = _MockRunSkillsManagerToolUsecase();
    final nativeSuccesses = <({String workspaceId, String toolSlug})>[];
    when(
      () => templateTool.call(
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'template-tool',
        arguments: {'value': 1},
      ),
    ).thenAnswer((_) async => 'template result');
    when(
      () => nativeTool.call(
        workspaceId: 'workspace-1',
        toolSlug: 'native-tool',
        arguments: {'value': 2},
      ),
    ).thenAnswer((_) async => {'ok': true});
    when(
      () => appSkillTool.callCancelable(
        workspaceId: 'workspace-1',
        skillSlug: 'duckduckgo',
        toolSlug: 'search',
        arguments: {'query': 'dart'},
      ),
    ).thenReturn(CancelableOperation.fromFuture(.value('service result')));
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      runSkillTemplateToolUsecase: templateTool,
      runAppSkillToolUsecase: appSkillTool,
      runSkillsManagerToolUsecase: (_) => nativeTool,
      onSkillsManagerToolSuccess:
          ({required workspaceId, required toolSlug, required result}) {
            nativeSuccesses.add((workspaceId: workspaceId, toolSlug: toolSlug));
          },
    );

    expect(
      await provider.runSkillTemplateTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'template-tool',
        arguments: {'value': 1},
      )),
      'template result',
    );
    expect(
      await provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: 'skills_manager',
        toolSlug: 'native-tool',
        arguments: {'value': 2},
      )),
      {'ok': true},
    );
    expect(
      await provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: 'duckduckgo',
        toolSlug: 'search',
        arguments: {'query': 'dart'},
      )),
      'service result',
    );
    expect(nativeSuccesses, [
      (workspaceId: 'workspace-1', toolSlug: 'native-tool'),
    ]);
  });

  test('registers app native skill calls for cancellation', () async {
    final _ = cancellationRuntime.start('conversation-1');
    final appSkillTool = _MockRunAppSkillToolUsecase();
    final operation = CancelableCompleter<Object?>();
    when(
      () => appSkillTool.callCancelable(
        workspaceId: 'workspace-1',
        skillSlug: 'duckduckgo',
        toolSlug: 'search',
        arguments: {'query': 'dart'},
      ),
    ).thenReturn(operation.operation);
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      runAppSkillToolUsecase: appSkillTool,
    );

    final result = provider.runSkillNativeTool((
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      skillSlug: 'duckduckgo',
      toolSlug: 'search',
      arguments: {'query': 'dart'},
    ));

    cancellationRuntime.requestStop('conversation-1');

    expect(operation.isCanceled, isTrue);
    expect(await result, isNull);
  });

  test('throws when skill runners are not configured', () {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
    );

    expect(
      () => provider.runSkillTemplateTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'template-tool',
        arguments: const {},
      )),
      throwsA(isA<StateError>()),
    );
    expect(
      () => provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'native-tool',
        arguments: const {},
      )),
      throwsA(isA<StateError>()),
    );
  });

  test('throws when sub-agent or skill-manager runners are missing', () async {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
    );

    await expectLater(
      () => provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: agentsSkillSlug,
        toolSlug: listAgentsToolName,
        arguments: const {},
      )),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      () => provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        skillSlug: SkillToolSlugs.skillsManager,
        toolSlug: 'list',
        arguments: const {},
      )),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects incomplete skill credential configuration', () async {
    final listSkills = _MockListAvailableSkillsUsecase();
    final appSkill = _appAvailableSkill('missing-app-skill');
    const appSkillDefinition = AppSkillDefinition(
      identifier: 'missing-app-skill',
      slug: 'missing-app-skill',
      title: 'Missing app skill',
      description: '',
      content: '',
    );
    when(
      () => listSkills.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loaded,
      ),
    ).thenAnswer((_) async => [appSkill]);

    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      listAvailableSkillsUsecase: (_) => listSkills,
      appSkillRegistry: const AppSkillRegistry(),
      skillCredentialsRepository: _MockSkillCredentialsRepository(),
    );

    await expectLater(
      provider.runSkillControlTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: SkillToolNames.listCredentials,
        arguments: const {'skillSlug': 'missing-app-skill'},
      )),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      provider.runSkillControlTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: SkillToolNames.listCredentials,
        arguments: const {'skillSlug': 'not-loaded'},
      )),
      throwsA(isA<StateError>()),
    );

    final configuredCandidates = _MockListAppSkillCandidatesUsecase();
    when(
      () => configuredCandidates.call(
        workspaceId: 'workspace-1',
        skill: appSkillDefinition,
      ),
    ).thenAnswer((_) async => const []);
    final providerWithMissingRegistryEntry = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
      }) async => 'mcp result',
      listAvailableSkillsUsecase: (_) => listSkills,
      listAppSkillCredentialCandidatesUsecase: configuredCandidates,
      appSkillRegistry: const AppSkillRegistry(),
      skillCredentialsRepository: _MockSkillCredentialsRepository(),
    );
    await expectLater(
      providerWithMissingRegistryEntry.runSkillControlTool((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: SkillToolNames.listCredentials,
        arguments: const {'skillSlug': 'missing-app-skill'},
      )),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'throws when skill load and unload usecases are not configured',
    () async {
      final provider = AppResolvedToolProvider(
        agentCancellationRuntime: cancellationRuntime,
        mcpToolCaller: ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
        }) => Future.value('mcp result'),
      );

      await expectLater(
        provider.runSkillControlTool((
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolIdentifier: loadSkillToolName,
          arguments: const {'slug': 'skill-1'},
        )),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        provider.runSkillControlTool((
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolIdentifier: unloadSkillToolName,
          arguments: const {'slug': 'skill-1'},
        )),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('provider creates the shared tool runner', () {
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
          ),
        ).overrideWithValue(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(resolvedToolServiceProvider),
      isA<ResolvedToolService>(),
    );
  });
}
