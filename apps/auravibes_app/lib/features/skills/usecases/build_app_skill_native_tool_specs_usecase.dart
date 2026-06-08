import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:riverpod/riverpod.dart';

const skillsManagerSlug = 'skills_manager';
const listUserSkillsToolSlug = 'list_user_skills';
const getUserSkillToolSlug = 'get_user_skill';
const createUserSkillToolSlug = 'create_user_skill';
const updateUserSkillToolSlug = 'update_user_skill';
const deleteUserSkillToolSlug = 'delete_user_skill';
const listSkillTemplateToolsToolSlug = 'list_skill_template_tools';
const getSkillTemplateToolToolSlug = 'get_skill_template_tool';
const createSkillTemplateToolSlug = 'create_skill_template_tool';
const updateSkillTemplateToolSlug = 'update_skill_template_tool';
const deleteSkillTemplateToolSlug = 'delete_skill_template_tool';
const listSkillCredentialDefinitionsToolSlug =
    'list_skill_credential_definitions';
const getSkillCredentialDefinitionToolSlug = 'get_skill_credential_definition';
const createSkillCredentialDefinitionToolSlug =
    'create_skill_credential_definition';
const updateSkillCredentialDefinitionToolSlug =
    'update_skill_credential_definition';
const deleteSkillCredentialDefinitionToolSlug =
    'delete_skill_credential_definition';

class BuildAppSkillNativeToolSpecsUsecase {
  const BuildAppSkillNativeToolSpecsUsecase(this._listAvailableSkillsUsecase);

  final ListAvailableSkillsUsecase _listAvailableSkillsUsecase;

  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final hasSkillsManager = loadedSkills.any(
      (skill) =>
          skill.source == SkillSource.app && skill.slug == skillsManagerSlug,
    );
    if (!hasSkillsManager) return const [];

    return const [
      ToolSpec(
        name: 'skill__app__skills_manager__list_user_skills',
        description:
            'List all user-created skills in the current workspace. Use this '
            'before creating or editing skills to avoid duplicates.',
        inputJsonSchema: {
          'type': 'object',
          'properties': <String, Object?>{},
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__get_user_skill',
        description:
            'Get one user-created skill by slug, including its credential '
            'definition id if configured.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
          },
          'required': ['skillSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__create_user_skill',
        description:
            'Create a user skill in the current workspace. Slug is generated '
            'from title and is not editable. To associate credentials, pass '
            'the definitionId returned by create_skill_credential_definition '
            'as credentialDefinitionId.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Alphanumeric skill title with spaces.',
            },
            'description': {
              'type': 'string',
              'description': 'Short skill description.',
            },
            'content': {
              'type': 'string',
              'description': 'Skill instructions loaded into agent context.',
            },
            'credentialDefinitionId': {
              'type': 'string',
              'description': 'Optional user credential definition id.',
            },
            'isCredentialOptional': {
              'type': 'boolean',
              'description':
                  'Whether the skill can be loaded without a saved '
                  'credential for its credential definition.',
            },
            'isEnabled': {'type': 'boolean'},
          },
          'required': ['title', 'description', 'content'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__update_user_skill',
        description:
            'Update an existing user skill by slug. Slug remains immutable.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
            'title': {'type': 'string'},
            'description': {'type': 'string'},
            'content': {'type': 'string'},
            'credentialDefinitionId': {
              'type': 'string',
              'description':
                  'Optional user credential definition id. Pass an empty '
                  'string to clear the association.',
            },
            'isCredentialOptional': {
              'type': 'boolean',
              'description':
                  'Whether the skill can be loaded without a saved '
                  'credential for its credential definition.',
            },
            'isEnabled': {'type': 'boolean'},
          },
          'required': ['skillSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__delete_user_skill',
        description: 'Delete a user-created skill by slug.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
          },
          'required': ['skillSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__list_skill_template_tools',
        description: 'List URL template tools for a user skill by skill slug.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
          },
          'required': ['skillSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__get_skill_template_tool',
        description:
            'Get one URL template tool for a user skill by skill slug and '
            'tool slug.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
            'toolSlug': {'type': 'string'},
          },
          'required': ['skillSlug', 'toolSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__create_skill_template_tool',
        description:
            'Create a URL template tool for a user skill. Template and inputs '
            'must be JSON objects.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
            'title': {'type': 'string'},
            'description': {
              'type': 'string',
              'description': 'How the agent should decide when to use it.',
            },
            'template': {
              'type': 'object',
              'description':
                  'URL template object. Use Liquid in url, query, headers, '
                  'and body. Use bodyFormat json for JSON bodies and '
                  '{{ input.name | json }} for dynamic JSON values.',
            },
            'inputs': {
              'type': 'object',
              'description': 'Input definition JSON object.',
            },
            'requiresCredential': {
              'type': 'boolean',
              'description':
                  'Whether this tool must receive a credentialId argument.',
            },
            'isEnabled': {'type': 'boolean'},
          },
          'required': [
            'skillSlug',
            'title',
            'description',
            'template',
            'inputs',
          ],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__update_skill_template_tool',
        description: 'Update a URL template tool for a user skill by slug.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
            'toolSlug': {'type': 'string'},
            'title': {'type': 'string'},
            'description': {'type': 'string'},
            'template': {
              'type': 'object',
              'description':
                  'URL template object using Liquid in url, query, headers, '
                  'and body.',
            },
            'inputs': {'type': 'object'},
            'requiresCredential': {
              'type': 'boolean',
              'description':
                  'Whether this tool must receive a credentialId argument.',
            },
            'isEnabled': {'type': 'boolean'},
          },
          'required': ['skillSlug', 'toolSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__delete_skill_template_tool',
        description: 'Delete a URL template tool from a user skill by slug.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'skillSlug': {'type': 'string'},
            'toolSlug': {'type': 'string'},
          },
          'required': ['skillSlug', 'toolSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__list_skill_credential_definitions',
        description:
            'List reusable user credential definitions in the current '
            'workspace.',
        inputJsonSchema: {
          'type': 'object',
          'properties': <String, Object?>{},
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__get_skill_credential_definition',
        description:
            'Get one reusable user credential definition by slug in the '
            'current workspace.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'definitionSlug': {'type': 'string'},
          },
          'required': ['definitionSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__create_skill_credential_definition',
        description:
            'Create a reusable user credential definition in the current '
            'workspace.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'attributes': {
              'type': 'object',
              'description':
                  'Credential attribute definition object. Each attribute may '
                  'define description, optional, and secret. secret defaults '
                  'to true; set secret false only for safe display values.',
            },
          },
          'required': ['title', 'attributes'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__update_skill_credential_definition',
        description:
            'Update a reusable user credential definition by slug in the '
            'current workspace.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'definitionSlug': {'type': 'string'},
            'title': {'type': 'string'},
            'attributes': {
              'type': 'object',
              'description':
                  'Credential attribute definition object. Each attribute may '
                  'define description, optional, and secret. secret defaults '
                  'to true; set secret false only for safe display values.',
            },
          },
          'required': ['definitionSlug'],
          'additionalProperties': false,
        },
      ),
      ToolSpec(
        name: 'skill__app__skills_manager__delete_skill_credential_definition',
        description:
            'Delete a reusable user credential definition by slug in the '
            'current workspace.',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'definitionSlug': {'type': 'string'},
          },
          'required': ['definitionSlug'],
          'additionalProperties': false,
        },
      ),
    ];
  }
}

final buildAppSkillNativeToolSpecsUsecaseProvider =
    Provider<BuildAppSkillNativeToolSpecsUsecase>((ref) {
      return BuildAppSkillNativeToolSpecsUsecase(
        ref.watch(listAvailableSkillsUsecaseProvider),
      );
    });
