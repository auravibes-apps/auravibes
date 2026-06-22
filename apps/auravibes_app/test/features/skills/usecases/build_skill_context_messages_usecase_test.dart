import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_context_messages_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('BuildSkillContextMessagesUsecase', () {
    test('escapes XML special characters in skill title and content', () async {
      final listUseCase = _MockListAvailableSkillsUsecase();
      final usecase = BuildSkillContextMessagesUsecase(listUseCase);
      when(
        () => listUseCase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer(
        (_) async => [
          const AvailableSkill(
            id: '1',
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            content: '<x&y"z\'w>',
            source: SkillSource.user,
            kind: SkillKind.template,
          ),
        ],
      );

      final messages = await usecase.call(
        conversationId: 'c',
        workspaceId: 'w',
      );

      expect(
        messages.single.content,
        '<skill><name>&lt;a&amp;b&quot;c&#39;d&gt;</name>'
        '<content>&lt;x&amp;y&quot;z&#39;w&gt;</content></skill>',
      );
    });
  });
}

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase {}
