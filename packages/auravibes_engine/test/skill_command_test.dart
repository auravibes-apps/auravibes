import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('skill command specs are fixed and contain no dynamic enums', () {
    final before = buildSkillCommandToolSpecs();
    final after = buildSkillCommandToolSpecs();

    expect(before, after);
    expect(before.map((spec) => spec.name), [
      listSkillsToolName,
      loadSkillToolName,
      unloadSkillToolName,
      listSkillCredentialsToolName,
      callSkillToolName,
    ]);
    expect(
      before.any((spec) => spec.inputJsonSchema.toString().contains('enum')),
      isFalse,
    );
  });

  test('call target parser rejects missing identifiers', () {
    expect(
      () => SkillCommandTarget.fromArguments({
        'skill': '',
        'tool': 'search',
        'args': <String, Object?>{},
      }),
      throwsFormatException,
    );
  });

  test('call target parser validates and normalizes arguments', () {
    final target = SkillCommandTarget.fromArguments({
      'skill': 'research',
      'tool': 'search',
      'args': <Object?, Object?>{'query': 'Dart'},
      'revision': 'skill-7',
    });

    expect(target.skill, 'research');
    expect(target.tool, 'search');
    expect(target.args, {'query': 'Dart'});
    expect(target.revision, 'skill-7');
    expect(() => target.args['query'] = 'Flutter', throwsUnsupportedError);

    for (final arguments in [
      {
        'skill': 'research',
        'tool': '',
        'args': <String, Object?>{},
        'revision': 'skill-7',
      },
      {
        'skill': 'research',
        'tool': 'search',
        'args': <String, Object?>{},
        'revision': '',
      },
      {
        'skill': 'research',
        'tool': 'search',
        'args': 'invalid',
        'revision': 'skill-7',
      },
      {
        'skill': 'research',
        'tool': 'search',
        'args': <Object?, Object?>{1: 'invalid'},
        'revision': 'skill-7',
      },
    ]) {
      expect(
        () => SkillCommandTarget.fromArguments(arguments),
        throwsFormatException,
      );
    }
  });

  test('manifest serialization is deterministic', () {
    final manifest = SkillManifest(
      slug: 'research',
      title: 'Research',
      instructions: 'Use cited sources.',
      revision: 'skill-7',
      tools: [
        SkillManifestTool(
          name: 'search',
          description: 'Search sources.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
            },
            'required': ['query'],
            'additionalProperties': false,
          },
        ),
      ],
    );

    expect(manifest.toJson(), {
      'slug': 'research',
      'title': 'Research',
      'instructions': 'Use cited sources.',
      'revision': 'skill-7',
      'tools': [
        {
          'name': 'search',
          'description': 'Search sources.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
            },
            'required': ['query'],
            'additionalProperties': false,
          },
        },
      ],
    });
  });

  test('default resolver recognizes every fixed skill command', () {
    const resolver = AgentToolNameResolver();

    for (final name in skillCommandToolNames) {
      expect(
        resolver.resolve(name)?.kind,
        AgentResolvedToolKind.skillControl,
        reason: name,
      );
    }
  });

  test('manifest freezes schemas and sorts tools by name', () {
    final schema = <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'query': <String, Object?>{'type': 'string'},
      },
    };
    final manifest = SkillManifest(
      slug: 'research',
      title: 'Research',
      instructions: 'Use cited sources.',
      revision: 'skill-7',
      tools: [
        SkillManifestTool(
          name: 'summarize',
          description: 'Summarize sources.',
          inputJsonSchema: const {'type': 'object'},
        ),
        SkillManifestTool(
          name: 'search',
          description: 'Search sources.',
          inputJsonSchema: schema,
        ),
      ],
    );

    schema['type'] = 'string';
    (schema['properties']! as Map<String, Object?>)['query'] = null;

    expect(manifest.tools.map((tool) => tool.name), ['search', 'summarize']);
    expect(manifest.tools.first.inputJsonSchema, {
      'type': 'object',
      'properties': {
        'query': {'type': 'string'},
      },
    });
    expect(
      () => manifest.tools.first.inputJsonSchema['type'] = 'string',
      throwsUnsupportedError,
    );
    expect(
      () => manifest.tools.add(manifest.tools.first),
      throwsUnsupportedError,
    );
  });
}
