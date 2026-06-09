import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/skills/models/app_skill_definition.dart';
import 'package:auravibes_app/services/skills/models/app_skill_tool_definition.dart';

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

  List<AppSkillDefinition> getAll() => const [
    AppSkillDefinition(
      identifier: 'skills_manager',
      slug: 'skills_manager',
      title: 'Skills Manager',
      description: 'Create and edit user skills and skill template tools.',
      content: '''
Use this skill to create, inspect, edit, and delete user skills, skill template tools, and skill credential definitions.
When creating a skill, add the skill instructions, any needed template tool definitions, and any needed credential definitions.
Inspect existing workspace skills, template tools, and credential definitions before creating new records.
When a skill needs credentials, first create or find the credential definition, then pass its definitionId as credentialDefinitionId when creating or updating the skill. Do not use credential definition slug for skill associations.
Credential definition attributes are secret by default. Set secret false only for safe display values like account id, region, tenant, username, or base path.
Use Liquid templates for URL, query, headers, and body: {{ input.name }}, {{ credential.apiKey }}, {% if input.location %}, and {% for item in input.items %}.
For JSON request bodies, set bodyFormat to json and use {{ input.name | json }} or {{ credential.name | json }} for dynamic JSON values.
Use Liquid conditionals for optional or dependent fields. Do not use {input:name}, {credential:name}, or {{name}} in new templates.
Define each tool input accurately with type, description, and optional when appropriate.
Only create user skills from explicit user intent.
''',
      kind: SkillKind.native,
      nativeTools: [
        AppSkillToolDefinition(
          slug: 'list_user_skills',
          title: 'List user skills',
          description: 'List all user-created skills in the workspace.',
        ),
        AppSkillToolDefinition(
          slug: 'get_user_skill',
          title: 'Get user skill',
          description: 'Get a user-owned skill by slug.',
        ),
        AppSkillToolDefinition(
          slug: 'create_user_skill',
          title: 'Create user skill',
          description: 'Create a user-owned template skill.',
          titleKey: LocaleKeys
              .app_skills_skills_manager_tools_create_user_skill_title,
          descriptionKey: LocaleKeys
              .app_skills_skills_manager_tools_create_user_skill_description,
        ),
        AppSkillToolDefinition(
          slug: 'update_user_skill',
          title: 'Update user skill',
          description: 'Update a user-owned skill by slug.',
          titleKey: LocaleKeys
              .app_skills_skills_manager_tools_update_user_skill_title,
          descriptionKey: LocaleKeys
              .app_skills_skills_manager_tools_update_user_skill_description,
        ),
        AppSkillToolDefinition(
          slug: 'delete_user_skill',
          title: 'Delete user skill',
          description: 'Delete a user-owned skill by slug.',
        ),
        AppSkillToolDefinition(
          slug: 'list_skill_template_tools',
          title: 'List skill template tools',
          description: 'List URL template tools for a user skill.',
        ),
        AppSkillToolDefinition(
          slug: 'get_skill_template_tool',
          title: 'Get skill template tool',
          description: 'Get a URL template tool for a user skill.',
        ),
        AppSkillToolDefinition(
          slug: 'create_skill_template_tool',
          title: 'Create skill template tool',
          description: 'Create a URL template tool for a user skill.',
          titleKey: _createTemplateTitleKey,
          descriptionKey: _createTemplateDescriptionKey,
        ),
        AppSkillToolDefinition(
          slug: 'update_skill_template_tool',
          title: 'Update skill template tool',
          description: 'Update a URL template tool by slug.',
          titleKey: _updateTemplateTitleKey,
          descriptionKey: _updateTemplateDescriptionKey,
        ),
        AppSkillToolDefinition(
          slug: 'delete_skill_template_tool',
          title: 'Delete skill template tool',
          description: 'Delete a URL template tool by slug.',
        ),
        AppSkillToolDefinition(
          slug: 'list_skill_credential_definitions',
          title: 'List skill credential definitions',
          description: 'List reusable user credential definitions.',
        ),
        AppSkillToolDefinition(
          slug: 'get_skill_credential_definition',
          title: 'Get skill credential definition',
          description: 'Get a reusable user credential definition by slug.',
        ),
        AppSkillToolDefinition(
          slug: 'create_skill_credential_definition',
          title: 'Create skill credential definition',
          description: 'Create a reusable user credential definition.',
          titleKey: _createCredentialDefinitionTitleKey,
          descriptionKey: _createCredentialDescriptionKey,
        ),
        AppSkillToolDefinition(
          slug: 'update_skill_credential_definition',
          title: 'Update skill credential definition',
          description: 'Update a reusable user credential definition by slug.',
        ),
        AppSkillToolDefinition(
          slug: 'delete_skill_credential_definition',
          title: 'Delete skill credential definition',
          description: 'Delete a reusable user credential definition by slug.',
        ),
      ],
      titleKey: LocaleKeys.app_skills_skills_manager_title,
      descriptionKey: LocaleKeys.app_skills_skills_manager_description,
      contentKey: LocaleKeys.app_skills_skills_manager_content,
    ),
  ];

  AppSkillDefinition? getBySlug(String slug) {
    for (final skill in getAll()) {
      if (skill.slug == slug) return skill;
    }
    return null;
  }
}
