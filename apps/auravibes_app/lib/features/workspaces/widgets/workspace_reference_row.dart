import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_record_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferenceRow({
  required final String workspaceId,
  required final WorkspaceRecord record,
  final bool selected = false,
  final VoidCallback? onSelect,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceTableProvider(workspaceId, record.tableId),
  )) {
    AsyncData(value: final table) => _ReferenceTile(row: this, table: table),
    AsyncError() => const TextLocale(
      LocaleKeys.workspace_items_reference_unavailable,
    ),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _ReferenceTile({
  required final WorkspaceReferenceRow row,
  required final WorkspaceTable table,
}) extends StatelessWidget {
  String get _label => row.record.values[table.labelColumnId]?.toString() ?? '';
  String get _details =>
      table.columns.where(_secondary).take(2).map(_detail).join(' / ');

  @override
  Widget build(BuildContext context) => row.onSelect == null
      ? ListTile(
          title: Text(_label),
          subtitle: Text(table.name),
          onTap: () => _open(context),
        )
      : _ReferenceChoiceRow(tile: this);

  bool _secondary(WorkspaceColumn column) =>
      column.id != table.labelColumnId && column.type != .reference;
  String _detail(WorkspaceColumn column) =>
      '${column.name}: ${row.record.values[column.id] ?? ''}';
  Future<void> _open(BuildContext context) =>
      WorkspaceReferenceRecordDialog.open(context, row.workspaceId, (
        table: table,
        record: row.record,
        onSaved: null,
      ));
}

class const _ReferenceChoice({required final _ReferenceTile tile})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: tile.row.selected,
    onChanged: (_) => tile.row.onSelect?.call(),
    title: Text(tile._label),
    subtitle: Text(tile._details),
    semanticLabel: tile._label,
  );
}

class const _ReferenceChoiceRow({required final _ReferenceTile tile})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _ReferenceChoice(tile: tile)),
      AuraButton(
        onPressed: () => tile._open(context),
        child: const TextLocale(LocaleKeys.workspace_items_reference_details),
      ),
    ],
  );
}
