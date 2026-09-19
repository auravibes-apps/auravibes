import 'dart:convert';

import 'package:auravibes_engine/src/prompt_messages.dart';
import 'package:auravibes_engine/src/skills/skill_command.dart';
import 'package:auravibes_engine/src/skills/skill_credentials.dart';
import 'package:crypto/crypto.dart';
import 'package:toon_dart/toon_dart.dart';

const _xmlAttributeEscape = HtmlEscape(HtmlEscapeMode.attribute);
const _xmlTextEscape = HtmlEscape(HtmlEscapeMode.element);
const skillCatalogMetadataKind = 'skill_catalog';

class const SkillCatalogEntry({
  required final String slug,
  required final String title,
  required final String description,
  required final String revision,
  required final bool active,
}) {
  Map<String, Object?> toJson() => {
    'slug': slug,
    'title': title,
    'description': description,
    'revision': revision,
    'active': active,
  };
}

class const SkillActivationResult(final String value) {
  @override
  String toString() => value;
}

String buildSkillCatalogRevision(Iterable<SkillCatalogEntry> entries) {
  final sorted = entries.toList()
    ..sort((left, right) => left.slug.compareTo(right.slug));
  return sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'skills': sorted.map((entry) => entry.toJson()).toList(),
          }),
        ),
      )
      .toString();
}

String buildSkillRevision({
  required String identity,
  required String slug,
  required String title,
  required String description,
  required String instructions,
  required Iterable<SkillManifestTool> tools,
}) {
  final sortedTools = tools.toList()
    ..sort((left, right) => left.name.compareTo(right.name));
  final canonical = _canonicalJson({
    'identity': identity,
    'slug': slug,
    'title': title,
    'description': description,
    'instructions': instructions,
    'tools': [for (final tool in sortedTools) tool.toJson()],
  });
  return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
}

Object? _canonicalJson(Object? value) => switch (value) {
  final Map<Object?, Object?> map => {
    for (final key in map.keys.cast<String>().toList()..sort())
      key: _canonicalJson(map[key]),
  },
  final Iterable<Object?> values => [
    for (final value in values) _canonicalJson(value),
  ],
  _ => value,
};

SkillActivationResult buildSkillActivationResult({
  required SkillManifest manifest,
  required String content,
  Iterable<SkillCredentialOption> credentials = const [],
}) {
  final slug = _xmlAttributeEscape.convert(manifest.slug);
  final title = _xmlAttributeEscape.convert(manifest.title);
  final revision = _xmlAttributeEscape.convert(manifest.revision);
  final tools = _xmlTextEscape.convert(_skillToolsJson(manifest));
  final credentialOptions = _xmlTextEscape.convert(
    _skillCredentialsToon(credentials),
  );
  return SkillActivationResult(
    '<skill_content slug="$slug" title="$title" revision="$revision">'
    '${_xmlCdata(content)}'
    '<skill_tools>$tools</skill_tools>'
    '<skill_credentials>$credentialOptions</skill_credentials>'
    '</skill_content>',
  );
}

String _xmlCdata(String value) =>
    '<![CDATA[${value.replaceAll(']]>', ']]]]><![CDATA[>')}]]>';

String _skillToolsJson(
  SkillManifest manifest, {
  bool includeRevision = false,
}) => jsonEncode({
  if (includeRevision) 'revision': manifest.revision,
  'tools': manifest.tools.map((tool) => tool.toJson()).toList(growable: false),
});

String _skillCredentialsToon(Iterable<SkillCredentialOption> credentials) {
  final sorted = credentials.toList()
    ..sort((left, right) => left.credentialId.compareTo(right.credentialId));
  return toonEncode({
    'options': sorted.map((credential) => credential.toJson()).toList(),
  });
}

class const AgentSkill({
  required final String title,
  required final String content,
  final String? identity,
  final SkillManifest? manifest,
});

class const BuildSkillContextMessages() {
  List<AgentChatMessage> call(List<AgentSkill> loadedSkills) {
    return [
      for (final skill in loadedSkills)
        AgentChatMessage(
          role: .user,
          content: _skillXml(skill),
          metadata: const {'kind': skillContextMetadataKind},
        ),
    ];
  }

  List<AgentChatMessage> compose({
    required Iterable<AgentSkill> conversationSkills,
    required Iterable<AgentSkill> agentSkills,
    Iterable<SkillCatalogEntry> skillCatalog = const [],
    String? catalogRevision,
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
        AgentChatMessage(role: .system, content: agentContent),
      if (skillCatalog.isNotEmpty)
        AgentChatMessage(
          role: .system,
          content: _skillCatalogXml(skillCatalog, catalogRevision),
          metadata: const {'kind': skillCatalogMetadataKind},
        ),
      ...call(skills),
    ];
  }

  String _skillCatalogXml(
    Iterable<SkillCatalogEntry> entries,
    String? catalogRevision,
  ) {
    final sorted = entries.toList()
      ..sort((left, right) => left.slug.compareTo(right.slug));
    final revision = catalogRevision ?? buildSkillCatalogRevision(sorted);
    final catalog = jsonEncode({
      'skills': sorted.map((entry) => entry.toJson()).toList(),
    });
    return '<skill_catalog revision="${_xmlAttributeEscape.convert(revision)}">'
        '${_xmlTextEscape.convert(catalog)}'
        '</skill_catalog>';
  }

  String _skillXml(AgentSkill skill) {
    final manifest = skill.manifest;
    final tools = manifest == null
        ? ''
        : _xmlTextEscape.convert(
            _skillToolsJson(manifest, includeRevision: true),
          );
    final manifestXml = manifest == null
        ? ''
        : '<skill_tools>$tools</skill_tools>';

    return '<skill><name>${_xmlTextEscape.convert(skill.title)}</name>'
        '<content>${_xmlTextEscape.convert(skill.content)}</content>'
        '$manifestXml</skill>';
  }
}
