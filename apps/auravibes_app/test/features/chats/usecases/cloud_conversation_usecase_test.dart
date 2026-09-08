import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudChatGateway;

class _UpdateConversationRequestFake extends Fake
    implements UpdateConversationRequest;

void main() {
  setUpAll(() => registerFallbackValue(_UpdateConversationRequestFake()));

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
              context: CloudOperationContext.conversation,
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
