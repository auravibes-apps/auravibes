// ignore_for_file: type=lint, type=warning
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_historical_surface.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_form_scope.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// Observes the existing catalog's tab selection without changing its bindings.
Widget trackChatA2uiTabSelection(
  Widget child,
  VoidCallback Function(ValueGetter<int>) register,
  VoidCallback onChanged,
) => switch (child) {
  BoundNumber value => BoundNumber(
    key: value.key,
    dataContext: value.dataContext,
    value: value.value,
    builder: (context, number) => trackChatA2uiTabSelection(
      value.builder(context, number),
      register,
      onChanged,
    ),
  ),
  BoundObject value => BoundObject(
    key: value.key,
    dataContext: value.dataContext,
    value: value.value,
    builder: (context, object) => trackChatA2uiTabSelection(
      value.builder(context, object),
      register,
      onChanged,
    ),
  ),
  AuraTabs<void> tabs => _CopyableTabs(
    key: tabs.key,
    tabs: tabs,
    register: register,
    onChanged: onChanged,
  ),
  _ => child,
};

class _CopyableTabs extends StatefulWidget {
  const new({
    required this.tabs,
    required this.register,
    required this.onChanged,
    super.key,
  });

  final AuraTabs<void> tabs;
  final VoidCallback Function(ValueGetter<int>) register;
  final VoidCallback onChanged;

  @override
  State<_CopyableTabs> createState() => _CopyableTabsState();
}

class _CopyableTabsState extends State<_CopyableTabs> {
  var _selectedIndex = 0;
  late VoidCallback _unregister;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.tabs.selectedIndex ?? widget.tabs.initialIndex;
    _selectedIndex = _currentIndex();
    _unregister = widget.register(_currentIndex);
  }

  @override
  void didUpdateWidget(covariant _CopyableTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedIndex =
        widget.tabs.selectedIndex ??
        (oldWidget.tabs.items.isEmpty
            ? widget.tabs.initialIndex
            : _selectedIndex);
    _selectedIndex = _currentIndex();
    _unregister();
    _unregister = widget.register(_currentIndex);
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  int _currentIndex() => widget.tabs.items.isEmpty
      ? 0
      : (widget.tabs.selectedIndex ?? _selectedIndex).clamp(
          0,
          widget.tabs.items.length - 1,
        );

  void _select(int index) {
    _selectedIndex = index;
    widget.tabs.onChanged?.call(index);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => AuraTabs<void>(
    items: widget.tabs.items,
    initialIndex: widget.tabs.initialIndex,
    selectedIndex: widget.tabs.selectedIndex,
    onChanged: _select,
  );
}

class ChatA2uiSurfaceHost extends StatelessWidget {
  const new message({
    required this.runtime,
    required this.messageId,
    required this.payloads,
    this.issuesBySurface = const {},
    this.messageIssues = const [],
    this.interactive = true,
    super.key,
  }) : _historical = false;

  const new live({
    required this.runtime,
    required this.messageId,
    this.interactive = true,
    super.key,
  }) : payloads = const [],
       issuesBySurface = const {},
       messageIssues = const [],
       _historical = false;

  const new historical({
    required this.messageId,
    required this.payloads,
    super.key,
  }) : runtime = null,
       interactive = false,
       issuesBySurface = const {},
       messageIssues = const [],
       _historical = true;

  final ChatA2uiRuntime? runtime;
  final String messageId;
  final Iterable<String> payloads;
  final Map<String, List<String>> issuesBySurface;
  final List<String> messageIssues;
  final bool interactive;
  final bool _historical;

  @override
  Widget build(BuildContext context) {
    if (_historical) {
      return SelectionArea(
        child: ChatA2uiHistoricalSurface(
          messageId: messageId,
          payloads: payloads,
        ),
      );
    }
    final currentRuntime = runtime;
    if (currentRuntime == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(animation: currentRuntime, builder: _buildRuntime);
  }

  Widget _buildRuntime(BuildContext context, Widget? _) {
    final currentRuntime = runtime!;
    final currentMessageId = messageId;
    final ids = currentRuntime
        .surfaceSlotsFor(currentMessageId)
        .toList(growable: false);
    final readyIds = ids
        .where((id) => currentRuntime.isReadySurface(currentMessageId, id))
        .toList(growable: false);
    final messageHasWarning = currentRuntime
        .a2uiMessageIssuesFor(currentMessageId)
        .isNotEmpty;
    if (ids.isEmpty) {
      return _buildEmptyState(
        context,
        currentRuntime,
        currentMessageId,
        messageHasWarning,
      );
    }
    if (readyIds.isEmpty && !currentRuntime.hasSurfaceIssue(currentMessageId)) {
      return const SizedBox.shrink();
    }

    return SelectionArea(
      child: _buildSurfaceColumn(
        context,
        currentRuntime,
        currentMessageId,
        ids,
        readyIds,
        messageHasWarning,
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ChatA2uiRuntime currentRuntime,
    String currentMessageId,
    bool messageHasWarning,
  ) {
    if (issuesBySurface.isNotEmpty || messageIssues.isNotEmpty) {
      return AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in issuesBySurface.entries)
            ChatA2uiWarning(
              details: chatA2uiDiagnosticDetails(
                conversationId: currentRuntime.conversationId,
                messageId: currentMessageId,
                surfaceId: '$currentMessageId:${entry.key}',
                issues: entry.value,
              ),
              uiPayloads: payloads,
            ),
          if (messageIssues.isNotEmpty)
            ChatA2uiWarning(
              details: chatA2uiDiagnosticDetails(
                conversationId: currentRuntime.conversationId,
                messageId: currentMessageId,
                issues: messageIssues,
              ),
              uiPayloads: payloads,
            ),
        ],
      );
    }
    if (messageHasWarning || currentRuntime.hasSurfaceIssue(currentMessageId)) {
      return ChatA2uiWarning(
        details: chatA2uiDiagnosticDetails(
          conversationId: currentRuntime.conversationId,
          messageId: currentMessageId,
          issues: currentRuntime.a2uiMessageIssuesFor(currentMessageId),
        ),
        uiPayloads: currentRuntime.diagnosticPayloadsFor(currentMessageId),
      );
    }
    if (payloads.isEmpty) return const SizedBox.shrink();

    return ChatA2uiSurfaceHost.historical(
      key: ValueKey(currentMessageId),
      messageId: currentMessageId,
      payloads: payloads,
    );
  }

  Widget _buildSurfaceColumn(
    BuildContext context,
    ChatA2uiRuntime currentRuntime,
    String currentMessageId,
    List<String> ids,
    List<String> readyIds,
    bool messageHasWarning,
  ) {
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in ids)
          ..._buildSurfaceChildren(
            context,
            currentRuntime,
            currentMessageId,
            id,
            readyIds.contains(id),
          ),
        if (messageHasWarning)
          _buildMessageWarning(currentRuntime, currentMessageId),
      ],
    );
  }

  List<Widget> _buildSurfaceChildren(
    BuildContext context,
    ChatA2uiRuntime currentRuntime,
    String currentMessageId,
    String id,
    bool isReady,
  ) {
    final isInteractive =
        isReady &&
        currentRuntime.isInteractiveSurface(currentMessageId, id) &&
        interactive;
    final issues = currentRuntime.issuesForSurface(id);

    return [
      if (isReady)
        _buildSurface(currentRuntime, currentMessageId, id, isInteractive),
      if (issues.isNotEmpty)
        ChatA2uiWarning(
          details: chatA2uiDiagnosticDetails(
            conversationId: currentRuntime.conversationId,
            messageId: currentMessageId,
            surfaceId: id,
            issues: issues.map((issue) => issue.name),
          ),
          uiPayloads: currentRuntime.diagnosticPayloadsFor(currentMessageId),
        ),
      if (currentRuntime.hasSubmissionIssue(id)) const ChatA2uiFormWarning(),
      if (isInteractive) _buildSubmitButton(context, currentRuntime, id),
      if (isInteractive && currentRuntime.formResetLabel(id) != null)
        _buildResetButton(currentRuntime, id),
    ];
  }

  Widget _buildSurface(
    ChatA2uiRuntime currentRuntime,
    String currentMessageId,
    String id,
    bool isInteractive,
  ) {
    return AuraInteractionScope(
      policy: isInteractive
          ? const AuraInteractionPolicy.interactive()
          : const AuraInteractionPolicy.readOnly(),
      child: ChatA2uiFormScope(
        runtime: currentRuntime,
        surfaceId: id,
        child: TickerMode(
          enabled: currentRuntime.isCurrentMessage(currentMessageId),
          child: Surface(
            key: ValueKey(id),
            surfaceContext: currentRuntime.controller.contextFor(id),
            actionDelegate: const ReadOnlyChatA2uiActionDelegate(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    ChatA2uiRuntime currentRuntime,
    String id,
  ) {
    return AuraButton(
      key: ValueKey('a2ui_submit_$id'),
      isFullWidth: true,
      onPressed: () => currentRuntime.submitForm(
        id,
        messageText: chatA2uiText(
          context,
          LocaleKeys.chats_screens_chat_conversation_form_submitted,
          'Form answers submitted',
        ),
      ),
      disabled: !currentRuntime.canSubmitForm(messageId, id),
      semanticLabel: chatA2uiText(
        context,
        LocaleKeys.chats_screens_chat_conversation_submit_answers,
        'Submit answers',
      ),
      child: Text(
        currentRuntime.formSubmitLabel(id) ??
            chatA2uiText(
              context,
              LocaleKeys.chats_screens_chat_conversation_submit_answers,
              'Submit answers',
            ),
      ),
    );
  }

  Widget _buildResetButton(ChatA2uiRuntime currentRuntime, String id) {
    return AuraButton(
      key: ValueKey('a2ui_reset_$id'),
      variant: AuraButtonVariant.outlined,
      onPressed: () => currentRuntime.resetForm(id),
      child: Text(currentRuntime.formResetLabel(id)!),
    );
  }

  Widget _buildMessageWarning(
    ChatA2uiRuntime currentRuntime,
    String currentMessageId,
  ) {
    return ChatA2uiWarning(
      details: chatA2uiDiagnosticDetails(
        conversationId: currentRuntime.conversationId,
        messageId: currentMessageId,
        issues: currentRuntime.a2uiMessageIssuesFor(currentMessageId),
      ),
      uiPayloads: currentRuntime.diagnosticPayloadsFor(currentMessageId),
    );
  }
}
