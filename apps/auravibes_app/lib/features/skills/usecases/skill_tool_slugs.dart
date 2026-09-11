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
    final loadedSkills = await _loadedSkills(conversationId, workspaceId);
    final conversationState = await _conversationState(conversationId);
    final runtimeSkills = _runtimeSkills(loadedSkills, extraSkills);

    return await _toolSpecs(runtimeSkills, workspaceId, conversationState);
  }

  Future<List<AvailableSkill>> _loadedSkills(
    String conversationId,
    String workspaceId,
  ) => _listAvailableSkillsUsecase(workspaceId).call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: .loaded,
  );

  Future<({bool isUnknown, bool isSubAgent})> _conversationState(
    String conversationId,
  ) async {
    final conversation = await _conversationRepository?.getConversationById(
      conversationId,
    );

    return (
      isUnknown: _conversationRepository != null && conversation == null,
      isSubAgent: conversation?.parentConversationId != null,
    );
  }

  Future<List<ToolSpec>> _toolSpecs(
    List<AvailableSkill> runtimeSkills,
    String workspaceId,
    ({bool isUnknown, bool isSubAgent}) conversationState,
  ) async => [
    ..._skillsManagerToolSpecs(runtimeSkills),
    ..._subAgentToolSpecs(
      runtimeSkills,
      isUnknownConversation: conversationState.isUnknown,
      isSubAgentConversation: conversationState.isSubAgent,
    ),
    ...await _serviceSkillToolSpecs(runtimeSkills, workspaceId),
  ];

  List<AvailableSkill> _runtimeSkills(
    List<AvailableSkill> loadedSkills,
    List<AvailableSkill> extraSkills,
  ) {
    final skillKeys = <String>{};

    return [...loadedSkills, ...extraSkills]
        .where((skill) => skillKeys.add('${skill.source.name}:${skill.id}'))
        .toList();
  }

  List<ToolSpec> _skillsManagerToolSpecs(List<AvailableSkill> runtimeSkills) {
    if (!_hasAppSkill(runtimeSkills, SkillToolSlugs.skillsManager)) {
      return const [];
    }

    return skillsManagerToolSpecs;
  }

  List<ToolSpec> _subAgentToolSpecs(
    List<AvailableSkill> runtimeSkills, {
    required bool isUnknownConversation,
    required bool isSubAgentConversation,
  }) {
    if (!_hasAppSkill(runtimeSkills, agentsSkillSlug) ||
        isUnknownConversation ||
        isSubAgentConversation) {
      return const [];
    }

    final subAgentsSkill = _appSkillRegistry.getBySlug(agentsSkillSlug);
    if (subAgentsSkill == null) return const [];

    return _appSkillToolSpecs(subAgentsSkill, const []);
  }

  Future<List<ToolSpec>> _serviceSkillToolSpecs(
    List<AvailableSkill> runtimeSkills,
    String workspaceId,
  ) async {
    final specs = <ToolSpec>[];
    for (final skill in serviceSkillDefinitions) {
      if (!_hasAppSkill(runtimeSkills, skill.slug)) continue;
      final candidates = await _listAppSkillCredentialCandidatesUsecase.call(
        workspaceId: workspaceId,
        skill: skill,
      );
      specs.addAll(_appSkillToolSpecs(skill, candidates));
    }

    return specs;
  }
}

bool _hasAppSkill(Iterable<AvailableSkill> skills, String slug) => skills.any(
  (skill) => skill.source == SkillSource.app && skill.slug == slug,
);

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
  final name = _appSkillToolName(skill, tool);

  return materializeSkillTool(
    .new(
      name: name,
      description: tool.description,
      schema: tool.inputJsonSchema,
      requiresCredential: tool.requiresCredential,
      credentialIds: candidates.map((candidate) => candidate.id),
    ),
  );
}

String _appSkillToolName(
  AppSkillDefinition skill,
  AppSkillToolDefinition tool,
) => AgentResolvedToolName.skillNative(
  tableId: tool.slug,
  skillSlug: skill.slug,
  toolIdentifier: tool.slug,
).fullName;

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
