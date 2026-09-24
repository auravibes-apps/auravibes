import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudChatGateway;

class _UpdateConversationRequestFake extends Fake
    implements UpdateConversationRequest;

class _CreateConversationRequestFake extends Fake
    implements CreateConversationRequest;

class _ForkConversationRequestFake extends Fake
    implements ForkConversationRequest;

class _DeleteConversationRequestFake extends Fake
    implements DeleteConversationRequest;

class _GetConversationRequestFake extends Fake
    implements GetConversationRequest;

class _StopConversationRequestFake extends Fake
    implements StopConversationRequest;

class _WorkspaceGateway extends Mock implements CloudWorkspaceStateGateway;

class _Client extends Mock implements Client;

class _ConversationEndpoint extends Mock implements EndpointConversation;

const _workspace = CloudWorkspaceRef(
  localWorkspaceId: 'local',
  serverUrl: 'https://example.com/',
  accountId: 'account',
  cloudWorkspaceId: 1,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_CreateConversationRequestFake());
    registerFallbackValue(_UpdateConversationRequestFake());
    registerFallbackValue(_ForkConversationRequestFake());
    registerFallbackValue(_DeleteConversationRequestFake());
    registerFallbackValue(_GetConversationRequestFake());
    registerFallbackValue(_StopConversationRequestFake());
  });

  test('forks a cloud conversation with a fresh target ID', () async {
    final gateway = _Gateway();
    final now = DateTime(2026);
    final conversation = ConversationEntity(
      id: 'conversation-1',
      title: 'Conversation',
      workspaceId: 'workspace-1',
      isPinned: true,
      createdAt: now,
      updatedAt: now,
      revision: 3,
      modelId: 'model-1',
      agentId: 'agent-1',
      parentConversationId: 'parent-1',
    );
    final expected = ConversationSummary(
      id: 'conversation-copy-1',
      title: 'Conversation Copy',
      isPinned: true,
      modelId: 'model-1',
      agentId: 'agent-1',
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );
    final requests = <ForkConversationRequest>[];
    when(() => gateway.forkConversation(captureAny()))
        .thenAnswer((invocation) async {
          requests.add(
            invocation.positionalArguments.single as ForkConversationRequest,
          );

          return expected;
        });

    final actual = await CloudConversationUsecase(gateway).fork(conversation);

    expect(actual, same(expected));
    expect(requests, hasLength(1));
    expect(requests.single.workspaceId, 0);
    expect(requests.single.sourceConversationId, conversation.id);
    expect(requests.single.forkConversationId, isNot(conversation.id));
    expect(requests.single.requestId, requests.single.forkConversationId);
  });

  test(
    'persists and resets cloud reasoning configuration through update path',
    () async {
      final stateGateway = _WorkspaceGateway();
      final client = _Client();
      final endpoint = _ConversationEndpoint();
      when(() => stateGateway.workspace).thenReturn(_workspace);
      when(() => stateGateway.client).thenReturn(client);
      when(() => client.conversation).thenReturn(endpoint);
      final gateway = CloudChatGateway(stateGateway);
      const configuration = ReasoningConfiguration(effort: 'high');
      const toCreate = ConversationToCreate(
        title: 'Reasoning Chat',
        workspaceId: 'workspace-1',
        reasoningConfiguration: configuration,
      );
      final now = DateTime.utc(2026);
      final summary = ConversationSummary(
        id: 'conversation-1',
        title: 'Reasoning Chat',
        isPinned: false,
        reasoningConfigJson: configuration.encode(),
        revision: 1,
        createdAt: now,
        updatedAt: now,
      );
      when(() => endpoint.create(captureAny()))
          .thenAnswer((_) async => summary);

      final _ = await CloudConversationUsecase(gateway).create(toCreate);

      final createRequest =
          verify(() => endpoint.create(captureAny())).captured.single
              as CreateConversationRequest;
      expect(createRequest.reasoningConfigJson, configuration.encode());

      final conversation = ConversationEntity(
        id: summary.id,
        title: summary.title,
        workspaceId: 'workspace-1',
        isPinned: summary.isPinned,
        createdAt: summary.createdAt,
        updatedAt: summary.updatedAt,
        revision: summary.revision,
        reasoningConfiguration: configuration,
      );
      final resetSummary = ConversationSummary(
        id: conversation.id,
        title: conversation.title,
        isPinned: conversation.isPinned,
        revision: 2,
        createdAt: now,
        updatedAt: now,
      );
      when(() => endpoint.update(captureAny()))
          .thenAnswer((_) async => resetSummary);

      final _ = await CloudConversationUsecase(gateway).update(
        conversation,
        const ConversationPatch(clearReasoningConfiguration: true),
      );

      final updateRequest =
          verify(() => endpoint.update(captureAny())).captured.single
              as UpdateConversationRequest;
      expect(updateRequest.reasoningConfigJson, isNull);
      expect(updateRequest.clearReasoningConfig, isTrue);
    },
  );

  test(
    'deletes an active cloud conversation with one server request',
    () async {
      final stateGateway = _WorkspaceGateway();
      final client = _Client();
      final endpoint = _ConversationEndpoint();
      when(() => stateGateway.workspace).thenReturn(_workspace);
      when(() => stateGateway.client).thenReturn(client);
      when(() => client.conversation).thenReturn(endpoint);
      final gateway = CloudChatGateway(stateGateway);
      final now = DateTime.utc(2026);
      final conversation = ConversationEntity(
        id: 'conversation-1',
        title: 'Conversation',
        workspaceId: 'workspace-1',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
        revision: 3,
      );
      when(() => endpoint.delete(any()))
          .thenAnswer((_) => Future<void>.value());

      await CloudConversationUsecase(gateway).delete(conversation);

      verify(() => endpoint.delete(any())).called(1);
      final _ = verifyNever(() => endpoint.getConversationSnapshot(any()));
      final _ = verifyNever(() => endpoint.stopConversation(any()));
    },
  );

  test('retries a stale cloud model update with the latest revision', () async {
    final gateway = _Gateway();
    final now = DateTime(2026);
    final conversation = ConversationEntity(
      id: 'conversation-1',
      title: 'Conversation',
      workspaceId: 'workspace-1',
      isPinned: false,
      createdAt: now,
      updatedAt: now,
      revision: 1,
      modelId: 'deleted-model',
    );
    final refreshed = ConversationSummary(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      modelId: 'deleted-model',
      revision: 2,
      createdAt: now,
      updatedAt: now,
    );
    final updated = ConversationSummary(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      modelId: 'replacement-model',
      revision: 3,
      createdAt: now,
      updatedAt: now,
    );
    final requests = <UpdateConversationRequest>[];

    when(() => gateway.updateConversation(captureAny()))
        .thenAnswer((invocation) async {
          requests.add(
            invocation.positionalArguments.single as UpdateConversationRequest,
          );
          if (requests.length == 1) {
            throw CloudAppException(
              localizationKey: 'cloud_errors.conflict',
              context: .conversation,
              code: ConversationErrorCode.staleRevision.name,
            );
          }

          return updated;
        });
    when(() => gateway.getConversation(conversation.id))
        .thenAnswer((_) async => refreshed);

    final actual = await CloudConversationUsecase(gateway)
        .updateModel(conversation, 'replacement-model');

    expect(actual, same(updated));
    expect(requests, hasLength(2));
    expect(requests.firstOrNull?.expectedRevision, 1);
    expect(requests.lastOrNull?.expectedRevision, 2);
    expect(requests.lastOrNull?.modelId, 'replacement-model');
    verify(() => gateway.getConversation(conversation.id)).called(1);
  });
}
