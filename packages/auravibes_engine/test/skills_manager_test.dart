import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('exposes a stable skills-manager definition and tool contract', () {
    expect(skillsManagerSkillDefinition.slug, skillsManagerSkillSlug);
    expect(
      skillsManagerSkillDefinition.content,
      contains('Set connectorToolIds'),
    );
    expect(skillsManagerToolSpecs, hasLength(11));
    expect(
      skillsManagerToolSpecs.map((spec) => spec.name),
      orderedEquals([
        'skill__app_native__skills_manager__list_user_skills',
        'skill__app_native__skills_manager__get_user_skill',
        'skill__app_native__skills_manager__create_user_skill',
        'skill__app_native__skills_manager__update_user_skill',
        'skill__app_native__skills_manager__delete_user_skill',
        'skill__app_native__skills_manager__list_skill_resources',
        'skill__app_native__skills_manager__get_skill_resource',
        'skill__app_native__skills_manager__create_skill_resource',
        'skill__app_native__skills_manager__update_skill_resource',
        'skill__app_native__skills_manager__delete_skill_resource',
        'skill__app_native__skills_manager__clone_app_skill',
      ]),
    );
    expect(skillsManagerToolSpecs[2].inputJsonSchema['required'], [
      'title',
      'description',
      'content',
    ]);
    final createSkillProperties =
        skillsManagerToolSpecs[2].inputJsonSchema['properties'] as Map;
    final connectorToolIds = createSkillProperties['connectorToolIds'] as Map;
    expect(connectorToolIds['type'], 'array');
    expect((connectorToolIds['items'] as Map)['type'], 'string');
    expect(
      skillsManagerToolSpecs[2].inputJsonSchema['required'],
      isNot(contains('connectorToolIds')),
    );
    expect(skillsManagerToolSpecs[7].inputJsonSchema['required'], [
      'skillSlug',
      'title',
      'description',
      'content',
    ]);
    expect(
      skillsManagerToolSpecs.map((spec) => spec.name),
      isNot(
        contains(
          'skill__app_native__skills_manager__create_skill_template_tool',
        ),
      ),
    );
    expect(
      skillsManagerToolSpecs.map((spec) => spec.name),
      isNot(
        contains(
          'skill__app_native__skills_manager__create_skill_credential_definition',
        ),
      ),
    );
  });
}
