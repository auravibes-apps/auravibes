import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_record_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferenceRow({
  required final String workspaceId,
  required final WorkspaceRecord record,
  final bool selected = false,
  final String? selectedId,
  final bool multiple = false,
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
  String get _label =>
      row.record.values[table.labelColumnId]?.toString().trim() ?? '';
  String get _details => table.columns
      .where(_secondary)
      .map(_detail)
      .where((detail) => detail.isNotEmpty)
      .take(2)
      .join(' / ');
  String get _shortId => row.record.id.lastCharacters(6);
  String get _titleText => _label.isEmpty
      ? LocaleKeys.workspace_items_reference_unnamed.tr(args: [_shortId])
      : _label;
  String get _subtitleText => _details.isEmpty
      ? LocaleKeys.workspace_items_reference_record_id.tr(args: [_shortId])
      : LocaleKeys.workspace_items_reference_candidate_details.tr(
          args: [_details, _shortId],
        );

  @override
  Widget build(BuildContext context) => row.onSelect == null
      ? ListTile(
          title: Text(_titleText),
          subtitle: Text(table.name),
          onTap: () => _open(context),
        )
      : _ReferenceChoiceRow(tile: this);

  bool _secondary(WorkspaceColumn column) =>
      column.id != table.labelColumnId && column.type != .reference;
  String _detail(WorkspaceColumn column) =>
      switch (row.record.values[column.id]) {
        null || '' => '',
        final value => '${column.name}: $value',
      };
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
  Widget build(BuildContext context) =>
      tile.row.multiple ? _ReferenceCheckbox(tile) : _ReferenceRadio(tile);
}

class const _ReferenceCheckbox(final _ReferenceTile tile)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: tile.row.selected,
    onChanged: _select,
    title: Text(tile._titleText),
    subtitle: Text(tile._subtitleText),
    semanticLabel: tile._label,
  );

  void _select(bool _) => tile.row.onSelect?.call();
}

class const _ReferenceRadio(final _ReferenceTile tile) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRadioListTile<String>(
    value: tile.row.record.id,
    groupValue: tile.row.selectedId,
    onChanged: _select,
    title: Text(tile._titleText),
    subtitle: Text(tile._subtitleText),
    semanticLabel: tile._label,
  );

  void _select(String? _) => tile.row.onSelect?.call();
}

class const _ReferenceChoiceRow({required final _ReferenceTile tile})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _ReferenceChoice(tile: tile)),
      IconButton(
        onPressed: () => tile._open(context),
        tooltip: LocaleKeys.workspace_items_reference_details.tr(),
        icon: const Icon(Icons.open_in_new),
      ),
    ],
  );
}
