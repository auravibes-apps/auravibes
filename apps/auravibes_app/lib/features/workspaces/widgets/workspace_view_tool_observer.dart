import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

/// Opens newly completed view commands, never previously loaded history.
class WorkspaceViewToolObserver extends ConsumerStatefulWidget {
  const new({
    required this.workspaceId,
    required this.conversationId,
    required this.child,
    super.key,
  });

  final String workspaceId;
  final String conversationId;
  final Widget child;

  @override
  ConsumerState<WorkspaceViewToolObserver> createState() =>
      _WorkspaceViewToolObserverState();
}

class _WorkspaceViewToolObserverState
    extends ConsumerState<WorkspaceViewToolObserver> {
  final _handled = <String>{};
  bool _initialized = false;
  int _sequence = 0;

  @override
  void didUpdateWidget(WorkspaceViewToolObserver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.conversationId != widget.conversationId) {
      _handled.clear();
      _initialized = false;
      _sequence++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = chatMessagesProvider(
      widget.workspaceId,
      widget.conversationId,
    );
    final initial = ref.read(provider);
    final initialMessages = initial.value;
    if (!_initialized &&
        initialMessages != null &&
        !initial.isLoading &&
        !initial.hasError) {
      _observe(initialMessages);
    }
    ref.listen(provider, (_, next) {
      final messages = next.value;
      if (messages == null || next.isLoading || next.hasError) return;
      _observe(messages);
    });

    return widget.child;
  }

  void _observe(List<MessageEntity> messages) {
    final calls = messages
        .where(
          (message) =>
              message.conversationId == widget.conversationId &&
              !message.isForkReference &&
              message.sourceConversationId == null,
        )
        .expand(
          (message) =>
              message.metadata?.toolCalls ?? const <MessageToolCallEntity>[],
        );
    for (final call in calls) {
      if (call.resultStatus != ToolCallResultStatus.success) continue;
      if (!_initialized) {
        final _ = _handled.add(call.id);
        continue;
      }
      final id = _viewId(call);
      if (id != null && _handled.add(call.id)) {
        unawaited(_open(id, ++_sequence));
      }
    }
    _initialized = true;
  }

  Future<void> _open(String id, int sequence) async {
    if (!mounted || sequence != _sequence) return;
    final workspaceId = widget.workspaceId;
    final conversationId = widget.conversationId;
    try {
      final views = await ref.read(
        workspaceViewUsecaseProvider(workspaceId).future,
      );
      if (!_isCurrent(workspaceId, conversationId, sequence)) return;
      final _ = await views.open(id);
      if (!_isCurrent(workspaceId, conversationId, sequence)) return;
      ref.invalidate(workspaceViewDataProvider(workspaceId, id));
      ref
          .read(workspaceOpenViewProvider(workspaceId, conversationId).notifier)
          .openItem(id, 'view');
    } on Object catch (error) {
      if (!_isCurrent(workspaceId, conversationId, sequence)) return;
      final denied =
          (error is WorkspaceTableException &&
              error.localizationKey ==
                  LocaleKeys.cloud_errors_permission_denied) ||
          (error is CloudAppException &&
              error.localizationKey ==
                  LocaleKeys.cloud_errors_permission_denied);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(
          content: TextLocale(
            denied
                ? LocaleKeys.cloud_errors_permission_denied
                : LocaleKeys.common_error_message,
          ),
          action: denied
              ? null
              : SnackBarAction(
                  label: LocaleKeys.route_state_retry.tr(),
                  onPressed: () => unawaited(_open(id, sequence)),
                ),
        ),
      );
    }
  }

  bool _isCurrent(String workspaceId, String conversationId, int sequence) =>
      mounted &&
      sequence == _sequence &&
      workspaceId == widget.workspaceId &&
      conversationId == widget.conversationId;
}

String? _viewId(MessageToolCallEntity call) {
  if (call.id.isEmpty || call.name != workspaceCommandToolName) return null;
  final action = call.arguments['action'];
  if (action != 'createView' && action != 'saveView') return null;
  try {
    final result = jsonDecode(call.responseRaw ?? '');
    if (result is! Map || result['kind'] != 'view') return null;
    final id = result['id'];

    return id is String && id.isNotEmpty ? id : null;
  } on FormatException {
    return null;
  }
}
