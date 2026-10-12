import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class const ChatAssistantResponseAnnouncement({
  required final String conversationId,
  required final List<ChatAssistantResponseProgress> responses,
  required final bool isStopRequested,
  super.key,
}) extends StatefulWidget {
  @override
  State<ChatAssistantResponseAnnouncement> createState() =>
      _ChatAssistantResponseAnnouncementState();
}

class const ChatAssistantResponseProgress({
  required final String messageId,
  required final bool isStreaming,
  required final MessageStatus status,
  required final bool hasResponse,
  required final bool isAwaitingUserAction,
});

class _ChatAssistantResponseAnnouncementState
    extends State<ChatAssistantResponseAnnouncement> {
  final Map<String, _AssistantResponseAnnouncement> _announcementByMessageId =
      {};
  _AssistantResponseAnnouncement? _currentAnnouncement;

  @override
  void initState() {
    super.initState();
    _synchronizeResponses();
  }

  @override
  void didUpdateWidget(covariant ChatAssistantResponseAnnouncement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _announcementByMessageId.clear();
      _currentAnnouncement = null;
    }
    _synchronizeResponses();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('assistant_response_status_${widget.conversationId}'),
    child: const SizedBox(width: 1, height: 1),
    container: true,
    focusable: false,
    liveRegion: true,
    label: _localizedAnnouncement(context),
  );

  void _synchronizeResponses() {
    for (final response in widget.responses) {
      if (response.isStreaming) {
        _announceStartIfNeeded(response);
        continue;
      }

      _announceTerminalIfNeeded(response);
    }
  }

  void _announceStartIfNeeded(ChatAssistantResponseProgress response) {
    if (_announcementByMessageId.containsKey(response.messageId) ||
        !response.hasResponse) {
      return;
    }

    _announcementByMessageId[response.messageId] = .started;
    _currentAnnouncement = .started;
  }

  void _announceTerminalIfNeeded(ChatAssistantResponseProgress response) {
    if (_announcementByMessageId[response.messageId] != .started) return;
    final terminalAnnouncement = _terminalAnnouncement(response);
    if (terminalAnnouncement == null) return;

    _announcementByMessageId[response.messageId] = terminalAnnouncement;
    _currentAnnouncement = terminalAnnouncement;
  }

  _AssistantResponseAnnouncement? _terminalAnnouncement(
    ChatAssistantResponseProgress response,
  ) {
    if (widget.isStopRequested) return .cancelled;

    return switch (response.status) {
      .sent => .completed,
      .error => .failed,
      .unfinished when response.isAwaitingUserAction => null,
      .unfinished => .cancelled,
      .sending => null,
    };
  }

  String? _localizedAnnouncement(BuildContext context) =>
      switch (_currentAnnouncement) {
        .started =>
          LocaleKeys.chats_screens_chat_conversation_assistant_response_started
              .tr(context: context),
        .completed =>
          LocaleKeys
              .chats_screens_chat_conversation_assistant_response_completed
              .tr(context: context),
        .failed =>
          LocaleKeys.chats_screens_chat_conversation_assistant_response_failed
              .tr(context: context),
        .cancelled =>
          LocaleKeys
              .chats_screens_chat_conversation_assistant_response_cancelled
              .tr(context: context),
        null => null,
      };
}

enum _AssistantResponseAnnouncement { started, completed, failed, cancelled }
