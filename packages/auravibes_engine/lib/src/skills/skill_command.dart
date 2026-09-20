import 'dart:collection';

import 'package:auravibes_engine/src/tool_spec.dart';

const activateSkillToolName = 'activate_skill';
const listSkillCredentialsToolName = 'list_skill_credentials';
const callSkillToolName = 'call_skill_tool';
const loadSkillResourceToolName = 'load_skill_resource';

const skillCommandToolNames = <String>{
  activateSkillToolName,
  listSkillCredentialsToolName,
  callSkillToolName,
  loadSkillResourceToolName,
};

List<ToolSpec> buildSkillCommandToolSpecs() => [
  ToolSpec(
    name: activateSkillToolName,
    description: 'Activate one skill from the current skill catalog.',
    inputJsonSchema: _skillActivationSchema,
  ),
  ToolSpec(
    name: listSkillCredentialsToolName,
    description: 'List credential ids and names available to a loaded skill.',
    inputJsonSchema: _skillSlugSchema,
  ),
  ToolSpec(
    name: callSkillToolName,
    description: 'Call one tool exposed by a loaded skill manifest.',
    inputJsonSchema: const {
      'type': 'object',
      'properties': {
        'skill': {'type': 'string'},
        'tool': {'type': 'string'},
        'args': {'type': 'object'},
        'revision': {'type': 'string'},
      },
      'required': ['skill', 'tool', 'args', 'revision'],
      'additionalProperties': false,
    },
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

const _skillSlugSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'slug': {'type': 'string'},
  },
  'required': ['slug'],
  'additionalProperties': false,
};

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

class SkillCommandTarget._({
  required final String skill,
  required final String tool,
  required final Map<String, Object?> args,
  required final String revision,
}) {
  factory fromArguments(Map<String, Object?> arguments) {
    final skill = arguments['skill'];
    final tool = arguments['tool'];
    final args = arguments['args'];
    final revision = arguments['revision'];
    if (skill is! String || skill.isEmpty) {
      throw const FormatException('skill must be a non-empty string');
    }
    if (tool is! String || tool.isEmpty) {
      throw const FormatException('tool must be a non-empty string');
    }
    if (revision is! String || revision.isEmpty) {
      throw const FormatException('revision must be a non-empty string');
    }
    if (args is! Map) {
      throw const FormatException('args must be an object');
    }

    final normalizedArgs = <String, Object?>{};
    for (final entry in args.entries) {
      if (entry.key is! String) {
        throw const FormatException('args keys must be strings');
      }
      normalizedArgs[entry.key as String] = entry.value;
    }

    return SkillCommandTarget._(
      skill: skill,
      tool: tool,
      args: _freezeMap(normalizedArgs),
      revision: revision,
    );
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
    required Iterable<SkillManifestTool> tools,
  }) : tools = List.unmodifiable(tools.toList()..sort(_compareTools));

  final String slug;
  final String title;
  final String description;
  final String revision;
  final List<SkillManifestTool> tools;

  Map<String, Object?> toJson() => {
    'slug': slug,
    'title': title,
    'description': description,
    'revision': revision,
    'tools': tools.map((tool) => tool.toJson()).toList(growable: false),
  };

  static int _compareTools(SkillManifestTool left, SkillManifestTool right) =>
      left.name.compareTo(right.name);
}

class SkillManifestTool {
  new({
    required this.name,
    required this.description,
    required Map<String, Object?> inputJsonSchema,
    this.credentialRequired = false,
  }) : inputJsonSchema = _freezeMap(inputJsonSchema);

  final String name;
  final String description;
  final Map<String, Object?> inputJsonSchema;
  final bool credentialRequired;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    if (credentialRequired) 'credentialRequired': true,
    'inputSchema': inputJsonSchema,
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
