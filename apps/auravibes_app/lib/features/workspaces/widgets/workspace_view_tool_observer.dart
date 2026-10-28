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

typedef _Item = ({
  String id,
  String kind,
  bool refreshDirectory,
  String? parentId,
});
typedef _OpenRequest = ({
  String id,
  String kind,
  int sequence,
  bool refreshDirectory,
});
typedef _RefreshRequest = ({
  String id,
  String workspaceId,
  String conversationId,
  bool refreshDirectory,
});

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
    if (!_initialized) _observeReady(ref.read(provider));
    ref.listen(provider, (_, next) => _observeReady(next));

    return widget.child;
  }

  void _observeReady(AsyncValue<List<MessageEntity>> state) {
    final messages = state.value;
    if (messages == null || state.isLoading || state.hasError) return;
    _observe(messages);
  }

  void _observe(List<MessageEntity> messages) {
    for (final call in _calls(messages)) {
      if (call.resultStatus != ToolCallResultStatus.success) continue;
      if (!_initialized) {
        final _ = _handled.add(call.id);
        continue;
      }
      _handleCall(call);
    }
    _initialized = true;
  }

  Future<void> _open(_OpenRequest request) async {
    if (!mounted) return;
    final context = (
      workspaceId: widget.workspaceId,
      conversationId: widget.conversationId,
    );
    try {
      await _refreshItem(request, context.workspaceId, context.conversationId);
      _openIfCurrent(request, context.workspaceId, context.conversationId);
    } on _StaleWorkspaceContext {
      return;
    } on Object catch (error) {
      _reportError(error, request, context);
    }
  }

  void _reportError(
    Object error,
    _OpenRequest request,
    ({String workspaceId, String conversationId}) context,
  ) {
    final (:workspaceId, :conversationId) = context;
    if (!_isCurrent(workspaceId, conversationId, request.sequence)) return;
    _showError(error, () {
      if (!_isCurrent(workspaceId, conversationId, request.sequence)) return;
      unawaited(_open(request));
    });
  }

  Future<void> _refreshItem(
    _OpenRequest request,
    String workspaceId,
    String conversationId,
  ) async {
    final refresh = (
      id: request.id,
      workspaceId: workspaceId,
      conversationId: conversationId,
      refreshDirectory: request.refreshDirectory,
    );
    if (request.kind == 'table') {
      await _refreshTable(refresh);
    } else {
      await _refreshView(refresh);
    }
  }

  void _openIfCurrent(
    _OpenRequest request,
    String workspaceId,
    String conversationId,
  ) {
    if (!_isCurrent(workspaceId, conversationId, request.sequence)) return;
    ref
        .read(workspaceOpenViewProvider(workspaceId, conversationId).notifier)
        .openItem(request.id, request.kind);
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

extension _WorkspaceToolErrors on _WorkspaceViewToolObserverState {
  void _showError(Object error, VoidCallback onRetry) {
    final denied = _denied(error);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    final _ = messenger?.showSnackBar(_snackBar(denied, onRetry));
  }

  SnackBar _snackBar(bool denied, VoidCallback onRetry) => SnackBar(
    content: TextLocale(
      denied
          ? LocaleKeys.cloud_errors_permission_denied
          : LocaleKeys.common_error_message,
    ),
    action: denied
        ? null
        : SnackBarAction(
            label: LocaleKeys.route_state_retry.tr(),
            onPressed: onRetry,
          ),
  );

  bool _denied(Object error) =>
      (error is WorkspaceTableException &&
          error.localizationKey == LocaleKeys.cloud_errors_permission_denied) ||
      (error is CloudAppException &&
          error.localizationKey == LocaleKeys.cloud_errors_permission_denied);
}

extension _WorkspaceToolCalls on _WorkspaceViewToolObserverState {
  Iterable<MessageToolCallEntity> _calls(List<MessageEntity> messages) =>
      messages
          .where(_eligible)
          .expand(
            (message) =>
                message.metadata?.toolCalls ?? const <MessageToolCallEntity>[],
          );

  bool _eligible(MessageEntity message) =>
      message.conversationId == widget.conversationId &&
      !message.isForkReference &&
      message.sourceConversationId == null;

  void _handleCall(MessageToolCallEntity call) {
    final item = _item(call);
    if (item == null || !_handled.add(call.id)) return;
    if (item.kind == 'folder') {
      _refreshFolder(item);

      return;
    }
    _openItem(call, item);
  }

  void _openItem(MessageToolCallEntity call, _Item item) {
    final createTable =
        workspaceActionForTool(call.name, call.arguments) == 'createTable';
    if (createTable) {
      ref.invalidate(
        workspaceTablesProvider(widget.workspaceId, item.parentId),
      );
    }
    unawaited(_open(_request(item, createTable)));
  }

  _OpenRequest _request(_Item item, bool createTable) => (
    id: item.id,
    kind: item.kind,
    sequence: ++_sequence,
    refreshDirectory: item.refreshDirectory && !createTable,
  );

  void _refreshFolder(_Item item) {
    if (item.refreshDirectory) {
      ref.invalidate(
        workspaceFoldersProvider(widget.workspaceId, item.parentId),
      );
    } else {
      ref.invalidate(workspaceFoldersProvider);
    }
  }
}

extension _WorkspaceToolRefresh on _WorkspaceViewToolObserverState {
  Future<T> _guarded<T>(
    Future<T> operation,
    String workspaceId,
    String conversationId,
  ) async {
    final result = await operation;
    if (!_sameContext(workspaceId, conversationId)) {
      throw const _StaleWorkspaceContext();
    }

    return result;
  }

  Future<void> _refreshTable(_RefreshRequest request) async {
    final (:id, :workspaceId, :conversationId, :refreshDirectory) = request;
    final tables = await _guarded(
      ref.read(workspaceTableUsecaseProvider(workspaceId).future),
      workspaceId,
      conversationId,
    );
    final table = await _guarded(tables.table(id), workspaceId, conversationId);
    _invalidateTable(request, table.parentId);
  }

  void _invalidateTable(_RefreshRequest request, String? parentId) {
    final (:id, :workspaceId, :refreshDirectory, conversationId: _) = request;
    if (refreshDirectory) {
      ref.invalidate(workspaceTablesProvider(workspaceId, parentId));
    }
    ref
      ..invalidate(workspaceTableProvider(workspaceId, id))
      ..invalidate(workspaceTableRecordsProvider(workspaceId, id))
      ..invalidate(workspaceRecordQueryUsecaseProvider(workspaceId));
  }

  Future<void> _refreshView(_RefreshRequest request) async {
    final (:id, :workspaceId, :conversationId, :refreshDirectory) = request;
    final views = await _guarded(
      ref.read(workspaceViewUsecaseProvider(workspaceId).future),
      workspaceId,
      conversationId,
    );
    final data = await _guarded(views.open(id), workspaceId, conversationId);
    _invalidateView(request, data.view.parentId);
  }

  void _invalidateView(_RefreshRequest request, String? parentId) {
    final (:id, :workspaceId, :refreshDirectory, conversationId: _) = request;
    if (refreshDirectory) {
      ref.invalidate(workspaceViewsProvider(workspaceId, parentId));
    }
    ref.invalidate(workspaceViewDataProvider(workspaceId, id));
  }
}

class _StaleWorkspaceContext implements Exception {
  const new();
}

_Item? _item(MessageToolCallEntity call) {
  if (call.id.isEmpty || !isWorkspaceToolName(call.name)) return null;
  try {
    final result = jsonDecode(call.responseRaw ?? '');
    if (result is! Map) return null;

    return _itemResult(call, result);
  } on FormatException {
    return null;
  }
}

_Item? _itemResult(MessageToolCallEntity call, Map<dynamic, dynamic> result) {
  final action = workspaceActionForTool(call.name, call.arguments);
  final expectedKind = _expectedKind(action);
  if (expectedKind == null) return null;
  final kind = result['kind'];
  final id = _resultId(result, kind);
  if (!_validResult(kind, expectedKind, id)) {
    return null;
  }

  return _resolvedItem(call, result, action);
}

_Item? _resolvedItem(
  MessageToolCallEntity call,
  Map<dynamic, dynamic> result,
  String action,
) {
  final parentId = _parentId(call, result, action);
  if (parentId != null && parentId is! String) return null;

  return _buildItem(result, action, parentId as String?);
}

_Item _buildItem(
  Map<dynamic, dynamic> result,
  String action,
  String? parentId,
) {
  final kind = result['kind'] as String;

  return (
    id: _resultId(result, kind) as String? ?? '',
    kind: _displayKind(kind),
    refreshDirectory: _refreshDirectory(action, result),
    parentId: parentId,
  );
}

String _displayKind(String kind) => kind == 'record' ? 'table' : kind;

Object? _resultId(Map<dynamic, dynamic> result, Object? kind) =>
    kind == 'record' ? result['tableId'] : result['id'];

bool _validResult(Object? kind, String expectedKind, Object? id) =>
    (kind == expectedKind || (expectedKind == 'record' && kind == 'table')) &&
    id is String &&
    id.isNotEmpty;

Object? _parentId(
  MessageToolCallEntity call,
  Map<dynamic, dynamic> result,
  String action,
) => action == 'createTable' || action == 'createFolder'
    ? call.arguments['parentId']
    : result['parentId'];

String? _expectedKind(String action) => switch (action) {
  'createFolder' || 'renameFolder' => 'folder',
  'createView' || 'saveView' => 'view',
  'createRecord' || 'updateRecord' => 'record',
  'createTable' || 'renameTable' || 'saveColumn' => 'table',
  _ => null,
};

bool _refreshDirectory(String action, Map<dynamic, dynamic> result) =>
    switch (action) {
      'createTable' || 'createFolder' => true,
      'renameFolder' => result.containsKey('parentId'),
      'renameTable' || 'createView' || 'saveView' => true,
      _ => false,
    };
