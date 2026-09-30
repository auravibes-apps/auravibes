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
    required ConversationSkillActionRequest request,
  }) async {
    final key =
        '${request.workspaceId}\u0000'
        '${request.conversationId}\u0000'
        '${request.slug}';
    if (!_inProgress.add(key)) return .inProgress;

    try {
      return await _apply(request);
    } finally {
      final _ = _inProgress.remove(key);
    }
  }
}

typedef _ResolvedActionSkill = ({
  AvailableSkill? skill,
  List<AvailableSkill> loadedSkills,
  ConversationSkillActionResult? failure,
});

bool _isAlreadyAdded(
  ConversationSkillActionRequest request,
  List<AvailableSkill> loadedSkills,
) =>
    request.action == .add &&
    loadedSkills.any((item) => item.slug == request.slug);

ConversationSkillActionResult? _credentialFailure(AvailableSkill skill) =>
    switch (skill.credentialReadiness) {
      .missing => .credentialsMissing,
      .unknown => .credentialsUnknown,
      .ready => null,
    };

_ResolvedActionSkill _failedActionSkill(
  ConversationSkillActionResult failure,
) => (skill: null, loadedSkills: const [], failure: failure);

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

extension on ApplyConversationSkillActionUsecase {
  Future<ConversationSkillActionResult> _apply(
    ConversationSkillActionRequest request,
  ) async {
    final workspaceFailure = await _workspaceFailure(request);
    if (workspaceFailure != null) return workspaceFailure;

    return await _applyResolvedSkill(
      request,
      await _resolveActionSkill(request),
    );
  }

  Future<ConversationSkillActionResult> _applyResolvedSkill(
    ConversationSkillActionRequest request,
    _ResolvedActionSkill resolved,
  ) async {
    if (resolved.failure case final failure?) return failure;
    final skill = resolved.skill;
    if (skill == null) return .unavailable;
    if (_isAlreadyAdded(request, resolved.loadedSkills)) return .alreadyAdded;

    final credentialFailure = _credentialFailure(skill);
    if (credentialFailure != null) return credentialFailure;

    return await _loadAndFinishAction(request, skill);
  }

  Future<ConversationSkillActionResult> _loadAndFinishAction(
    ConversationSkillActionRequest request,
    AvailableSkill skill,
  ) async {
    final loadFailure = await _loadActionSkill(request);
    if (loadFailure != null) return loadFailure;

    return await _finishAction(request, skill);
  }

  Future<ConversationSkillActionResult?> _workspaceFailure(
    ConversationSkillActionRequest request,
  ) async {
    final String? conversationWorkspaceId;
    try {
      conversationWorkspaceId = await workspaceIdForConversation(
        request.conversationId,
      );
    } on Object {
      return .unavailable;
    }
    if (conversationWorkspaceId != request.workspaceId) return .unauthorized;

    return null;
  }

  Future<_ResolvedActionSkill> _resolveActionSkill(
    ConversationSkillActionRequest request,
  ) async {
    try {
      final skill = await _catalogSkill(request);
      if (skill == null) {
        return _failedActionSkill(.unavailable);
      }

      if (!await _catalogRevisionMatches(request)) {
        return _failedActionSkill(.stale);
      }

      final loadedSkills = await listSkills(
        request.workspaceId,
        request.conversationId,
        .loaded,
      );

      return (skill: skill, loadedSkills: loadedSkills, failure: null);
    } on Object {
      return _failedActionSkill(.unavailable);
    }
  }

  Future<AvailableSkill?> _catalogSkill(
    ConversationSkillActionRequest request,
  ) async {
    final workspaceId = request.workspaceId;
    final conversationId = request.conversationId;
    final slug = request.slug;
    final skills = await listSkills(workspaceId, conversationId, .catalog);

    return skills.where((item) => item.slug == slug).firstOrNull;
  }

  Future<bool> _catalogRevisionMatches(
    ConversationSkillActionRequest request,
  ) async {
    final expectedRevision = request.expectedCatalogRevision;
    if (expectedRevision == null) return true;

    return await _matchesCatalogRevision(
      request.workspaceId,
      request.conversationId,
      expectedRevision,
    );
  }

  Future<ConversationSkillActionResult?> _loadActionSkill(
    ConversationSkillActionRequest request,
  ) async {
    try {
      await loadSkill(
        request.workspaceId,
        request.conversationId,
        request.slug,
      );
    } on LoadConversationSkillException catch (error) {
      return _loadFailure(error);
    } on Object {
      return .unavailable;
    }

    return null;
  }

  Future<ConversationSkillActionResult> _finishAction(
    ConversationSkillActionRequest request,
    AvailableSkill skill,
  ) async {
    if (request.action == .add) return .added;
    try {
      await sendMessage(
        request.workspaceId,
        request.conversationId,
        .new(text: request.userRequestForSkill(skill.title)),
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
