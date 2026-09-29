import 'package:auravibes_app/features/chats/agent_adapters/build_skill_context_messages_service.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/message_persisted_exception.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/conversation_skill_action.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class ApplyConversationSkillActionUsecase({
  required final Future<String?> Function(String conversationId)
  workspaceIdForConversation,
  required final Future<List<AvailableSkill>> Function(
    String workspaceId,
    String conversationId,
    SkillLoadFilter filter,
  )
  listSkills,
  required final Future<List<ChatMessage>> Function(
    String workspaceId,
    String conversationId,
  )
  buildContextMessages,
  required final Future<void> Function(
    String workspaceId,
    String conversationId,
    String slug,
  )
  loadSkill,
  required final Future<void> Function(
    String workspaceId,
    String conversationId,
    ChatDraft draft,
  )
  sendMessage,
}) {
  final Set<String> _inProgress = {};

  Future<ConversationSkillActionResult> call({
    required String workspaceId,
    required String conversationId,
    required String slug,
    required ConversationSkillAction action,
    required String Function(String title) userRequestForSkill,
    String? expectedCatalogRevision,
  }) async {
    final key = '$workspaceId\u0000$conversationId\u0000$slug';
    if (!_inProgress.add(key)) return .inProgress;

    try {
      return await _apply(
        workspaceId: workspaceId,
        conversationId: conversationId,
        slug: slug,
        action: action,
        expectedCatalogRevision: expectedCatalogRevision,
        userRequestForSkill: userRequestForSkill,
      );
    } finally {
      final _ = _inProgress.remove(key);
    }
  }
}

extension on ApplyConversationSkillActionUsecase {
  Future<ConversationSkillActionResult> _apply({
    required String workspaceId,
    required String conversationId,
    required String slug,
    required ConversationSkillAction action,
    required String? expectedCatalogRevision,
    required String Function(String title) userRequestForSkill,
  }) async {
    final String? conversationWorkspaceId;
    try {
      conversationWorkspaceId = await workspaceIdForConversation(
        conversationId,
      );
    } on Object {
      return .unavailable;
    }
    if (conversationWorkspaceId != workspaceId) {
      return .unauthorized;
    }

    final AvailableSkill? skill;
    final List<AvailableSkill> loadedSkills;
    try {
      skill = (await listSkills(
        workspaceId,
        conversationId,
        .catalog,
      )).where((item) => item.slug == slug).firstOrNull;
      if (skill == null) return .unavailable;

      if (expectedCatalogRevision != null &&
          !await _matchesCatalogRevision(
            workspaceId,
            conversationId,
            expectedCatalogRevision,
          )) {
        return .stale;
      }

      loadedSkills = await listSkills(workspaceId, conversationId, .loaded);
    } on Object {
      return .unavailable;
    }

    final isLoaded = loadedSkills.any((item) => item.slug == slug);
    if (action == .add && isLoaded) return .alreadyAdded;
    if (skill.credentialReadiness == .missing) return .credentialsMissing;
    if (skill.credentialReadiness == .unknown) return .credentialsUnknown;
    try {
      await loadSkill(workspaceId, conversationId, slug);
    } on LoadConversationSkillException catch (error) {
      return _loadFailure(error);
    } on Object {
      return skill.credentialReadiness == .unknown
          ? .credentialsUnknown
          : .unavailable;
    }

    if (action == .add) return .added;

    try {
      await sendMessage(
        workspaceId,
        conversationId,
        .new(text: userRequestForSkill(skill.title)),
      );
    } on MessagePersistedException {
      return .used;
    }

    return .used;
  }

  Future<bool> _matchesCatalogRevision(
    String workspaceId,
    String conversationId,
    String expectedRevision,
  ) async {
    try {
      final messages = await buildContextMessages(workspaceId, conversationId);
      final catalog = messages
          .where(
            (message) => message.metadata['kind'] == skillCatalogMetadataKind,
          )
          .firstOrNull;

      return catalog?.metadata[skillCatalogRevisionMetadataKey] ==
          expectedRevision;
    } on Object {
      return false;
    }
  }

  ConversationSkillActionResult _loadFailure(
    LoadConversationSkillException error,
  ) {
    if (error.localizationKey ==
        LocaleKeys.skills_screen_error_requires_credential) {
      return .credentialsMissing;
    }
    if (error.localizationKey ==
        LocaleKeys.skills_screen_error_app_skill_disabled) {
      return .unavailable;
    }

    return .unavailable;
  }
}

final applyConversationSkillActionUsecaseProvider =
    Provider<ApplyConversationSkillActionUsecase>((ref) {
      final conversations = ref.watch(conversationRepositoryProvider);

      return ApplyConversationSkillActionUsecase(
        workspaceIdForConversation: (conversationId) async =>
            (await conversations.getConversationById(conversationId))
                ?.workspaceId,
        listSkills: (workspaceId, conversationId, filter) => ref
            .read(listAvailableSkillsUsecaseProvider(workspaceId))
            .call(
              conversationId: conversationId,
              workspaceId: workspaceId,
              filter: filter,
            ),
        buildContextMessages: (workspaceId, conversationId) => ref
            .read(buildSkillContextMessagesServiceProvider)
            .call(conversationId: conversationId, workspaceId: workspaceId),
        loadSkill: (workspaceId, conversationId, slug) => ref
            .read(loadConversationSkillUsecaseProvider(workspaceId))
            .call(
              conversationId: conversationId,
              workspaceId: workspaceId,
              slug: slug,
            ),
        sendMessage: (workspaceId, conversationId, draft) => ref
            .read(sendMessageUsecaseProvider(workspaceId))
            .call(conversationId: conversationId, draft: draft),
      );
    });
