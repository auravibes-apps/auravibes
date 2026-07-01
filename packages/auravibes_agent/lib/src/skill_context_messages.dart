import 'dart:convert';

import 'package:auravibes_agent/src/prompt_messages.dart';

const _xmlEscape = HtmlEscape();

class AgentSkill {
  const AgentSkill({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

class BuildSkillContextMessages {
  const BuildSkillContextMessages();

  List<AgentChatMessage> call(List<AgentSkill> loadedSkills) {
    return [
      for (final skill in loadedSkills)
        AgentChatMessage(
          role: AgentChatMessageRole.user,
          content: _skillXml(skill),
          metadata: const {'kind': skillContextMetadataKind},
        ),
    ];
  }

  String _skillXml(AgentSkill skill) {
    return '<skill><name>${_xmlEscape.convert(skill.title)}</name>'
        '<content>${_xmlEscape.convert(skill.content)}</content></skill>';
  }
}
