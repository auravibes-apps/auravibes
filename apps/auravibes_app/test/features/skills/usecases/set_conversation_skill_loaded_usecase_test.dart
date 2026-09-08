import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/set_conversation_skill_loaded_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ConversationSkillsRepository;

class _Cloud extends Mock implements CloudSkillStore;

void main() {
  for (final isAppSkill in [false, true]) {
    for (final isLoaded in [false, true]) {
      test('local app=$isAppSkill loaded=$isLoaded', () async {
        final repository = _Repository();
        final write = isAppSkill
            ? repository.setAppSkillLoaded
            : repository.setWorkspaceSkillLoaded;
        when(() => write('conversation', 'skill', isLoaded: isLoaded))
            .thenAnswer(
              (_) async => ConversationSkillEntity(
                id: 'selection',
                conversationId: 'conversation',
                isLoaded: isLoaded,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            );

        await SetConversationSkillLoadedUsecase(repository, null).call(
          'conversation',
          'skill',
          isLoaded: isLoaded,
          isAppSkill: isAppSkill,
        );

        verify(() => write('conversation', 'skill', isLoaded: isLoaded))
            .called(1);
        verifyNoMoreInteractions(repository);
      });

      test('cloud app=$isAppSkill loaded=$isLoaded', () async {
        final repository = _Repository();
        final cloud = _Cloud();
        when(
          () => cloud.setConversationSkill(
            'conversation',
            'skill',
            selected: isLoaded,
            isAppSkill: isAppSkill,
          ),
        ).thenAnswer((_) => Future<void>.value());

        await SetConversationSkillLoadedUsecase(repository, cloud).call(
          'conversation',
          'skill',
          isLoaded: isLoaded,
          isAppSkill: isAppSkill,
        );

        verify(
          () => cloud.setConversationSkill(
            'conversation',
            'skill',
            selected: isLoaded,
            isAppSkill: isAppSkill,
          ),
        ).called(1);
        verifyNoMoreInteractions(cloud);
        verifyZeroInteractions(repository);
      });
    }
  }

  test('missing store retains error', () async {
    await expectLater(
      const SetConversationSkillLoadedUsecase(
        null,
        null,
      ).call('conversation', 'skill', isLoaded: true, isAppSkill: false),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Conversation skill store is unavailable',
        ),
      ),
    );
  });

  test('cloud failure propagates without local fallback', () async {
    final repository = _Repository();
    final cloud = _Cloud();
    final failure = StateError('offline');
    when(
      () => cloud.setConversationSkill(
        'conversation',
        'skill',
        selected: false,
        isAppSkill: true,
      ),
    ).thenAnswer((_) => Future<void>.error(failure));

    await expectLater(
      SetConversationSkillLoadedUsecase(
        repository,
        cloud,
      ).call('conversation', 'skill', isLoaded: false, isAppSkill: true),
      throwsA(same(failure)),
    );
    verifyZeroInteractions(repository);
  });
}
