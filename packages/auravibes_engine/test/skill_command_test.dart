import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('skill commands only activate guidance and load resources', () {
    final specs = buildSkillCommandToolSpecs();

    expect(specs.map((spec) => spec.name), [
      activateSkillToolName,
      loadSkillResourceToolName,
    ]);
    expect(skillCommandToolNames, {
      activateSkillToolName,
      loadSkillResourceToolName,
    });
    for (final spec in specs) {
      expect(
        strictToolSchemaIssue(Map<String, dynamic>.from(spec.inputJsonSchema)),
        isNull,
        reason: spec.name,
      );
      expect(spec.inputJsonSchema.toString(), isNot(contains('toolId')));
    }
  });

  test('activation target requires a catalog revision', () {
    final target = SkillActivationTarget.fromArguments({
      'slug': 'research',
      'revision': 'skill-7',
    });

    expect(target.slug, 'research');
    expect(target.revision, 'skill-7');
    expect(
      () => SkillActivationTarget.fromArguments({'slug': 'research'}),
      throwsFormatException,
    );
  });

  test('resource target requires skill and resource slugs', () {
    final target = SkillResourceTarget.fromArguments({
      'skill': 'research',
      'resource': 'refund-policy',
    });

    expect(target.skill, 'research');
    expect(target.resource, 'refund-policy');
    expect(
      () => SkillResourceTarget.fromArguments({'skill': 'research'}),
      throwsFormatException,
    );
  });

  test('manifest stores sorted unique Connector tool IDs only', () {
    final manifest = SkillManifest(
      slug: 'research',
      title: 'Research',
      description: 'Find sources.',
      revision: 'skill-7',
      connectorToolIds: [
        'connector/notion/search',
        'connector/gmail/send',
        'connector/notion/search',
      ],
    );

    expect(manifest.connectorToolIds, [
      'connector/gmail/send',
      'connector/notion/search',
    ]);
    expect(manifest.toJson(), {
      'slug': 'research',
      'title': 'Research',
      'description': 'Find sources.',
      'revision': 'skill-7',
      'connectorToolIds': ['connector/gmail/send', 'connector/notion/search'],
    });
  });

  test('manifest omits Connector references when none are configured', () {
    final manifest = SkillManifest(
      slug: 'writer',
      title: 'Writer',
      description: 'Write clearly.',
      revision: 'skill-8',
    );

    expect(manifest.toJson(), {
      'slug': 'writer',
      'title': 'Writer',
      'description': 'Write clearly.',
      'revision': 'skill-8',
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
}
