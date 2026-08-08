import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('compatibility builder returns fixed skill command specs', () {
    // Intentional coverage of deprecated compatibility API.
    // ignore: deprecated_member_use_from_same_package
    final specs = buildSkillControlToolSpecs(
      loadableSkillSlugs: ['research', 'agents'],
      loadedSkillSlugs: ['writing'],
    );

    expect(specs, buildSkillCommandToolSpecs());
    expect(specs.map((spec) => spec.name), skillCommandToolNames);
    expect(
      specs.any((spec) => spec.inputJsonSchema.toString().contains('enum')),
      isFalse,
    );
  });
}
