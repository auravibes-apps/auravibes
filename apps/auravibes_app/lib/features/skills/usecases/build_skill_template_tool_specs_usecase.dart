import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class BuildSkillTemplateToolSpecsUsecase {
  const BuildSkillTemplateToolSpecsUsecase(
    this._listAvailableSkillsUsecase,
    this._skillTemplateToolsRepository,
    this._skillCredentialsRepository, {
    this._workspaceSession,
  });

  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase;
  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final SkillCredentialsRepository _skillCredentialsRepository;
  final Future<WorkspaceSession> Function(String workspaceId)?
  _workspaceSession;

  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    final session = await _workspaceSession?.call(workspaceId);
    if (session?.cloud != null) {
      throw StateError(
        'Cloud template tools execute in the server agent loop.',
      );
    }
    final loadedSkills = await _listAvailableSkillsUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final skillKeys = <String>{};
    final runtimeSkills = [...loadedSkills, ...extraSkills]
        .where((skill) => skillKeys.add('${skill.source.name}:${skill.id}'))
        .toList();
    final specs = <ToolSpec>[];

    for (final skill in runtimeSkills.where(
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

    final credentialIds = await _credentialIds(
      workspaceId: workspaceId,
      skill: skill,
      tool: tool,
    );
    if (credentialIds == null) return null;

    return materializeSkillTool(
      SkillToolMaterializationInput(
        name: AgentResolvedToolName.skillTemplate(
          tableId: tool.slug,
          skillSlug: skill.slug,
          toolIdentifier: tool.slug,
        ).fullName,
        description: tool.description.trim().isEmpty
            ? '${tool.title}: ${skill.description}'
            : tool.description,
        schema: {
          'type': 'object',
          'properties': inputProperties,
          'required': requiredInputs,
          'additionalProperties': false,
        },
        requiresCredential: tool.requiresCredential,
        credentialIds: credentialIds,
      ),
    );
  }

  Future<List<String>?> _credentialIds({
    required String workspaceId,
    required AvailableSkill skill,
    required SkillTemplateToolEntity tool,
  }) async {
    final credentialDefinitionId = skill.credentialDefinitionId;
    if (credentialDefinitionId == null) {
      return tool.requiresCredential ? null : const [];
    }

    final credentials = await _skillCredentialsRepository
        .getCredentialsForDefinition(
          workspaceId: workspaceId,
          credentialDefinitionId: credentialDefinitionId,
        );
    if (credentials.isEmpty) {
      return tool.requiresCredential ? null : const [];
    }

    return [for (final credential in credentials) credential.id];
  }
}

final buildSkillTemplateToolSpecsUsecaseProvider =
    Provider<BuildSkillTemplateToolSpecsUsecase>((ref) {
      return BuildSkillTemplateToolSpecsUsecase(
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
        ref.watch(skillTemplateToolsRepositoryProvider),
        ref.watch(skillCredentialsRepositoryProvider),
        workspaceSession: (workspaceId) =>
            ref.read(workspaceSessionForRouteProvider(workspaceId).future),
      );
    });
