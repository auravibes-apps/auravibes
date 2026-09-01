import 'dart:collection';

import 'package:auravibes_engine/src/tool_spec.dart';

const listSkillsToolName = 'list_skills';
const loadSkillToolName = 'load_skill';
const unloadSkillToolName = 'unload_skill';
const listSkillCredentialsToolName = 'list_skill_credentials';
const callSkillToolName = 'call_skill_tool';

const skillCommandToolNames = <String>{
  listSkillsToolName,
  loadSkillToolName,
  unloadSkillToolName,
  listSkillCredentialsToolName,
  callSkillToolName,
};

List<ToolSpec> buildSkillCommandToolSpecs() => [
  ToolSpec(
    name: listSkillsToolName,
    description: 'List skills available to load and skills currently loaded.',
    inputJsonSchema: const {
      'type': 'object',
      'properties': <String, Object?>{},
      'additionalProperties': false,
    },
  ),
  ToolSpec(
    name: loadSkillToolName,
    description: 'Load one skill for the current conversation.',
    inputJsonSchema: _skillSlugSchema,
  ),
  ToolSpec(
    name: unloadSkillToolName,
    description: 'Unload one skill from the current conversation.',
    inputJsonSchema: _skillSlugSchema,
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
];

const _skillSlugSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'slug': {'type': 'string'},
  },
  'required': ['slug'],
  'additionalProperties': false,
};

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

class SkillManifest {
  new({
    required this.slug,
    required this.title,
    required this.instructions,
    required this.revision,
    required Iterable<SkillManifestTool> tools,
  }) : tools = List.unmodifiable(tools.toList()..sort(_compareTools));

  final String slug;
  final String title;
  final String instructions;
  final String revision;
  final List<SkillManifestTool> tools;

  Map<String, Object?> toJson() => {
    'slug': slug,
    'title': title,
    'instructions': instructions,
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
  }) : inputJsonSchema = _freezeMap(inputJsonSchema);

  final String name;
  final String description;
  final Map<String, Object?> inputJsonSchema;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
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
