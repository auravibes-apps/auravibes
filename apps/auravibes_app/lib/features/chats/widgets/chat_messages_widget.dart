// ignore_for_file: type=lint, type=warning
// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/provider_recovery_metadata.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/browser/models/sidebar_tool_result_tab.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/widgets/chat_shared_asset.dart';
import 'package:auravibes_app/features/chats/models/chat_skill_suggestion_intent.dart';
import 'package:auravibes_app/features/chats/notifiers/activity_run_expansion_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/background_work_providers.dart';
import 'package:auravibes_app/features/chats/providers/chat_a2ui_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_bookmarks_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_result.dart';
import 'package:auravibes_app/features/chats/usecases/fork_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/message_bookmark_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_header_button.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_app/features/chats/widgets/chat_external_link.dart';
import 'package:auravibes_app/features/chats/widgets/chat_assistant_response_announcement.dart';
import 'package:auravibes_app/features/chats/widgets/shared_chat_attachment_image.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result_controller.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/conversation_skill_action.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/apply_conversation_skill_action_usecase.dart';
import 'package:auravibes_app/features/skills/widgets/conversation_skill_selector_modal.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/utils/number_formatter.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/utils/tool_metadata_decoder.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _a2uiLogger = Logger('chat_a2ui_actions');
const _latestMessageScrollThreshold = 64.0;

String? _searchTargetMessageId(BuildContext context) {
  final arguments = ModalRoute.of(context)?.settings.arguments;
  if (arguments is! Map) return null;
  final messageId = arguments['message-id'];

  return messageId is String ? messageId : null;
}

List<String> _messageIdsAroundTarget(List<String> messages, String targetId) {
  final targetIndex = messages.indexOf(targetId);
  if (targetIndex < 0) return const [];
  final start = targetIndex < 500 ? 0 : targetIndex - 499;
  final end = targetIndex + 501 < messages.length
      ? targetIndex + 501
      : messages.length;

  return messages.sublist(start, end);
}

List<String> _messageIdsWithTargetContext({
  required String targetId,
  required List<String> liveMessageIds,
  required List<MessageEntity> targetMessages,
  required Map<String, MessageEntity>? liveMessagesById,
}) {
  final targetIds = targetMessages.map((message) => message.id).toList();
  final targetIdIndex = liveMessageIds.indexOf(targetId);
  MessageEntity? targetMessage;
  for (final message in targetMessages) {
    if (message.id == targetId) {
      targetMessage = message;
      break;
    }
  }
  final targetCreatedAt = targetMessage?.createdAt;
  final liveTail = targetIdIndex >= 0
      ? liveMessageIds.skip(targetIdIndex + 1)
      : targetCreatedAt == null
      ? const <String>[]
      : liveMessageIds.where((messageId) {
          final message = liveMessagesById?[messageId];

          return message != null && message.createdAt.isAfter(targetCreatedAt);
        });
  final includedIds = targetIds.toSet();

  return [
    ...targetIds,
    for (final messageId in liveTail.take(500))
      if (includedIds.add(messageId)) messageId,
  ];
}

typedef _ActivityToolDisplay = ({String displayName, String? description});

class const ChatPrimaryScrollController({
  required final Widget child,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(_DisclosureScrollController.new);
    useEffect(() => controller.dispose, [controller]);

    return PrimaryScrollController(controller: controller, child: child);
  }
}

class const ChatMessagesWidget({
  required final String workspaceId,
  required final String conversationId,
  required final List<String> messages,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
  final Map<String, MessageEntity>? messageEntitiesById,
  final List<PendingToolCall> pendingToolCalls = const [],
  final bool showThinking = false,
  final bool isStopRequested = false,
  final Future<void> Function(MessageEntity message)? onRetryMessage,
  super.key,
}) extends HookConsumerWidget {
  // Null lets callers fall back to per-message provider reads.
  // ignore: unnecessary-nullable
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        PrimaryScrollController.of(context) as _DisclosureScrollController;
    final parentConversationId = conversationId;
    final targetMessageId = _searchTargetMessageId(context);
    final isTargetInLiveMessages =
        targetMessageId != null && messages.contains(targetMessageId);
    final isCloudWorkspace =
        ref.watch(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
        null;
    final targetMessageRequest =
        targetMessageId == null || !isCloudWorkspace || isTargetInLiveMessages
        ? null
        : (
            workspaceId: workspaceId,
            conversationId: conversationId,
            messageId: targetMessageId,
          );
    final targetMessagesAsync = targetMessageRequest == null
        ? null
        : ref.watch(
            conversationMessageTargetMessagesProvider(targetMessageRequest),
          );
    final backgroundWorksAsync = isCloudWorkspace
        ? ref.watch(
            cloudConversationBackgroundWorksProvider((
              workspaceId: workspaceId,
              conversationId: conversationId,
            )),
          )
        : ref.watch(conversationBackgroundWorksProvider(conversationId));
    final backgroundToolCallIds = backgroundWorksAsync.value
        ?.map((work) => work.identity.toolCallId)
        .toSet();
    final conversation = ref
        .watch(
          conversationByIdStreamProvider(
            workspaceId,
            conversationId: conversationId,
          ),
        )
        .value;
    final a2uiRuntime = ref.watch(chatA2uiRuntimeProvider(conversationId));
    final _ = useListenable(a2uiRuntime);
    final AsyncValue<ConversationSkillSelectorState>? skillSelectorAsync =
        a2uiRuntime.hasSkillSuggestions
        ? ref.watch(
            conversationSkillSelectorProvider(workspaceId, conversationId),
          )
        : null;
    final ConversationSkillSelectorState? skillSelectorState =
        switch (skillSelectorAsync) {
          AsyncData<ConversationSkillSelectorState>(:final value) => value,
          AsyncLoading<ConversationSkillSelectorState>(
            :final value?,
            hasValue: true,
          ) =>
            value,
          null ||
          AsyncLoading<ConversationSkillSelectorState>() ||
          AsyncError<ConversationSkillSelectorState>() => null,
        };
    final List<AvailableSkill> loadedSkills =
        skillSelectorState?.loaded ?? const <AvailableSkill>[];
    final List<AvailableSkill> loadableSkills =
        skillSelectorState?.loadable ?? const <AvailableSkill>[];
    final skillsBySlug = useMemoized(
      () => <String, AvailableSkill>{
        for (final skill in loadedSkills) skill.slug: skill,
        for (final skill in loadableSkills) skill.slug: skill,
      },
      [loadedSkills, loadableSkills],
    );
    useEffect(() {
      a2uiRuntime
        ..setWorkspaceId(workspaceId)
        ..setSkillCatalog(skillsBySlug);

      return null;
    }, [a2uiRuntime, workspaceId, skillsBySlug]);
    final isTopLevelConversation = _isTopLevelConversation(
      conversation,
      a2uiRuntime,
    );
    final submittedA2uiReplayPayloads = _submittedA2uiReplayPayloads(
      messageEntitiesById?.values ?? const <MessageEntity>[],
      conversationId,
    );
    final latestA2uiMessageId = _latestA2uiMessageId(
      messages,
      messageEntitiesById,
    );
    useEffect(
      () => _restoreA2uiEffect(
        isTopLevelConversation: isTopLevelConversation,
        runtime: a2uiRuntime,
        messageEntitiesById: messageEntitiesById,
        replayPayloadsByMessageId: submittedA2uiReplayPayloads,
        latestA2uiMessageId: latestA2uiMessageId,
      ),
      [
        a2uiRuntime,
        conversationId,
        isTopLevelConversation,
        latestA2uiMessageId,
        messageEntitiesById,
        messages,
        workspaceId,
      ],
    );
    useEffect(
      () => _listenToA2uiActionsEffect(
        context: context,
        isTopLevelConversation: isTopLevelConversation,
        runtime: a2uiRuntime,
        ref: ref,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
      [
        a2uiRuntime,
        context,
        conversationId,
        isTopLevelConversation,
        workspaceId,
      ],
    );
    final childConversations =
        ref
            .watch(
              childConversationsStreamProvider(
                workspaceId,
                parentConversationId: parentConversationId,
              ),
            )
            .value ??
        const <ConversationEntity>[];
    final compactionState = ref.watch(
      conversationCompactionExecutionStateProvider(workspaceId, conversationId),
    );
    final isCompacting =
        compactionState?.status == CompactionExecutionStatus.running;
    final targetMessages = targetMessagesAsync?.asData?.value;
    final effectiveMessageIds = switch (targetMessageId) {
      null => messages,
      _ when isCloudWorkspace =>
        targetMessages == null
            ? messages
            : _messageIdsWithTargetContext(
                targetId: targetMessageId,
                liveMessageIds: messages,
                targetMessages: targetMessages,
                liveMessagesById: messageEntitiesById,
              ),
      final messageId => _messageIdsAroundTarget(messages, messageId),
    };
    final effectiveMessageEntities = {
      ...?messageEntitiesById,
      for (final message in targetMessages ?? const <MessageEntity>[])
        message.id: message,
    };
    final resolvedMessages = <_ResolvedChatMessage?>[];
    final focusedMessageId = GoRouter.maybeOf(context) == null
        ? null
        : GoRouterState.of(context).uri.queryParameters['message-id'] ??
              GoRouterState.of(context).uri.queryParameters['messageId'];
    final focusedMessageAsync =
        focusedMessageId == null ||
            effectiveMessageIds.contains(focusedMessageId) ||
            targetMessageRequest != null
        ? null
        : ref.watch(
            fetchConversationMessageByIdProvider((
              workspaceId: workspaceId,
              conversationId: conversationId,
              messageId: focusedMessageId,
            )),
          );
    final focusedMessage = focusedMessageAsync?.asData?.value;
    for (final messageId in effectiveMessageIds) {
      final storedMessage = ref.watch(
        messageConversationByIdProvider((
          workspaceId: workspaceId,
          conversationId: conversationId,
          messageId: messageId,
        )),
      );
      final message = messageId == targetMessageId
          ? effectiveMessageEntities[messageId] ?? storedMessage
          : storedMessage ?? effectiveMessageEntities[messageId];
      final isStreaming = ref.watch(isMessageStreamingProvider(messageId));
      resolvedMessages.add(
        message == null
            ? null
            : _ResolvedChatMessage(message: message, isStreaming: isStreaming),
      );
    }
    if (focusedMessage != null &&
        !effectiveMessageIds.contains(focusedMessage.id)) {
      resolvedMessages.add(
        _ResolvedChatMessage(message: focusedMessage, isStreaming: false),
      );
    }
    if (targetMessageId != null &&
        (targetMessagesAsync?.isLoading == true ||
            focusedMessageAsync?.isLoading == true)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (targetMessagesAsync?.hasError == true) {
      if (targetMessagesAsync?.error case CloudAppException(code: 'notFound')) {
        return const Center(
          child: TextLocale(
            LocaleKeys.chats_screens_conversation_search_target_not_found,
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            const TextLocale(
              LocaleKeys.chats_screens_conversation_search_target_load_error,
            ),
            TextButton(
              onPressed: () {
                if (targetMessageRequest == null) return;
                ref.invalidate(
                  conversationMessageTargetMessagesProvider(
                    targetMessageRequest,
                  ),
                );
              },
              child: const TextLocale(
                LocaleKeys.chats_screens_conversation_search_target_retry,
              ),
            ),
          ],
        ),
      );
    }
    if (targetMessageId != null &&
        !effectiveMessageIds.contains(targetMessageId) &&
        focusedMessage == null &&
        focusedMessageAsync?.hasError != true) {
      return const Center(
        child: TextLocale(
          LocaleKeys.chats_screens_conversation_search_target_not_found,
        ),
      );
    }
    final data = _buildChatTimelineItems(
      resolvedMessages,
      submittedA2uiReplayPayloads,
      searchTargetMessageId: targetMessageId,
      pendingToolCallKeys: {
        for (final pendingCall in pendingToolCalls)
          _activityToolCallKey(pendingCall.messageId, pendingCall.toolCall.id),
      },
    ).reversed.toList(growable: false);
    final assistantResponseProgress = <ChatAssistantResponseProgress>[
      for (final source in resolvedMessages)
        if (source != null &&
            !source.message.isUser &&
            !source.message.isForkReference &&
            source.message.messageType != MessageType.system &&
            source.message.messageType != MessageType.toolCall)
          ChatAssistantResponseProgress(
            messageId: source.message.id,
            isStreaming: source.isStreaming,
            status: source.message.status,
            hasResponse: _hasAssistantResponseCandidate(
              source,
              submittedA2uiReplayPayloads,
            ),
            isAwaitingUserAction:
                source.message.status == MessageStatus.unfinished &&
                _hasA2uiMessageState(source.message),
          ),
    ];
    final retryableMessageId = _retryableUserMessageId(resolvedMessages);

    void updateDisclosure(VoidCallback update) => update();

    final thinkingCount = showThinking ? 1 : 0;
    final compactionCount = isCompacting ? 1 : 0;
    final itemCount = data.length + thinkingCount + compactionCount;
    final focusedItemIndex = focusedMessageId == null
        ? -1
        : data.indexWhere(
            (item) => _timelineItemContainsMessageId(item, focusedMessageId),
          );
    final focusedListIndex = focusedItemIndex < 0
        ? -1
        : focusedItemIndex + thinkingCount + compactionCount;
    final itemKeys = useMemoized(
      () => focusedListIndex < 0
          ? <GlobalKey>[]
          : List<GlobalKey>.generate(itemCount, (_) => GlobalKey()),
      [focusedListIndex, itemCount, messages],
    );
    final hasFocusedTarget = useRef(false);
    useEffect(() {
      hasFocusedTarget.value = false;
      return null;
    }, [focusedMessageId]);
    useEffect(
      () => _focusMessageEffect(
        controller: controller,
        itemKeys: itemKeys,
        itemIndex: focusedListIndex,
        hasFocusedTarget: hasFocusedTarget,
      ),
      [
        controller,
        focusedListIndex,
        focusedMessageId,
        hasFocusedTarget,
        itemKeys,
      ],
    );

    void jumpToLatest() {
      if (!controller.hasClients) return;
      unawaited(
        controller.animateTo(
          controller.position.minScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          reverse: true,
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final item = _buildChatTimelineItem(
              context: context,
              index: index,
              data: data,
              focusedMessageId: focusedMessageId,
              showThinking: showThinking,
              isCompacting: isCompacting,
              thinkingCount: thinkingCount,
              compactionCount: compactionCount,
              disclosureController: controller,
              onDisclosureChanged: updateDisclosure,
              parentConversationId: parentConversationId,
              childConversations: childConversations,
              workspaceId: workspaceId,
              isCloudWorkspace: isCloudWorkspace,
              backgroundToolCallIds: backgroundToolCallIds,
              a2uiRuntime: isTopLevelConversation ? a2uiRuntime : null,
              replayPayloadsByMessageId: submittedA2uiReplayPayloads,
              conversation: conversation,
              searchTargetMessageId: targetMessageId,
              retryableMessageId: retryableMessageId,
              onRetryMessage: onRetryMessage,
              onOpenToolResult: onOpenToolResult,
            );

            return focusedListIndex < 0
                ? item
                : KeyedSubtree(key: itemKeys[index], child: item);
          },
          separatorBuilder: (context, index) => const AuraSizedBox(height: .sm),
          itemCount: itemCount,
          addAutomaticKeepAlives: false,
          scrollCacheExtent: const ScrollCacheExtent.pixels(500),
          keyboardDismissBehavior: .manual,
        ),
        ChatAssistantResponseAnnouncement(
          key: ValueKey('assistant_response_announcements_$conversationId'),
          conversationId: conversationId,
          responses: assistantResponseProgress,
          isStopRequested: isStopRequested,
        ),
        if (focusedMessageAsync case AsyncError(:final error))
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: AuraCallout(
              title: CloudAppErrors.localizationKey(error).tr(),
              icon: Icons.error_outline,
              tint: .error,
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, child) =>
                controller.hasClients &&
                    controller.offset > _latestMessageScrollThreshold
                ? child!
                : const SizedBox.shrink(),
            child: AuraIconButton(
              key: const ValueKey('chat_jump_to_latest'),
              icon: Icons.keyboard_arrow_down_rounded,
              onPressed: jumpToLatest,
              size: .large,
              variant: .elevated,
              tooltip: LocaleKeys
                  .chats_screens_chat_conversation_jump_to_latest_message
                  .tr(),
            ),
          ),
        ),
      ],
    );
  }
}

bool _isTopLevelConversation(
  ConversationEntity? conversation,
  ChatA2uiRuntime runtime,
) => conversation == null
    ? runtime.enabled
    : conversation.parentConversationId == null;

void Function()? _restoreA2uiEffect({
  required bool isTopLevelConversation,
  required ChatA2uiRuntime runtime,
  required Map<String, MessageEntity>? messageEntitiesById,
  required Map<String, List<String>> replayPayloadsByMessageId,
  required String? latestA2uiMessageId,
}) {
  if (!isTopLevelConversation) return null;
  var active = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!active) return;
    _restoreA2uiMessages(
      runtime: runtime,
      messageEntitiesById: messageEntitiesById,
      replayPayloadsByMessageId: replayPayloadsByMessageId,
      latestA2uiMessageId: latestA2uiMessageId,
    );
  });
  return () {
    active = false;
  };
}

void _restoreA2uiMessages({
  required ChatA2uiRuntime runtime,
  required Map<String, MessageEntity>? messageEntitiesById,
  required Map<String, List<String>> replayPayloadsByMessageId,
  required String? latestA2uiMessageId,
}) {
  runtime.enable();
  if (messageEntitiesById == null) return;
  for (final message in messageEntitiesById.values) {
    if (message.isForkReference) continue;
    _restoreA2uiMessage(
      runtime: runtime,
      message: message,
      replayPayloads: replayPayloadsByMessageId[message.id] ?? const [],
      isLatestUnfinished:
          message.id == latestA2uiMessageId &&
          message.status == MessageStatus.unfinished,
    );
  }
  final latestMessage = latestA2uiMessageId == null
      ? null
      : messageEntitiesById[latestA2uiMessageId];
  runtime.restoreCurrentSkillSuggestionMessage(
    latestMessage != null && latestMessage.status == MessageStatus.sent
        ? latestMessage.id
        : null,
  );
}

void _restoreA2uiMessage({
  required ChatA2uiRuntime runtime,
  required MessageEntity message,
  required List<String> replayPayloads,
  required bool isLatestUnfinished,
}) {
  final metadata = message.metadata;
  final payloads = [...?metadata?.a2uiMessages, ...replayPayloads];
  final surfaceIssues =
      metadata?.a2uiIssuesBySurface ?? const <String, List<String>>{};
  final messageIssues = metadata?.a2uiMessageIssues ?? const <String>[];
  final diagnosticPayloads = metadata?.modelMetadata['a2uiDiagnosticPayloads'];
  if (!_hasA2uiState(
    payloads,
    surfaceIssues,
    messageIssues,
    diagnosticPayloads,
  )) {
    return;
  }
  runtime.restoreMessage(
    message.id,
    payloads,
    current: isLatestUnfinished,
    a2uiIssuesBySurface: surfaceIssues,
    a2uiMessageIssues: messageIssues,
    diagnosticPayloads: diagnosticPayloads is List
        ? diagnosticPayloads.whereType<String>()
        : const [],
  );
}

bool _hasA2uiState(
  List<String> payloads,
  Map<String, List<String>> surfaceIssues,
  List<String> messageIssues,
  Object? diagnosticPayloads,
) =>
    payloads.isNotEmpty ||
    surfaceIssues.isNotEmpty ||
    messageIssues.isNotEmpty ||
    diagnosticPayloads is List;

void Function()? _listenToA2uiActionsEffect({
  required BuildContext context,
  required bool isTopLevelConversation,
  required ChatA2uiRuntime runtime,
  required WidgetRef ref,
  required String workspaceId,
  required String conversationId,
}) {
  if (!isTopLevelConversation) return null;
  final subscription = runtime.actions.listen(
    (action) => unawaited(
      _submitA2uiAction(
        ref,
        runtime: runtime,
        workspaceId: workspaceId,
        conversationId: conversationId,
        action: action,
        languageCode: context.locale.languageCode,
      ),
    ),
  );
  final skillSubscription = runtime.skillSuggestions.listen(
    (intent) => unawaited(
      _submitSkillSuggestion(
        context,
        ref,
        workspaceId: workspaceId,
        conversationId: conversationId,
        intent: intent,
      ),
    ),
  );
  return () {
    unawaited(subscription.cancel());
    unawaited(skillSubscription.cancel());
  };
}

Future<void> _submitSkillSuggestion(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required String conversationId,
  required ChatSkillSuggestionIntent intent,
}) async {
  if (!context.mounted ||
      intent.workspaceId != workspaceId ||
      intent.conversationId != conversationId) {
    return;
  }

  final ConversationSkillActionResult result;
  try {
    result = await ref
        .read(applyConversationSkillActionUsecaseProvider)
        .call(
          request: (
            workspaceId: workspaceId,
            conversationId: conversationId,
            slug: intent.slug,
            action: switch (intent.action) {
              .add => .add,
              .useNow => .useNow,
            },
            expectedCatalogRevision: intent.catalogRevision,
            userRequestForSkill: (title) => LocaleKeys
                .skills_selector_use_now_request
                .tr(namedArgs: {'skill': title}),
          ),
        );
  } on Object {
    if (!context.mounted) return;
    _showConversationSkillPicker(context, workspaceId, conversationId);

    return;
  }

  if (!context.mounted) return;
  switch (result) {
    case .added || .alreadyAdded:
      ref.invalidate(
        conversationSkillSelectorProvider(workspaceId, conversationId),
      );
      return;
    case .used || .inProgress:
      return;
    case .stale ||
        .unavailable ||
        .unauthorized ||
        .connectionMissing ||
        .connectionUnknown:
      _showConversationSkillPicker(context, workspaceId, conversationId);
  }
}

void _showConversationSkillPicker(
  BuildContext context,
  String workspaceId,
  String conversationId,
) {
  if (!context.mounted) return;

  unawaited(
    ConversationSkillSelectorModal.show(
      context: context,
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
}

Widget _buildChatTimelineItem({
  required BuildContext context,
  required int index,
  required List<_ChatTimelineItem> data,
  required String? focusedMessageId,
  required bool showThinking,
  required bool isCompacting,
  required int thinkingCount,
  required int compactionCount,
  required _DisclosureScrollController disclosureController,
  required void Function(VoidCallback update) onDisclosureChanged,
  required String parentConversationId,
  required List<ConversationEntity> childConversations,
  required String workspaceId,
  required String? searchTargetMessageId,
  required bool isCloudWorkspace,
  required Set<String>? backgroundToolCallIds,
  required ChatA2uiRuntime? a2uiRuntime,
  required Map<String, List<String>> replayPayloadsByMessageId,
  required ConversationEntity? conversation,
  required String? retryableMessageId,
  required Future<void> Function(MessageEntity message)? onRetryMessage,
  required ValueChanged<SidebarToolResultTab> onOpenToolResult,
}) {
  if (showThinking && index == 0) {
    return const ChatThinkingIndicator(
      key: ValueKey('chat_thinking_indicator'),
    );
  }
  if (isCompacting && index == thinkingCount) {
    return const _CompactingIndicator();
  }

  final item = data[index - thinkingCount - compactionCount];
  final isTopLevelConversation =
      conversation != null && conversation.parentConversationId == null;
  final messageId = switch (item) {
    _ActivityRunTimelineItem(:final run) => run.responseMessageId,
    _MessageTimelineItem(:final source) => source.message.id,
  };
  final child = switch (item) {
    _ActivityRunTimelineItem(:final run) => _AssistantActivityRun(
      key: ValueKey('activity_trace_${run.id}'),
      run: run,
      onDisclosureChanged: onDisclosureChanged,
      parentConversationId: parentConversationId,
      childConversations: childConversations,
      workspaceId: workspaceId,
      isCloudWorkspace: isCloudWorkspace,
      backgroundToolCallIds: backgroundToolCallIds,
      isTopLevelConversation: isTopLevelConversation,
      a2uiRuntime: a2uiRuntime,
      a2uiReplayPayloadsByMessageId: replayPayloadsByMessageId,
      a2uiReplayPayloads: run.responseMessageId == null
          ? const []
          : replayPayloadsByMessageId[run.responseMessageId] ?? const [],
      canRetry: run.responseMessageId == retryableMessageId,
      onRetryMessage: onRetryMessage,
      onOpenToolResult: onOpenToolResult,
    ),
    _MessageTimelineItem(
      :final source,
      :final activityRenderedInSession,
      :final showResponseActions,
    ) =>
      _ChatMessageTimelineItem(
        key: ValueKey(source.message.id),
        source: source,
        isSearchTarget: messageId == searchTargetMessageId,
        activityRenderedInSession: activityRenderedInSession,
        onDisclosureChanged: onDisclosureChanged,
        parentConversationId: parentConversationId,
        childConversations: childConversations,
        workspaceId: workspaceId,
        isCloudWorkspace: isCloudWorkspace,
        backgroundToolCallIds: backgroundToolCallIds,
        isTopLevelConversation: isTopLevelConversation,
        a2uiRuntime: a2uiRuntime,
        a2uiReplayPayloads:
            replayPayloadsByMessageId[source.message.id] ?? const [],
        showResponseActions: showResponseActions,
        canRetry: source.message.id == retryableMessageId,
        onRetryMessage: onRetryMessage,
        onOpenToolResult: onOpenToolResult,
      ),
  };
  final rendered = _DisclosureSizeReporter(
    controller: disclosureController,
    child: child,
  );
  final highlighted =
      focusedMessageId != null &&
      _timelineItemContainsMessageId(item, focusedMessageId);
  final focused = highlighted
      ? DecoratedBox(
          key: ValueKey('focused_message_$focusedMessageId'),
          decoration: BoxDecoration(
            border: Border.all(color: context.auraColors.primary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: rendered,
        )
      : rendered;
  if (conversation != null &&
      messageId != null &&
      conversation.forkThroughMessageId == messageId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        focused,
        _ForkBoundaryDivider(
          conversation: conversation!,
          workspaceId: workspaceId,
        ),
      ],
    );
  }
  return focused;
}

bool _timelineItemContainsMessageId(_ChatTimelineItem item, String messageId) =>
    switch (item) {
      _ActivityRunTimelineItem(:final run) => run.sources.any(
        (source) => source.message.id == messageId,
      ),
      _MessageTimelineItem(:final source) => source.message.id == messageId,
    };

VoidCallback? _focusMessageEffect({
  required _DisclosureScrollController controller,
  required List<GlobalKey> itemKeys,
  required int itemIndex,
  required ObjectRef<bool> hasFocusedTarget,
}) {
  if (itemIndex < 0 || itemIndex >= itemKeys.length) return null;
  var active = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!active || hasFocusedTarget.value || !controller.hasClients) return;
    unawaited(
      _focusMessage(
        controller: controller,
        itemKeys: itemKeys,
        itemIndex: itemIndex,
        hasFocusedTarget: hasFocusedTarget,
      ),
    );
  });
  return () {
    active = false;
  };
}

Future<void> _focusMessage({
  required _DisclosureScrollController controller,
  required List<GlobalKey> itemKeys,
  required int itemIndex,
  required ObjectRef<bool> hasFocusedTarget,
}) async {
  if (itemKeys[itemIndex].currentContext case final targetContext?) {
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    hasFocusedTarget.value = true;
    return;
  }

  if (itemKeys.length <= 1) return;
  final position = controller.position;
  final scrollRange = position.maxScrollExtent - position.minScrollExtent;
  controller.jumpTo(
    (position.minScrollExtent + scrollRange * itemIndex / (itemKeys.length - 1))
        .clamp(position.minScrollExtent, position.maxScrollExtent),
  );

  while (controller.hasClients) {
    await WidgetsBinding.instance.endOfFrame;
    if (itemKeys[itemIndex].currentContext case final targetContext?) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      hasFocusedTarget.value = true;
      return;
    }
    if (!controller.hasClients) return;

    final mounted = [
      for (var index = 0; index < itemKeys.length; index++)
        if (itemKeys[index].currentContext case final context?) index,
    ];
    if (mounted.isEmpty) return;
    final currentPosition = controller.position;
    final direction = itemIndex < mounted.first
        ? -1
        : itemIndex > mounted.last
        ? 1
        : 0;
    if (direction == 0) return;
    final nextPosition =
        (currentPosition.pixels +
                direction * currentPosition.viewportDimension * .8)
            .clamp(
              currentPosition.minScrollExtent,
              currentPosition.maxScrollExtent,
            );
    if (nextPosition == currentPosition.pixels) return;
    controller.jumpTo(nextPosition);
  }
}

class _ResolvedChatMessage {
  const _ResolvedChatMessage({
    required this.message,
    required this.isStreaming,
  });

  final MessageEntity message;
  final bool isStreaming;
}

sealed class _ChatTimelineItem {
  const _ChatTimelineItem();
}

class _ActivityRunTimelineItem extends _ChatTimelineItem {
  const _ActivityRunTimelineItem(this.run);

  final _ActivityRun run;
}

class _MessageTimelineItem extends _ChatTimelineItem {
  const _MessageTimelineItem(
    this.source, {
    this.activityRenderedInSession = false,
    this.showResponseActions = true,
  });

  final _ResolvedChatMessage source;
  final bool activityRenderedInSession;
  final bool showResponseActions;
}

class _ActivityRun {
  const _ActivityRun(
    this.sources, {
    this.activityContentMessageIds = const {},
    this.richResponseMessageIds = const {},
    this.pendingToolCallKeys = const {},
    this.responseMessageId,
  });

  final List<_ResolvedChatMessage> sources;
  final Set<String> activityContentMessageIds;
  final Set<String> richResponseMessageIds;
  final Set<String> pendingToolCallKeys;
  final String? responseMessageId;

  String get id => sources.first.message.id;
}

typedef _ActivityToolCall = ({
  String messageId,
  MessageToolCallEntity toolCall,
  bool isForkReference,
  bool isStreaming,
  bool hideArguments,
});

String _activityToolCallKey(String messageId, String toolCallId) =>
    '$messageId:$toolCallId';

sealed class _ActivityRunEntry {
  const _ActivityRunEntry();
}

class _ActivityNarrativeEntry extends _ActivityRunEntry {
  const _ActivityNarrativeEntry({
    required this.messageId,
    required this.content,
  });

  final String messageId;
  final String content;
}

class _ActivityThinkingEntry extends _ActivityRunEntry {
  const _ActivityThinkingEntry({
    required this.messageId,
    required this.content,
  });

  final String messageId;
  final String content;
}

class _ActivityResponseEntry extends _ActivityRunEntry {
  const _ActivityResponseEntry(this.source, {required this.isFinal});

  final _ResolvedChatMessage source;
  final bool isFinal;
}

class _ActivityToolGroupEntry extends _ActivityRunEntry {
  const _ActivityToolGroupEntry(this.toolCalls);

  final List<_ActivityToolCall> toolCalls;
}

List<_ActivityRunEntry> _buildActivityRunEntries(_ActivityRun run) {
  final entries = <_ActivityRunEntry>[];
  final toolCalls = <_ActivityToolCall>[];

  void addToolGroup() {
    if (toolCalls.isEmpty) return;
    entries.add(_ActivityToolGroupEntry(List.of(toolCalls)));
    toolCalls.clear();
  }

  for (final source in run.sources) {
    final messageId = source.message.id;

    final thinking = source.message.metadata?.thinking?.trim();
    if (thinking != null && thinking.isNotEmpty) {
      addToolGroup();
      entries.add(
        _ActivityThinkingEntry(messageId: messageId, content: thinking),
      );
    }

    if (run.responseMessageId == messageId) {
      entries.add(_ActivityResponseEntry(source, isFinal: true));
    } else if (run.richResponseMessageIds.contains(messageId)) {
      addToolGroup();
      entries.add(_ActivityResponseEntry(source, isFinal: false));
    } else if (run.activityContentMessageIds.contains(messageId)) {
      final content = source.message.content.trim();
      if (content.isNotEmpty) {
        addToolGroup();
        entries.add(
          _ActivityNarrativeEntry(messageId: messageId, content: content),
        );
      }
    }

    for (final toolCall
        in source.message.metadata?.toolCalls ??
            const <MessageToolCallEntity>[]) {
      toolCalls.add((
        messageId: messageId,
        toolCall: toolCall,
        isForkReference: source.message.isForkReference,
        isStreaming: source.isStreaming,
        hideArguments: run.pendingToolCallKeys.contains(
          _activityToolCallKey(messageId, toolCall.id),
        ),
      ));
    }
  }
  addToolGroup();

  return entries;
}

String _activityToolGroupId(_ActivityToolGroupEntry entry) =>
    entry.toolCalls.first.messageId;

bool _isLiveActivityToolGroup(_ActivityToolGroupEntry entry) =>
    entry.toolCalls.any(
      (item) =>
          !item.isForkReference &&
          (item.isStreaming || item.toolCall.isPending),
    );

List<_ChatTimelineItem> _buildChatTimelineItems(
  List<_ResolvedChatMessage?> messages,
  Map<String, List<String>> replayPayloadsByMessageId, {
  Set<String> pendingToolCallKeys = const {},
  String? searchTargetMessageId,
}) {
  final items = <_ChatTimelineItem>[];
  final activitySources = <_ResolvedChatMessage>[];
  final activityContentMessageIds = <String>{};
  final richResponseMessageIds = <String>{};

  void addActivityRun({String? responseMessageId}) {
    if (activitySources.isEmpty) return;
    final run = _ActivityRun(
      List.of(activitySources),
      activityContentMessageIds: Set.of(activityContentMessageIds),
      richResponseMessageIds: Set.of(richResponseMessageIds),
      pendingToolCallKeys: pendingToolCallKeys,
      responseMessageId: responseMessageId,
    );
    if (_buildActivityRunEntries(run).isNotEmpty) {
      items.add(_ActivityRunTimelineItem(run));
    }
    activitySources.clear();
    activityContentMessageIds.clear();
    richResponseMessageIds.clear();
  }

  for (var index = 0; index < messages.length; index++) {
    final source = messages[index];
    if (source == null) {
      addActivityRun();
      continue;
    }

    final message = source.message;
    if (message.id == searchTargetMessageId) {
      addActivityRun();
      items.add(_MessageTimelineItem(source));
      continue;
    }
    final hasVisibleResponse = _hasVisibleAssistantResponse(
      message,
      replayPayloadsByMessageId,
    );
    final hasFollowingAssistantActivity = _hasFollowingAssistantActivity(
      messages,
      index,
    );
    final hasToolCalls = message.metadata?.toolCalls.isNotEmpty == true;
    final requiresMessageItem = _requiresMessageTimelineItem(
      message,
      replayPayloadsByMessageId,
    );
    final hasActivity =
        !_isTimelineBoundary(message) &&
        (_hasAssistantActivity(message) ||
            (hasVisibleResponse && hasFollowingAssistantActivity));

    if (hasActivity) {
      final awaitsA2uiAction =
          message.status == MessageStatus.unfinished &&
          _hasA2uiMessageState(message);
      final isFinalResponse =
          message.status == MessageStatus.sent &&
          hasVisibleResponse &&
          !hasFollowingAssistantActivity &&
          !hasToolCalls;
      if (requiresMessageItem && (awaitsA2uiAction || isFinalResponse)) {
        activitySources.add(source);
        addActivityRun();
        items.add(
          _MessageTimelineItem(
            source,
            activityRenderedInSession: true,
            showResponseActions: isFinalResponse && !source.isStreaming,
          ),
        );
        continue;
      }
      activitySources.add(source);
      if (hasVisibleResponse && !isFinalResponse) {
        if (requiresMessageItem) {
          richResponseMessageIds.add(message.id);
        } else {
          activityContentMessageIds.add(message.id);
        }
      }
      if (isFinalResponse) {
        addActivityRun(responseMessageId: message.id);
      }
      continue;
    }

    addActivityRun();
    items.add(
      _MessageTimelineItem(
        source,
        showResponseActions:
            message.isUser ||
            (!source.isStreaming && message.status == MessageStatus.sent),
      ),
    );
  }
  addActivityRun();

  return items;
}

bool _hasFollowingAssistantActivity(
  List<_ResolvedChatMessage?> messages,
  int index,
) {
  if (index + 1 >= messages.length) return false;
  final next = messages[index + 1];

  return next == null || !_isTimelineBoundary(next.message);
}

bool _hasAssistantActivity(MessageEntity message) =>
    _hasAssistantThinking(message) ||
    message.metadata?.toolCalls.isNotEmpty == true;

bool _hasAssistantThinking(MessageEntity message) =>
    message.metadata?.thinking?.trim().isNotEmpty == true;

bool _hasVisibleAssistantResponse(
  MessageEntity message,
  Map<String, List<String>> replayPayloadsByMessageId,
) =>
    message.content.trim().isNotEmpty ||
    _requiresMessageTimelineItem(message, replayPayloadsByMessageId);

bool _hasAssistantResponseCandidate(
  _ResolvedChatMessage source,
  Map<String, List<String>> replayPayloadsByMessageId,
) {
  if (_hasVisibleAssistantResponse(source.message, replayPayloadsByMessageId)) {
    return true;
  }

  return source.isStreaming &&
      source.message.metadata?.toolCalls.isNotEmpty != true;
}

bool _requiresMessageTimelineItem(
  MessageEntity message,
  Map<String, List<String>> replayPayloadsByMessageId,
) =>
    message.attachments.isNotEmpty ||
    _hasA2uiMessageState(message) ||
    replayPayloadsByMessageId[message.id]?.isNotEmpty == true ||
    message.metadata?.modelMetadata['a2uiDiagnosticPayloads'] is List;

bool _isTimelineBoundary(MessageEntity message) =>
    message.isUser ||
    message.messageType == MessageType.system ||
    message.status == MessageStatus.error ||
    message.metadata?.isCompactionSummary == true;

bool _isErrorMessage(MessageEntity message) =>
    _isErrorSystemMessage(message) ||
    (!message.isUser &&
        message.status == MessageStatus.error &&
        _isProviderErrorMessage(message));

bool _isErrorSystemMessage(MessageEntity message) =>
    !message.isUser &&
    message.messageType == MessageType.system &&
    message.status == MessageStatus.error;

bool _isProviderErrorMessage(MessageEntity message) =>
    message.metadata?.modelMetadata[ProviderRecoveryMetadata
        .providerErrorKey] ==
    true;

String? _retryableUserMessageId(List<_ResolvedChatMessage?> messages) {
  for (final source in messages.reversed) {
    final message = source?.message;
    if (message?.isUser != true) continue;

    return _canRetryUserMessage(message!) ? message.id : null;
  }

  return null;
}

bool _canRetryUserMessage(MessageEntity message) =>
    message.isUser &&
    !message.isForkReference &&
    message.hasValidContent &&
    (message.status == MessageStatus.unfinished ||
        (message.status == MessageStatus.error &&
            ProviderRecoveryMetadata.isRetryEligible(message)));

class const _ChatMessageTimelineItem({
  required final _ResolvedChatMessage source,
  final bool isSearchTarget = false,
  final bool activityRenderedInSession = false,
  required final void Function(VoidCallback update) onDisclosureChanged,
  required final String parentConversationId,
  required final List<ConversationEntity> childConversations,
  required final String workspaceId,
  required final bool isCloudWorkspace,
  required final Set<String>? backgroundToolCallIds,
  required final bool isTopLevelConversation,
  final ChatA2uiRuntime? a2uiRuntime,
  final List<String> a2uiReplayPayloads = const [],
  final bool showResponseActions = true,
  required final bool canRetry,
  required final Future<void> Function(MessageEntity message)? onRetryMessage,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final message = source.message;

    if (message.metadata?.isCompactionSummary == true) {
      return _CompactedMessageWidget(
        message: message,
        workspaceId: workspaceId,
        key: ValueKey(message.id),
      );
    }

    if (_isErrorMessage(message)) {
      return _ErrorMessageWidget(
        content: message.content,
        isProviderError: _isProviderErrorMessage(message),
        providerFailureCategory: ProviderRecoveryMetadata.categoryFor(message),
        key: ValueKey(message.id),
      );
    }

    final showActivity =
        !activityRenderedInSession &&
        !_isTimelineBoundary(message) &&
        _hasAssistantActivity(message);
    final content = AuraColumn(
      crossAxisAlignment: message.isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showActivity)
          _AssistantActivityRun(
            key: ValueKey('activity_trace_${message.id}'),
            run: _ActivityRun([source]),
            onDisclosureChanged: onDisclosureChanged,
            parentConversationId: parentConversationId,
            childConversations: childConversations,
            workspaceId: workspaceId,
            isCloudWorkspace: isCloudWorkspace,
            backgroundToolCallIds: backgroundToolCallIds,
            isTopLevelConversation: isTopLevelConversation,
            onOpenToolResult: onOpenToolResult,
          ),
        _ChatMessageContent(
          message: message,
          isStreaming: source.isStreaming,
          workspaceId: workspaceId,
          conversationId: parentConversationId,
          a2uiRuntime: a2uiRuntime,
          a2uiReplayPayloads: a2uiReplayPayloads,
          showResponseActions: showResponseActions,
          canRetry: canRetry,
          onRetryMessage: onRetryMessage,
        ),
      ],
    );
    if (!isSearchTarget) return content;

    return Semantics(
      container: true,
      label: LocaleKeys.chats_screens_conversation_search_highlight.tr(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.auraColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}

class const _ChatMessageContent({
  required final MessageEntity message,
  required final bool isStreaming,
  required final String workspaceId,
  required final String conversationId,
  required final ChatA2uiRuntime? a2uiRuntime,
  required final List<String> a2uiReplayPayloads,
  final bool showResponseActions = true,
  required final bool canRetry,
  required final Future<void> Function(MessageEntity message)? onRetryMessage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hasContent = message.content.trim().isNotEmpty;
    final showTextBubble = _showTextBubble(
      message: message,
      isStreaming: isStreaming,
      hasContent: hasContent,
      hasActivity: _hasAssistantActivity(message),
    );
    final status = _messageDeliveryStatus(message, isStreaming);
    final hasA2uiResponse =
        !message.isUser &&
        !message.isForkReference &&
        ((message.metadata?.a2uiMessages.isNotEmpty ?? false) ||
            a2uiReplayPayloads.isNotEmpty);

    return AuraColumn(
      children: _messageContentChildren(
        message: message,
        hasContent: hasContent,
        showTextBubble: showTextBubble,
        hasA2uiResponse: hasA2uiResponse,
        status: status,
        workspaceId: workspaceId,
        conversationId: conversationId,
        a2uiRuntime: a2uiRuntime,
        a2uiReplayPayloads: a2uiReplayPayloads,
        showResponseActions: showResponseActions,
        canRetry: canRetry,
        onRetryMessage: onRetryMessage,
      ),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: .xs,
    );
  }
}

bool _showTextBubble({
  required MessageEntity message,
  required bool isStreaming,
  required bool hasContent,
  required bool hasActivity,
}) =>
    hasContent || (message.attachments.isEmpty && !isStreaming && !hasActivity);

AuraMessageDeliveryStatus _messageDeliveryStatus(
  MessageEntity message,
  bool isStreaming,
) {
  final metadata = message.metadata;
  final isAwaitingA2uiAction =
      !isStreaming &&
      message.status == MessageStatus.unfinished &&
      (metadata?.modelMetadata['a2uiRequiresUserAction'] == true ||
          metadata?.a2uiMessages.isNotEmpty == true);
  return isAwaitingA2uiAction
      ? AuraMessageDeliveryStatus.sent
      : _mapMessageStatus(message.status, isStreaming);
}

List<Widget> _messageContentChildren({
  required MessageEntity message,
  required bool hasContent,
  required bool showTextBubble,
  required bool hasA2uiResponse,
  required AuraMessageDeliveryStatus status,
  required String workspaceId,
  required String conversationId,
  required ChatA2uiRuntime? a2uiRuntime,
  required List<String> a2uiReplayPayloads,
  required bool showResponseActions,
  required bool canRetry,
  required Future<void> Function(MessageEntity message)? onRetryMessage,
}) {
  final selectableChildren = <Widget>[
    if (showTextBubble)
      _MessageTextContent(
        message: message,
        hasContent: hasContent,
        status: status,
        showMetadata:
            message.isUser || (showResponseActions && !hasA2uiResponse),
      ),
    if (message.attachments.isNotEmpty ||
        message.metadata?.cloudAssetIds.isNotEmpty == true)
      _MessageAttachments(message: message, workspaceId: workspaceId),
    if (!message.isUser && !message.isForkReference && a2uiRuntime != null)
      ChatA2uiSurfaceHost.message(
        key: ValueKey('a2ui_${message.id}'),
        runtime: a2uiRuntime,
        messageId: message.id,
        payloads: [...?message.metadata?.a2uiMessages, ...a2uiReplayPayloads],
        issuesBySurface: message.metadata?.a2uiIssuesBySurface ?? const {},
        messageIssues: message.metadata?.a2uiMessageIssues ?? const [],
        wrapInSelectionArea: false,
      ),
  ];

  return [
    if (selectableChildren.isNotEmpty)
      SelectionArea(
        child: AuraColumn(
          mainAxisSize: .min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: selectableChildren,
        ),
      ),
    if (showResponseActions &&
        !hasA2uiResponse &&
        (_messageCopyText(message, a2uiRuntime) != null ||
            (canRetry && onRetryMessage != null) ||
            message.isBookmarkEligible))
      _MessageActions(
        message: message,
        resolveContent: () => _messageCopyText(message, a2uiRuntime),
        workspaceId: workspaceId,
        conversationId: conversationId,
        onRetryMessage: canRetry ? onRetryMessage : null,
      ),
    if (showResponseActions && hasA2uiResponse)
      _MessageFooter(
        key: ValueKey('message_footer_${message.id}'),
        status: status,
        resolveContent: () => _messageCopyText(message, a2uiRuntime),
        message: message,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
  ];
}

String? _messageCopyText(MessageEntity message, ChatA2uiRuntime? a2uiRuntime) {
  final content = message.content;
  final a2uiText = message.isUser
      ? null
      : a2uiRuntime?.copyableTextFor(message.id);
  if (content.trim().isEmpty) return a2uiText;
  if (a2uiText == null || a2uiText.trim().isEmpty) return content;
  return '$content\n\n$a2uiText';
}

Color _userMessageSelectionColor(AuraColorScheme colors) {
  return Color.alphaBlend(
    colors.primary.withValues(alpha: .24),
    colors.surfaceVariant,
  );
}

AuraMessageDeliveryStatus _mapMessageStatus(
  MessageStatus status,
  bool isStreaming,
) => switch (status) {
  MessageStatus.sending => AuraMessageDeliveryStatus.sending,
  MessageStatus.unfinished =>
    isStreaming
        ? AuraMessageDeliveryStatus.sending
        : AuraMessageDeliveryStatus.unfinished,
  MessageStatus.sent => AuraMessageDeliveryStatus.sent,
  MessageStatus.error => AuraMessageDeliveryStatus.error,
};

Map<String, List<String>> _submittedA2uiReplayPayloads(
  Iterable<MessageEntity> messages,
  String conversationId,
) {
  final payloadsByAssistantMessage = <String, List<String>>{};
  for (final message in messages) {
    if (!message.isUser || message.isForkReference) continue;
    final action = A2uiChatContract.decodeActionMetadata(
      message.metadata?.modelMetadata,
      conversationId: conversationId,
    );
    final assistantMessageId = action?.assistantMessageId;
    if (action == null || assistantMessageId == null) continue;
    final payload = chatA2uiSubmittedAnswersReplayPayload(action);
    if (payload == null) continue;
    payloadsByAssistantMessage
        .putIfAbsent(assistantMessageId, () => [])
        .add(payload);
  }

  return payloadsByAssistantMessage;
}

String? _latestA2uiMessageId(
  List<String> messageIds,
  Map<String, MessageEntity>? messages,
) {
  if (messages == null) return null;
  final latestUserIndex = _latestUserMessageIndex(messageIds, messages);
  for (var index = messageIds.length - 1; index > latestUserIndex; index--) {
    final id = messageIds[index];
    final message = messages[id];
    if (_hasA2uiMessageState(message)) return id;
  }

  return null;
}

int _latestUserMessageIndex(
  List<String> messageIds,
  Map<String, MessageEntity> messages,
) {
  var latestUserIndex = -1;
  for (var index = 0; index < messageIds.length; index++) {
    if (messages[messageIds[index]]?.isUser == true) latestUserIndex = index;
  }
  return latestUserIndex;
}

bool _hasA2uiMessageState(MessageEntity? message) {
  if (message == null || message.isUser || message.isForkReference)
    return false;
  final metadata = message.metadata;
  if (metadata == null) return false;
  return metadata.a2uiMessages.isNotEmpty ||
      metadata.a2uiIssuesBySurface.isNotEmpty ||
      metadata.a2uiMessageIssues.isNotEmpty;
}

class const _MessageAttachments({
  required final MessageEntity message,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Wrap(
        spacing: context.auraTheme.fromSpacing(.xs),
        runSpacing: context.auraTheme.fromSpacing(.xs),
        children: [
          for (final attachment in message.attachments)
            if (attachment.assetId case final id?)
              ChatSharedAsset(workspaceId: workspaceId, assetId: id)
            else
              _AttachmentPreview(attachment: attachment),
          for (final id in message.metadata?.cloudAssetIds ?? const <String>[])
            ChatSharedAsset(workspaceId: workspaceId, assetId: id),
        ],
      ),
    );
  }
}

Future<void> _submitA2uiAction(
  WidgetRef ref, {
  required ChatA2uiRuntime runtime,
  required String workspaceId,
  required String conversationId,
  required ChatUiAction action,
  required String languageCode,
}) async {
  try {
    final iterationLimitNotifier = ref.read(
      conversationIterationLimitProvider(conversationId).notifier,
    );
    final decision = await ref
        .read(sendMessageUsecaseProvider(workspaceId))
        .call(
          conversationId: conversationId,
          draft: ChatDraft(
            text: action.messageText,
            metadataJson: action.metadataJson,
            languageCode: languageCode,
          ),
        );
    iterationLimitNotifier.markIfIterationLimitReached(decision);
  } on Object catch (error, stackTrace) {
    runtime.rejectFormSubmission(action.surfaceId);
    _a2uiLogger.warning(
      'A2UI action rejected: conversationId=$conversationId',
      error,
      stackTrace,
    );
  }
}

class const _AttachmentPreview({
  required final MessageAttachmentEntity attachment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (attachment.modality == MessageAttachmentModality.image) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: SharedChatAttachmentImage(localPath: attachment.localPath),
      );
    }

    return Chip(
      avatar: Icon(
        attachment.modality == MessageAttachmentModality.audio
            ? Icons.mic_none_outlined
            : Icons.insert_drive_file_outlined,
      ),
      label: Text(attachment.displayName),
    );
  }
}

class const _MessageTextContent({
  required final MessageEntity message,
  required final bool hasContent,
  required final AuraMessageDeliveryStatus status,
  required final bool showMetadata,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      final colors = context.auraColors;
      return TextSelectionTheme(
        data: Theme.of(context).textSelectionTheme.copyWith(
          selectionColor: _userMessageSelectionColor(colors),
          selectionHandleColor: colors.primary,
        ),
        child: AuraMessageBubble(
          content: message.content,
          isUser: true,
          key: ValueKey(message.id),
          status: status,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasContent)
          _AiMessageContent(
            content: message.content,
            key: ValueKey(message.id),
            status: status,
            showMetadata: showMetadata,
          ),
      ],
    );
  }
}

class const _MessageFooter({
  required final MessageEntity message,
  required final String workspaceId,
  required final String conversationId,
  required final AuraMessageDeliveryStatus status,
  required final String? Function() resolveContent,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final copyableText = resolveContent();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MessageActions(
          message: message,
          resolveContent: copyableText == null ? null : resolveContent,
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
        if (status != AuraMessageDeliveryStatus.sent) ...[
          SizedBox(height: context.auraTheme.fromSpacing(.xs) / 2),
          AuraMessageStatus(status: status),
        ],
      ],
    );
  }
}

bool _canForkMessage(MessageEntity message) =>
    !message.isUser && message.status == MessageStatus.sent;

class const _MessageActions({
  required final MessageEntity message,
  final String? Function()? resolveContent,
  required final String workspaceId,
  required final String conversationId,
  final Future<void> Function(MessageEntity message)? onRetryMessage,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolve = resolveContent;
    final retry = onRetryMessage;
    final typography = context.auraTheme.typography;
    final timestamp = Text(
      RelativeTimeFormatter.format(
        message.createdAt,
        locale: Localizations.localeOf(context),
        translate: (key, {args}) => context.tr(key, args: args),
      ),
      style: TextStyle(
        color: context.auraColors.onSurfaceVariant,
        fontSize: typography.fontSizeXs,
        fontFamily: typography.bodyFontFamily,
      ),
    );

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isUser) ...[
            timestamp,
            SizedBox(width: context.auraTheme.fromSpacing(.xs)),
          ],
          if (resolve != null) _MessageCopyAction(resolveContent: resolve),
          if (retry != null)
            _MessageRetryAction(message: message, onRetryMessage: retry),
          if (message.isBookmarkEligible)
            _MessageBookmarkAction(
              message: message,
              workspaceId: workspaceId,
              conversationId: conversationId,
            ),
          if (_canForkMessage(message))
            _MessageForkAction(
              message: message,
              workspaceId: workspaceId,
              conversationId: conversationId,
            ),
          if (!message.isUser) ...[
            SizedBox(width: context.auraTheme.fromSpacing(.xs)),
            timestamp,
          ],
        ],
      ),
    );
  }
}

class const _MessageBookmarkAction({
  required final MessageEntity message,
  required final String workspaceId,
  required final String conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(messageBookmarksProvider(workspaceId)).value;
    final messageId = message.sourceMessageId ?? message.id;
    final isBookmarked =
        bookmarks?.any(
          (bookmark) =>
              bookmark.workspace.workspaceId == workspaceId &&
              bookmark.details.messageId == messageId,
        ) ??
        false;
    final tooltip = isBookmarked
        ? LocaleKeys.chats_screens_chat_conversation_unbookmark_message.tr()
        : LocaleKeys.chats_screens_chat_conversation_bookmark_message.tr();

    return AuraIconButton(
      key: ValueKey('bookmark_message_${message.id}'),
      icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
      size: .small,
      tooltip: tooltip,
      onPressed: () => unawaited(
        _toggleMessageBookmark(context, ref, (
          workspaceId: workspaceId,
          conversationId: conversationId,
          message: message,
          isBookmarked: isBookmarked,
        )),
      ),
    );
  }
}

Future<void> _toggleMessageBookmark(
  BuildContext context,
  WidgetRef ref,
  ({
    String workspaceId,
    String conversationId,
    MessageEntity message,
    bool isBookmarked,
  })
  request,
) async {
  try {
    final cloud = await ref.read(messageBookmarkUseCaseProvider).toggle((
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      message: request.message,
      isBookmarked: request.isBookmarked,
      resolveCloudConversation: () => ref.read(
        cloudConversationUsecaseProvider(request.workspaceId).future,
      ),
    ));
    if (!context.mounted) return;
    ref.invalidate(messageBookmarksProvider(request.workspaceId));
    if (cloud) ref.invalidate(cloudMessageBookmarksProvider);
  } on Object {
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_bookmark_error,
      ),
      variant: .error,
    );
  }
}

class const _MessageRetryAction({
  required final MessageEntity message,
  required final Future<void> Function(MessageEntity message) onRetryMessage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: AuraIconButton(
      key: ValueKey('retry_message_${message.id}'),
      icon: Icons.refresh,
      size: .small,
      tooltip: LocaleKeys.chats_screens_chat_conversation_retry_message.tr(),
      onPressed: () => unawaited(onRetryMessage(message)),
    ),
  );
}

class const _MessageForkAction({
  required final MessageEntity message,
  required final String workspaceId,
  required final String conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: LocaleKeys.chats_screens_chat_conversation_fork.tr(),
    child: IconButton(
      icon: const Icon(Icons.call_split_outlined),
      onPressed: () => unawaited(
        _forkMessage(context, ref, message, workspaceId, conversationId),
      ),
    ),
  );
}

Future<void> _forkMessage(
  BuildContext context,
  WidgetRef ref,
  MessageEntity message,
  String workspaceId,
  String conversationId,
) async {
  try {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(workspaceId).future,
    );
    final String forkId;
    if (cloud != null) {
      forkId = (await cloud.fork(
        (await ref.read(
          conversationByIdStreamProvider(
            workspaceId,
            conversationId: conversationId,
          ).future,
        ))!,
        throughMessageId: message.id,
      )).id;
    } else {
      final conversation = await ref.read(
        conversationByIdStreamProvider(
          workspaceId,
          conversationId: conversationId,
        ).future,
      );
      if (conversation == null) return;
      forkId =
          (await ref
                  .read(forkConversationUsecaseProvider)
                  .call(conversation, throughMessageId: message.id))
              .id;
    }
    ref.invalidate(conversationsStreamProvider(workspaceId: workspaceId));
    if (context.mounted) {
      ConversationRoute(workspaceId: workspaceId, chatId: forkId).go(context);
    }
  } on Object {
    if (!context.mounted) return;
    AuraSnackBars.show(
      context: context,
      content: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_fork_error,
      ),
      variant: .error,
    );
  }
}

class const _ForkBoundaryDivider({
  required final ConversationEntity conversation,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceId = conversation.forkSourceConversationId;
    final source = sourceId == null
        ? null
        : ref
              .watch(
                conversationByIdStreamProvider(
                  workspaceId,
                  conversationId: sourceId,
                ),
              )
              .value;
    final label = TextLocale(
      LocaleKeys.chats_screens_chat_conversation_forked_from,
      args: [conversation.forkSourceTitle.orPlaceholder()],
      style: TextStyle(color: context.auraColors.onSurfaceVariant),
    );
    final row = Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: label,
        ),
        const Expanded(child: Divider()),
      ],
    );
    return source == null
        ? row
        : InkWell(
            onTap: () => ConversationRoute(
              workspaceId: source.workspaceId,
              chatId: source.id,
            ).go(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: context.auraTheme.interactionSizes.minimumTargetSize,
                minHeight: context.auraTheme.interactionSizes.minimumTargetSize,
              ),
              child: Center(child: row),
            ),
          );
  }
}

class _MessageCopyAction extends StatefulWidget {
  const new({required this.resolveContent, super.key});

  final String? Function() resolveContent;

  @override
  State<_MessageCopyAction> createState() => _MessageCopyActionState();
}

class _MessageCopyActionState extends State<_MessageCopyAction> {
  var _copied = false;

  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: _copied ? Icons.check : Icons.copy_outlined,
    onPressed: () => unawaited(_copy()),
    tooltip:
        (_copied
                ? LocaleKeys.chats_screens_chat_conversation_message_copied
                : LocaleKeys.chats_screens_chat_conversation_copy_message)
            .tr(),
  );

  Future<void> _copy() async {
    final content = widget.resolveContent();
    if (content == null || content.trim().isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: content));
    } on Object {
      return;
    }

    if (mounted) setState(() => _copied = true);
  }
}

Widget _chatMarkdown({
  required BuildContext context,
  required String content,
  required TextStyle style,
}) => MouseRegion(
  cursor: SystemMouseCursors.text,
  child: DefaultSelectionStyle(
    mouseCursor: MouseCursor.defer,
    child: GptMarkdown(
      content,
      style: style,
      onLinkTap: (url, _) => unawaited(openChatExternalLink(context, url)),
    ),
  ),
);

class const _AiMessageContent({
  required final String content,
  super.key,
  final AuraMessageDeliveryStatus status = AuraMessageDeliveryStatus.sent,
  final bool showMetadata = true,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final typography = context.auraTheme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chatMarkdown(
          context: context,
          content: content,
          style: TextStyle(
            color: auraColors.onSurface,
            fontSize: typography.fontSizeBase,
            height: typography.lineHeightBase,
            fontFamily: typography.bodyFontFamily,
          ),
        ),
        if (showMetadata && status != AuraMessageDeliveryStatus.sent) ...[
          const AuraSizedBox(height: .xs),
          AuraMessageStatus(status: status),
        ],
      ],
    );
  }
}

class const _AssistantActivityRun({
  required final _ActivityRun run,
  required final void Function(VoidCallback update) onDisclosureChanged,
  required final String parentConversationId,
  required final List<ConversationEntity> childConversations,
  required final String workspaceId,
  required final bool isCloudWorkspace,
  required final Set<String>? backgroundToolCallIds,
  required final bool isTopLevelConversation,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
  final ChatA2uiRuntime? a2uiRuntime,
  final List<String> a2uiReplayPayloads = const [],
  final Map<String, List<String>> a2uiReplayPayloadsByMessageId = const {},
  final bool canRetry = false,
  final Future<void> Function(MessageEntity message)? onRetryMessage,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mcpAppControllers = useMemoized(
      () => <String, McpAppToolResultController>{},
    );
    final activityEntries = _buildActivityRunEntries(run);
    final responseEntryIndex = activityEntries.indexWhere(
      (entry) => entry is _ActivityResponseEntry && entry.isFinal,
    );
    final entriesBeforeResponse = responseEntryIndex < 0
        ? activityEntries
        : activityEntries.take(responseEntryIndex).toList(growable: false);
    final entriesAfterResponse = responseEntryIndex < 0
        ? const <_ActivityRunEntry>[]
        : activityEntries.skip(responseEntryIndex + 1).toList(growable: false);
    final responseSource = responseEntryIndex < 0
        ? null
        : (activityEntries[responseEntryIndex] as _ActivityResponseEntry)
              .source;
    final toolGroupEntries = [
      for (final entry in activityEntries)
        if (entry is _ActivityToolGroupEntry) entry,
    ];
    final toolCalls = <_ActivityToolCall>[
      for (final entry in toolGroupEntries) ...entry.toolCalls,
    ];
    final expandableToolGroupIds = {
      for (final entry in toolGroupEntries)
        if (entry.toolCalls.length > 1) _activityToolGroupId(entry),
    };
    final liveToolGroupIds = [
      for (final entry in toolGroupEntries)
        if (_isLiveActivityToolGroup(entry)) _activityToolGroupId(entry),
    ];
    final liveToolGroupSignature = liveToolGroupIds.join('\u0000');
    final isLive =
        run.sources.any(
          (source) => !source.message.isForkReference && source.isStreaming,
        ) ||
        toolCalls.any(
          (item) => !item.isForkReference && item.toolCall.isPending,
        );
    final toolSignature = toolCalls
        .map((item) => '${item.messageId}\u0000${item.toolCall.id}')
        .join('\u0000');
    final latestPendingToolId = _latestPendingToolId(
      toolCalls
          .where((item) => !item.isForkReference)
          .map((item) => item.toolCall)
          .toList(growable: false),
    );
    final initialExpansionState = (
      isLive: isLive,
      traceExpanded: isLive,
      expandedToolGroupIds: isLive
          ? liveToolGroupIds.where(expandableToolGroupIds.contains).toSet()
          : <String>{},
      expandedToolIds: latestPendingToolId == null
          ? <String>{}
          : <String>{latestPendingToolId},
    );
    final expansionState =
        ref.watch(
          activityRunExpansionProvider.select(
            (state) => state[parentConversationId]?[run.id],
          ),
        ) ??
        initialExpansionState;
    final renderedExpansionState = expansionState;

    List<McpAppToolResultController?> appControllersForToolIds(
      Set<String> toolIds,
    ) => [
      for (final toolCall in toolCalls)
        if (toolIds.contains(toolCall.toolCall.id))
          mcpAppControllers[toolCall.toolCall.id],
    ];

    void updateExpansionState(
      ActivityRunExpansionState Function(ActivityRunExpansionState) update,
    ) => ref
        .read(activityRunExpansionProvider.notifier)
        .updateExpansion(
          conversationId: parentConversationId,
          activityRunId: run.id,
          initialState: initialExpansionState,
          update: update,
        );

    void updateExpansionStateAfterBuild(
      ActivityRunExpansionState Function(ActivityRunExpansionState) update,
    ) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        updateExpansionState(update);
      });
    }

    Future<void> collapseAfterRun() => runAfterMcpAppToolResultsTeardown(
      controllers: appControllersForToolIds(expansionState.expandedToolIds),
      action: () {
        if (!context.mounted) return;
        onDisclosureChanged(() {
          updateExpansionStateAfterBuild(
            (_) => (
              isLive: false,
              traceExpanded: false,
              expandedToolGroupIds: const {},
              expandedToolIds: const {},
            ),
          );
        });
      },
    );

    final previousIsLive = useRef(isLive);
    final previousToolSignature = useRef(toolSignature);
    final previousPendingToolId = useRef(latestPendingToolId);

    useEffect(
      () {
        final wasLive = previousIsLive.value;
        final hasNewTool = previousToolSignature.value != toolSignature;
        final hasNewPendingTool =
            previousPendingToolId.value != latestPendingToolId;
        if (!isLive && (expansionState.isLive || wasLive)) {
          unawaited(collapseAfterRun());
        } else if (isLive && (!wasLive || hasNewTool || hasNewPendingTool)) {
          onDisclosureChanged(() {
            updateExpansionStateAfterBuild(
              (current) => (
                isLive: true,
                traceExpanded: true,
                expandedToolGroupIds: {
                  ...current.expandedToolGroupIds,
                  ...liveToolGroupIds.where(expandableToolGroupIds.contains),
                },
                expandedToolIds: latestPendingToolId == null
                    ? current.expandedToolIds
                    : {...current.expandedToolIds, latestPendingToolId},
              ),
            );
          });
        }
        previousIsLive.value = isLive;
        previousToolSignature.value = toolSignature;
        previousPendingToolId.value = latestPendingToolId;
        return null;
      },
      [
        expandableToolGroupIds.length,
        expansionState.isLive,
        isLive,
        latestPendingToolId,
        liveToolGroupSignature,
        toolSignature,
      ],
    );

    final toolContents = <String, Widget>{};
    for (final entry in toolGroupEntries) {
      final groupId = _activityToolGroupId(entry);
      final activityToolCalls =
          <
            ({
              String messageId,
              MessageToolCallEntity toolCall,
              bool isForkReference,
              String displayName,
              String? description,
              bool showArguments,
              VoidCallback? openSubAgent,
              VoidCallback? onRunInBackground,
            })
          >[];
      for (final item in entry.toolCalls) {
        final display = _activityToolDisplay(
          ref: ref,
          workspaceId: workspaceId,
          toolCall: item.toolCall,
        );
        activityToolCalls.add((
          messageId: item.messageId,
          toolCall: item.toolCall,
          isForkReference: item.isForkReference,
          displayName: display.displayName,
          description: display.description,
          showArguments: !item.hideArguments,
          openSubAgent: _openSubAgent(
            context: context,
            ref: ref,
            workspaceId: workspaceId,
            parentConversationId: parentConversationId,
            childConversations: childConversations,
            toolCall: item.toolCall,
          ),
          onRunInBackground:
              !item.isForkReference &&
                  isTopLevelConversation &&
                  item.toolCall.isRunning &&
                  !(backgroundToolCallIds?.contains(item.toolCall.id) ??
                      false) &&
                  (isCloudWorkspace
                      ? item.toolCall.backgroundEligible
                      : ref
                                .watch(
                                  toolBackgroundEligibilityProvider((
                                    conversationId: parentConversationId,
                                    toolCallId: item.toolCall.id,
                                  )),
                                )
                                .value ==
                            true)
              ? () => _detachToolCallFromActivity(
                  context: context,
                  ref: ref,
                  workspaceId: workspaceId,
                  conversationId: parentConversationId,
                  isCloud: isCloudWorkspace,
                  toolCallId: item.toolCall.id,
                  toolKind: display.displayName,
                  originatingMessageId: item.messageId,
                )
              : null,
        ));
      }
      final toolRows = [
        for (final activityToolCall in activityToolCalls)
          _ActivityToolCallRow(
            key: ValueKey('activity_tool_row_${activityToolCall.toolCall.id}'),
            controller: mcpAppControllers.putIfAbsent(
              activityToolCall.toolCall.id,
              McpAppToolResultController.new,
            ),
            workspaceId: workspaceId,
            conversationId: parentConversationId,
            toolCall: activityToolCall.toolCall,
            displayName: activityToolCall.displayName,
            description: activityToolCall.description,
            showArguments: activityToolCall.showArguments,
            isExpanded: renderedExpansionState.expandedToolIds.contains(
              activityToolCall.toolCall.id,
            ),
            onToggle: () async {
              final toolCallId = activityToolCall.toolCall.id;
              final shouldExpandToolCall = !renderedExpansionState
                  .expandedToolIds
                  .contains(toolCallId);
              if (!shouldExpandToolCall) {
                final controller = mcpAppControllers[toolCallId];
                if (controller != null) await controller.prepareForTeardown();
              }
              if (!context.mounted) return;

              _toggleDisclosure(
                context: context,
                update: () => onDisclosureChanged(() {
                  updateExpansionState(
                    (current) => (
                      isLive: current.isLive,
                      traceExpanded: current.traceExpanded,
                      expandedToolGroupIds: current.expandedToolGroupIds,
                      expandedToolIds: updateActivityRunExpandedIds(
                        expandedIds: current.expandedToolIds,
                        id: toolCallId,
                        isExpanded: shouldExpandToolCall,
                      ),
                    ),
                  );
                }),
              );
            },
            openSubAgent: activityToolCall.openSubAgent,
            onRunInBackground: activityToolCall.onRunInBackground,
            onOpenToolResult: onOpenToolResult,
          ),
      ];
      if (toolRows.length == 1) {
        toolContents[groupId] = toolRows.single;
      } else {
        final shouldExpandToolGroup = !renderedExpansionState
            .expandedToolGroupIds
            .contains(groupId);
        Future<void> toggleToolGroup() => runAfterMcpAppToolResultsTeardown(
          controllers: shouldExpandToolGroup
              ? const <McpAppToolResultController?>[]
              : [
                  for (final activityToolCall in activityToolCalls)
                    if (renderedExpansionState.expandedToolIds.contains(
                      activityToolCall.toolCall.id,
                    ))
                      mcpAppControllers[activityToolCall.toolCall.id],
                ],
          action: () {
            if (!context.mounted) return;
            onDisclosureChanged(() {
              updateExpansionState((current) {
                return (
                  isLive: current.isLive,
                  traceExpanded: current.traceExpanded,
                  expandedToolGroupIds: updateActivityRunExpandedIds(
                    expandedIds: current.expandedToolGroupIds,
                    id: groupId,
                    isExpanded: shouldExpandToolGroup,
                  ),
                  expandedToolIds: current.expandedToolIds,
                );
              });
            });
          },
        );

        toolContents[groupId] = AuraColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActivityTraceDisclosure(
              key: ValueKey('activity_tool_list_toggle_$groupId'),
              icon: Icons.build_outlined,
              label: _toolCallsSummary(
                activityToolCalls.map((toolCall) => toolCall.displayName),
                Localizations.localeOf(context),
              ),
              color: context.auraColors.secondary,
              isExpanded: renderedExpansionState.expandedToolGroupIds.contains(
                groupId,
              ),
              onPressed: () => unawaited(toggleToolGroup()),
            ),
            if (renderedExpansionState.expandedToolGroupIds.contains(groupId))
              Padding(
                padding: EdgeInsets.only(
                  left: context.auraTheme.fromSpacing(.sm),
                ),
                child: AuraColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: toolRows,
                ),
              ),
          ],
        );
      }
    }
    final hasOuterDisclosure =
        entriesBeforeResponse.length + entriesAfterResponse.length > 1;
    final activityLabel = toolCalls.isEmpty
        ? LocaleKeys.chats_screens_chat_conversation_activity_thinking.tr()
        : LocaleKeys.chats_screens_chat_conversation_activity_tools_count
              .plural(toolCalls.length, context: context);
    final shouldExpandTrace = !renderedExpansionState.traceExpanded;
    Future<void> toggleTrace() => runAfterMcpAppToolResultsTeardown(
      controllers: shouldExpandTrace
          ? const <McpAppToolResultController?>[]
          : appControllersForToolIds(renderedExpansionState.expandedToolIds),
      action: () {
        if (!context.mounted) return;
        onDisclosureChanged(() {
          updateExpansionState(
            (current) => (
              isLive: current.isLive,
              traceExpanded: shouldExpandTrace,
              expandedToolGroupIds: current.expandedToolGroupIds,
              expandedToolIds: current.expandedToolIds,
            ),
          );
        });
      },
    );

    Widget activityEntry(_ActivityRunEntry entry) {
      if (entry case _ActivityNarrativeEntry(
        :final messageId,
        :final content,
      )) {
        return Padding(
          padding: EdgeInsets.only(bottom: context.auraTheme.fromSpacing(.xs)),
          child: _ActivityNarrative(
            key: ValueKey('activity_narrative_$messageId'),
            content: content,
          ),
        );
      }
      if (entry case _ActivityThinkingEntry(:final messageId, :final content)) {
        return Padding(
          padding: EdgeInsets.only(bottom: context.auraTheme.fromSpacing(.xs)),
          child: _ActivityThinkingCard(
            key: ValueKey('activity_thinking_$messageId'),
            content: content,
          ),
        );
      }
      if (entry case _ActivityResponseEntry(:final source)) {
        return _ChatMessageContent(
          message: source.message,
          isStreaming: source.isStreaming,
          workspaceId: workspaceId,
          conversationId: parentConversationId,
          a2uiRuntime: a2uiRuntime,
          a2uiReplayPayloads:
              a2uiReplayPayloadsByMessageId[source.message.id] ?? const [],
          showResponseActions: false,
          canRetry: false,
          onRetryMessage: null,
        );
      }
      final toolContent =
          toolContents[_activityToolGroupId(entry as _ActivityToolGroupEntry)]!;
      return toolContent;
    }

    Widget activityContent(Iterable<_ActivityRunEntry> entries) => AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final entry in entries) activityEntry(entry)],
    );

    final responseContent = responseSource == null
        ? null
        : _ChatMessageContent(
            message: responseSource.message,
            isStreaming: responseSource.isStreaming,
            workspaceId: workspaceId,
            conversationId: parentConversationId,
            a2uiRuntime: a2uiRuntime,
            a2uiReplayPayloads: a2uiReplayPayloads,
            showResponseActions: !responseSource.isStreaming,
            canRetry: canRetry,
            onRetryMessage: onRetryMessage,
          );

    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasOuterDisclosure)
          _ActivityTraceDisclosure(
            key: ValueKey('activity_trace_toggle_${run.id}'),
            icon: Icons.psychology_outlined,
            label: activityLabel,
            color: context.auraColors.onSurfaceVariant,
            isActivity: true,
            isExpanded: renderedExpansionState.traceExpanded,
            onPressed: () => unawaited(toggleTrace()),
          ),
        if (hasOuterDisclosure &&
            renderedExpansionState.traceExpanded &&
            entriesBeforeResponse.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: context.auraTheme.fromSpacing(.sm),
              top: context.auraTheme.fromSpacing(.xs),
            ),
            child: activityContent(entriesBeforeResponse),
          ),
        if (responseSource != null &&
            !hasOuterDisclosure &&
            entriesBeforeResponse.isNotEmpty)
          activityContent(entriesBeforeResponse),
        if (responseContent != null) responseContent,
        if (responseSource != null &&
            hasOuterDisclosure &&
            renderedExpansionState.traceExpanded &&
            entriesAfterResponse.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: context.auraTheme.fromSpacing(.sm),
              top: context.auraTheme.fromSpacing(.xs),
            ),
            child: activityContent(entriesAfterResponse),
          ),
        if (responseSource != null &&
            !hasOuterDisclosure &&
            entriesAfterResponse.isNotEmpty)
          activityContent(entriesAfterResponse),
        if (responseSource == null && !hasOuterDisclosure)
          activityContent(entriesBeforeResponse),
      ],
    );
  }
}

class const _ActivityNarrative({required final String content, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return SelectionArea(
      child: _chatMarkdown(
        context: context,
        content: content,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: typography.fontSizeSm,
          height: typography.lineHeightBase,
          fontFamily: typography.bodyFontFamily,
        ),
      ),
    );
  }
}

class const _ActivityThinkingCard({required final String content, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return AuraContainer(
      variant: AuraContainerVariant.surfaceVariant,
      padding: .small,
      borderRadius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const AuraSizedBox(width: .xs),
              TextLocale(
                LocaleKeys.chats_screens_chat_conversation_activity_thinking,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: typography.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  fontFamily: typography.bodyFontFamily,
                ),
              ),
            ],
          ),
          const AuraSizedBox(height: .xs),
          SelectionArea(
            child: _chatMarkdown(
              context: context,
              content: content,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: typography.fontSizeSm,
                height: typography.lineHeightBase,
                fontFamily: typography.bodyFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _toolCallDisplayName(
  AsyncValue<String> displayNameAsync,
  String toolName,
) => displayNameAsync.maybeWhen(
  data: (displayName) => displayName,
  orElse: () => ToolNameFormatter.formatDisplayName(
    ToolNameFormatter.parse(toolName),
    rawName: toolName,
  ),
);

_ActivityToolDisplay _activityToolDisplay({
  required WidgetRef ref,
  required String workspaceId,
  required MessageToolCallEntity toolCall,
}) {
  return (
    displayName: _toolCallDisplayName(
      ref.watch(toolDisplayNameProvider(workspaceId, toolCall.name)),
      toolCall.name,
    ),
    description: normalizeToolCallUserFacingDescription(
      toolCall.userFacingDescription,
    ),
  );
}

String _toolCallsSummary(Iterable<String> displayNames, Locale locale) {
  const maximumNames = 2;
  final names = displayNames.toList(growable: false);
  final summary = names.take(maximumNames).toList();
  final remaining = names.length - summary.length;
  if (remaining > 0) {
    summary.add('+${NumberFormatter.count(remaining, locale)}');
  }

  return summary.join(', ');
}

String? _latestPendingToolId(List<MessageToolCallEntity> toolCalls) {
  for (var index = toolCalls.length - 1; index >= 0; index--) {
    final toolCall = toolCalls[index];
    if (toolCall.isPending) return toolCall.id;
  }

  return null;
}

VoidCallback? _openSubAgent({
  required BuildContext context,
  required WidgetRef ref,
  required String workspaceId,
  required String parentConversationId,
  required List<ConversationEntity> childConversations,
  required MessageToolCallEntity toolCall,
}) {
  final subAgentConversationId =
      _subAgentConversationId(toolCall) ??
      _activeSubAgentConversationId(ref, parentConversationId, toolCall) ??
      _persistedSubAgentConversationId(toolCall, childConversations);
  if (subAgentConversationId == null) return null;

  return () => SubAgentConversationRoute(
    workspaceId: workspaceId,
    chatId: parentConversationId,
    subAgentConversationId: subAgentConversationId,
  ).push(context);
}

void _detachToolCallFromActivity({
  required BuildContext context,
  required WidgetRef ref,
  required String workspaceId,
  required String conversationId,
  required bool isCloud,
  required String toolCallId,
  required String toolKind,
  required String originatingMessageId,
}) {
  unawaited(() async {
    try {
      final detached = await BackgroundWorkActions.runToolInBackground((
        ref: ref,
        workspaceId: workspaceId,
        conversationId: conversationId,
        toolCallId: toolCallId,
        toolKind: toolKind,
        originatingMessageId: originatingMessageId,
        isCloud: isCloud,
      ));
      if (detached || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextLocale(
            LocaleKeys
                .chats_screens_chat_conversation_background_work_detach_error,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextLocale(
            LocaleKeys
                .chats_screens_chat_conversation_background_work_detach_error,
          ),
        ),
      );
    }
  }());
}

class const _ActivityTraceDisclosure({
  required final IconData icon,
  required final String label,
  required final Color color,
  final bool isActivity = false,
  required final bool isExpanded,
  required final VoidCallback onPressed,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return AuraPressable(
      color: color,
      decoration: isActivity
          ? BoxDecoration(
              color: colors.surfaceVariant.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(
                context.auraTheme.fromBorderRadius(.md),
              ),
            )
          : null,
      onPressed: () => _toggleDisclosure(context: context, update: onPressed),
      interaction: AuraPressableInteraction.localNavigation,
      padding: const AuraEdgeInsetsGeometry.symmetric(
        horizontal: .sm,
        vertical: .xs,
      ),
      semanticLabel: label,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const AuraSizedBox(width: .xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: typography.fontSizeSm,
                fontWeight: isActivity ? typography.fontWeightMedium : null,
                fontFamily: typography.bodyFontFamily,
              ),
            ),
          ),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _DisclosureScrollController extends ScrollController {
  var anchorActive = false;
  _RenderDisclosureSizeReporter? _anchorReporter;
  double _pendingExtentDelta = 0;

  void beginAnchor(_RenderDisclosureSizeReporter? reporter) {
    anchorActive = true;
    _anchorReporter = reporter;
    _pendingExtentDelta = 0;
  }

  void clearAnchor() {
    anchorActive = false;
    _anchorReporter = null;
    _pendingExtentDelta = 0;
  }

  void recordExtentDelta(_RenderDisclosureSizeReporter reporter, double delta) {
    if (anchorActive && reporter == _anchorReporter) {
      _pendingExtentDelta += delta;
    }
  }

  double takeExtentDelta() {
    final delta = _pendingExtentDelta;
    _pendingExtentDelta = 0;
    return delta;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _DisclosureScrollPosition(
    controller: this,
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  );
}

class _DisclosureScrollPosition extends ScrollPositionWithSingleContext {
  _DisclosureScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  final _DisclosureScrollController controller;

  @override
  bool correctForNewDimensions(
    ScrollMetrics oldPosition,
    ScrollMetrics newPosition,
  ) {
    // Correct during layout; a post-frame jump briefly paints the reverse-list
    // size change in the wrong direction.
    if (controller.anchorActive) {
      final extentDelta = controller.takeExtentDelta();
      if (extentDelta.abs() > .5) {
        final correction = axisDirection == AxisDirection.up
            ? extentDelta
            : -extentDelta;
        final targetPixels = oldPosition.pixels + correction;
        correctPixels(
          targetPixels.clamp(
            newPosition.minScrollExtent,
            newPosition.maxScrollExtent,
          ),
        );
        controller.clearAnchor();
        return false;
      }
      controller.clearAnchor();
    }

    return super.correctForNewDimensions(oldPosition, newPosition);
  }
}

class const _DisclosureSizeReporter({
  required this.controller,
  required super.child,
  super.key,
}) extends SingleChildRenderObjectWidget {
  final _DisclosureScrollController controller;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDisclosureSizeReporter(controller);
}

class _RenderDisclosureSizeReporter extends RenderProxyBox {
  _RenderDisclosureSizeReporter(this.controller);

  final _DisclosureScrollController controller;
  double? _previousHeight;

  @override
  void performLayout() {
    super.performLayout();
    final previousHeight = _previousHeight;
    final currentHeight = size.height;
    _previousHeight = currentHeight;
    if (previousHeight != null) {
      controller.recordExtentDelta(this, currentHeight - previousHeight);
    }
  }
}

void _toggleDisclosure({
  required BuildContext context,
  required VoidCallback update,
}) {
  final position = Scrollable.maybeOf(context)?.position;
  if (position is _DisclosureScrollPosition) {
    var renderObject = context.findRenderObject();
    _RenderDisclosureSizeReporter? reporter;
    while (renderObject != null) {
      if (renderObject is _RenderDisclosureSizeReporter) {
        reporter = renderObject;
        break;
      }
      renderObject = renderObject.parent;
    }
    position.controller.beginAnchor(reporter);
  }
  update();
}

class const _ActivityToolCallRow({
  required final McpAppToolResultController controller,
  required final String workspaceId,
  required final String conversationId,
  required final MessageToolCallEntity toolCall,
  required final String displayName,
  required final String? description,
  required final bool showArguments,
  required final bool isExpanded,
  required final Future<void> Function() onToggle,
  required final VoidCallback? openSubAgent,
  required final VoidCallback? onRunInBackground,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final decodedArgs = showArguments
        ? ToolMetadataDecoder.decode(toolCall.argumentsRaw)
        : null;
    final decodedResponse = ToolMetadataDecoder.decode(toolCall.responseRaw);
    final hasFailureWithoutDetails =
        toolCall.resultStatus == ToolCallResultStatus.executionError &&
        (decodedResponse == null || decodedResponse.isEmpty);
    final hasDetails =
        hasFailureWithoutDetails ||
        decodedArgs?.isNotEmpty == true ||
        decodedResponse?.isNotEmpty == true ||
        toolCall.appData?.isNotEmpty == true;
    final statusKey = _statusLocaleKey();
    final statusColor = _statusColor(context);
    final onOpenSubAgent = openSubAgent;
    final onBackground = onRunInBackground;
    final statusBadge = _ActivityToolStatusBadge(
      label: statusKey.tr(),
      color: statusColor,
      textKey: ValueKey('activity_tool_status_${toolCall.id}'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: .baseline,
          textBaseline: .alphabetic,
          children: [
            Expanded(
              child: AuraPressable(
                key: ValueKey('activity_tool_${toolCall.id}'),
                color: statusColor,
                onPressed: hasDetails ? () => unawaited(onToggle()) : null,
                interaction: AuraPressableInteraction.localNavigation,
                padding: const AuraEdgeInsetsGeometry.symmetric(
                  horizontal: .sm,
                  vertical: .xs,
                ),
                semanticLabel: [
                  displayName,
                  if (description != null) description,
                  statusKey.tr(),
                ].join(' '),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 240;

                    return Row(
                      children: [
                        Icon(_statusIcon(), size: 14, color: statusColor),
                        const AuraSizedBox(width: .xs),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: displayName),
                                if (description != null)
                                  TextSpan(
                                    text: ' · $description',
                                    style: TextStyle(
                                      color: statusColor.withValues(alpha: .72),
                                      fontSize: context
                                          .auraTheme
                                          .typography
                                          .fontSizeXs,
                                      fontFamily: context
                                          .auraTheme
                                          .typography
                                          .bodyFontFamily,
                                    ),
                                  ),
                              ],
                              style: TextStyle(
                                color: statusColor,
                                fontSize:
                                    context.auraTheme.typography.fontSizeSm,
                                fontFamily:
                                    context.auraTheme.typography.bodyFontFamily,
                              ),
                            ),
                            key: ValueKey('activity_tool_label_${toolCall.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const AuraSizedBox(width: .xs),
                        if (isCompact)
                          Flexible(child: statusBadge)
                        else
                          statusBadge,
                        if (hasDetails)
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: statusColor,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (onOpenSubAgent != null)
              AuraButton(
                key: ValueKey('activity_open_sub_agent_${toolCall.id}'),
                onPressed: onOpenSubAgent,
                child: const AuraRow(
                  children: [
                    TextLocale(
                      LocaleKeys
                          .chats_screens_chat_conversation_view_sub_agent_run,
                    ),
                    AuraIcon(Icons.open_in_new, size: .small, tint: .primary),
                  ],
                  spacing: .xs,
                  mainAxisSize: .min,
                ),
                variant: .ghost,
                size: .small,
              ),
          ],
        ),
        if (onBackground != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AuraButton(
              key: ValueKey('activity_run_in_background_${toolCall.id}'),
              onPressed: onBackground,
              variant: .ghost,
              size: .small,
              child: const TextLocale(
                LocaleKeys.chats_screens_chat_conversation_background_work_run,
              ),
            ),
          ),
        if (isExpanded && hasDetails)
          _ActivityToolCallDetails(
            key: ValueKey('activity_tool_details_${toolCall.id}'),
            controller: controller,
            workspaceId: workspaceId,
            conversationId: conversationId,
            toolCall: toolCall,
            decodedArgs: decodedArgs,
            decodedResponse: decodedResponse,
            onOpenToolResult: onOpenToolResult,
          ),
      ],
    );
  }

  String _statusLocaleKey() {
    final status = toolCall.resultStatus;
    if (status != null) return status.localeKey;

    return LocaleKeys.tool_call_status_pending;
  }

  IconData _statusIcon() {
    final status = toolCall.resultStatus;
    if (status == null) {
      return Icons.hourglass_empty;
    }

    return switch (status) {
      ToolCallResultStatus.running => Icons.sync,
      ToolCallResultStatus.success => Icons.check_circle_outline,
      ToolCallResultStatus.skippedByUser => Icons.skip_next,
      ToolCallResultStatus.stoppedByUser => Icons.stop_circle_outlined,
      ToolCallResultStatus.toolNotFound => Icons.error_outline,
      ToolCallResultStatus.disabledInWorkspace => Icons.block,
      ToolCallResultStatus.disabledInConversation => Icons.block,
      ToolCallResultStatus.disabledByAgent => Icons.block,
      ToolCallResultStatus.notConfigured => Icons.settings,
      ToolCallResultStatus.executionError => Icons.warning_amber,
      ToolCallResultStatus.uncertain => Icons.help_outline,
    };
  }

  Color _statusColor(BuildContext context) {
    final status = toolCall.resultStatus;
    final colors = context.auraColors;
    if (status == null) {
      return colors.warning;
    }

    return switch (status) {
      ToolCallResultStatus.running => colors.primary,
      ToolCallResultStatus.success => colors.success,
      ToolCallResultStatus.skippedByUser => colors.onSurfaceVariant,
      ToolCallResultStatus.stoppedByUser => colors.onSurfaceVariant,
      ToolCallResultStatus.toolNotFound => colors.error,
      ToolCallResultStatus.disabledInWorkspace => colors.warning,
      ToolCallResultStatus.disabledInConversation => colors.warning,
      ToolCallResultStatus.disabledByAgent => colors.warning,
      ToolCallResultStatus.notConfigured => colors.warning,
      ToolCallResultStatus.executionError => colors.error,
      ToolCallResultStatus.uncertain => colors.warning,
    };
  }
}

class const _ActivityToolStatusBadge({
  required final String label,
  required final Color color,
  required final Key textKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 120),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.fromSpacing(.xs),
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(.sm),
        ),
      ),
      child: Text(
        label,
        key: textKey,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: context.auraTheme.typography.fontSizeXs,
          fontFamily: context.auraTheme.typography.bodyFontFamily,
        ),
      ),
    ),
  );
}

class const _ActivityToolCallDetails({
  required final McpAppToolResultController controller,
  required final String workspaceId,
  required final String conversationId,
  required final MessageToolCallEntity toolCall,
  required final String? decodedArgs,
  required final String? decodedResponse,
  required final ValueChanged<SidebarToolResultTab> onOpenToolResult,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final colors = context.auraColors;
    final responseRaw = toolCall.responseRaw;
    final contextProjection = responseRaw == null
        ? null
        : readToolOutputProjectionMetadata(
            toolCall.responseContextRaw ?? responseRaw,
          );
    final persistedProjection = responseRaw == null
        ? null
        : readToolOutputProjectionMetadata(responseRaw);
    final truncationMetadata = contextProjection ?? persistedProjection;
    final truncationKey = persistedProjection == null
        ? LocaleKeys.chats_screens_chat_conversation_activity_context_truncated
        : LocaleKeys
              .chats_screens_chat_conversation_activity_persisted_truncated;
    final truncationMessage = truncationMetadata == null
        ? null
        : truncationKey.tr(
            namedArgs: {
              'originalBytes': truncationMetadata.originalBytes.toString(),
              'limitBytes': truncationMetadata.limitBytes.toString(),
            },
          );

    return Padding(
      padding: EdgeInsets.only(
        left: theme.fromSpacing(.sm),
        top: theme.fromSpacing(.xs),
        bottom: theme.fromSpacing(.xs),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (decodedArgs case final value? when value.isNotEmpty)
              _ActivityToolCallDetail(
                label: LocaleKeys
                    .chats_screens_chat_conversation_activity_arguments,
                child: Text(
                  value,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: theme.typography.fontSizeXs,
                    fontFamily: theme.typography.monoFontFamily,
                  ),
                ),
              ),
            if (truncationMessage case final value?)
              Semantics(
                child: Text(
                  value,
                  key: ValueKey('activity_tool_truncation_${toolCall.id}'),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: theme.typography.fontSizeXs,
                    fontFamily: theme.typography.bodyFontFamily,
                  ),
                ),
                container: true,
                excludeSemantics: true,
                label: value,
              ),
            if (toolCall.resultStatus == ToolCallResultStatus.executionError &&
                (decodedResponse == null || decodedResponse!.isEmpty))
              TextLocale(
                isWorkspaceToolName(toolCall.name)
                    ? LocaleKeys
                          .chats_screens_chat_conversation_activity_workspace_failure_no_details
                    : LocaleKeys
                          .chats_screens_chat_conversation_activity_failure_no_details,
              ),
            if (decodedResponse case final value? when value.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: theme.fromSpacing(.xs)),
                child: _ActivityToolCallDetail(
                  label: LocaleKeys
                      .chats_screens_chat_conversation_activity_result,
                  child: AuraContainer(
                    key: ValueKey('activity_tool_result_${toolCall.id}'),
                    variant: AuraContainerVariant.surfaceVariant,
                    padding: .small,
                    borderRadius: 8,
                    child: ToolCallResponsePreview(
                      content: value,
                      inspectionStatus: truncationMessage,
                      onShowMore: () => onOpenToolResult((
                        id: toolCall.id,
                        title: toolCall.name,
                        content: value,
                        status: truncationMessage,
                      )),
                    ),
                  ),
                ),
              ),
            McpAppToolResult(
              workspaceId: workspaceId,
              conversationId: conversationId,
              toolCall: toolCall,
              fallbackText: decodedResponse,
              controller: controller,
            ),
          ],
        ),
      ),
    );
  }
}

class const _ActivityToolCallDetail({
  required final String label,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextLocale(
        label,
        style: TextStyle(
          color: context.auraColors.onSurfaceVariant,
          fontSize: context.auraTheme.typography.fontSizeXs,
          fontWeight: FontWeight.w600,
          fontFamily: context.auraTheme.typography.bodyFontFamily,
        ),
      ),
      const AuraSizedBox(height: .xs),
      child,
    ],
  );
}

String? _persistedSubAgentConversationId(
  MessageToolCallEntity toolCall,
  List<ConversationEntity> children,
) {
  if (!_isRunSubAgentTool(toolCall.name)) return null;
  final title = _subAgentTitle(toolCall);
  if (title == null) return null;

  final matches = children.where((child) => child.title == title).toList();

  return matches.length == 1 ? matches.single.id : null;
}

String? _activeSubAgentConversationId(
  WidgetRef ref,
  String parentConversationId,
  MessageToolCallEntity toolCall,
) {
  if (!_isRunSubAgentTool(toolCall.name) || toolCall.responseRaw != null) {
    return null;
  }

  return ref.watch(
    activeSubAgentRuntimeProvider.select((state) {
      final childIds = state[parentConversationId] ?? const <String>{};

      return childIds.length == 1 ? childIds.single : null;
    }),
  );
}

String? _subAgentConversationId(MessageToolCallEntity toolCall) {
  if (!_isRunSubAgentTool(toolCall.name)) return null;

  final responseRaw = toolCall.responseRaw;
  if (responseRaw == null) return null;

  try {
    final decoded = jsonDecode(responseRaw);
    if (decoded case {'conversationId': final String conversationId}) {
      return conversationId;
    }
    if (decoded case {
      'childConversationId': final String childConversationId,
    }) {
      return childConversationId;
    }
    if (decoded case {'children': final List children}) {
      final childIds = children
          .whereType<Map>()
          .map((child) => child['conversationId'])
          .whereType<String>()
          .toSet();
      return childIds.length == 1 ? childIds.single : null;
    }
  } on Object {
    return null;
  }

  return null;
}

bool _isRunSubAgentTool(String toolName) {
  return toolName == runSubAgentToolName ||
      toolName.endsWith('__$runSubAgentToolName');
}

String? _subAgentTitle(MessageToolCallEntity toolCall) {
  try {
    final decoded = jsonDecode(toolCall.argumentsRaw);
    if (decoded case {'title': final String title}) {
      final normalized = title.trim();
      if (normalized.isNotEmpty) return normalized;
    }
  } on Object {
    return null;
  }

  return null;
}

class const _CompactedMessageWidget({
  required final MessageEntity message,
  required final String workspaceId,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    const iconSize = 16.0;
    const infoIconSize = 14.0;
    const containerBorderRadius = 10.0;
    final kind = message.metadata?.compactionKind;
    final originLabel = switch (kind) {
      CompactionKind.manual =>
        LocaleKeys.compaction_compacted_manual_origin.tr(),
      CompactionKind.auto => LocaleKeys.compaction_compacted_auto_origin.tr(),
      _ => LocaleKeys.compaction_compacted_widget_label.tr(),
    };

    return AuraModal(
      entryPointChild: AuraContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compress_outlined,
                  size: iconSize,
                  color: auraColors.onSurfaceVariant,
                ),
                const AuraSizedBox(width: .xs),
                Text(
                  originLabel,
                  style: TextStyle(
                    color: auraColors.onSurfaceVariant,
                    fontSize: context.auraTheme.typography.fontSizeSm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.info_outline,
                  size: infoIconSize,
                  color: auraColors.onSurfaceVariant,
                ),
              ],
            ),
            const AuraSizedBox(height: .xs),
            Text(
              message.content,
              style: TextStyle(
                color: auraColors.onSurfaceVariant,
                fontSize: context.auraTheme.typography.fontSizeSm,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ),
        padding: .medium,
        margin: .small,
        variant: AuraContainerVariant.surfaceVariant,
        borderRadius: containerBorderRadius,
      ),
      contentChild: Builder(
        builder: (modalContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: CompactedMessageDetails(
                message: message,
                workspaceId: workspaceId,
              ),
            ),
            AuraButton(
              onPressed: () =>
                  Navigator.of(modalContext, rootNavigator: true).pop(),
              child: const TextLocale(LocaleKeys.common_close),
              variant: AuraButtonVariant.text,
            ),
          ],
        ),
      ),
      barrierLabel: LocaleKeys.common_close.tr(),
      semanticLabel: LocaleKeys.compaction_compacted_details_title.tr(),
    );
  }
}

class const _ErrorMessageWidget({
  required final String content,
  required final bool isProviderError,
  required final ProviderFailureCategory? providerFailureCategory,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final visibleContent = isProviderError
        ? LogRedaction.redact(content)
        : content.tr(context: context);
    final guidanceLabel = isProviderError
        ? _providerRecoveryGuidanceLabel(context, providerFailureCategory)
        : null;
    const iconSize = 16.0;
    const containerBorderRadius = 10.0;

    return AuraContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (guidanceLabel case final label?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(label),
            ),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: iconSize,
                color: auraColors.onError,
              ),
              const AuraSizedBox(width: .xs),
              Flexible(child: AuraSelectableText(visibleContent)),
            ],
          ),
          if (visibleContent.isNotEmpty)
            _MessageCopyAction(resolveContent: () => visibleContent),
        ],
      ),
      padding: .medium,
      margin: .small,
      variant: AuraContainerVariant.surfaceVariant,
      borderRadius: containerBorderRadius,
      border: Border.fromBorderSide(BorderSide(color: auraColors.error)),
    );
  }
}

String _providerRecoveryGuidanceLabel(
  BuildContext context,
  ProviderFailureCategory? category,
) => switch (category) {
  .authentication =>
    LocaleKeys.chats_screens_chat_conversation_provider_recovery_authentication
        .tr(context: context),
  .quotaRateLimit =>
    LocaleKeys
        .chats_screens_chat_conversation_provider_recovery_quota_rate_limit
        .tr(context: context),
  .transientOutage =>
    LocaleKeys
        .chats_screens_chat_conversation_provider_recovery_transient_outage
        .tr(context: context),
  .configuration =>
    LocaleKeys.chats_screens_chat_conversation_provider_recovery_configuration
        .tr(context: context),
  .unknown || null =>
    LocaleKeys.chats_screens_chat_conversation_provider_recovery_unknown.tr(
      context: context,
    ),
};

class const _CompactingIndicator() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    const containerBorderRadius = 10.0;

    return AuraContainer(
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: SizedBox(width: 16, height: 16, child: AuraSpinner()),
          ),
          const AuraSizedBox(width: .sm),
          Text(
            LocaleKeys.compaction_compacting_row_label.tr(),
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: context.auraTheme.typography.fontSizeSm,
            ),
          ),
        ],
      ),
      padding: .medium,
      margin: .small,
      variant: AuraContainerVariant.surfaceVariant,
      borderRadius: containerBorderRadius,
    );
  }
}
