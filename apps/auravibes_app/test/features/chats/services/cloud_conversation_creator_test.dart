import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_conversation_creator.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CloudConversationUsecase extends Mock
    implements CloudConversationUsecase;

void main() {
  test('maps a cloud conversation into the app entity', () async {
    final usecase = _CloudConversationUsecase();
    const value = ConversationToCreate(
      title: 'New Conversation',
      workspaceId: 'workspace-1',
      modelId: 'model-1',
      agentId: 'agent-1',
      parentConversationId: 'parent-1',
      isPinned: true,
    );
    final now = DateTime.utc(2026);
    final summary = ConversationSummary(
      id: 'conversation-1',
      title: 'Created',
      isPinned: true,
      modelId: 'model-1',
      agentId: 'agent-1',
      parentConversationId: 'parent-1',
      revision: 4,
      createdAt: now,
      updatedAt: now,
    );
    when(() => usecase.create(value)).thenAnswer((_) async => summary);

    final conversation = await CloudConversationCreator(
      load: () async => usecase,
    ).call(value);

    expect(
      conversation,
      ConversationEntity(
        id: 'conversation-1',
        title: 'Created',
        workspaceId: 'workspace-1',
        isPinned: true,
        createdAt: now,
        updatedAt: now,
        revision: 4,
        modelId: 'model-1',
        agentId: 'agent-1',
        parentConversationId: 'parent-1',
      ),
    );
    final _ = verify(() => usecase.create(value)).called(1);
  });

  test('reports an unavailable cloud workspace', () async {
    final creator = CloudConversationCreator(load: () async => null);

    final _ = await expectLater(
      creator.call(
        const ConversationToCreate(
          title: 'New Conversation',
          workspaceId: 'workspace-1',
        ),
      ),
      throwsStateError,
    );
  });
}
