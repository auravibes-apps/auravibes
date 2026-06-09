import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:riverpod/riverpod.dart';

const skillContextMetadataKind = 'skill_context';

class BuildSkillContextMessagesUsecase {
  const BuildSkillContextMessagesUsecase(this._listAvailableSkillsUsecase);

  final ListAvailableSkillsUsecase _listAvailableSkillsUsecase;

  Future<List<ChatMessage>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );

    return [
      for (final skill in loadedSkills)
        ChatMessage(
          role: ChatMessageRole.user,
          content: _skillXml(skill),
          metadata: const {'kind': skillContextMetadataKind},
        ),
    ];
  }

  String _skillXml(AvailableSkill skill) {
    return '<skill><name>${_escapeXml(skill.title)}</name>'
        '<content>${_escapeXml(skill.content)}</content></skill>';
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

final buildSkillContextMessagesUsecaseProvider =
    Provider<BuildSkillContextMessagesUsecase>((ref) {
      return BuildSkillContextMessagesUsecase(
        ref.watch(listAvailableSkillsUsecaseProvider),
      );
    });
