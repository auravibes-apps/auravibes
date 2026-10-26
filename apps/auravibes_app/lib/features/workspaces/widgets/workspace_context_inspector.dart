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
    final future = useMemoized(
      () async => await (await ref.read(
        workspaceConversationContextUsecaseProvider(workspaceId).future,
      )).describe(conversationId),
      [workspaceId, conversationId],
    );
    final state = useFuture(future);

    return AlertDialog(
      title: const TextLocale(LocaleKeys.workspace_chat_title),
      content: switch (state) {
        AsyncSnapshot(:final Object error) => WorkspaceItemFailure(
          error: error,
        ),
        AsyncSnapshot(connectionState: .done, :final data) =>
          _WorkspaceContextScope(data: data),
        _ => const CircularProgressIndicator(),
      },
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_close),
        ),
      ],
      scrollable: true,
    );
  }
}

class const _WorkspaceContextScope({required final Map<String, Object?>? data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = this.data;
    if (data == null) return const TextLocale(LocaleKeys.workspace_chat_none);
    final rows = data['records'];
    final label = data['labelColumnId'];

    return Column(
      mainAxisSize: .min,
      children: [
        if (data['name'] case final String name)
          Text(name)
        else
          const TextLocale(LocaleKeys.workspace_items_title),
        const TextLocale(LocaleKeys.workspace_chat_scope),
        if (_hasRestrictedReferences(rows))
          const TextLocale(LocaleKeys.workspace_chat_reference_scope),
        if (rows is List<Object?>)
          for (final row in rows)
            if (row is Map<String, Object?>)
              ListTile(
                title: Text(_recordLabel(row, label)),
                subtitle: Text('${row['id']}'),
              ),
      ],
    );
  }
}

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
