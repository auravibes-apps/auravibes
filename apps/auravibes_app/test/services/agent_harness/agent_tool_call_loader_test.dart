// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_call_loader.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_status_mapper.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

void main() {
  test('projects app awaiting approval and running as engine pending', () {
    expect(
      AgentToolStatusMapper.toLifecycle(null),
      agent.AgentToolCallLifecycle.pending,
    );
    expect(
      AgentToolStatusMapper.toLifecycle(ToolCallResultStatus.running),
      agent.AgentToolCallLifecycle.pending,
    );
  });

  setUpAll(registerTestFallbackValues);

  group('AgentToolCallLoader', () {
    var messageRepository = MockMessageRepository();
    var conversationRepository = MockConversationRepository();
    var loadToolSpecs = MockLoadConversationToolSpecsUsecase();
    var catalog = agent.buildToolCatalog<ResolvedTool>([]);
    var usecase = AgentToolCallLoader(
      messageRepository: messageRepository,
      conversationRepository: conversationRepository,
      loadConversationToolSpecsUsecaseForWorkspace: (_) => loadToolSpecs,
      toolResolverService: const ToolResolverService(),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      conversationRepository = MockConversationRepository();
      loadToolSpecs = MockLoadConversationToolSpecsUsecase();
      catalog = agent.buildToolCatalog<ResolvedTool>([]);
      when(
        () => conversationRepository.getConversationById(any()),
      ).thenAnswer((_) async => _conversation);
      when(
        () => loadToolSpecs.buildCatalog(
          conversationId: any(named: 'conversationId'),
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer((_) async => catalog);
      usecase = AgentToolCallLoader(
        messageRepository: messageRepository,
        conversationRepository: conversationRepository,
        loadConversationToolSpecsUsecaseForWorkspace: (_) => loadToolSpecs,
        toolResolverService: const ToolResolverService(),
      );
    });

    test('resolves bare agent tool names to app skill tools', () {
      final tool = const ToolResolverService().resolveTool(
        agent.listAgentsToolName,
        agent.buildToolCatalog<ResolvedTool>([]),
      );

      expect(tool?.type, ResolvedToolType.skillNative);
      expect(tool?.skillSlug, agent.agentsSkillSlug);
      expect(tool?.fullName, 'skill__app__agents__list_agents');
    });

    test('resolves generated names to exact catalog targets', () {
      final firstCalculator = ResolvedTool.builtIn(
        tableId: 'calculator-row-1',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      );
      final secondCalculator = ResolvedTool.builtIn(
        tableId: 'calculator-row-2',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      );
      final github = ResolvedTool.mcp(
        tableId: 'github-row',
        toolIdentifier: 'search',
        mcpServerId: 'github-server',
        mcpSlug: 'github',
      );
      final linear = ResolvedTool.mcp(
        tableId: 'linear-row',
        toolIdentifier: 'search',
        mcpServerId: 'linear-server',
        mcpSlug: 'linear',
      );
      final catalog = agent.buildToolCatalog<ResolvedTool>([
        _candidate('calculator', 'calculator-row-1', firstCalculator),
        _candidate('calculator', 'calculator-row-2', secondCalculator),
        _candidate('search', 'github-server', github),
        _candidate('search', 'linear-server', linear),
      ]);
      final [firstName, secondName, githubName, linearName] = catalog.specs
          .map((spec) => spec.name)
          .toList();
      const resolver = ToolResolverService();

      expect(
        resolver.resolveTool(firstName, catalog)?.tableId,
        'calculator-row-1',
      );
      expect(
        resolver.resolveTool(secondName, catalog)?.tableId,
        'calculator-row-2',
      );
      expect(
        resolver.resolveTool(githubName, catalog)?.mcpServerId,
        'github-server',
      );
      expect(
        resolver.resolveTool(linearName, catalog)?.mcpServerId,
        'linear-server',
      );
      expect(
        resolver.resolveTool('built_in_legacy_calculator', catalog)?.tableId,
        'legacy',
      );
    });

    Future<void> returnsPendingResolvedTools() async {
      when(
        () => messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer(
        (_) async => [
          _message(id: 'user-1', isUser: true),
          _message(
            id: 'assistant-1',
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'resolved-tool',
                  name: 'built_in_calc_calculator',
                  argumentsRaw: '{}',
                ),
                MessageToolCallEntity(
                  id: 'missing-tool',
                  name: 'unknown_tool',
                  argumentsRaw: '{}',
                ),
                MessageToolCallEntity(
                  id: 'already-resolved',
                  name: 'built_in_calc_calculator',
                  argumentsRaw: '{}',
                  resultStatus: ToolCallResultStatus.success,
                ),
              ],
            ),
          ),
        ],
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.messageId, 'assistant-1');
      expect(result.toolsToRun.map((tool) => tool.id), ['resolved-tool']);
      expect(result.notFoundToolCallIds, ['missing-tool']);
    }

    test(
      'returns pending resolved tools and not-found ids',
      returnsPendingResolvedTools,
    );

    test('dispatches generated tool name through loaded catalog', () async {
      final target = ResolvedTool.mcp(
        tableId: 'github-row',
        toolIdentifier: 'search',
        mcpServerId: 'github-server',
        mcpSlug: 'github',
      );
      catalog = agent.buildToolCatalog<ResolvedTool>([
        _candidate('search', 'github-server', target),
      ]);
      final generatedName = catalog.specs.single.name;
      when(
        () => messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer(
        (_) async => [
          _message(
            id: 'assistant-1',
            metadata: MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'generated-tool',
                  name: generatedName,
                  argumentsRaw: '{}',
                ),
              ],
            ),
          ),
        ],
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.toolsToRun.single.tool.mcpServerId, 'github-server');
      verify(
        () => loadToolSpecs.buildCatalog(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).called(1);
    });

    test(
      'returns empty result when latest assistant message has no tool calls',
      () async {
        when(
          () => messageRepository.getMessagesByConversation('conversation-2'),
        ).thenAnswer((_) async => [_message(id: 'assistant-2')]);

        final result = await usecase.call(conversationId: 'conversation-2');

        expect(result.messageId, 'assistant-2');
        expect(result.toolsToRun, isEmpty);
        expect(result.notFoundToolCallIds, isEmpty);
        expect(result.hasToolCalls, isFalse);
      },
    );
    test('filters out running tool calls', () async {
      when(
        () => messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer(
        (_) async => [
          _message(id: 'user-1', isUser: true),
          _message(
            id: 'assistant-1',
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'running-tool',
                  name: 'built_in_calc_calculator',
                  argumentsRaw: '{}',
                  resultStatus: ToolCallResultStatus.running,
                ),
              ],
            ),
          ),
        ],
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.hasToolCalls, isFalse);
      expect(result.toolsToRun, isEmpty);
      expect(result.notFoundToolCallIds, isEmpty);
      expect(result.previouslyFailedToolCallIds, isEmpty);
    });

    test('T005: resolves native composite tool ID', () async {
      when(
        () => messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer(
        (_) async => [
          _message(id: 'user-1', isUser: true),
          _message(
            id: 'assistant-1',
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'native-tool-1',
                  name: 'native_ws-tool-123_url',
                  argumentsRaw: '{"input": "https://example.com"}',
                ),
              ],
            ),
          ),
        ],
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.toolsToRun.length, 1);
      expect(result.toolsToRun.first.id, 'native-tool-1');
      expect(result.toolsToRun.first.tool.isNative, isTrue);
      expect(result.toolsToRun.first.tool.tableId, 'ws-tool-123');
      expect(result.toolsToRun.first.tool.toolIdentifier, 'url');
      expect(result.toolsToRun.first.tool.nativeTool, NativeToolType.url);
    });
    test('allows explicit retry after a new user message', () async {
      when(
        () => messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer(
        (_) async => [
          _message(id: 'user-1', isUser: true),
          _message(
            id: 'assistant-1',
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'old-call-1',
                  name: 'native_ws-tool-123_url',
                  argumentsRaw: '{"input": "https://example.com"}',
                  resultStatus: ToolCallResultStatus.notConfigured,
                ),
              ],
            ),
          ),
          _message(id: 'user-2', isUser: true),
          _message(
            id: 'assistant-2',
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'new-call-1',
                  name: 'native_ws-tool-123_url',
                  argumentsRaw: '{"input": "https://other.com"}',
                ),
                MessageToolCallEntity(
                  id: 'new-call-2',
                  name: 'native_ws-tool-123_url',
                  argumentsRaw: '{"input": "https://example.com"}',
                ),
              ],
            ),
          ),
        ],
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.hasToolCalls, isTrue);
      expect(result.toolsToRun.map((tool) => tool.id), [
        'new-call-1',
        'new-call-2',
      ]);
      expect(result.previouslyFailedToolCallIds, isEmpty);
      expect(result.notFoundToolCallIds, isEmpty);
    });
  });
}

agent.ToolCatalogCandidate<ResolvedTool> _candidate(
  String name,
  String sourceId,
  ResolvedTool target,
) => agent.ToolCatalogCandidate.external(
  spec: agent.ToolSpec(name: name, description: '', inputJsonSchema: const {}),
  target: target,
  sourceId: sourceId,
);

final _conversation = ConversationEntity(
  id: 'conversation-1',
  title: 'Conversation',
  workspaceId: 'workspace-1',
  isPinned: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

MessageEntity _message({
  required String id,
  bool isUser = false,
  MessageMetadataEntity? metadata,
}) {
  final now = DateTime(2026);

  return MessageEntity(
    id: id,
    conversationId: 'conversation-1',
    content: 'content',
    messageType: MessageType.text,
    isUser: isUser,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
    metadata: metadata,
  );
}
