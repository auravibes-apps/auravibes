import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/skill_url_template.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:riverpod/riverpod.dart';

class BuildSkillTemplateToolSpecsUsecase {
  const BuildSkillTemplateToolSpecsUsecase(
    this._listAvailableSkillsUsecase,
    this._skillTemplateToolsRepository,
    this._skillCredentialsRepository,
  );

  final ListAvailableSkillsUsecase _listAvailableSkillsUsecase;
  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final SkillCredentialsRepository _skillCredentialsRepository;

  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final specs = <ToolSpec>[];

    for (final skill in loadedSkills.where(
      (skill) => skill.source == SkillSource.user,
    )) {
      final tools = await _skillTemplateToolsRepository.getSkillTools(skill.id);
      for (final tool in tools.where((tool) => tool.isEnabled)) {
        final spec = await _buildToolSpec(
          workspaceId: workspaceId,
          skill: skill,
          tool: tool,
        );
        if (spec != null) specs.add(spec);
      }
    }

    return specs;
  }

  Future<ToolSpec?> _buildToolSpec({
    required String workspaceId,
    required AvailableSkill skill,
    required SkillTemplateToolEntity tool,
  }) async {
    final inputDefinitions = SkillTemplateInputDefinition.parseMap(
      tool.inputsJson,
    );
    final inputProperties = {
      for (final entry in inputDefinitions.entries)
        entry.key: {
          'type': entry.value.type,
          'description': entry.value.description,
        },
    };
    final requiredInputs = [
      for (final entry in inputDefinitions.entries)
        if (!entry.value.optional) entry.key,
    ];

    final credentialSchema = await _buildCredentialSchema(
      workspaceId: workspaceId,
      skill: skill,
      tool: tool,
    );
    if (credentialSchema == null) return null;

    return ToolSpec(
      name: skillTemplateToolCompositeId(
        skillSlug: skill.slug,
        toolSlug: tool.slug,
      ),
      description: tool.description.trim().isEmpty
          ? '${tool.title}: ${skill.description}'
          : tool.description,
      inputJsonSchema: {
        'type': 'object',
        'properties': {
          ...inputProperties,
          ...credentialSchema.properties,
        },
        'required': [...requiredInputs, ...credentialSchema.requiredFields],
        'additionalProperties': false,
      },
    );
  }

  Future<_CredentialSchema?> _buildCredentialSchema({
    required String workspaceId,
    required AvailableSkill skill,
    required SkillTemplateToolEntity tool,
  }) async {
    final credentialDefinitionId = skill.credentialDefinitionId;
    if (credentialDefinitionId == null) {
      return tool.requiresCredential ? null : const _CredentialSchema.empty();
    }

    final credentials = await _skillCredentialsRepository
        .getCredentialsForDefinition(
          workspaceId: workspaceId,
          credentialDefinitionId: credentialDefinitionId,
        );
    if (credentials.isEmpty) {
      return tool.requiresCredential ? null : const _CredentialSchema.empty();
    }

    return _CredentialSchema(
      properties: {
        'credentialId': {
          'type': 'string',
          'enum': [for (final credential in credentials) credential.id],
          'description':
              'Credential id to use for this skill tool. Use '
              'list_skill_credentials to inspect available credential names.',
        },
      },
      requiredFields: tool.requiresCredential
          ? const ['credentialId']
          : const [],
    );
  }
}

class _CredentialSchema {
  const _CredentialSchema({
    required this.properties,
    required this.requiredFields,
  });

  const _CredentialSchema.empty()
    : properties = const {},
      requiredFields = const [];

  final Map<String, Object> properties;
  final List<String> requiredFields;
}

final buildSkillTemplateToolSpecsUsecaseProvider =
    Provider<BuildSkillTemplateToolSpecsUsecase>((ref) {
      return BuildSkillTemplateToolSpecsUsecase(
        ref.watch(listAvailableSkillsUsecaseProvider),
        ref.watch(skillTemplateToolsRepositoryProvider),
        ref.watch(skillCredentialsRepositoryProvider),
      );
    });

String skillTemplateToolCompositeId({
  required String skillSlug,
  required String toolSlug,
}) {
  return 'skill__user__${skillSlug}__$toolSlug';
}
