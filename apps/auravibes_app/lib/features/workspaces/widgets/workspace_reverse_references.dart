import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReverseReferences({required final String workspaceId,
  required final WorkspaceRecord record, super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = useState(false);
    final cursor = useState<String?>(null);
    final future = useMemoized(() async {
      if (!expanded.value) return null;
      final references = await ref.read(workspaceReferencesUsecaseProvider(workspaceId).future);
      return references.reverse(tableId: record.tableId, recordId: record.id, afterId: cursor.value);
    }, [expanded.value, cursor.value]);
    final page = useFuture(future);
    return Column(children: [
      AuraButton(onPressed: () => expanded.value = !expanded.value,
        child: const TextLocale(LocaleKeys.workspace_items_reference_reverse)),
      if (expanded.value) ...[
        if (page.hasError) const TextLocale(LocaleKeys.workspace_items_reference_unavailable)
        else if (page.connectionState != ConnectionState.done) const CircularProgressIndicator()
        else ...[
          if (page.data?.records.isEmpty ?? true) const TextLocale(LocaleKeys.workspace_items_reference_empty),
          for (final source in page.data?.records ?? const <WorkspaceRecord>[])
            _ReverseRow(workspaceId: workspaceId, record: source),
          if (page.data?.nextId case final id?) AuraButton(onPressed: () => cursor.value = id,
            child: const TextLocale(LocaleKeys.workspace_items_reference_next)),
        ],
      ],
    ]);
  }
}

class const _ReverseRow({required final String workspaceId,
  required final WorkspaceRecord record}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(workspaceTableProvider(workspaceId, record.tableId))) {
    AsyncData(value: final table) => ListTile(title: Text(record.values[table.labelColumnId]?.toString() ?? ''),
      subtitle: Text(table.name), onTap: () => _open(context, table)),
    AsyncError() => const TextLocale(LocaleKeys.workspace_items_reference_unavailable),
    AsyncLoading() => const CircularProgressIndicator(),
  };

  Future<void> _open(BuildContext context, WorkspaceTable table) => showDialog<void>(
    context: context, builder: (context) => Dialog(child: SizedBox(width: 680, height: 560,
      child: SingleChildScrollView(child: WorkspaceRecordEditor(workspaceId: workspaceId,
        table: table, record: record, onBack: () => Navigator.of(context).pop())))));
}
