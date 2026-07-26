import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

const String _createTemplateTitleKey =
    LocaleKeys.app_skills_skills_manager_tools_create_skill_template_tool_title;
const String _createTemplateDescriptionKey = LocaleKeys
    .app_skills_skills_manager_tools_create_skill_template_tool_description;
const String _updateTemplateTitleKey =
    LocaleKeys.app_skills_skills_manager_tools_update_skill_template_tool_title;
const String _updateTemplateDescriptionKey = LocaleKeys
    .app_skills_skills_manager_tools_update_skill_template_tool_description;
const String _createCredentialDefinitionTitleKey = LocaleKeys
    .app_skills_skills_manager_tools_create_skill_credential_definition_title;
const String _createCredentialDescriptionKey =
    'app_skills.skills_manager.tools.'
    'create_skill_credential_definition.description';

class AppSkillRegistry {
  const AppSkillRegistry();

  List<AppSkillDefinition> getAll() => [
    _localizedSkillsManagerDefinition(),
    AppSkillDefinition(
      identifier: agentsSkillSlug,
      slug: agentsSkillSlug,
      title: agentsSkillTitle,
      description: 'Inspect enabled workspace agents.',
      content: agentsSkillContent,
      nativeTools: [
        AppSkillToolDefinition(
          slug: listAgentsToolSpec.name,
          title: listAgentsToolSpec.name,
          description: listAgentsToolSpec.description,
          inputJsonSchema: Map<String, dynamic>.from(
            listAgentsToolSpec.inputJsonSchema,
          ),
        ),
      ],
      titleKey: LocaleKeys.app_skills_agents_title,
      descriptionKey: LocaleKeys.app_skills_agents_description,
      contentKey: LocaleKeys.app_skills_agents_content,
    ),
    ...serviceSkillDefinitions,
  ];

  AppSkillDefinition? getBySlug(String slug) {
    for (final skill in getAll()) {
      if (skill.slug == slug) return skill;
    }

    return null;
  }

  AppSkillDefinition? getByIdentifier(String identifier) {
    for (final skill in getAll()) {
      if (skill.identifier == identifier) return skill;
    }

    return null;
  }
}

AppSkillDefinition _localizedSkillsManagerDefinition() {
  const definition = skillsManagerSkillDefinition;

  return AppSkillDefinition(
    identifier: definition.identifier,
    slug: definition.slug,
    title: definition.title,
    description: definition.description,
    content: definition.content,
    nativeTools: [
      for (final tool in definition.nativeTools)
        AppSkillToolDefinition(
          slug: tool.slug,
          title: tool.title,
          description: tool.description,
          inputJsonSchema: Map<String, dynamic>.from(tool.inputJsonSchema),
          titleKey: _toolTitleKey(tool.slug),
          descriptionKey: _toolDescriptionKey(tool.slug),
        ),
    ],
    titleKey: LocaleKeys.app_skills_skills_manager_title,
    descriptionKey: LocaleKeys.app_skills_skills_manager_description,
    contentKey: LocaleKeys.app_skills_skills_manager_content,
  );
}

String? _toolTitleKey(String slug) => switch (slug) {
  'create_user_skill' =>
    LocaleKeys.app_skills_skills_manager_tools_create_user_skill_title,
  'update_user_skill' =>
    LocaleKeys.app_skills_skills_manager_tools_update_user_skill_title,
  'create_skill_template_tool' => _createTemplateTitleKey,
  'update_skill_template_tool' => _updateTemplateTitleKey,
  'create_skill_credential_definition' => _createCredentialDefinitionTitleKey,
  _ => null,
};

String? _toolDescriptionKey(String slug) => switch (slug) {
  'create_user_skill' =>
    LocaleKeys.app_skills_skills_manager_tools_create_user_skill_description,
  'update_user_skill' =>
    LocaleKeys.app_skills_skills_manager_tools_update_user_skill_description,
  'create_skill_template_tool' => _createTemplateDescriptionKey,
  'update_skill_template_tool' => _updateTemplateDescriptionKey,
  'create_skill_credential_definition' => _createCredentialDescriptionKey,
  _ => null,
};
