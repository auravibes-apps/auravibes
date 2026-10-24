import 'package:auravibes_app/features/workspaces/models/workspace_reference.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferencePicker({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn column,
  required final List<String> selected,
  required final ValueChanged<List<String>> onSelected,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = useState(selected.toSet());
    final search = useState('');
    final cursor = useState<String?>(null);
    final refresh = useState(0);
    final target = ref.watch(
      workspaceTableProvider(workspaceId, column.targetTableId ?? ''),
    );
    final future = useMemoized(() async {
      final usecase = await ref.read(
        workspaceReferencesUsecaseProvider(workspaceId).future,
      );
      return usecase.targets(
        sourceTableId: table.id,
        columnId: column.id,
        search: search.value,
        afterId: cursor.value,
      );
    }, [search.value, cursor.value, refresh.value]);
    final page = useFuture(future);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(column.name),
          AuraTextField(
            label: LocaleKeys.workspace_items_reference_search.tr(),
            onChanged: (value) {
              search.value = value;
              cursor.value = null;
            },
          ),
          if (target case AsyncData(value: final target))
            if (target.canEditRecords)
              AuraButton(
                onPressed: () => _create(context, target, (record) {
                  _select(selectedIds, record.id);
                  refresh.value++;
                }),
                child: const TextLocale(
                  LocaleKeys.workspace_items_create_record,
                ),
              ),
          Expanded(
            child: _ReferenceResults(
              workspaceId: workspaceId,
              page: page,
              selected: selectedIds.value,
              onSelect: (id) => _select(selectedIds, id),
            ),
          ),
          if (page.data?.nextId case final next?)
            AuraButton(
              onPressed: () => cursor.value = next,
              child: const TextLocale(
                LocaleKeys.workspace_items_reference_next,
              ),
            ),
          if (cursor.value != null)
            AuraButton(
              onPressed: () => cursor.value = null,
              child: const TextLocale(
                LocaleKeys.workspace_items_reference_previous,
              ),
            ),
          AuraButton(
            onPressed: () => onSelected(selectedIds.value.toList()),
            child: const TextLocale(LocaleKeys.workspace_items_done),
          ),
        ],
      ),
    );
  }

  void _select(ValueNotifier<Set<String>> selected, String id) {
    if (!column.referenceMultiple) {
      selected.value = {id};
      return;
    }
    final next = {...selected.value};
    if (!next.remove(id)) next.add(id);
    selected.value = next;
  }

  Future<void> _create(
    BuildContext context,
    WorkspaceTable target,
    ValueChanged<WorkspaceRecord> saved,
  ) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: 680,
        height: 560,
        child: SingleChildScrollView(
          child: WorkspaceRecordEditor(
            workspaceId: workspaceId,
            table: target,
            record: null,
            onSaved: saved,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    ),
  );
}

class const _ReferenceResults({
  required final String workspaceId,
  required final AsyncSnapshot<WorkspaceReferencePage> page,
  required final Set<String> selected,
  required final ValueChanged<String> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (page.hasError)
      return const TextLocale(LocaleKeys.workspace_items_reference_unavailable);
    if (page.connectionState != ConnectionState.done)
      return const Center(child: CircularProgressIndicator());
    final records = page.data?.records ?? const <WorkspaceRecord>[];
    if (records.isEmpty)
      return const TextLocale(LocaleKeys.workspace_items_reference_empty);
    return ListView(
      children: [
        for (final record in records)
          _ReferenceRow(
            workspaceId: workspaceId,
            record: record,
            selected: selected.contains(record.id),
            onSelect: () => onSelect(record.id),
          ),
      ],
    );
  }
}

class const _ReferenceRow({
  required final String workspaceId,
  required final WorkspaceRecord record,
  required final bool selected,
  required final VoidCallback onSelect,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceTableProvider(workspaceId, record.tableId),
  )) {
    AsyncData(value: final table) => Row(
      children: [
        Expanded(
          child: AuraCheckboxListTile(
            value: selected,
            onChanged: (_) => onSelect(),
            title: Text(record.values[table.labelColumnId]?.toString() ?? ''),
            subtitle: Text(_details(table)),
            semanticLabel:
                record.values[table.labelColumnId]?.toString() ?? table.name,
          ),
        ),
        AuraButton(
          onPressed: () => _detailsDialog(context, table),
          child: const TextLocale(LocaleKeys.workspace_items_reference_details),
        ),
      ],
    ),
    AsyncError() => const TextLocale(
      LocaleKeys.workspace_items_reference_unavailable,
    ),
    AsyncLoading() => const CircularProgressIndicator(),
  };

  String _details(WorkspaceTable table) => table.columns
      .where(
        (column) =>
            column.id != table.labelColumnId && column.type != .reference,
      )
      .take(2)
      .map((column) => '${column.name}: ${record.values[column.id] ?? ''}')
      .join(' · ');

  Future<void> _detailsDialog(BuildContext context, WorkspaceTable table) =>
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 680,
            height: 560,
            child: SingleChildScrollView(
              child: WorkspaceRecordEditor(
                workspaceId: workspaceId,
                table: table,
                record: record,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      );
}
