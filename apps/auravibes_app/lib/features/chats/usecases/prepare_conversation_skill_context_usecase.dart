import 'package:auravibes_app/features/chats/agent_adapters/app_agent_continuation_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/build_skill_context_messages_service.dart';
import 'package:auravibes_app/features/chats/models/skill_context_preparation_failure.dart';
import 'package:auravibes_app/features/chats/models/skill_context_preparation_result.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class PrepareConversationSkillContextUsecase({
  required final Future<List<AvailableSkill>> Function(
    String workspaceId,
    String conversationId,
    SkillLoadFilter filter,
  )
  listLoadedSkills,
  required final Future<List<ChatMessage>> Function(
    String workspaceId,
    String conversationId,
  )
  buildContextMessages,
  required final Future<List<ToolSpec>> Function(
    String workspaceId,
    String conversationId,
  )
  previewTools,
  required final Future<bool> Function(String conversationId) supportsTools,
}) {
  Future<SkillContextPreparationResult> call({
    required String workspaceId,
    required String conversationId,
  }) async {
    try {
      return await _prepare(workspaceId, conversationId);
    } on Object {
      return const SkillContextPreparationResult(
        selectedRevisions: {},
        canActivate: false,
        failure: .preparationFailed,
      );
    }
  }

  Future<SkillContextPreparationResult> _prepare(
    String workspaceId,
    String conversationId,
  ) async {
    final selectedRevisions = _selectedRevisions(
      await buildContextMessages(workspaceId, conversationId),
    );
    final selectedSkills = await listLoadedSkills(
      workspaceId,
      conversationId,
      .loaded,
    );
    final failure = _preparationFailure(selectedSkills, selectedRevisions);
    if (failure != null) {
      return SkillContextPreparationResult(
        selectedRevisions: selectedRevisions,
        canActivate: false,
        failure: failure,
      );
    }

    return SkillContextPreparationResult(
      selectedRevisions: selectedRevisions,
      canActivate: await _canActivate(workspaceId, conversationId),
      failure: null,
    );
  }

  SkillContextPreparationFailure? _preparationFailure(
    List<AvailableSkill> selectedSkills,
    Map<String, String> selectedRevisions,
  ) {
    if (_hasMissingCredentials(selectedSkills)) return .missingCredentials;
    if (_hasUnknownCredentials(selectedSkills)) return .preparationFailed;
    if (_hasUnresolvedSkill(selectedSkills, selectedRevisions)) {
      return .unavailableMetadata;
    }

    return null;
  }

  Future<bool> _canActivate(String workspaceId, String conversationId) async {
    if (!await supportsTools(conversationId)) return false;

    final tools = await previewTools(workspaceId, conversationId);

    return tools.any((tool) => tool.name == activateSkillToolName);
  }
}

Map<String, String> _selectedRevisions(List<ChatMessage> messages) {
  final catalog = messages
      .where((message) => message.metadata['kind'] == skillCatalogMetadataKind)
      .firstOrNull;
  final raw = catalog?.metadata[skillCatalogSelectedRevisionsMetadataKey];
  if (raw is! Map) return const {};

  return _stringEntries(raw);
}

Map<String, String> _stringEntries(Map<Object?, Object?> raw) {
  final entries = <String, String>{};
  for (final entry in raw.entries) {
    if (_isStringPair(entry.key, entry.value)) {
      entries[entry.key as String] = entry.value as String;
    }
  }

  return entries;
}

bool _isStringPair(Object? key, Object? value) =>
    key is String && value is String;

bool _hasMissingCredentials(List<AvailableSkill> skills) =>
    skills.any((skill) => skill.credentialReadiness == .missing);

bool _hasUnknownCredentials(List<AvailableSkill> skills) =>
    skills.any((skill) => skill.credentialReadiness == .unknown);

bool _hasUnresolvedSkill(
  List<AvailableSkill> skills,
  Map<String, String> revisions,
) => skills.any((skill) => !revisions.containsKey(skill.slug));

final prepareConversationSkillContextUsecaseProvider =
    Provider<PrepareConversationSkillContextUsecase>((ref) {
      return PrepareConversationSkillContextUsecase(
        listLoadedSkills: (workspaceId, conversationId, filter) => ref
            .read(listAvailableSkillsUsecaseProvider(workspaceId))
            .call(
              conversationId: conversationId,
              workspaceId: workspaceId,
              filter: filter,
            ),
        buildContextMessages: (workspaceId, conversationId) => ref
            .read(buildSkillContextMessagesServiceProvider)
            .call(conversationId: conversationId, workspaceId: workspaceId),
        previewTools: (workspaceId, conversationId) => ref
            .read(loadConversationToolSpecsUsecaseProvider(workspaceId))
            .preview(conversationId: conversationId, workspaceId: workspaceId),
        supportsTools: (conversationId) => ref
            .read(appAgentContinuationProvider)
            .supportsToolsForConversation(conversationId),
      );
    });
