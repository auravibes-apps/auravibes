import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/tool_spec.dart';

const skillsManagerSkillSlug = 'skills_manager';

const skillsManagerSkillDefinition = AppSkillDefinition(
  identifier: skillsManagerSkillSlug,
  slug: skillsManagerSkillSlug,
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
    ),
    AppSkillToolDefinition(
      slug: 'update_user_skill',
      title: 'Update user skill',
      description: 'Update a user-owned skill by slug.',
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
    ),
    AppSkillToolDefinition(
      slug: 'update_skill_template_tool',
      title: 'Update skill template tool',
      description: 'Update a URL template tool by slug.',
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
);

final List<ToolSpec> skillsManagerToolSpecs = [
  _spec(
    'list_user_skills',
    'List all user-created skills in the current workspace.',
  ),
  _spec(
    'get_user_skill',
    'Get one user-created skill by slug.',
    _schema(['skillSlug']),
  ),
  _spec(
    'create_user_skill',
    'Create a user-owned template skill.',
    _schema(
      ['title', 'description', 'content'],
      extra: const {
        'credentialDefinitionId': 'string',
        'isCredentialOptional': 'boolean',
        'isEnabled': 'boolean',
      },
    ),
  ),
  _spec(
    'update_user_skill',
    'Update a user-owned skill by slug.',
    _schema(
      ['skillSlug'],
      extra: const {
        'title': 'string',
        'description': 'string',
        'content': 'string',
        'credentialDefinitionId': 'string',
        'isCredentialOptional': 'boolean',
        'isEnabled': 'boolean',
      },
    ),
  ),
  _spec(
    'delete_user_skill',
    'Delete a user-created skill by slug.',
    _schema(['skillSlug']),
  ),
  _spec(
    'list_skill_template_tools',
    'List URL template tools for a user skill.',
    _schema(['skillSlug']),
  ),
  _spec(
    'get_skill_template_tool',
    'Get a URL template tool for a user skill.',
    _schema(['skillSlug', 'toolSlug']),
  ),
  _spec(
    'create_skill_template_tool',
    'Create a URL template tool for a user skill.',
    _schema(
      ['skillSlug', 'title', 'description', 'template', 'inputs'],
      extra: const {'requiresCredential': 'boolean', 'isEnabled': 'boolean'},
      objectFields: const {'template', 'inputs'},
    ),
  ),
  _spec(
    'update_skill_template_tool',
    'Update a URL template tool by slug.',
    _schema(
      ['skillSlug', 'toolSlug'],
      extra: const {
        'title': 'string',
        'description': 'string',
        'template': 'object',
        'inputs': 'object',
        'requiresCredential': 'boolean',
        'isEnabled': 'boolean',
      },
    ),
  ),
  _spec(
    'delete_skill_template_tool',
    'Delete a URL template tool from a user skill.',
    _schema(['skillSlug', 'toolSlug']),
  ),
  _spec(
    'list_skill_credential_definitions',
    'List reusable user credential definitions.',
  ),
  _spec(
    'get_skill_credential_definition',
    'Get a reusable user credential definition by slug.',
    _schema(['definitionSlug']),
  ),
  _spec(
    'create_skill_credential_definition',
    'Create a reusable user credential definition.',
    _schema(['title', 'attributes'], objectFields: const {'attributes'}),
  ),
  _spec(
    'update_skill_credential_definition',
    'Update a reusable user credential definition by slug.',
    _schema(
      ['definitionSlug'],
      extra: const {'title': 'string', 'attributes': 'object'},
    ),
  ),
  _spec(
    'delete_skill_credential_definition',
    'Delete a reusable user credential definition by slug.',
    _schema(['definitionSlug']),
  ),
];

ToolSpec _spec(
  String slug,
  String description, [
  Map<String, Object?>? schema,
]) => ToolSpec(
  name: 'skill__app__${skillsManagerSkillSlug}__$slug',
  description: description,
  inputJsonSchema:
      schema ??
      const {
        'type': 'object',
        'properties': <String, Object?>{},
        'additionalProperties': false,
      },
);

Map<String, Object?> _schema(
  List<String> required, {
  Map<String, String> extra = const {},
  Set<String> objectFields = const {},
}) {
  final properties = <String, Object?>{
    for (final field in required)
      field: {'type': objectFields.contains(field) ? 'object' : 'string'},
    for (final entry in extra.entries) entry.key: {'type': entry.value},
  };
  return {
    'type': 'object',
    'properties': properties,
    'required': required,
    'additionalProperties': false,
  };
}
