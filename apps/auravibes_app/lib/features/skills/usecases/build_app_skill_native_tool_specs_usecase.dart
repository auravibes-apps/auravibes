import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
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
  const BuildAppSkillNativeToolSpecsUsecase(
    this._listAvailableSkillsUsecase,
    this._listAppSkillCredentialCandidatesUsecase, [
    this._conversationRepository,
  ]);

  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase;
  final ListAppSkillCredentialCandidatesUsecase
  _listAppSkillCredentialCandidatesUsecase;
  final ConversationRepository? _conversationRepository;

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
    final runtimeSkills =
        [
              ...loadedSkills,
              ...extraSkills,
            ]
            .where((skill) => skillKeys.add('${skill.source.name}:${skill.id}'))
            .toList();
    final hasSkillsManager = runtimeSkills.any(
      (skill) =>
          skill.source == SkillSource.app && skill.slug == skillsManagerSlug,
    );
    final specs = <ToolSpec>[
      if (hasSkillsManager) ...skillsManagerToolSpecs,
    ];
    final hasSubAgents = runtimeSkills.any(
      (skill) =>
          skill.source == SkillSource.app && skill.slug == agentsSkillSlug,
    );
    if (hasSubAgents && !isUnknownConversation && !isSubAgentConversation) {
      final subAgentsSkill = _appSkillRegistry.getBySlug(
        agentsSkillSlug,
      );
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
