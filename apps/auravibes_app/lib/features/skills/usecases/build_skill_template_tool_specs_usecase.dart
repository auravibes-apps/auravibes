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

class const BuildSkillTemplateToolSpecsUsecase(
  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase,
  final SkillTemplateToolsRepository _skillTemplateToolsRepository,
  final SkillCredentialsRepository _skillCredentialsRepository, {
  final Future<WorkspaceSession> Function(String workspaceId)? workspaceSession,
}) {
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    final runtimeSkills = await _runtimeSkills(
      conversationId: conversationId,
      workspaceId: workspaceId,
      extraSkills: extraSkills,
    );

    return await _buildToolSpecs(workspaceId, runtimeSkills);
  }
}

extension on BuildSkillTemplateToolSpecsUsecase {
  Future<List<AvailableSkill>> _runtimeSkills({
    required String conversationId,
    required String workspaceId,
    required List<AvailableSkill> extraSkills,
  }) async {
    await _ensureLocalSession(workspaceId);
    final loadedSkills = await _loadedSkills(conversationId, workspaceId);

    return _uniqueSkills(loadedSkills, extraSkills);
  }

  Future<void> _ensureLocalSession(String workspaceId) async {
    final session = await workspaceSession?.call(workspaceId);
    if (session?.cloud != null) {
      throw StateError(
        'Cloud template tools execute in the server agent loop.',
      );
    }
  }

  Future<List<AvailableSkill>> _loadedSkills(
    String conversationId,
    String workspaceId,
  ) {
    return _listAvailableSkillsUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: .loaded,
    );
  }

  List<AvailableSkill> _uniqueSkills(
    List<AvailableSkill> loadedSkills,
    List<AvailableSkill> extraSkills,
  ) {
    final skillKeys = <String>{};
    return [...loadedSkills, ...extraSkills]
        .where((skill) => skillKeys.add('${skill.source.name}:${skill.id}'))
        .toList();
  }

  Future<List<ToolSpec>> _buildToolSpecs(
    String workspaceId,
    List<AvailableSkill> runtimeSkills,
  ) async {
    final specs = <ToolSpec>[];

    for (final skill in runtimeSkills.where(
      (skill) => skill.source == SkillSource.user,
    )) {
      await _addSkillToolSpecs(
        workspaceId: workspaceId,
        skill: skill,
        specs: specs,
      );
    }

    return specs;
  }

  Future<void> _addSkillToolSpecs({
    required String workspaceId,
    required AvailableSkill skill,
    required List<ToolSpec> specs,
  }) async {
    final tools = await _skillTemplateToolsRepository.getSkillTools(skill.id);
    for (final tool in tools.where((tool) => tool.isEnabled)) {
      await _addToolSpec(specs, workspaceId, skill, tool);
    }
  }

  Future<void> _addToolSpec(
    List<ToolSpec> specs,
    String workspaceId,
    AvailableSkill skill,
    SkillTemplateToolEntity tool,
  ) async {
    final spec = await _buildToolSpec(
      workspaceId: workspaceId,
      skill: skill,
      tool: tool,
    );
    if (spec != null) specs.add(spec);
  }

  Future<ToolSpec?> _buildToolSpec({
    required String workspaceId,
    required AvailableSkill skill,
    required SkillTemplateToolEntity tool,
  }) async {
    final inputDefinitions = SkillTemplateInputDefinition.parseMap(
      tool.inputsJson,
    );
    final credentialIds = await _credentialIds(
      workspaceId: workspaceId,
      skill: skill,
      tool: tool,
    );
    if (credentialIds == null) return null;

    return _materializeToolSpec(skill, tool, inputDefinitions, credentialIds);
  }

  ToolSpec _materializeToolSpec(
    AvailableSkill skill,
    SkillTemplateToolEntity tool,
    Map<String, SkillTemplateInputDefinition> inputDefinitions,
    List<String> credentialIds,
  ) => materializeSkillTool(
    .new(
      name: _toolName(skill, tool),
      description: _toolDescription(skill, tool),
      schema: _inputSchema(inputDefinitions),
      requiresCredential: tool.requiresCredential,
      credentialIds: credentialIds,
    ),
  );

  String _toolName(AvailableSkill skill, SkillTemplateToolEntity tool) =>
      AgentResolvedToolName.skillTemplate(
        tableId: tool.slug,
        skillSlug: skill.slug,
        toolIdentifier: tool.slug,
      ).fullName;

  Map<String, dynamic> _inputSchema(
    Map<String, SkillTemplateInputDefinition> inputDefinitions,
  ) => {
    'type': 'object',
    'properties': _inputProperties(inputDefinitions),
    'required': _requiredInputs(inputDefinitions),
    'additionalProperties': false,
  };

  Map<String, dynamic> _inputProperties(
    Map<String, SkillTemplateInputDefinition> inputDefinitions,
  ) => {
    for (final entry in inputDefinitions.entries)
      entry.key: {
        'type': entry.value.type,
        'description': entry.value.description,
      },
  };

  List<String> _requiredInputs(
    Map<String, SkillTemplateInputDefinition> inputDefinitions,
  ) => [
    for (final entry in inputDefinitions.entries)
      if (!entry.value.optional) entry.key,
  ];

  String _toolDescription(AvailableSkill skill, SkillTemplateToolEntity tool) =>
      tool.description.trim().isEmpty
      ? '${tool.title}: ${skill.description}'
      : tool.description;
}

extension on BuildSkillTemplateToolSpecsUsecase {
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
