import 'dart:convert';

import 'package:auravibes_engine/src/prompt_messages.dart';
import 'package:auravibes_engine/src/skills/skill_command.dart';

const _xmlEscape = HtmlEscape();

class AgentSkill {
  const AgentSkill({
    required this.title,
    required this.content,
    this.identity,
    this.manifest,
  });

  final String title;
  final String content;
  final String? identity;
  final SkillManifest? manifest;
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

  List<AgentChatMessage> compose({
    required Iterable<AgentSkill> conversationSkills,
    required Iterable<AgentSkill> agentSkills,
    String? agentContent,
  }) {
    final seen = <String>{};
    final skills = [...conversationSkills, ...agentSkills]
        .where(
          (skill) => seen.add(
            skill.identity ?? '${skill.title}\u0000${skill.content}',
          ),
        )
        .toList(growable: false);
    return [
      if (agentContent != null)
        AgentChatMessage(
          role: AgentChatMessageRole.system,
          content: agentContent,
        ),
      ...call(skills),
    ];
  }

  String _skillXml(AgentSkill skill) {
    final manifest = skill.manifest;
    final manifestXml = manifest == null
        ? ''
        : '<skill_manifest>'
              '${_xmlEscape.convert(jsonEncode(manifest.toJson()))}'
              '</skill_manifest>';

    return '<skill><name>${_xmlEscape.convert(skill.title)}</name>'
        '<content>${_xmlEscape.convert(skill.content)}</content>'
        '$manifestXml</skill>';
  }
}
