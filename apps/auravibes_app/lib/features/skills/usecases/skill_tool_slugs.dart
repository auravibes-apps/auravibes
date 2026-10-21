import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
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
  static const listSkillResources = 'list_skill_resources';
  static const getSkillResource = 'get_skill_resource';
  static const createSkillResource = 'create_skill_resource';
  static const updateSkillResource = 'update_skill_resource';
  static const deleteSkillResource = 'delete_skill_resource';
  static const cloneAppSkill = 'clone_app_skill';
}

class const BuildAppSkillNativeToolSpecsUsecase(
  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase,
  final ConversationRepository? _conversationRepository,
) {
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    final loadedSkills = await _loadedSkills(conversationId, workspaceId);
    final conversationState = await _conversationState(conversationId);
    final runtimeSkills = _runtimeSkills(loadedSkills, extraSkills);

    return _toolSpecs(runtimeSkills, conversationState);
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

  List<ToolSpec> _toolSpecs(
    List<AvailableSkill> runtimeSkills,
    ({bool isUnknown, bool isSubAgent}) conversationState,
  ) => [
    ..._skillsManagerToolSpecs(runtimeSkills),
    ..._subAgentToolSpecs(
      runtimeSkills,
      isUnknownConversation: conversationState.isUnknown,
      isSubAgentConversation: conversationState.isSubAgent,
    ),
    ..._browserToolSpecs(runtimeSkills),
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

    return _appSkillToolSpecs(subAgentsSkill);
  }

  List<ToolSpec> _browserToolSpecs(List<AvailableSkill> runtimeSkills) {
    if (!_hasAppSkill(runtimeSkills, AppSkillRegistry.browserSkillSlug)) {
      return const [];
    }
    final browserSkill = _appSkillRegistry.getBySlug(
      AppSkillRegistry.browserSkillSlug,
    );
    if (browserSkill == null) return const [];

    return _appSkillToolSpecs(browserSkill);
  }
}

bool _hasAppSkill(Iterable<AvailableSkill> skills, String slug) => skills.any(
  (skill) => skill.source == SkillSource.app && skill.slug == slug,
);

List<ToolSpec> _appSkillToolSpecs(
  AppSkillDefinition skill,
) => [for (final tool in skill.tools) ?_appSkillToolSpec(skill, tool)];

ToolSpec? _appSkillToolSpec(
  AppSkillDefinition skill,
  AppSkillToolDefinition tool,
) {
  final name = _appSkillToolName(skill, tool);

  return ToolSpec(
    name: name,
    description: tool.description,
    inputJsonSchema: Map<String, Object?>.from(tool.inputJsonSchema),
  );
}

String _appSkillToolName(
  AppSkillDefinition skill,
  AppSkillToolDefinition tool,
) => _appSkillToolTarget(skill, tool).fullName;

AgentResolvedToolName _appSkillToolTarget(
  AppSkillDefinition skill,
  AppSkillToolDefinition tool,
) => .skillNative(
  tableId: tool.slug,
  skillSlug: skill.slug,
  toolIdentifier: tool.slug,
);

final buildAppSkillNativeToolSpecsUsecaseProvider =
    Provider<BuildAppSkillNativeToolSpecsUsecase>((ref) {
      return BuildAppSkillNativeToolSpecsUsecase(
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
        ref.watch(conversationRepositoryProvider),
      );
    });

const _appSkillRegistry = AppSkillRegistry();
