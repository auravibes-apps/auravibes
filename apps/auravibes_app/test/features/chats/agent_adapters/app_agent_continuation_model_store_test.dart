import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_continuation_adapter.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/agent_harness/build_skill_context_messages_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ConversationRepository extends Mock implements ConversationRepository {}

class _ModelSelectionStore extends Mock implements ModelSelectionStore {}

class _ApiModelRepository extends Mock implements ApiModelRepository {}

class _SelectPromptMessages extends Mock
    implements SelectPromptMessagesUsecase {}

class _BuildSkillContext extends Mock
    implements BuildSkillContextMessagesService {}

class _LoadTools extends Mock implements LoadConversationToolSpecsUsecase {}

void main() {
  test(
    'continuation resolves model store after loading conversation workspace',
    () async {
      final conversations = _ConversationRepository();
      final selections = _ModelSelectionStore();
      when(() => conversations.getConversationById('conversation')).thenAnswer(
        (_) async => ConversationEntity(
          id: 'conversation',
          title: 'title',
          workspaceId: 'workspace',
          isPinned: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          modelId: 'selection',
        ),
      );
      when(() => selections.getById('selection')).thenAnswer((_) async => null);
      final resolvedWorkspaces = <String>[];
      final adapter = AppAgentContinuationAdapter(
        conversationRepository: conversations,
        modelSelectionStore: (workspaceId) async {
          resolvedWorkspaces.add(workspaceId);

          return selections;
        },
        apiModelRepository: _ApiModelRepository(),
        selectPromptMessagesUsecase: _SelectPromptMessages(),
        buildSkillContextMessagesUsecase: _BuildSkillContext(),
        loadConversationToolSpecsUsecase: _LoadTools(),
      );

      expect(await adapter.loadConversation('conversation'), isNotNull);
      expect(await adapter.loadSelectedModel('selection'), isNull);

      expect(resolvedWorkspaces, ['workspace']);
      verify(() => selections.getById('selection')).called(1);
    },
  );
}
