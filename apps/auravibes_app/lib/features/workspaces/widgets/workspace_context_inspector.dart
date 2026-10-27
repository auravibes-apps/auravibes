import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_context_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceContextInspector({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = useMemoized(() => _describeContext(ref), [
      workspaceId,
      conversationId,
    ]);
    final state = useFuture(future);

    return _WorkspaceContextInspectorDialog(state: state);
  }

  Future<Map<String, Object?>?> _describeContext(WidgetRef ref) async =>
      await (await ref.read(
        workspaceConversationContextUsecaseProvider(workspaceId).future,
      )).describe(conversationId);
}

class const _WorkspaceContextInspectorDialog({
  required final AsyncSnapshot<Map<String, Object?>?> state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(LocaleKeys.workspace_chat_title),
    content: _WorkspaceContextInspectorContent(state: state),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const TextLocale(LocaleKeys.common_close),
      ),
    ],
    scrollable: true,
  );
}

class const _WorkspaceContextInspectorContent({
  required final AsyncSnapshot<Map<String, Object?>?> state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncSnapshot(:final Object error) => WorkspaceItemFailure(error: error),
    AsyncSnapshot(connectionState: .done, :final data) =>
      _WorkspaceContextScope(data: data),
    _ => const CircularProgressIndicator(),
  };
}

class const _WorkspaceContextScope({required final Map<String, Object?>? data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = this.data;
    if (data == null) return const TextLocale(LocaleKeys.workspace_chat_none);

    return Column(
      mainAxisSize: .min,
      children: [
        _WorkspaceContextScopeHeader(data: data),
        TextLocale(switch (data['kind']) {
          'directory' => LocaleKeys.workspace_chat_directory_shared_scope,
          'folder' => LocaleKeys.workspace_chat_folder_shared_scope,
          'file' => LocaleKeys.workspace_chat_file_shared_scope,
          _ => LocaleKeys.workspace_chat_scope,
        }),
        if (_hasRestrictedReferences(data['records']))
          const TextLocale(LocaleKeys.workspace_chat_reference_scope),
        _WorkspaceContextRecords(
          rows: _recordRows(data['records']),
          labelColumnId: _labelColumnId(data['labelColumnId']),
        ),
      ],
    );
  }
}

class const _WorkspaceContextScopeHeader({
  required final Map<String, Object?> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (data['name']) {
    final String name => Text(name),
    _ => const TextLocale(LocaleKeys.workspace_items_title),
  };
}

class const _WorkspaceContextRecords({
  required final List<Object?>? rows,
  required final String? labelColumnId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = this.rows;
    if (rows == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      children: [
        for (final row in rows)
          if (row is Map<String, Object?>)
            _WorkspaceContextRecordTile(row: row, labelColumnId: labelColumnId),
      ],
    );
  }
}

class const _WorkspaceContextRecordTile({
  required final Map<String, Object?> row,
  required final String? labelColumnId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(_recordLabel(row, labelColumnId)),
    subtitle: Text('${row['id']}'),
  );
}

List<Object?>? _recordRows(Object? value) =>
    value is List<Object?> ? value : null;

String? _labelColumnId(Object? value) => value is String ? value : null;

String _recordLabel(Map<String, Object?> row, Object? label) {
  final values = row['values'];
  if (values is! Map<String, Object?> || label is! String) {
    return '${row['id']}';
  }

  return '${values[label] ?? row['id']}';
}

bool _hasRestrictedReferences(Object? rows) {
  if (rows is! List<Object?>) return false;
  for (final row in rows) {
    if (row is! Map<String, Object?>) continue;
    final restricted = row['restrictedReferenceColumns'];
    if (restricted is List<Object?> && restricted.isNotEmpty) return true;
  }

  return false;
}
