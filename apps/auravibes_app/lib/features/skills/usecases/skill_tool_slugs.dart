import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

abstract final class SkillToolSlugs {
  static const skillsManager = 'skills_manager';
  static const listUserSkills = 'list_user_skills';
  static const getUserSkill = 'get_user_skill';
  static const createUserSkill = 'create_user_skill';
  static const updateUserSkill = 'update_user_skill';
  static const deleteUserSkill = 'delete_user_skill';
  static const listSkillTemplateTools = 'list_skill_template_tools';
  static const getSkillTemplateTool = 'get_skill_template_tool';
  static const createSkillTemplateTool = 'create_skill_template_tool';
  static const updateSkillTemplateTool = 'update_skill_template_tool';
  static const deleteSkillTemplateTool = 'delete_skill_template_tool';
  static const listSkillCredentialDefinitions =
      'list_skill_credential_definitions';
  static const getSkillCredentialDefinition = 'get_skill_credential_definition';
  static const createSkillCredentialDefinition =
      'create_skill_credential_definition';
  static const updateSkillCredentialDefinition =
      'update_skill_credential_definition';
  static const deleteSkillCredentialDefinition =
      'delete_skill_credential_definition';
}

class const BuildAppSkillNativeToolSpecsUsecase(
  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase,
  final ListAppSkillCredentialCandidatesUsecase
  _listAppSkillCredentialCandidatesUsecase, [
  final ConversationRepository? _conversationRepository,
]) {
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final conversation = await _conversationRepository?.getConversationById(
      conversationId,
    );
    final isUnknownConversation =
        _conversationRepository != null && conversation == null;
    final isSubAgentConversation = conversation?.parentConversationId != null;
    final skillKeys = <String>{};
    final runtimeSkills = [...loadedSkills, ...extraSkills]
        .where((skill) => skillKeys.add('${skill.source.name}:${skill.id}'))
        .toList();
    final hasSkillsManager = runtimeSkills.any(
      (skill) =>
          skill.source == SkillSource.app &&
          skill.slug == SkillToolSlugs.skillsManager,
    );
    final specs = <ToolSpec>[if (hasSkillsManager) ...skillsManagerToolSpecs];
    final hasSubAgents = runtimeSkills.any(
      (skill) =>
          skill.source == SkillSource.app && skill.slug == agentsSkillSlug,
    );
    if (hasSubAgents && !isUnknownConversation && !isSubAgentConversation) {
      final subAgentsSkill = _appSkillRegistry.getBySlug(agentsSkillSlug);
      if (subAgentsSkill != null) {
        specs.addAll(_appSkillToolSpecs(subAgentsSkill, const []));
      }
    }

    for (final skill in serviceSkillDefinitions) {
      final isLoaded = runtimeSkills.any(
        (loaded) =>
            loaded.source == SkillSource.app && loaded.slug == skill.slug,
      );
      if (!isLoaded) continue;
      final candidates = await _listAppSkillCredentialCandidatesUsecase.call(
        workspaceId: workspaceId,
        skill: skill,
      );
      specs.addAll(_appSkillToolSpecs(skill, candidates));
    }

    return specs;
  }
}

List<ToolSpec> _appSkillToolSpecs(
  AppSkillDefinition skill,
  List<AppSkillCredentialCandidate> candidates,
) {
  return [
    for (final tool in skill.nativeTools)
      ?_appSkillToolSpec(skill, tool, candidates),
  ];
}

ToolSpec? _appSkillToolSpec(
  AppSkillDefinition skill,
  AppSkillToolDefinition tool,
  List<AppSkillCredentialCandidate> candidates,
) {
  return materializeSkillTool(
    SkillToolMaterializationInput(
      name: AgentResolvedToolName.skillNative(
        tableId: tool.slug,
        skillSlug: skill.slug,
        toolIdentifier: tool.slug,
      ).fullName,
      description: tool.description,
      schema: tool.inputJsonSchema,
      requiresCredential: tool.requiresCredential,
      credentialIds: candidates.map((candidate) => candidate.id),
    ),
  );
}

final buildAppSkillNativeToolSpecsUsecaseProvider =
    Provider<BuildAppSkillNativeToolSpecsUsecase>((ref) {
      return BuildAppSkillNativeToolSpecsUsecase(
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
        ref.watch(listAppSkillCredentialCandidatesUsecaseProvider),
        ref.watch(conversationRepositoryProvider),
      );
    });

const _appSkillRegistry = AppSkillRegistry();
