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
      () async => (await ref.read(
        workspaceConversationContextUsecaseProvider(workspaceId).future,
      )).describe(conversationId),
      [workspaceId, conversationId],
    );
    final state = useFuture(future);
    return AlertDialog(
      scrollable: true,
      title: const TextLocale(LocaleKeys.workspace_chat_title),
      content: state.hasError
          ? WorkspaceItemFailure(error: state.error!)
          : state.connectionState != ConnectionState.done
          ? const CircularProgressIndicator()
          : _scope(state.data),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_close),
        ),
      ],
    );
  }

  Widget _scope(Map<String, Object?>? data) {
    if (data == null) return const TextLocale(LocaleKeys.workspace_chat_none);
    final rows = data['records'];
    final label = data['labelColumnId'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data['name'] case final String name)
          Text(name)
        else
          const TextLocale(LocaleKeys.workspace_items_title),
        const TextLocale(LocaleKeys.workspace_chat_scope),
        if (rows is List<Object?>)
          for (final row in rows.whereType<Map<String, Object?>>())
            ListTile(
              title: Text(
                '${(row['values'] as Map<String, Object?>)[label] ?? row['id']}',
              ),
              subtitle: Text('${row['id']}'),
            ),
      ],
    );
  }
}
