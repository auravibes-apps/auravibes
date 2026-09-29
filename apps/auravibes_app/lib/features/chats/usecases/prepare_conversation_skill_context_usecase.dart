import 'package:auravibes_app/features/chats/agent_adapters/app_agent_continuation_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/build_skill_context_messages_service.dart';
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
      final contextMessages = await buildContextMessages(
        workspaceId,
        conversationId,
      );
      final selectedRevisions = _selectedRevisions(contextMessages);
      final selectedSkills = await listLoadedSkills(
        workspaceId,
        conversationId,
        .loaded,
      );
      if (selectedSkills.any(
        (skill) => skill.credentialReadiness == .missing,
      )) {
        return SkillContextPreparationResult(
          selectedRevisions: selectedRevisions,
          canActivate: false,
          failure: .missingCredentials,
        );
      }
      if (selectedSkills.any(
        (skill) => skill.credentialReadiness == .unknown,
      )) {
        return SkillContextPreparationResult(
          selectedRevisions: selectedRevisions,
          canActivate: false,
          failure: .preparationFailed,
        );
      }
      if (selectedSkills.any(
        (skill) => !selectedRevisions.containsKey(skill.slug),
      )) {
        return SkillContextPreparationResult(
          selectedRevisions: selectedRevisions,
          canActivate: false,
          failure: .unavailableMetadata,
        );
      }

      final tools = await previewTools(workspaceId, conversationId);
      final canActivate =
          await supportsTools(conversationId) &&
          tools.any((tool) => tool.name == activateSkillToolName);

      return SkillContextPreparationResult(
        selectedRevisions: selectedRevisions,
        canActivate: canActivate,
        failure: null,
      );
    } on Object {
      return const SkillContextPreparationResult(
        selectedRevisions: {},
        canActivate: false,
        failure: .preparationFailed,
      );
    }
  }
}

Map<String, String> _selectedRevisions(List<ChatMessage> messages) {
  final catalog = messages
      .where((message) => message.metadata['kind'] == skillCatalogMetadataKind)
      .firstOrNull;
  final raw = catalog?.metadata[skillCatalogSelectedRevisionsMetadataKey];
  if (raw is! Map) return const {};

  return {
    for (final entry in raw.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

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
