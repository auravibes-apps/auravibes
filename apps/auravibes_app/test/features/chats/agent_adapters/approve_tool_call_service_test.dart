import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/approve_tool_call_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_effective_tool_approval_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('AppApproveToolCallDataProvider', () {
    var messageRepository = MockMessageRepository();
    var conversationRepository = MockConversationRepository();
    var conversationToolsRepository = MockConversationToolsRepository();
    var resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
    var loadToolSpecs = MockLoadConversationToolSpecsUsecase();
    var agentToolResumeService = MockAgentToolResumeService();
    var effectiveToolApproval = _FakeResolveEffectiveToolApprovalUsecase();
    var provider = AppApproveToolCallDataProvider(
      messageRepository: messageRepository,
      conversationRepository: conversationRepository,
      toolResolverService: const ToolResolverService(),
      agentToolResumeService: agentToolResumeService,
      runResolvedToolUsecase: .new(
        agentCancellationRuntime: AgentCancellationRuntime(),
        mcpToolCaller: ({
          required mcpServerId,
          required toolIdentifier,
          required arguments,
        }) => Future.value(''),
      ),
      agentCancellationRuntime: .new(),
      onToolCallChanged: _noop,
      conversationToolsRepository: conversationToolsRepository,
      resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
      loadConversationToolSpecsUsecase: loadToolSpecs,
      resolveEffectiveToolApprovalUsecase: effectiveToolApproval,
    );

    const messageId = 'message-1';
    const conversationId = 'conversation-1';
    const workspaceId = 'workspace-1';

    final tool = ResolvedTool.builtIn(
      tableId: 'calculator',
      toolIdentifier: 'calculator',
      tooltype: .calculator,
    );
    final conversation = ConversationEntity(
      id: conversationId,
      title: 'Conversation',
      workspaceId: workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    final message = MessageEntity(
      id: messageId,
      conversationId: conversationId,
      content: 'assistant',
      messageType: .text,
      isUser: false,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      metadata: const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'tool-1',
            name: 'calculator',
            argumentsRaw: '{"input":"1+1"}',
          ),
        ],
      ),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      conversationRepository = MockConversationRepository();
      conversationToolsRepository = MockConversationToolsRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      loadToolSpecs = MockLoadConversationToolSpecsUsecase();
      agentToolResumeService = MockAgentToolResumeService();
      effectiveToolApproval = _FakeResolveEffectiveToolApprovalUsecase();
      provider = AppApproveToolCallDataProvider(
        messageRepository: messageRepository,
        conversationRepository: conversationRepository,
        toolResolverService: const ToolResolverService(),
        agentToolResumeService: agentToolResumeService,
        runResolvedToolUsecase: .new(
          agentCancellationRuntime: AgentCancellationRuntime(),
          mcpToolCaller: ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) => Future.value(''),
        ),
        agentCancellationRuntime: .new(),
        onToolCallChanged: _noop,
        conversationToolsRepository: conversationToolsRepository,
        resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
        loadConversationToolSpecsUsecase: loadToolSpecs,
        resolveEffectiveToolApprovalUsecase: effectiveToolApproval,
      );
    });

    test('loads approvable tool call from message metadata', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);

      final result = await provider.loadToolCall(
        messageId: messageId,
        toolCallId: 'tool-1',
        conversationId: conversationId,
      );

      expect(result?.conversationId, conversationId);
      expect(result?.name, 'calculator');
      expect(result?.argumentsRaw, '{"input":"1+1"}');
    });

    test('resolves approval through catalog model name', () async {
      final target = ResolvedTool.mcp(
        tableId: 'github-row',
        toolIdentifier: 'search',
        mcpServerId: 'github-server',
        mcpSlug: 'github',
      );
      final catalog = agent.buildToolCatalog<ResolvedTool>([
        agent.ToolCatalogCandidate.external(
          spec: .new(name: 'search', description: '', inputJsonSchema: {}),
          target: target,
          sourceId: 'github-server',
        ),
      ]);
      final generatedName = catalog.specs.single.name;
      final generatedMessage = message.copyWith(
        metadata: MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: generatedName,
              argumentsRaw: '{}',
            ),
          ],
        ),
      );
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => generatedMessage);
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer((_) async => conversation);
      when(
        () => loadToolSpecs.buildCatalog(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
      ).thenAnswer((_) async => catalog);

      final loaded = await provider.loadToolCall(
        messageId: messageId,
        toolCallId: 'tool-1',
        conversationId: conversationId,
      );

      expect(loaded?.name, generatedName);
      expect(
        (await provider.resolveTool(
          conversationId: conversationId,
          toolName: generatedName,
          argumentsRaw: '{}',
        ))?.mcpServerId,
        'github-server',
      );
    });

    test('returns null when message or tool call is missing', () async {
      when(() => messageRepository.getMessageById('missing'))
          .thenAnswer((_) async => null);
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);

      expect(
        await provider.loadToolCall(
          messageId: 'missing',
          toolCallId: 'tool-1',
          conversationId: conversationId,
        ),
        isNull,
      );
      expect(
        await provider.loadToolCall(
          messageId: messageId,
          toolCallId: 'missing-tool',
          conversationId: conversationId,
        ),
        isNull,
      );
    });

    test(
      'persists conversation approval for exact nested skill target',
      () async {
        const argumentsRaw =
            '{"skill":"agents","tool":"list_agents","args":{},'
            '"revision":"rev-1"}';
        final expected = ResolvedTool.skillCommand(
          commandName: agent.callSkillToolName,
          target: agent.AgentResolvedToolName.skillNative(
            tableId: agent.listAgentsToolName,
            skillSlug: agent.agentsSkillSlug,
            toolIdentifier: agent.listAgentsToolName,
          ),
        );
        effectiveToolApproval.effectiveTool = expected;
        final catalog = agent.buildToolCatalog<ResolvedTool>([
          agent.ToolCatalogCandidate.reserved(
            spec: .new(
              name: agent.callSkillToolName,
              description: 'Call a loaded skill tool.',
              inputJsonSchema: const {'type': 'object'},
            ),
            target: ResolvedTool.skillCommand(
              commandName: agent.callSkillToolName,
            ),
          ),
        ]);
        final nestedMessage = message.copyWith(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-1',
                name: agent.callSkillToolName,
                argumentsRaw: argumentsRaw,
              ),
            ],
          ),
        );
        when(() => messageRepository.getMessageById(messageId))
            .thenAnswer((_) async => nestedMessage);
        when(() => conversationRepository.getConversationById(conversationId))
            .thenAnswer((_) async => conversation);
        when(
          () => loadToolSpecs.buildCatalog(
            conversationId: conversationId,
            workspaceId: workspaceId,
          ),
        ).thenAnswer((_) async => catalog);
        when(
          () => resolveToolApprovalDecision.resolvePermissionTableId(
            conversationId: conversationId,
            workspaceId: workspaceId,
            resolvedTool: expected,
          ),
        ).thenAnswer((_) async => 'agents-list-permission');
        when(
          () => conversationToolsRepository.setConversationToolPermission(
            conversationId,
            'agents-list-permission',
            permissionMode: .alwaysAllow,
          ),
        ).thenAnswer((_) async => true);

        final resolved = await provider.resolveTool(
          conversationId: conversationId,
          toolName: agent.callSkillToolName,
          argumentsRaw: argumentsRaw,
        );

        expect(resolved, same(expected));
        expect(resolved?.fullName, 'skill__app_native__agents__list_agents');
        if (resolved == null) fail('Expected nested skill target.');
        await provider.grantToolForConversation(
          conversationId: conversationId,
          tool: resolved,
        );

        verify(
          () => conversationToolsRepository.setConversationToolPermission(
            conversationId,
            'agents-list-permission',
            permissionMode: .alwaysAllow,
          ),
        ).called(1);
      },
    );

    test('grants resolved tool permission for the conversation', () async {
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer(
            (_) async => ConversationEntity(
              id: conversationId,
              title: 'Conversation',
              workspaceId: workspaceId,
              isPinned: false,
              createdAt: .new(2026),
              updatedAt: .new(2026),
            ),
          );
      when(
        () => resolveToolApprovalDecision.resolvePermissionTableId(
          conversationId: conversationId,
          workspaceId: workspaceId,
          resolvedTool: tool,
        ),
      ).thenAnswer((_) async => 'permission-table-1');
      when(
        () => conversationToolsRepository.setConversationToolPermission(
          conversationId,
          'permission-table-1',
          permissionMode: .alwaysAllow,
        ),
      ).thenAnswer((_) async => true);

      await expectLater(
        provider.grantToolForConversation(
          conversationId: conversationId,
          tool: tool,
        ),
        completes,
      );

      verify(
        () => conversationToolsRepository.setConversationToolPermission(
          conversationId,
          'permission-table-1',
          permissionMode: .alwaysAllow,
        ),
      ).called(1);
    });

    test('skips permission grant when conversation is missing', () async {
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer((_) async => null);

      await expectLater(
        provider.grantToolForConversation(
          conversationId: conversationId,
          tool: tool,
        ),
        completes,
      );

      verifyNever(
        () => conversationToolsRepository.setConversationToolPermission(
          conversationId,
          'permission-table-1',
          permissionMode: .alwaysAllow,
        ),
      ).called(0);
    });

    test('updates tool call result status in message metadata', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);
      when(
        () => messageRepository.patchMessage(
          messageId,
          any(),
          conversationId: conversationId,
        ),
      ).thenAnswer((_) async => message);

      const cases = {
        agent.AgentToolResultStatus.success: ToolCallResultStatus.success,
        agent.AgentToolResultStatus.toolNotFound:
            ToolCallResultStatus.toolNotFound,
        agent.AgentToolResultStatus.executionError:
            ToolCallResultStatus.executionError,
        agent.AgentToolResultStatus.disabledInConversation:
            ToolCallResultStatus.disabledInConversation,
        agent.AgentToolResultStatus.disabledByAgent:
            ToolCallResultStatus.disabledByAgent,
        agent.AgentToolResultStatus.disabledInWorkspace:
            ToolCallResultStatus.disabledInWorkspace,
        agent.AgentToolResultStatus.notConfigured:
            ToolCallResultStatus.notConfigured,
        agent.AgentToolResultStatus.stoppedByUser:
            ToolCallResultStatus.stoppedByUser,
      };

      for (final entry in cases.entries) {
        await provider.updateToolCallResult((
          messageId: messageId,
          toolCallId: 'tool-1',
          conversationId: conversationId,
          resultStatus: entry.key,
          responseRaw: 'response',
        ));
      }

      final patches = verify(
        () => messageRepository.patchMessage(
          messageId,
          captureAny(),
          conversationId: conversationId,
        ),
      ).captured.whereType<MessagePatch>().toList();
      expect(
        patches.map((patch) => patch.metadata?.toolCalls.single.resultStatus),
        cases.values,
      );
      expect(
        patches.map((patch) => patch.metadata?.toolCalls.single.responseRaw),
        everyElement('response'),
      );
      expect(
        patches.map((patch) => patch.status),
        everyElement(MessageStatus.sent),
      );
    });

    test('marks tool call running in message metadata', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);
      when(
        () => messageRepository.patchMessage(
          messageId,
          any(),
          conversationId: conversationId,
        ),
      ).thenAnswer((_) async => message);

      await provider.markToolCallRunning(
        messageId: messageId,
        toolCallId: 'tool-1',
        conversationId: conversationId,
      );

      final patch =
          verify(
                () => messageRepository.patchMessage(
                  messageId,
                  captureAny(),
                  conversationId: conversationId,
                ),
              ).captured.single
              as MessagePatch;
      expect(
        patch.metadata?.toolCalls.single.resultStatus,
        ToolCallResultStatus.running,
      );
      expect(patch.metadata?.toolCalls.single.responseRaw, isNull);
      expect(patch.status, isNull);
    });

    test('resumes conversation through resume service', () async {
      when(() => agentToolResumeService.call(messageId: messageId))
          .thenAnswer((_) => Future<void>.value());

      await expectLater(
        provider.resumeConversationIfReady(
          messageId: messageId,
          conversationId: conversationId,
        ),
        completes,
      );

      verify(() => agentToolResumeService.call(messageId: messageId)).called(1);
    });
  });
}

var _noopCalls = 0;

void _noop() => _noopCalls += 1;

class _FakeResolveEffectiveToolApprovalUsecase
    implements ResolveEffectiveToolApprovalUsecase {
  ResolvedTool? effectiveTool;

  @override
  Future<ResolvedTool?> call({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool requestedTool,
    required String argumentsRaw,
  }) async {
    if (!requestedTool.isSkillCommand ||
        requestedTool.toolIdentifier != agent.callSkillToolName) {
      return requestedTool;
    }

    return effectiveTool;
  }

  @override
  Future<agent.AgentResolvedToolName?> resolveTarget({
    required String conversationId,
    required String workspaceId,
    required agent.SkillCommandTarget command,
  }) async => effectiveTool?.target;
}
