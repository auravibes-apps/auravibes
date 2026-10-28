import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
      final item = _item(call);
      if (item != null && _handled.add(call.id)) {
        if (item.kind == 'folder') {
          if (item.refreshDirectory) {
            ref.invalidate(
              workspaceFoldersProvider(widget.workspaceId, item.parentId),
            );
          } else {
            ref.invalidate(workspaceFoldersProvider);
          }
          continue;
        }
        if (workspaceActionForTool(call.name, call.arguments) ==
            'createTable') {
          ref.invalidate(
            workspaceTablesProvider(widget.workspaceId, item.parentId),
          );
        }
        unawaited(
          _open(
            item.id,
            item.kind,
            ++_sequence,
            item.refreshDirectory &&
                workspaceActionForTool(call.name, call.arguments) !=
                    'createTable',
          ),
        );
      }
    }
    _initialized = true;
  }

  Future<void> _open(
    String id,
    String kind,
    int sequence,
    bool refreshDirectory,
  ) async {
    if (!mounted) return;
    final workspaceId = widget.workspaceId;
    final conversationId = widget.conversationId;
    try {
      if (kind == 'table') {
        final tables = await ref.read(
          workspaceTableUsecaseProvider(workspaceId).future,
        );
        if (!_sameContext(workspaceId, conversationId)) return;
        final table = await tables.table(id);
        if (!_sameContext(workspaceId, conversationId)) return;
        if (refreshDirectory) {
          ref.invalidate(workspaceTablesProvider(workspaceId, table.parentId));
        }
        ref
          ..invalidate(workspaceTableProvider(workspaceId, id))
          ..invalidate(workspaceTableRecordsProvider(workspaceId, id))
          ..invalidate(workspaceRecordQueryUsecaseProvider(workspaceId));
      } else {
        final views = await ref.read(
          workspaceViewUsecaseProvider(workspaceId).future,
        );
        if (!_sameContext(workspaceId, conversationId)) return;
        final data = await views.open(id);
        if (!_sameContext(workspaceId, conversationId)) return;
        if (refreshDirectory) {
          ref.invalidate(
            workspaceViewsProvider(workspaceId, data.view.parentId),
          );
        }
        ref.invalidate(workspaceViewDataProvider(workspaceId, id));
      }
      if (!_isCurrent(workspaceId, conversationId, sequence)) return;
      ref
          .read(workspaceOpenViewProvider(workspaceId, conversationId).notifier)
          .openItem(id, kind);
    } on Object catch (error) {
      if (!_isCurrent(workspaceId, conversationId, sequence)) return;
      final denied =
          (error is WorkspaceTableException &&
              error.localizationKey ==
                  LocaleKeys.cloud_errors_permission_denied) ||
          (error is CloudAppException &&
              error.localizationKey ==
                  LocaleKeys.cloud_errors_permission_denied);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      void retry() {
        if (!_isCurrent(workspaceId, conversationId, sequence)) return;
        unawaited(_open(id, kind, sequence, refreshDirectory));
      }

      final _ = messenger?.showSnackBar(
        .new(
          content: TextLocale(
            denied
                ? LocaleKeys.cloud_errors_permission_denied
                : LocaleKeys.common_error_message,
          ),
          action: denied
              ? null
              : SnackBarAction(
                  label: LocaleKeys.route_state_retry.tr(),
                  onPressed: retry,
                ),
        ),
      );
    }
  }

  bool _sameContext(String workspaceId, String conversationId) =>
      mounted &&
      workspaceId == widget.workspaceId &&
      conversationId == widget.conversationId;

  bool _isCurrent(String workspaceId, String conversationId, int sequence) =>
      mounted &&
      sequence == _sequence &&
      workspaceId == widget.workspaceId &&
      conversationId == widget.conversationId;
}

({String id, String kind, bool refreshDirectory, String? parentId})? _item(
  MessageToolCallEntity call,
) {
  if (call.id.isEmpty || !isWorkspaceToolName(call.name)) return null;
  try {
    final result = jsonDecode(call.responseRaw ?? '');
    if (result is! Map) return null;
    final resolvedAction = workspaceActionForTool(call.name, call.arguments);
    final action = resolvedAction;
    if (!{
      'createFolder',
      'renameFolder',
      'createView',
      'saveView',
      'createTable',
      'renameTable',
      'saveColumn',
      'createRecord',
      'updateRecord',
    }.contains(action)) {
      return null;
    }
    final kind = result['kind'];
    final id = kind == 'record' ? result['tableId'] : result['id'];
    final expectedKind = switch (action) {
      'createFolder' || 'renameFolder' => 'folder',
      'createView' || 'saveView' => 'view',
      'createRecord' || 'updateRecord' => 'record',
      _ => 'table',
    };
    if ((kind != expectedKind &&
            !(expectedKind == 'record' && kind == 'table')) ||
        id is! String ||
        id.isEmpty) {
      return null;
    }

    final parentId = action == 'createTable' || action == 'createFolder'
        ? call.arguments['parentId']
        : result['parentId'];
    if (parentId != null && parentId is! String) return null;

    return (
      id: id,
      kind: kind == 'record' ? 'table' : kind as String,
      refreshDirectory: switch (action) {
        'createTable' || 'createFolder' => true,
        'renameFolder' => result.containsKey('parentId'),
        'renameTable' || 'createView' || 'saveView' => true,
        _ => false,
      },
      parentId: parentId as String?,
    );
  } on FormatException {
    return null;
  }
}
