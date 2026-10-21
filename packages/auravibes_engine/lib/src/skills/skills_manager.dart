import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/tool_schema_strictification.dart';
import 'package:auravibes_engine/src/tool_spec.dart';

const skillsManagerSkillSlug = 'skills_manager';

const skillsManagerSkillDefinition = AppSkillDefinition(
  identifier: skillsManagerSkillSlug,
  slug: skillsManagerSkillSlug,
  title: 'Skills Manager',
  description: 'Create and edit user skills and resources.',
  content: '''
Use this skill to create, inspect, edit, and delete user skills and skill resources.
Create the parent skill first, then create resources separately with the resource tools. Resources are one-level text or Markdown references loaded only after the parent skill is activated.
Set connectorToolIds to the stable IDs of shared Connector tools the guidance uses. Do not copy Connector tool definitions or credentials into a Skill.
Connector references guide the agent. The current Connection and permissions are checked when the Connector tool runs.
Inspect existing workspace Skills before creating records.
Only create user skills from explicit user intent.
''',
  tools: [
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
      description: 'Create a user-owned Skill.',
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
      slug: 'list_skill_resources',
      title: 'List skill resources',
      description: 'List resources for a user skill.',
    ),
    AppSkillToolDefinition(
      slug: 'get_skill_resource',
      title: 'Get skill resource',
      description: 'Get a resource for a user skill by slug.',
    ),
    AppSkillToolDefinition(
      slug: 'create_skill_resource',
      title: 'Create skill resource',
      description: 'Create a text or Markdown resource for a user skill.',
    ),
    AppSkillToolDefinition(
      slug: 'update_skill_resource',
      title: 'Update skill resource',
      description: 'Update a user skill resource by slug.',
    ),
    AppSkillToolDefinition(
      slug: 'delete_skill_resource',
      title: 'Delete skill resource',
      description: 'Delete a user skill resource by slug.',
    ),
    AppSkillToolDefinition(
      slug: 'clone_app_skill',
      title: 'Clone app skill',
      description:
          'Clone a declarative built-in service skill as a user skill.',
    ),
  ],
);

final List<ToolSpec> skillsManagerToolSpecs = _strictSkillsManagerToolSpecs([
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
    'Create a user-owned Skill.',
    _schema(
      ['title', 'description', 'content'],
      extra: const {
        'isEnabled': 'boolean',
      },
      extraJson: const {
        'connectorToolIds': {
          'type': 'array',
          'items': {'type': 'string'},
        },
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
        'isEnabled': 'boolean',
      },
      extraJson: const {
        'connectorToolIds': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
    ),
  ),
  _spec(
    'delete_user_skill',
    'Delete a user-created skill by slug.',
    _schema(['skillSlug']),
  ),
  _spec(
    'list_skill_resources',
    'List resources for a user skill.',
    _schema(['skillSlug']),
  ),
  _spec(
    'get_skill_resource',
    'Get a resource for a user skill by slug.',
    _schema(['skillSlug', 'resourceSlug']),
  ),
  _spec(
    'create_skill_resource',
    'Create a text or Markdown resource for a user skill.',
    _schema(['skillSlug', 'title', 'description', 'content']),
  ),
  _spec(
    'update_skill_resource',
    'Update a user skill resource by slug.',
    _schema(
      ['skillSlug', 'resourceSlug'],
      extra: const {
        'title': 'string',
        'description': 'string',
        'content': 'string',
      },
    ),
  ),
  _spec(
    'delete_skill_resource',
    'Delete a user skill resource by slug.',
    _schema(['skillSlug', 'resourceSlug']),
  ),
  _spec(
    'clone_app_skill',
    'Clone a declarative built-in service skill as a user skill.',
    _schema(['appSkillSlug']),
  ),
]);

List<ToolSpec> _strictSkillsManagerToolSpecs(List<ToolSpec> specs) => [
  for (final spec in specs)
    if (_strictSchemaExceptions.contains(spec.name))
      spec
    else
      ToolSpec(
        name: spec.name,
        description: spec.description,
        inputJsonSchema: strictProviderToolSchema(spec.inputJsonSchema),
      ),
];

const _strictSchemaExceptions = {
  'skill__app_native__skills_manager__create_user_skill',
  'skill__app_native__skills_manager__update_skill_resource',
  'skill__app_native__skills_manager__update_user_skill',
};

ToolSpec _spec(
  String slug,
  String description, [
  Map<String, Object?>? schema,
]) => ToolSpec(
  name: 'skill__app_native__${skillsManagerSkillSlug}__$slug',
  description: description,
  inputJsonSchema:
      schema ??
      const {
        'type': 'object',
        'properties': <String, Object?>{},
        'required': <String>[],
        'additionalProperties': false,
      },
);

Map<String, Object?> _schema(
  List<String> required, {
  Map<String, String> extra = const {},
  Map<String, Object?> extraJson = const {},
  Set<String> objectFields = const {},
}) {
  final properties = <String, Object?>{
    for (final field in required)
      field: {'type': objectFields.contains(field) ? 'object' : 'string'},
    for (final entry in extra.entries) entry.key: {'type': entry.value},
    ...extraJson,
  };
  return {
    'type': 'object',
    'properties': properties,
    'required': required,
    'additionalProperties': false,
  };
}
