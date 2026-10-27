// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_conversation_data_provider.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_agent_language_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_command_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../../../data/database/drift/database_test_utils.dart';
import '../../../test_mocks.dart';

class _MockWorkspaceConversationTools extends Mock
    implements WorkspaceConversationToolsUsecase;

class _MockLoadConversationSkillUsecase extends Mock
    implements LoadConversationSkillUsecase;

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase;

class _MockBuildAppSkillNativeToolSpecsUsecase extends Mock
    implements BuildAppSkillNativeToolSpecsUsecase;

_MockBuildAppSkillNativeToolSpecsUsecase _currentAppSkillSpecs(
  String? toolName,
) {
  final specs = _MockBuildAppSkillNativeToolSpecsUsecase();
  when(
    () => specs.call(
      conversationId: any(named: 'conversationId'),
      workspaceId: any(named: 'workspaceId'),
      languageCode: any(named: 'languageCode'),
    ),
  ).thenAnswer(
    (_) async => [
      if (toolName != null)
        ToolSpec(
          name: toolName,
          description: 'Current app skill tool',
          inputJsonSchema: const {'type': 'object'},
        ),
    ],
  );

  return specs;
}

const _runtimeConnector = ConnectorDefinition(
  identifier: 'example',
  title: 'Example',
  description: 'Example Connector.',
  tools: [
    ConnectorToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search current records.',
      inputJsonSchema: {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
        },
        'required': ['query'],
        'additionalProperties': false,
      },
      urlTemplate: .new(
        template: .new(url: 'https://example.invalid/search'),
        inputs: {},
      ),
      requiresConnection: true,
    ),
  ],
);

MockConversationRepository _conversationRepository() {
  final repository = MockConversationRepository();
  when(() => repository.getConversationById('conversation-1')).thenAnswer(
    (_) async => ConversationEntity(
      id: 'conversation-1',
      title: 'Conversation',
      workspaceId: 'workspace-1',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    ),
  );

  return repository;
}

class _MockBuildLoadedSkillManifestsUsecase extends Mock
    implements BuildLoadedSkillManifestsUsecase;

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
  SubAgentCompletionFailure? get failure => null;

  @override
  bool get isStopped => false;

  @override
  void finish({
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
    SubAgentCompletionFailure? failure,
  }) {
    final _ = failure;
    if (status != SubAgentCompletionStatus.done) return;
  }
}

SubAgentRunner _subAgentRunner({
  void Function(String conversationId)? onContinue,
}) {
  return SubAgentRunner(
    agentCatalog: _FakeSubAgentCatalog(),
    conversationStore: _FakeSubAgentConversationStore(),
    messageStore: _FakeSubAgentMessageStore(),
    startRequest: ({required parentId, required childId}) =>
        _FakeSubAgentRequestHandle(),
    continueAgentTurn: ({required conversationId, required context}) async {
      onContinue?.call(conversationId);

      return AgentIterationDecision.done;
    },
  );
}

void main() {
  test('workspace failures return safe actionable messages', () async {
    final commands = _MockWorkspaceConversationTools();
    final arguments = <String, dynamic>{};
    final service = ResolvedToolService(
      agentCancellationRuntime: .new(),
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => null,
      workspaceConversationTools: commands,
    );
    for (final (error, message) in [
      (const WorkspaceTableException(denied: true), 'unavailable'),
      (const WorkspaceTableException(conflict: true), 'Read it again'),
      (const WorkspaceTableException(), 'invalid'),
    ]) {
      when(
        () => commands.call(
          conversationId: 'chat',
          arguments: arguments,
          operationId: 'call',
        ),
      ).thenThrow(error);
      await expectLater(
        service(
          conversationId: 'chat',
          tool: ResolvedTool.workspaceCommand(),
          arguments: arguments,
          toolCallId: 'call',
        ),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (failure) => failure.responseRaw,
            'safe message',
            contains(message),
          ),
        ),
      );
    }
  });
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  tearDownAll(database.close);
  setUpAll(registerTestFallbackValues);
  var cancellationRuntime = AgentCancellationRuntime();
  var mcpCalls = <({String serverId, String toolIdentifier})>[];
  var usecase = ResolvedToolService(
    agentCancellationRuntime: cancellationRuntime,
    mcpToolCaller:
        ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
          onElicitation,
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
            onElicitation,
          }) async {
            mcpCalls.add((
              serverId: mcpServerId,
              toolIdentifier: toolIdentifier,
            ));

            return 'mcp result';
          },
    );
  });

  test('exposes cancellation support for background eligibility', () {
    expect(
      usecase.supportsCancellation(
        ResolvedTool.native(tableId: 'url', nativeToolType: NativeToolType.url),
      ),
      isTrue,
    );
    expect(
      usecase.supportsCancellation(
        ResolvedTool.builtIn(
          tableId: 'calculator',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        ),
      ),
      isFalse,
    );
    expect(
      usecase.supportsCancellation(
        ResolvedTool.mcp(
          tableId: 'weather',
          toolIdentifier: 'forecast',
          mcp: (
            mcpServerId: 'server-1',
            mcpSlug: 'weather',
            outputSchemaJson: null,
          ),
        ),
      ),
      isFalse,
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
        mcp: (
          mcpServerId: 'server-1',
          mcpSlug: 'server-1',
          outputSchemaJson: null,
        ),
      ),
      arguments: {'value': 1},
    );

    expect(result, 'mcp result');
    expect(mcpCalls, [(serverId: 'server-1', toolIdentifier: 'remote-tool')]);
  });

  test('keeps MCP App result data separate from model output', () async {
    Map<String, Object?> appData(String text) => {
      'content': [
        {'type': 'text', 'text': text},
      ],
      '_meta': {
        'ui': {'resourceUri': 'ui://tool/view'},
      },
    };
    final service = ResolvedToolService(
      agentCancellationRuntime: .new(),
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
            onElicitation,
          }) async => McpToolCallerResult(
            modelText: 'model result',
            appData: appData(arguments['text'] as String),
          ),
    );

    final firstResult = await service(
      conversationId: 'conversation-1',
      tool: ResolvedTool.mcp(
        tableId: 'tool-1',
        toolIdentifier: 'remote-tool',
        mcp: (
          mcpServerId: 'server-1',
          mcpSlug: 'server-1',
          outputSchemaJson: null,
        ),
      ),
      arguments: const {'text': 'first conversation'},
      toolCallId: 'tool-call-1',
    );
    final secondResult = await service(
      conversationId: 'conversation-2',
      tool: ResolvedTool.mcp(
        tableId: 'tool-1',
        toolIdentifier: 'remote-tool',
        mcp: (
          mcpServerId: 'server-1',
          mcpSlug: 'server-1',
          outputSchemaJson: null,
        ),
      ),
      arguments: const {'text': 'second conversation'},
      toolCallId: 'tool-call-1',
    );

    expect(firstResult, 'model result');
    expect(secondResult, 'model result');
    expect(
      service.takeMcpAppResultData(
        conversationId: 'conversation-1',
        toolCallId: 'tool-call-1',
      ),
      appData('first conversation'),
    );
    expect(
      service.takeMcpAppResultData(
        conversationId: 'conversation-2',
        toolCallId: 'tool-call-1',
      ),
      appData('second conversation'),
    );
  });

  test('does not retain empty MCP App result data', () async {
    final service = ResolvedToolService(
      agentCancellationRuntime: .new(),
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
            onElicitation,
          }) async => const McpToolCallerResult(
            modelText: 'ordinary result',
            appData: {},
          ),
    );

    final result = await service(
      conversationId: 'conversation-1',
      tool: ResolvedTool.mcp(
        tableId: 'tool-1',
        toolIdentifier: 'remote-tool',
        mcp: (
          mcpServerId: 'server-1',
          mcpSlug: 'server-1',
          outputSchemaJson: null,
        ),
      ),
      arguments: const {},
      toolCallId: 'tool-call-1',
    );

    expect(result, 'ordinary result');
    expect(
      service.takeMcpAppResultData(
        conversationId: 'conversation-1',
        toolCallId: 'tool-call-1',
      ),
      isNull,
    );
  });

  test('routes MCP elicitation to the requesting conversation', () async {
    String? requestedConversationId;
    McpElicitationRequest? requestedElicitation;
    final service = ResolvedToolService(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
            onElicitation,
          }) async {
            final handler = onElicitation;
            if (handler == null) {
              throw StateError('Elicitation handler missing.');
            }
            final response = await handler(
              const McpElicitationRequest(
                serverName: 'Example server',
                message: 'Please provide a name.',
                mode: .form,
                requestedSchema: {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                  'required': ['name'],
                },
              ),
            );
            expect(response.action, McpElicitationAction.accept);

            return 'done';
          },
      mcpElicitationRequester: (conversationId, request) async {
        requestedConversationId = conversationId;
        requestedElicitation = request;

        return const McpElicitationResponse(
          action: .accept,
          content: {'name': 'Ada'},
        );
      },
    );

    final result = await service.call(
      conversationId: 'conversation-elicitation',
      tool: ResolvedTool.mcp(
        tableId: 'tool-1',
        toolIdentifier: 'remote-tool',
        mcp: (
          mcpServerId: 'server-1',
          mcpSlug: 'server-1',
          outputSchemaJson: null,
        ),
      ),
      arguments: const {},
    );

    expect(result, 'done');
    expect(requestedConversationId, 'conversation-elicitation');
    expect(requestedElicitation?.serverName, 'Example server');
  });

  test('rejects cloud tool execution on the client', () {
    expect(
      () => ResolvedToolService.cloud()(
        conversationId: 'conversation-1',
        tool: .mcp(
          tableId: 'tool-1',
          toolIdentifier: 'remote-tool',
          mcp: (
            mcpServerId: 'server-1',
            mcpSlug: 'server-1',
            outputSchemaJson: null,
          ),
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
          mcp: (mcpServerId: '', mcpSlug: 'server-1', outputSchemaJson: null),
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
        onElicitation,
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
          .toExecution(.skillControl(toolIdentifier: activateSkillToolName))
          .descriptor,
      provider
          .toExecution(
            .connectorCommand(commandName: listConnectorToolsToolName),
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
      AgentResolvedToolKind.connectorCommand,
      AgentResolvedToolKind.skillNative,
    ]);
    expect(descriptors[3].kind, AgentResolvedToolKind.connectorCommand);
    expect(descriptors[4].skillSlug, 'app-skill');
    expect(descriptors[4].skillToolSlug, 'app-tool');
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
        onElicitation,
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
          onElicitation,
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
          onElicitation,
        }) => Future.value('mcp result'),
        conversationRepository: missingRepository,
      ).getConversationWorkspaceId('conversation-1'),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'activates a Skill by loading guidance without tool definitions',
    () async {
      final loadSkill = _MockLoadConversationSkillUsecase();
      final listSkills = _MockListAvailableSkillsUsecase();
      final manifests = _MockBuildLoadedSkillManifestsUsecase();
      const skill = AvailableSkill(
        id: 'skill-1',
        slug: 'skill-1',
        title: 'Skill',
        description: 'Use skill.',
        content: 'Use skill.',
        source: .user,
        kind: .template,
      );
      final manifest = SkillManifest(
        slug: 'skill-1',
        title: 'Skill',
        description: 'Use skill.',
        revision: 'rev-1',
      );
      when(
        () => listSkills.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .catalog,
        ),
      ).thenAnswer((_) async => const [skill]);
      when(
        () => loadSkill.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          slug: 'skill-1',
        ),
      ).thenAnswer((_) => Future<void>.value());
      when(
        () => manifests.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          extraSkills: any(named: 'extraSkills'),
        ),
      ).thenAnswer((_) async => [manifest]);
      final provider = AppResolvedToolProvider(
        agentCancellationRuntime: cancellationRuntime,
        mcpToolCaller: ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
          onElicitation,
        }) async => 'mcp result',
        loadConversationSkillUsecase: (_) => loadSkill,
        buildLoadedSkillManifestsUsecase: manifests,
        listAvailableSkillsUsecase: (_) => listSkills,
      );

      expect(
        await provider.runSkillControlTool((
          conversationId: 'conversation-1',
          toolCallId: 'call-1',
          workspaceId: 'workspace-1',
          toolIdentifier: activateSkillToolName,
          arguments: {'slug': 'skill-1', 'revision': 'rev-1'},
        )),
        isA<SkillActivationResult>().having(
          (result) => result.value,
          'value',
          contains('<skill_content slug="skill-1"'),
        ),
      );
    },
  );

  test('runs browser tools through the native app tool path', () async {
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
    var browserCalls = 0;
    var failBrowserCall = false;
    final service = ResolvedToolService(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => 'mcp result',
      conversationRepository: conversationRepository,
      buildAppSkillNativeToolSpecsUsecase: _currentAppSkillSpecs(
        'skill__app_native__browser__browser_read_page',
      ),
      browserSkillToolRunner:
          ({
            required workspaceId,
            required conversationId,
            required toolSlug,
            required arguments,
          }) async {
            browserCalls++;
            expect(workspaceId, 'workspace-1');
            expect(conversationId, 'conversation-1');
            expect(toolSlug, 'browser_read_page');
            expect(arguments, {'tabId': 'tab-1', 'format': 'text'});
            if (failBrowserCall) throw StateError('WebView unavailable.');

            return 'page output';
          },
    );

    Future<Object?> call() => service.call(
      conversationId: 'conversation-1',
      tool: ResolvedTool.skillNative(
        tableId: 'browser_read_page',
        skillSlug: AppSkillRegistry.browserSkillSlug,
        toolIdentifier: 'browser_read_page',
      ),
      arguments: const {'tabId': 'tab-1', 'format': 'text'},
    );

    expect(await call(), 'page output');
    failBrowserCall = true;
    await expectLater(call(), throwsA(isA<StateError>()));
    expect(browserCalls, 2);
  });
  test('executes a known Connector tool without loading a Skill', () async {
    var loadedWorkspaceId = '';
    Map<String, dynamic>? executedArguments;
    final connectorCommandUsecase = ConnectorCommandUsecase(
      loadConnections: (workspaceId, connector) async {
        loadedWorkspaceId = workspaceId;
        expect(connector.identifier, 'example');

        return const [
          ConnectorConnectionCandidate(id: 'service:one', name: 'Work'),
        ];
      },
      runTool:
          ({
            required workspaceId,
            required connector,
            required tool,
            required arguments,
          }) async {
            executedArguments = arguments;

            return 'record found';
          },
      connectors: const [_runtimeConnector],
    );
    final service = ResolvedToolService(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => 'mcp result',
      conversationRepository: _conversationRepository(),
      connectorCommandUsecase: connectorCommandUsecase,
    );

    final result = await service.call(
      conversationId: 'conversation-1',
      tool: ResolvedTool.connectorCommand(
        commandName: executeConnectorToolName,
      ),
      arguments: const {
        'toolId': 'connector/example/search',
        'args': {'query': 'find a record'},
      },
    );

    expect(result, 'record found');
    expect(loadedWorkspaceId, 'workspace-1');
    expect(executedArguments, {
      'query': 'find a record',
      'connectionId': 'service:one',
    });
  });

  test('blocks Connector execution when workspace has no Connection', () async {
    var toolRan = false;
    final connectorCommandUsecase = ConnectorCommandUsecase(
      loadConnections: (_, _) async => const [],
      runTool:
          ({
            required workspaceId,
            required connector,
            required tool,
            required arguments,
          }) async {
            toolRan = true;

            return 'unexpected';
          },
      connectors: const [_runtimeConnector],
    );
    final service = ResolvedToolService(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => 'mcp result',
      conversationRepository: _conversationRepository(),
      connectorCommandUsecase: connectorCommandUsecase,
    );

    await expectLater(
      service.call(
        conversationId: 'conversation-1',
        tool: ResolvedTool.connectorCommand(
          commandName: executeConnectorToolName,
        ),
        arguments: const {
          'toolId': 'connector/example/search',
          'args': {'query': 'find a record'},
        },
      ),
      throwsA(
        isA<AgentToolExecutionFailure>().having(
          (failure) => failure.responseRaw,
          'responseRaw',
          contains('No enabled Connection'),
        ),
      ),
    );
    expect(toolRan, isFalse);
  });

  test('runs and rejects sub-agent tools', () async {
    final specs = _MockBuildAppSkillNativeToolSpecsUsecase();
    final languageRuntime = ConversationAgentLanguageRuntime()
      ..remember('conversation-1', 'es');
    final childLanguageCodes = <String?>[];
    final nativeToolSlugs = [listAgentsToolName, runSubAgentToolName];
    when(
      () => specs.call(
        conversationId: any(named: 'conversationId'),
        workspaceId: any(named: 'workspaceId'),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer(
      (_) async => [
        for (final slug in nativeToolSlugs)
          ToolSpec(
            name: AgentResolvedToolName.skillNative(
              tableId: slug,
              skillSlug: agentsSkillSlug,
              toolIdentifier: slug,
            ).fullName,
            description: slug,
            inputJsonSchema: const {'type': 'object'},
          ),
      ],
    );
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => 'mcp result',
      buildAppSkillNativeToolSpecsUsecase: specs,
      subAgentRunner: _subAgentRunner(
        onContinue: (conversationId) {
          childLanguageCodes.add(
            languageRuntime.languageCodeFor(conversationId),
          );
        },
      ),
      conversationLanguageRuntime: languageRuntime,
    );

    final listAgentsResult = await provider.runSkillNativeTool((
      conversationId: 'conversation-1',
      toolCallId: 'call-1',
      workspaceId: 'workspace-1',
      skillSlug: agentsSkillSlug,
      toolSlug: listAgentsToolName,
      arguments: const {},
    ));
    expect(listAgentsResult, contains('agent-1'));
    expect(
      (jsonDecode('$listAgentsResult') as Map<String, dynamic>)['hint'],
      contains('Los agentes configurados'),
    );
    expect(
      await provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        toolCallId: 'call-1',
        workspaceId: 'workspace-1',
        skillSlug: agentsSkillSlug,
        toolSlug: runSubAgentToolName,
        arguments: const {'title': 'Child', 'prompt': 'Run task'},
      )),
      contains('child-1'),
    );
    expect(childLanguageCodes, ['es']);
    await expectLater(
      () => provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        toolCallId: 'call-1',
        workspaceId: 'workspace-1',
        skillSlug: agentsSkillSlug,
        toolSlug: 'unknown',
        arguments: const {},
      )),
      throwsA(isA<StateError>()),
    );
    verify(
      () => specs.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        languageCode: 'es',
      ),
    ).called(3);
  });

  test('rejects app native tools absent from current specifications', () async {
    final specs = _currentAppSkillSpecs(null);
    var browserToolRan = false;
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => 'mcp result',
      buildAppSkillNativeToolSpecsUsecase: specs,
      browserSkillToolRunner:
          ({
            required workspaceId,
            required conversationId,
            required toolSlug,
            required arguments,
          }) async {
            browserToolRan = true;

            return 'unexpected';
          },
    );

    await expectLater(
      provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        toolCallId: 'call-1',
        workspaceId: 'workspace-1',
        skillSlug: AppSkillRegistry.browserSkillSlug,
        toolSlug: 'browser_read_page',
        arguments: const {'tabId': 'tab-1', 'format': 'text'},
      )),
      throwsA(isA<StateError>()),
    );
    expect(browserToolRan, isFalse);
  });

  test('throws when sub-agent or skill-manager runners are missing', () async {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) async => 'mcp result',
    );

    await expectLater(
      () => provider.runSkillNativeTool((
        conversationId: 'conversation-1',
        toolCallId: 'call-1',
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
        toolCallId: 'call-1',
        workspaceId: 'workspace-1',
        skillSlug: SkillToolSlugs.skillsManager,
        toolSlug: 'list',
        arguments: const {},
      )),
      throwsA(isA<StateError>()),
    );
  });

  test('throws when skill activation runner is not configured', () {
    final provider = AppResolvedToolProvider(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller: ({
        required mcpServerId,
        required toolIdentifier,
        required arguments,
        onElicitation,
      }) => Future.value('mcp result'),
    );

    expect(
      () => provider.runSkillControlTool((
        conversationId: 'conversation-1',
        toolCallId: 'call-1',
        workspaceId: 'workspace-1',
        toolIdentifier: activateSkillToolName,
        arguments: const {'slug': 'skill-1', 'revision': 'rev-1'},
      )),
      throwsStateError,
    );
  });

  test('provider creates the shared tool runner', () async {
    await clearAppDatabase(database);
    final appSkillSpecs = _currentAppSkillSpecs(
      AgentResolvedToolName.skillNative(
        tableId: runSubAgentToolName,
        skillSlug: agentsSkillSlug,
        toolIdentifier: runSubAgentToolName,
      ).fullName,
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        cloudSkillStoreProvider('workspace-1').overrideWithValue(null),
        buildAppSkillNativeToolSpecsUsecaseProvider.overrideWithValue(
          appSkillSpecs,
        ),
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

  test('continues a sub-agent through the provider container', () async {
    final conversationRepository = MockConversationRepository();
    final messageRepository = MockMessageRepository();
    final agentLoop = MockAgentLoopRunner();
    final parent = ConversationEntity(
      id: 'parent-1',
      title: 'Parent',
      workspaceId: 'workspace-1',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      modelId: 'model-1',
    );
    final child = parent.copyWith(
      id: 'child-1',
      title: 'Child',
      parentConversationId: 'parent-1',
    );
    final prompt = MessageEntity(
      id: 'prompt-1',
      conversationId: 'child-1',
      content: 'Run task',
      messageType: .text,
      isUser: true,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );

    when(() => conversationRepository.getConversationById('parent-1'))
        .thenAnswer((_) async => parent);
    when(() => conversationRepository.createConversation(any()))
        .thenAnswer((_) async => child);
    when(() => messageRepository.createMessage(any()))
        .thenAnswer((_) async => prompt);
    when(
      () => messageRepository.getLatestAssistantMessagesByConversations(any()),
    ).thenAnswer((_) async => []);
    when(
      () => agentLoop.call(
        conversationId: 'child-1',
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => AgentIterationDecision.waitForToolApproval);

    await clearAppDatabase(database);
    final appSkillSpecs = _currentAppSkillSpecs(
      AgentResolvedToolName.skillNative(
        tableId: runSubAgentToolName,
        skillSlug: agentsSkillSlug,
        toolIdentifier: runSubAgentToolName,
      ).fullName,
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        cloudSkillStoreProvider('workspace-1').overrideWithValue(null),
        buildAppSkillNativeToolSpecsUsecaseProvider.overrideWithValue(
          appSkillSpecs,
        ),
        workspaceSessionProvider(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
          ),
        ).overrideWithValue(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
          ),
        ),
        workspaceSessionForRouteProvider('workspace-1').overrideWith(
          (_) async => const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
          ),
        ),
        conversationRepositoryProvider.overrideWithValue(
          conversationRepository,
        ),
        messageRepositoryProvider.overrideWithValue(messageRepository),
        appAgentLoopProvider.overrideWithValue(agentLoop),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(resolvedToolServiceProvider);
    final activeSubAgents = container.read(
      activeSubAgentRuntimeProvider.notifier,
    );
    final approvalWait = Completer<void>();
    final _ = container.listen(activeSubAgentRuntimeProvider, (_, _) {
      if (activeSubAgents.statusOf('child-1') == .awaitingApproval &&
          !approvalWait.isCompleted) {
        approvalWait.complete();
      }
    });
    final resultFuture = service.call(
      conversationId: 'parent-1',
      tool: ResolvedTool.skillNative(
        tableId: runSubAgentToolName,
        skillSlug: agentsSkillSlug,
        toolIdentifier: runSubAgentToolName,
      ),
      arguments: const {'title': 'Child', 'prompt': 'Run task'},
    );
    await approvalWait.future;
    expect(
      activeSubAgents.statusOf('child-1'),
      ActiveSubAgentStatus.awaitingApproval,
    );

    activeSubAgents.finish((
      parentId: 'parent-1',
      childId: 'child-1',
      status: .done,
      error: null,
      stackTrace: null,
    ));
    final result = await resultFuture;

    expect(result, contains('"conversationId":"child-1"'));
    expect(result, contains('"status":"done"'));

    expect(activeSubAgents.statusOf('child-1'), ActiveSubAgentStatus.completed);
    verify(
      () => agentLoop.call(
        conversationId: 'child-1',
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  test(
    'preserves a stopped sub-agent child ID through provider cancellation',
    () async {
      final conversationRepository = MockConversationRepository();
      final messageRepository = MockMessageRepository();
      final agentLoop = MockAgentLoopRunner();
      final parent = ConversationEntity(
        id: 'parent-1',
        title: 'Parent',
        workspaceId: 'workspace-1',
        isPinned: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        modelId: 'model-1',
      );
      final child = parent.copyWith(
        id: 'child-1',
        title: 'Child',
        parentConversationId: 'parent-1',
      );
      final prompt = MessageEntity(
        id: 'prompt-1',
        conversationId: 'child-1',
        content: 'Run task',
        messageType: .text,
        isUser: true,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );

      when(() => conversationRepository.getConversationById('parent-1'))
          .thenAnswer((_) async => parent);
      when(() => conversationRepository.createConversation(any()))
          .thenAnswer((_) async => child);
      when(() => messageRepository.createMessage(any()))
          .thenAnswer((_) async => prompt);
      when(
        () =>
            messageRepository.getLatestAssistantMessagesByConversations(any()),
      ).thenAnswer((_) async => []);

      await clearAppDatabase(database);
      final appSkillSpecs = _currentAppSkillSpecs(
        AgentResolvedToolName.skillNative(
          tableId: runSubAgentToolName,
          skillSlug: agentsSkillSlug,
          toolIdentifier: runSubAgentToolName,
        ).fullName,
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          cloudSkillStoreProvider('workspace-1').overrideWithValue(null),
          buildAppSkillNativeToolSpecsUsecaseProvider.overrideWithValue(
            appSkillSpecs,
          ),
          workspaceSessionProvider(
            const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
            ),
          ).overrideWithValue(
            const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
            ),
          ),
          workspaceSessionForRouteProvider('workspace-1').overrideWith(
            (_) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(
            conversationRepository,
          ),
          messageRepositoryProvider.overrideWithValue(messageRepository),
          appAgentLoopProvider.overrideWithValue(agentLoop),
        ],
      );
      addTearDown(container.dispose);

      final cancellationRuntime = container.read(
        agentCancellationRuntimeProvider,
      );
      final parentScope = cancellationRuntime.start('parent-1');
      addTearDown(() => cancellationRuntime.clear('parent-1', parentScope));
      when(
        () => agentLoop.call(
          conversationId: 'child-1',
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {
        cancellationRuntime.requestStop('parent-1');

        return AgentIterationDecision.done;
      });

      final service = container.read(resolvedToolServiceProvider);
      final result = await service.call(
        conversationId: 'parent-1',
        tool: ResolvedTool.skillNative(
          tableId: runSubAgentToolName,
          skillSlug: agentsSkillSlug,
          toolIdentifier: runSubAgentToolName,
        ),
        arguments: const {'title': 'Child', 'prompt': 'Run task'},
      );

      expect(result, contains('"conversationId":"child-1"'));
      expect(result, contains('"status":"stopped"'));
      verify(
        () => agentLoop.call(
          conversationId: 'child-1',
          context: any(named: 'context'),
        ),
      ).called(1);
    },
  );
}
