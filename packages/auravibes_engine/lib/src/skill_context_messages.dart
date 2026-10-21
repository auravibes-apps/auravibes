import 'dart:convert';

import 'package:auravibes_engine/src/prompt_messages.dart';
import 'package:auravibes_engine/src/skills/skill_command.dart';
import 'package:crypto/crypto.dart';
import 'package:toon_dart/toon_dart.dart';

const _xmlAttributeEscape = HtmlEscape(HtmlEscapeMode.attribute);
const _xmlTextEscape = HtmlEscape(HtmlEscapeMode.element);
const skillCatalogMetadataKind = 'skill_catalog';
const skillCatalogRevisionMetadataKey = 'catalogRevision';
const skillCatalogSelectedRevisionsMetadataKey = 'selectedRevisions';

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

class const SkillResourceResult(final String value) {
  @override
  String toString() => value;
}

class const SkillResourceSummary({
  required final String slug,
  required final String title,
  required final String description,
}) {
  Map<String, Object?> toJson() => {
    'slug': slug,
    'title': title,
    'description': description,
  };
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
  Iterable<String> connectorToolIds = const [],
}) {
  final sortedConnectorToolIds =
      connectorToolIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  final canonical = _canonicalJson({
    'identity': identity,
    'slug': slug,
    'title': title,
    'description': description,
    'instructions': instructions,
    'connectorToolIds': sortedConnectorToolIds,
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
  Iterable<SkillResourceSummary> resources = const [],
}) {
  final slug = _xmlAttributeEscape.convert(manifest.slug);
  final title = _xmlAttributeEscape.convert(manifest.title);
  final revision = _xmlAttributeEscape.convert(manifest.revision);
  final connectorToolRefs = _xmlTextEscape.convert(
    jsonEncode(manifest.connectorToolIds),
  );
  final resourceOptions = _xmlTextEscape.convert(
    _skillResourcesToon(resources),
  );
  final connectorToolRefsXml = manifest.connectorToolIds.isEmpty
      ? ''
      : '<connector_tool_refs>$connectorToolRefs</connector_tool_refs>';
  return SkillActivationResult(
    '<skill_content slug="$slug" title="$title" revision="$revision">'
    '${_xmlCdata(content)}'
    '$connectorToolRefsXml'
    '<skill_resources>$resourceOptions</skill_resources>'
    '</skill_content>',
  );
}

SkillResourceResult buildSkillResourceResult({
  required String skillSlug,
  required String resourceSlug,
  required String title,
  required String content,
}) => SkillResourceResult(
  '<skill_resource skill="${_xmlAttributeEscape.convert(skillSlug)}" '
  'slug="${_xmlAttributeEscape.convert(resourceSlug)}" '
  'title="${_xmlAttributeEscape.convert(title)}">'
  '${_xmlCdata(content)}'
  '</skill_resource>',
);

String _xmlCdata(String value) =>
    '<![CDATA[${value.replaceAll(']]>', ']]]]><![CDATA[>')}]]>';

String _skillResourcesToon(Iterable<SkillResourceSummary> resources) {
  final sorted = resources.toList()
    ..sort((left, right) => left.slug.compareTo(right.slug));
  return toonEncode({
    'resources': sorted.map((resource) => resource.toJson()).toList(),
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
    final catalog = skillCatalog.toList(growable: false);
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
      if (catalog.isNotEmpty)
        AgentChatMessage(
          role: .system,
          content: _skillCatalogXml(catalog, catalogRevision),
          metadata: {
            'kind': skillCatalogMetadataKind,
            skillCatalogRevisionMetadataKey:
                catalogRevision ?? buildSkillCatalogRevision(catalog),
            skillCatalogSelectedRevisionsMetadataKey: {
              for (final entry in catalog)
                if (entry.active) entry.slug: entry.revision,
            },
          },
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
    final manifestXml = manifest == null
        ? ''
        : _skillManifestXml(manifest);

    return '<skill><name>${_xmlTextEscape.convert(skill.title)}</name>'
        '<content>${_xmlTextEscape.convert(skill.content)}</content>'
        '$manifestXml</skill>';
  }

  String _skillManifestXml(SkillManifest manifest) {
    final connectorToolRefs = manifest.connectorToolIds.isEmpty
        ? ''
        : '<connector_tool_refs>${_xmlTextEscape.convert(jsonEncode(manifest.connectorToolIds))}</connector_tool_refs>';

    return connectorToolRefs;
  }
}
