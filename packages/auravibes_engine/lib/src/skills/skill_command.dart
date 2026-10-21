import 'dart:collection';

import 'package:auravibes_engine/src/tool_spec.dart';

const activateSkillToolName = 'activate_skill';
const loadSkillResourceToolName = 'load_skill_resource';

const skillCommandToolNames = <String>{
  activateSkillToolName,
  loadSkillResourceToolName,
};

List<ToolSpec> buildSkillCommandToolSpecs() => [
  ToolSpec(
    name: activateSkillToolName,
    description: 'Activate one skill from the current skill catalog.',
    inputJsonSchema: _skillActivationSchema,
  ),
  ToolSpec(
    name: loadSkillResourceToolName,
    description: 'Load one resource from an activated skill.',
    inputJsonSchema: const {
      'type': 'object',
      'properties': {
        'skill': {'type': 'string'},
        'resource': {'type': 'string'},
      },
      'required': ['skill', 'resource'],
      'additionalProperties': false,
    },
  ),
];

const _skillActivationSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'slug': {'type': 'string'},
    'revision': {'type': 'string'},
  },
  'required': ['slug', 'revision'],
  'additionalProperties': false,
};

class SkillActivationTarget._({
  required final String slug,
  required final String revision,
}) {
  factory fromArguments(Map<String, Object?> arguments) {
    final slug = arguments['slug'];
    final revision = arguments['revision'];
    if (slug is! String || slug.isEmpty) {
      throw const FormatException('slug must be a non-empty string');
    }
    if (revision is! String || revision.isEmpty) {
      throw const FormatException('revision must be a non-empty string');
    }

    return SkillActivationTarget._(slug: slug, revision: revision);
  }
}

class SkillResourceTarget._({
  required final String skill,
  required final String resource,
}) {
  factory fromArguments(Map<String, Object?> arguments) {
    final skill = arguments['skill'];
    final resource = arguments['resource'];
    if (skill is! String || skill.isEmpty) {
      throw const FormatException('skill must be a non-empty string');
    }
    if (resource is! String || resource.isEmpty) {
      throw const FormatException('resource must be a non-empty string');
    }

    return SkillResourceTarget._(skill: skill, resource: resource);
  }
}

class SkillManifest {
  new({
    required this.slug,
    required this.title,
    required this.description,
    required this.revision,
    Iterable<String> connectorToolIds = const [],
  }) : connectorToolIds = List.unmodifiable(
         connectorToolIds
             .map((id) => id.trim())
             .where((id) => id.isNotEmpty)
             .toSet()
             .toList()
           ..sort(),
       );

  final String slug;
  final String title;
  final String description;
  final String revision;
  final List<String> connectorToolIds;

  Map<String, Object?> toJson() => {
    'slug': slug,
    'title': title,
    'description': description,
    'revision': revision,
    if (connectorToolIds.isNotEmpty) 'connectorToolIds': connectorToolIds,
  };
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) =>
    UnmodifiableMapView({
      for (final entry in value.entries) entry.key: _freezeJson(entry.value),
    });

Object? _freezeJson(Object? value) => switch (value) {
  final Map<Object?, Object?> value => UnmodifiableMapView({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  }),
  final List<Object?> value => List<Object?>.unmodifiable(
    value.map(_freezeJson),
  ),
  _ => value,
};
