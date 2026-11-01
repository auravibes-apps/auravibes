import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

const _catalogSizes = [10, 50, 100, 500, 1000];
const _warmupIterations = 5;
const _measuredIterations = 15;
const _loadedSkillInterval = 10;

void main() {
  stdout.writeln(
    'tools,skills,loaded_skills,median_assembly_us,serialized_context_bytes',
  );
  for (final size in _catalogSizes) {
    _benchmark(_syntheticCatalog(size));
  }
}

void _benchmark(_SyntheticCatalog catalog) {
  for (var iteration = 0; iteration < _warmupIterations; iteration++) {
    _assemble(catalog);
  }

  final durations = <int>[];
  String? serializedContext;
  for (var iteration = 0; iteration < _measuredIterations; iteration++) {
    final stopwatch = Stopwatch()..start();
    final context = _assemble(catalog);
    stopwatch.stop();
    durations.add(stopwatch.elapsedMicroseconds);

    final currentContext = jsonEncode(context.toJson());
    if (serializedContext == null) {
      serializedContext = currentContext;
    } else if (serializedContext != currentContext) {
      throw StateError('Context serialization changed between runs.');
    }
  }

  durations.sort();
  final medianMicroseconds = durations[durations.length ~/ 2];
  final serializedContextBytes = utf8.encode(serializedContext!).length;
  stdout.writeln(
    '${catalog.tools.length},'
    '${catalog.skills.length},'
    '${catalog.loadedSkillCount},'
    '$medianMicroseconds,$serializedContextBytes',
  );
}

_AssembledContext _assemble(_SyntheticCatalog catalog) {
  final tools = buildToolCatalog<int>([
    for (final tool in catalog.tools)
      ToolCatalogCandidate.external(
        spec: ToolSpec(
          name: tool.name,
          description: tool.description,
          inputJsonSchema: tool.inputSchema,
        ),
        target: tool.id,
        sourceId: tool.sourceId,
      ),
  ]);

  final skillCatalog = [
    for (final skill in catalog.skills)
      SkillCatalogEntry(
        slug: skill.slug,
        title: skill.title,
        description: skill.description,
        revision: skill.revision,
        active: skill.active,
      ),
  ];
  final conversationSkills = [
    for (final skill in catalog.skills)
      if (skill.active && skill.id % (_loadedSkillInterval * 2) == 0)
        _agentSkill(skill),
  ];
  final agentSkills = [
    for (final skill in catalog.skills)
      if (skill.active) _agentSkill(skill),
  ];
  final skillMessages = const BuildSkillContextMessages().compose(
    conversationSkills: conversationSkills,
    agentSkills: agentSkills,
    skillCatalog: skillCatalog,
    agentContent:
        'A deterministic synthetic agent instruction for benchmarking.',
  );

  return _AssembledContext(tools.specs, skillMessages);
}

AgentSkill _agentSkill(_SyntheticSkill skill) => AgentSkill(
  title: skill.title,
  content: skill.content,
  identity: skill.identity,
);

_SyntheticCatalog _syntheticCatalog(int size) {
  final tools = [
    for (var index = 0; index < size; index++)
      _SyntheticTool(
        id: index,
        name: 'read_record_$index',
        description:
            'Read deterministic record $index from the synthetic catalog.',
        sourceId: 'synthetic-source-$index',
        inputSchema: const {
          'type': 'object',
          'properties': {
            'record_id': {'type': 'string'},
            'limit': {'type': 'integer', 'minimum': 1, 'maximum': 100},
          },
          'required': ['record_id'],
        },
      ),
  ];
  final skills = [
    for (var index = 0; index < size; index++)
      _SyntheticSkill(
        id: index,
        slug: 'synthetic-skill-$index',
        title: 'Synthetic skill $index',
        description: 'Deterministic catalog entry for skill $index.',
        revision: 'revision-$index',
        identity: 'synthetic-skill-identity-$index',
        active: index % _loadedSkillInterval == 0,
        content:
            'Synthetic instructions for skill $index. '
            'Use the matching catalog entry and preserve its identity.',
      ),
  ];
  return _SyntheticCatalog(tools, skills);
}

class const _SyntheticCatalog(
  final List<_SyntheticTool> tools,
  final List<_SyntheticSkill> skills,
) {
  int get loadedSkillCount => skills.where((skill) => skill.active).length;
}

class const _SyntheticTool({
  required final int id,
  required final String name,
  required final String description,
  required final String sourceId,
  required final Map<String, Object?> inputSchema,
});

class const _SyntheticSkill({
  required final int id,
  required final String slug,
  required final String title,
  required final String description,
  required final String revision,
  required final String identity,
  required final bool active,
  required final String content,
});

class const _AssembledContext(
  final List<ToolSpec> tools,
  final List<AgentChatMessage> skillMessages,
) {
  Map<String, Object?> toJson() => {
    'tools': [
      for (final tool in tools)
        {
          'name': tool.name,
          'description': tool.description,
          'inputSchema': tool.inputJsonSchema,
        },
    ],
    'skillContextMessages': [
      for (final message in skillMessages)
        {
          'role': message.role.name,
          'content': message.content,
          'metadata': message.metadata,
        },
    ],
  };
}
