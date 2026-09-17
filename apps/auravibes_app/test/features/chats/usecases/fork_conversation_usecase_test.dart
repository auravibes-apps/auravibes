import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/usecases/fork_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository extends Fake implements ConversationRepository {
  String? sourceId;
  String? throughMessageId;

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) async {
    sourceId = sourceConversationId;
    this.throughMessageId = throughMessageId;

    return .new(
      id: 'fork',
      title: 'Source Fork',
      workspaceId: 'workspace',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      forkSourceConversationId: sourceConversationId,
      forkSourceTitle: 'Source',
      forkThroughMessageId: throughMessageId,
      forkMaterializedAt: DateTime.utc(2026),
    );
  }
}

void main() {
  test('forwards source and selected boundary to the repository', () async {
    final repository = _Repository();
    final source = ConversationEntity(
      id: 'source',
      title: 'Source',
      workspaceId: 'workspace',
      isPinned: true,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );

    final fork = await ForkConversationUsecase(repository)
        .call(source, throughMessageId: 'assistant-1');

    expect(repository.sourceId, 'source');
    expect(repository.throughMessageId, 'assistant-1');
    expect(fork.isFork, isTrue);
    expect(fork.isMaterialized, isTrue);
    expect(fork.isForkMaterialized, isTrue);
  });
}
