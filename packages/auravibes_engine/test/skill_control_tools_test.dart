import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('builds load and unload specs from portable skill state', () {
    final specs = buildSkillControlToolSpecs(
      loadableSkillSlugs: ['research', 'agents'],
      loadedSkillSlugs: ['writing'],
    );

    expect(specs.map((spec) => spec.name), [
      loadSkillToolName,
      unloadSkillToolName,
    ]);
    expect(specs.first.inputJsonSchema['properties'], {
      'slug': {
        'type': 'string',
        'enum': ['research', 'agents'],
      },
    });
    expect(specs.last.inputJsonSchema['properties'], {
      'slug': {
        'type': 'string',
        'enum': ['writing'],
      },
    });
  });
}
