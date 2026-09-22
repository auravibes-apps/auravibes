import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/tool_call_approval_batch_item.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/cloud_tool_decision_item.dart';
import 'package:auravibes_app/features/chats/usecases/batch_tool_approval_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

class _MockCloudTurnUsecase extends Mock implements CloudTurnUsecase;

class _MockResolvedToolService extends Mock implements ResolvedToolService;

void main() {
  setUpAll(() {
    registerTestFallbackValues();
    registerFallbackValue(<ToolCallApprovalBatchItem>[]);
    registerFallbackValue(<ToolCallExecutionBatchUpdate>[]);
    registerFallbackValue(<CloudToolDecisionItem>[]);
  });

  var messageRepository = MockMessageRepository();
  var conversationRepository = MockConversationRepository();
  var resumeService = MockAgentToolResumeService();
  var resolvedToolService = _MockResolvedToolService();
  var loadToolSpecs = MockLoadConversationToolSpecsUsecase();
  var changeCount = 0;

  setUp(() {
    messageRepository = MockMessageRepository();
    conversationRepository = MockConversationRepository();
    resumeService = MockAgentToolResumeService();
    resolvedToolService = _MockResolvedToolService();
    loadToolSpecs = MockLoadConversationToolSpecsUsecase();
    changeCount = 0;

    when(() => resumeService.call(messageId: any(named: 'messageId')))
        .thenAnswer((_) => Future<void>.value());
  });

  BatchToolApprovalUsecase createUsecase({
    CloudTurnResolver? resolveCloudTurn,
  }) => BatchToolApprovalUsecase(
    messageRepository: messageRepository,
    conversationRepository: conversationRepository,
    agentToolResumeService: resumeService,
    runResolvedTool: resolvedToolService,
    cancellationRuntime: .new(),
    toolResolver: const ToolResolverService(),
    loadToolSpecs: (_) => loadToolSpecs,
    effectiveToolApproval: null,
    resolveCloudTurn: resolveCloudTurn ?? (_) async => null,
    onToolCallChanged: () => changeCount++,
  );

  test(
    'returns empty result without a repository call for no approvals',
    () async {
      final result = await createUsecase().approveOnce(
        rootConversationId: 'root',
        workspaceId: 'workspace',
        pendingCalls: const [],
      );

      expect(result.claimed, isEmpty);
      expect(result.alreadyHandled, isEmpty);
      expect(result.conflicted, isEmpty);
      final _ = verifyNever(
        () => messageRepository.claimToolCallBatch(any(), approve: true),
      );
    },
  );

  test(
    'skips unique local calls and resumes each source message once',
    () async {
      final rootCall = _pending(toolCallId: 'root-call');
      final rootSecondCall = _pending(
        toolCallId: 'root-second-call',
        messageId: rootCall.messageId,
      );
      final childCall = _pending(
        toolCallId: 'child-call',
        messageId: 'child-message',
        sourceConversationId: 'child',
      );
      final claims = [
        _claim(rootCall, .claimed),
        _claim(rootSecondCall, .conflicted),
        _claim(childCall, .claimed),
      ];
      when(() => messageRepository.claimToolCallBatch(any(), approve: false))
          .thenAnswer((_) async => claims);

      final result = await createUsecase().skip(
        rootConversationId: 'root',
        workspaceId: 'workspace',
        pendingCalls: [rootCall, rootCall, rootSecondCall, childCall],
      );

      expect(result.claimed, hasLength(2));
      expect(result.alreadyHandled, isEmpty);
      expect(result.conflicted, hasLength(1));
      expect(changeCount, 1);
      verify(() => messageRepository.claimToolCallBatch(any(), approve: false))
          .called(1);
      verify(() => resumeService.call(messageId: 'msg-1')).called(1);
      verify(() => resumeService.call(messageId: 'child-message')).called(1);
      final _ = verifyNever(
        () => messageRepository.persistToolCallBatchResults(any()),
      );
    },
  );

  test('does not resume when local batch claims nothing', () async {
    when(() => messageRepository.claimToolCallBatch(any(), approve: false))
        .thenAnswer((_) async => const []);

    final result = await createUsecase().skip(
      rootConversationId: 'root',
      workspaceId: 'workspace',
      pendingCalls: [_pending()],
    );

    expect(result.claimed, isEmpty);
    expect(changeCount, 1);
    final _ = verifyNever(
      () => resumeService.call(messageId: any(named: 'messageId')),
    );
  });

  test(
    'persists resolution failures and resumes an approved local call',
    () async {
      final call = _pending(toolCallId: 'failed-call');
      final claim = _claim(call, .claimed);
      when(() => messageRepository.claimToolCallBatch(any(), approve: true))
          .thenAnswer((_) async => [claim]);
      when(() => conversationRepository.getConversationById(any()))
          .thenAnswer((_) async => null);
      when(
        () => loadToolSpecs.buildCatalog(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
        ),
      ).thenThrow(StateError('catalog unavailable'));
      when(() => messageRepository.persistToolCallBatchResults(any()))
          .thenAnswer((_) => Future<void>.value());

      final result = await createUsecase().approveOnce(
        rootConversationId: 'root',
        workspaceId: 'workspace',
        pendingCalls: [call],
      );

      expect(result.claimed, hasLength(1));
      expect(changeCount, 2);
      final updates =
          verify(
                () =>
                    messageRepository.persistToolCallBatchResults(captureAny()),
              ).captured.single
              as Iterable<ToolCallExecutionBatchUpdate>;
      expect(updates.single.resultStatus, ToolCallResultStatus.executionError);
      verify(() => resumeService.call(messageId: call.messageId)).called(1);
    },
  );

  test(
    'resolves and executes approved local calls through the batch runner',
    () async {
      final call = _pending(
        toolCallId: 'success-call',
        sourceConversationId: 'child',
      );
      final claim = _claim(call, .claimed);
      final resolved = ResolvedTool.skillCommand(commandName: 'tool');
      final catalog = agent.buildToolCatalog<ResolvedTool>([
        agent.ToolCatalogCandidate.reserved(
          spec: .new(
            name: 'tool',
            description: 'test tool',
            inputJsonSchema: const {},
          ),
          target: resolved,
        ),
      ]);
      when(() => messageRepository.claimToolCallBatch(any(), approve: true))
          .thenAnswer((_) async => [claim]);
      when(() => conversationRepository.getConversationById('child'))
          .thenAnswer((_) async => _conversation('child', 'child-workspace'));
      when(
        () => loadToolSpecs.buildCatalog(
          conversationId: 'child',
          workspaceId: 'child-workspace',
        ),
      ).thenAnswer((_) async => catalog);
      when(
        () => resolvedToolService.call(
          conversationId: 'child',
          tool: resolved,
          arguments: {'input': 'value'},
        ),
      ).thenAnswer((_) async => 'done');
      when(() => messageRepository.persistToolCallBatchResults(any()))
          .thenAnswer((_) => Future<void>.value());

      final result = await createUsecase().approveOnce(
        rootConversationId: 'root',
        workspaceId: 'workspace',
        pendingCalls: [call],
      );

      expect(result.claimed, hasLength(1));
      expect(changeCount, 2);
      final updates =
          verify(
                () =>
                    messageRepository.persistToolCallBatchResults(captureAny()),
              ).captured.single
              as Iterable<ToolCallExecutionBatchUpdate>;
      expect(updates.single.resultStatus, ToolCallResultStatus.success);
      expect(updates.single.responseRaw, 'done');
      verify(() => resumeService.call(messageId: call.messageId)).called(1);
    },
  );

  test('maps cloud approval results and preserves source identities', () async {
    final cloud = _MockCloudTurnUsecase();
    final calls = [
      _pending(
        toolCallId: 'child-call',
        sourceConversationId: 'child',
        argumentsDigest: 'child-digest',
        turnId: 'child-turn',
        turnRevision: 4,
      ),
      _pending(
        toolCallId: 'root-call',
        argumentsDigest: 'root-digest',
        turnId: 'root-turn',
        turnRevision: 5,
      ),
    ];
    when(() => cloud.decideBatch(any(), approved: true)).thenAnswer(
      (_) async => SubmitToolDecisionBatchResult(
        accepted: ['child:child-turn:child-call'],
        alreadyHandled: ['root:root-turn:root-call'],
        conflicted: ['missing:turn:call'],
      ),
    );
    when(() => cloud.decideBatch(any(), approved: false)).thenAnswer(
      (_) async => SubmitToolDecisionBatchResult(
        accepted: [],
        alreadyHandled: [],
        conflicted: ['child:child-turn:child-call'],
      ),
    );
    final usecase = createUsecase(resolveCloudTurn: (_) async => cloud);

    final approved = await usecase.approveOnce(
      rootConversationId: 'root',
      workspaceId: 'workspace',
      pendingCalls: calls,
    );
    final skipped = await usecase.skip(
      rootConversationId: 'root',
      workspaceId: 'workspace',
      pendingCalls: calls,
    );

    expect(approved.claimed.single.conversationId, 'child');
    expect(approved.alreadyHandled.single.conversationId, 'root');
    expect(approved.conflicted, isEmpty);
    expect(skipped.conflicted.single.conversationId, 'child');
    final approvedItems =
        verify(() => cloud.decideBatch(captureAny(), approved: true))
                .captured
                .single
            as List<CloudToolDecisionItem>;
    final skippedItems =
        verify(() => cloud.decideBatch(captureAny(), approved: false))
                .captured
                .single
            as List<CloudToolDecisionItem>;
    expect(approvedItems.map((item) => item.conversationId), ['child', 'root']);
    expect(
      approvedItems.every((item) => item.editedArgumentsJson != null),
      isTrue,
    );
    expect(
      skippedItems.every((item) => item.editedArgumentsJson == null),
      isTrue,
    );
    expect(changeCount, 0);
  });

  test('rejects mixed local and cloud calls', () {
    final cloudCall = _pending(
      toolCallId: 'cloud-call',
      argumentsDigest: 'digest',
      turnId: 'turn',
      turnRevision: 1,
    );

    expect(
      () => createUsecase().approveOnce(
        rootConversationId: 'root',
        workspaceId: 'workspace',
        pendingCalls: [_pending(), cloudCall],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('fails cloud approval when cloud turn is unavailable', () {
    final cloudCall = _pending(
      toolCallId: 'cloud-call',
      argumentsDigest: 'digest',
      turnId: 'turn',
      turnRevision: 1,
    );

    expect(
      () => createUsecase().approveOnce(
        rootConversationId: 'root',
        workspaceId: 'workspace',
        pendingCalls: [cloudCall],
      ),
      throwsA(isA<StateError>()),
    );
  });
}

PendingToolCall _pending({
  String toolCallId = 'tool-call',
  String messageId = 'msg-1',
  String sourceConversationId = '',
  String toolName = 'tool',
  String argumentsRaw = '{"input":"value"}',
  String? argumentsDigest,
  String? turnId,
  int? turnRevision,
}) => PendingToolCall(
  toolCall: .new(
    id: toolCallId,
    name: toolName,
    argumentsRaw: argumentsRaw,
    argumentsDigest: argumentsDigest,
    turnId: turnId,
    turnRevision: turnRevision,
  ),
  messageId: messageId,
  sourceConversationId: sourceConversationId,
);

ToolCallApprovalBatchClaim _claim(
  PendingToolCall call,
  ToolCallApprovalBatchClaimStatus status,
) => ToolCallApprovalBatchClaim(
  item: .new(
    conversationId: call.sourceConversationId.isEmpty
        ? 'root'
        : call.sourceConversationId,
    messageId: call.messageId,
    toolCallId: call.toolCall.id,
    argumentsDigest: call.toolCall.argumentsDigest,
    turnRevision: call.toolCall.turnRevision,
  ),
  status: status,
  toolCall: call.toolCall,
);

ConversationEntity _conversation(String id, String workspaceId) =>
    ConversationEntity(
      id: id,
      title: id,
      workspaceId: workspaceId,
      isPinned: false,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );
