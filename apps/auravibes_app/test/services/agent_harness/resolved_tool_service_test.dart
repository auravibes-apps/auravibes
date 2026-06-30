// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_agent/auravibes_agent.dart'
    show AgentCancellationRuntime, AgentResolvedToolKind;
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skills_manager_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../../test_mocks.dart';

class _MockLoadConversationSkillUsecase extends Mock
    implements LoadConversationSkillUsecase {}

class _MockUnloadConversationSkillUsecase extends Mock
    implements UnloadConversationSkillUsecase {}

class _MockRunSkillTemplateToolUsecase extends Mock
    implements RunSkillTemplateToolUsecase {}

class _MockRunSkillsManagerToolUsecase extends Mock
    implements RunSkillsManagerToolUsecase {}

void main() {
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
          mcpCalls.add((
            serverId: mcpServerId,
            toolIdentifier: toolIdentifier,
          ));

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
        tooltype: UserToolType.calculator,
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
          tooltype: UserToolType.calculator,
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
        tool: ResolvedTool.native(
          tableId: 'tool-1',
          nativeToolType: NativeToolType.url,
        ),
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
      ),
      arguments: {'value': 1},
    );

    expect(result, 'mcp result');
    expect(
      mcpCalls,
      [(serverId: 'server-1', toolIdentifier: 'remote-tool')],
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
        ),
        arguments: {'value': 1},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('maps resolved tools to agent descriptors', () {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) async => 'mcp result',
    );

    final descriptors = [
      provider
          .toExecution(
            ResolvedTool.builtIn(
              tableId: 'calc',
              toolIdentifier: 'calculator',
              tooltype: UserToolType.calculator,
            ),
          )
          .descriptor,
      provider
          .toExecution(
            ResolvedTool.native(
              tableId: 'url',
              nativeToolType: NativeToolType.url,
            ),
          )
          .descriptor,
      provider
          .toExecution(
            ResolvedTool.skillControl(toolIdentifier: loadSkillToolName),
          )
          .descriptor,
      provider
          .toExecution(
            ResolvedTool.skillTemplate(
              tableId: 'template-1',
              skillSlug: 'skill-1',
              toolIdentifier: 'tool-1',
            ),
          )
          .descriptor,
      provider
          .toExecution(
            ResolvedTool.skillNative(
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
      AgentResolvedToolKind.skillTemplate,
      AgentResolvedToolKind.skillNative,
    ]);
    expect(descriptors[3].skillSlug, 'skill-1');
    expect(descriptors[4].skillToolSlug, 'app-tool');
  });

  test('loads workspace id through injected conversation repository', () async {
    final conversationRepository = MockConversationRepository();
    when(
      () => conversationRepository.getConversationById('conversation-1'),
    ).thenAnswer(
      (_) async => ConversationEntity(
        id: 'conversation-1',
        title: 'Conversation',
        workspaceId: 'workspace-1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
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
    when(
      () => missingRepository.getConversationById('conversation-1'),
    ).thenAnswer((_) async => null);

    expect(
      () => AppResolvedToolProvider(
        agentCancellationRuntime: cancellationRuntime,
        mcpToolCaller:
            ({
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
        mcpToolCaller:
            ({
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
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) async => 'mcp result',
      loadConversationSkillUsecase: loadSkill,
      unloadConversationSkillUsecase: unloadSkill,
    );

    expect(
      await provider.runSkillControlTool(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: loadSkillToolName,
        arguments: {'slug': 'skill-1'},
      ),
      'Skill "skill-1" loaded.',
    );
    expect(
      await provider.runSkillControlTool(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: unloadSkillToolName,
        arguments: {'slug': 'skill-1'},
      ),
      'Skill "skill-1" unloaded.',
    );
  });

  test('rejects skill control calls without a slug', () {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) async => 'mcp result',
    );

    expect(
      () => provider.runSkillControlTool(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolIdentifier: loadSkillToolName,
        arguments: {},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('delegates skill template and native tools', () async {
    final templateTool = _MockRunSkillTemplateToolUsecase();
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
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) async => 'mcp result',
      runSkillTemplateToolUsecase: templateTool,
      runSkillsManagerToolUsecase: nativeTool,
      onSkillsManagerToolSuccess:
          ({required workspaceId, required toolSlug, required result}) {
            nativeSuccesses.add((workspaceId: workspaceId, toolSlug: toolSlug));
          },
    );

    expect(
      await provider.runSkillTemplateTool(
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'template-tool',
        arguments: {'value': 1},
      ),
      'template result',
    );
    expect(
      await provider.runSkillNativeTool(
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'native-tool',
        arguments: {'value': 2},
      ),
      {'ok': true},
    );
    expect(nativeSuccesses, [
      (workspaceId: 'workspace-1', toolSlug: 'native-tool'),
    ]);
  });

  test('throws when skill runners are not configured', () {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) async => 'mcp result',
    );

    expect(
      () => provider.runSkillTemplateTool(
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'template-tool',
        arguments: const {},
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => provider.runSkillNativeTool(
        workspaceId: 'workspace-1',
        skillSlug: 'skill-1',
        toolSlug: 'native-tool',
        arguments: const {},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'throws when skill load and unload usecases are not configured',
    () async {
      final provider = AppResolvedToolProvider(
        agentCancellationRuntime: cancellationRuntime,
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
            }) => Future.value('mcp result'),
      );

      await expectLater(
        provider.runSkillControlTool(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolIdentifier: loadSkillToolName,
          arguments: const {'slug': 'skill-1'},
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        provider.runSkillControlTool(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolIdentifier: unloadSkillToolName,
          arguments: const {'slug': 'skill-1'},
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('provider creates the shared tool runner', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(resolvedToolServiceProvider),
      isA<ResolvedToolService>(),
    );
  });
}
