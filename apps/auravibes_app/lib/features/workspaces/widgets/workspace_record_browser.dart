import 'package:easy_localization/easy_localization.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceRecordBrowser({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final ValueChanged<WorkspaceRecord> onRecord,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _Draft.use(table);
    final records = ref.watch(
      workspaceRecordQueryProvider(workspaceId, table.id, draft.query.value),
    );

    return _Frame(this, draft, records);
  }
}

class const _Draft(
  final ValueNotifier<WorkspaceRecordQuery> query,
  final ValueNotifier<bool> controls,
  final ValueNotifier<Set<String>> columns,
  final ValueNotifier<String?> filter,
) {
  static _Draft use(WorkspaceTable table) => _Draft(
    useState(const WorkspaceRecordQuery()),
    useState(false),
    useState(table.columns.map((column) => column.id).toSet()),
    useState(null),
  );
}

class const _Frame(
  final WorkspaceRecordBrowser owner,
  final _Draft draft,
  final AsyncValue<WorkspaceRecordPage> records,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Search(draft),
      if (draft.controls.value) _Controls(owner.table, draft),
      Expanded(child: _RecordState(owner, draft, records)),
      _Pages(draft.query, records.value?.hasMore ?? false),
    ],
  );
}

class const _Search(final _Draft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AuraInput(
          label: const TextLocale(LocaleKeys.workspace_items_search),
          onSubmitted: _search,
          identifier: 'workspace_record_search',
        ),
      ),
      AuraIconButton(
        icon: Icons.tune,
        onPressed: _toggle,
        identifier: 'workspace_query_controls',
      ),
    ],
  );
  void _search(String text) =>
      draft.query.value = draft.query.value.change(search: text);
  void _toggle() => draft.controls.value = !draft.controls.value;
}

class const _RecordState(
  final WorkspaceRecordBrowser owner,
  final _Draft draft,
  final AsyncValue<WorkspaceRecordPage> records,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (records) {
    AsyncData(:final value) => _Rows(
      owner.table,
      value.records,
      draft.columns.value,
      owner.onRecord,
    ),
    AsyncError(:final error) => SingleChildScrollView(
      child: WorkspaceItemFailure(error: error),
    ),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

class const _Pages(
  final ValueNotifier<WorkspaceRecordQuery> query,
  final bool more,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: .spaceBetween,
    children: [
      AuraIconButton(icon:Icons.chevron_left,onPressed:() => _page(-1),disabled:query.value.offset==0,tooltip:LocaleKeys.workspace_items_previous_page.tr()),
      Text('${query.value.offset ~/ query.value.limit + 1}'),
      AuraIconButton(icon:Icons.chevron_right,onPressed:() => _page(1),disabled:!more,tooltip:LocaleKeys.workspace_items_next_page.tr()),
    ],
  );
  void _page(int direction) => query.value = query.value.change(
    offset: query.value.offset + query.value.limit * direction,
  );
}

class const _Controls(final WorkspaceTable table, final _Draft draft)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    child: ListView(
      children: [
        _FilterColumn(table, draft),
        _FilterValue(draft),
        _SortColumn(table, draft),
        _Direction(draft),
        if (table.columns.any((column) => !_supportsQuery(column)))
          const TextLocale(LocaleKeys.workspace_items_query_type_unavailable),
        for (final column in table.columns) _VisibleColumn(column, draft),
      ],
    ),
  );
}

class const _QueryDropdown(
  final WorkspaceTable table,
  final String value,
  final ValueChanged<String?> onChanged, {
  final bool filter = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      if (filter)
        const AuraDropdownOption(
          value: '',
          child: TextLocale(LocaleKeys.workspace_items_all_columns),
        ),
      for (final column in table.columns) _QueryColumnOption(column),
    ],
    value: value,
    onChanged: onChanged,
    label: TextLocale(
      filter ? LocaleKeys.common_filters : LocaleKeys.common_sort_by,
    ),
  );
}

class _QueryColumnOption extends AuraDropdownOption<String> {
  _QueryColumnOption(WorkspaceColumn column)
    : super(
        value: column.id,
        isEnabled: _supportsQuery(column),
        child: Text(column.name),
      );
}

class const _FilterColumn(final WorkspaceTable table, final _Draft draft)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _QueryDropdown(table, draft.filter.value ?? '', _change, filter: true);
  void _change(String? id) {
    draft.filter.value = id;
    if (id == null || id.isEmpty)
      draft.query.value = draft.query.value.filter(null, '');
  }
}

class const _FilterValue(final _Draft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    label: const TextLocale(LocaleKeys.workspace_items_filter_value),
    onSubmitted: _filter,
  );
  void _filter(String value) =>
      draft.query.value = draft.query.value.filter(draft.filter.value, value);
}

class const _SortColumn(final WorkspaceTable table, final _Draft draft)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _QueryDropdown(
    table,
    draft.query.value.sortColumnId ?? table.labelColumnId,
    _sort,
  );
  void _sort(String? id) =>
      draft.query.value = draft.query.value.change(sort: id);
}

class const _Direction(final _Draft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: draft.query.value.descending,
    onChanged: _change,
    title: const TextLocale(LocaleKeys.workspace_items_descending),
  );
  void _change(bool value) =>
      draft.query.value = draft.query.value.change(descending: value);
}

class const _VisibleColumn(final WorkspaceColumn column, final _Draft draft)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: draft.columns.value.contains(column.id),
    onChanged: _change,
    title: Text(column.name),
  );
  void _change(bool? checked) {
    if (checked == true) {
      draft.columns.value = {...draft.columns.value, column.id};

      return;
    }
    if (draft.columns.value.length <= 1) return;
    final selected = draft.columns.value.toSet();
    final _ = selected.remove(column.id);
    draft.columns.value = selected;
  }
}

class const _Rows(
  final WorkspaceTable table,
  final List<WorkspaceRecord> records,
  final Set<String> columns,
  final ValueChanged<WorkspaceRecord> onRecord,
) extends StatelessWidget {
  List<WorkspaceColumn> get visible {
    final selected=table.columns.where((column) => columns.contains(column.id)).toList();

    return selected.isEmpty ? [table.columns.firstWhere((column) => column.id==table.labelColumnId)] : selected;
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty)
      return const Center(
        child: TextLocale(LocaleKeys.workspace_items_no_records),
      );

    return LayoutBuilder(builder: _layout);
  }

  Widget _layout(BuildContext context, BoxConstraints constraints) =>
      constraints.maxWidth < 600
      ? ListView(
          children: [for (final record in records) _RecordRow(this, record)],
        )
      : _Grid(this);
}

class const _RecordRow(final _Rows owner, final WorkspaceRecord record)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(_value(record, owner.table.labelColumnId)),
    subtitle: Text(_details()),
    onTap: () => owner.onRecord(record),
  );
  String _details() => [
    for (final column in owner.visible.where(
      (column) => column.id != owner.table.labelColumnId,
    ))
      '${column.name}: ${_value(record, column.id)}',
  ].join('\n');
}

class const _Grid(final _Rows owner) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: SingleChildScrollView(
      scrollDirection: .horizontal,
      child: DataTable(
        columns: [
          for (final column in owner.visible)
            DataColumn(label: Text(column.name)),
        ],
        rows: [for (final record in owner.records) _row(record)],
      ),
    ),
  );
  DataRow _row(WorkspaceRecord record) => DataRow(
    cells: [
      for (final column in owner.visible)
        DataCell(
          Text(_value(record, column.id)),
          onTap: () => owner.onRecord(record),
        ),
    ],
  );
}

String _value(WorkspaceRecord record, String columnId) =>
    record.values[columnId]?.toString() ?? '';
bool _supportsQuery(WorkspaceColumn column) => !{
  'timestamp',
  'money',
  'multiSelect',
  'attachment',
  'reference',
}.contains(column.type.name);
