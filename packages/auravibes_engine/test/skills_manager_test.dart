import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('exposes a stable skills-manager definition and tool contract', () {
    expect(skillsManagerSkillDefinition.slug, skillsManagerSkillSlug);
    expect(
      skillsManagerSkillDefinition.content,
      contains('Do not use {input:name}, {credential:name}, or {{name}}'),
    );
    expect(skillsManagerToolSpecs, hasLength(16));
    expect(
      skillsManagerToolSpecs.map((spec) => spec.name),
      orderedEquals([
        'skill__app_native__skills_manager__list_user_skills',
        'skill__app_native__skills_manager__get_user_skill',
        'skill__app_native__skills_manager__create_user_skill',
        'skill__app_native__skills_manager__update_user_skill',
        'skill__app_native__skills_manager__delete_user_skill',
        'skill__app_native__skills_manager__clone_app_skill',
        'skill__app_native__skills_manager__list_skill_template_tools',
        'skill__app_native__skills_manager__get_skill_template_tool',
        'skill__app_native__skills_manager__create_skill_template_tool',
        'skill__app_native__skills_manager__update_skill_template_tool',
        'skill__app_native__skills_manager__delete_skill_template_tool',
        'skill__app_native__skills_manager__list_skill_credential_definitions',
        'skill__app_native__skills_manager__get_skill_credential_definition',
        'skill__app_native__skills_manager__create_skill_credential_definition',
        'skill__app_native__skills_manager__update_skill_credential_definition',
        'skill__app_native__skills_manager__delete_skill_credential_definition',
      ]),
    );
    expect(skillsManagerToolSpecs[2].inputJsonSchema['required'], [
      'title',
      'description',
      'content',
    ]);
    expect(skillsManagerToolSpecs[8].inputJsonSchema['required'], [
      'skillSlug',
      'title',
      'description',
      'definition',
    ]);
  });
}
