import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_query_filter_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_bulk_record_dialog.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_query_filter.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_label.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final draft = _Draft(table);
    final records = ref.watch(
      workspaceRecordQueryProvider(workspaceId, table.id, draft.query.value),
    );

    return _Frame(this, draft, records);
  }
}

class _Draft {
  new(WorkspaceTable table)
    : query = useState(const WorkspaceRecordQuery()),
      controls = useState(false),
      selecting = useState(false),
      selected = useState<Map<String, WorkspaceRecord>>({}),
      columns = useState(table.columns.map((column) => column.id).toSet());

  final ValueNotifier<WorkspaceRecordQuery> query;
  final ValueNotifier<bool> controls;
  final ValueNotifier<bool> selecting;
  final ValueNotifier<Map<String, WorkspaceRecord>> selected;
  final ValueNotifier<Set<String>> columns;
  bool canSelect(WorkspaceRecord record) =>
      selected.value.containsKey(record.id) ||
      selected.value.length < WorkspaceRecordChange.maxOperations;
  void toggle(WorkspaceRecord record) =>
      setSelected(record, checked: !selected.value.containsKey(record.id));
  void setSelected(WorkspaceRecord record, {required bool checked}) {
    selecting.value = true;
    final next = Map.of(selected.value);
    if (!checked) {
      final _ = next.remove(record.id);
    } else if (canSelect(record)) {
      final _ = next.putIfAbsent(record.id, () => record);
    }
    selected.value = next;
  }
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
      if (owner.table.canEditRecords) _BulkToolbar(owner, draft),
      if (draft.controls.value) _Controls(owner, draft),
      Expanded(child: _RecordState(owner, draft, records)),
      _Pages(draft.query, more: records.value?.hasMore ?? false),
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
        semanticLabel: LocaleKeys.common_filters.tr(),
        tooltip: LocaleKeys.common_filters.tr(),
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
      owner,
      value.records,
      draft.columns.value,
      owner.onRecord,
      draft,
    ),
    AsyncError(:final error) => SingleChildScrollView(
      child: WorkspaceItemFailure(error: error),
    ),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

class const _Pages(
  final ValueNotifier<WorkspaceRecordQuery> query, {
  required final bool more,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: .spaceBetween,
    children: [
      _PageButton(this, previous: true),
      Text('${query.value.offset ~/ query.value.limit + 1}'),
      _PageButton(this, previous: false),
    ],
  );
  void _page(int direction) => query.value = query.value.change(
    offset: query.value.offset + query.value.limit * direction,
  );
}

class const _PageButton(final _Pages pages, {required final bool previous})
    extends StatelessWidget {
  bool get _disabled => previous ? pages.query.value.offset == 0 : !pages.more;
  String get _tooltip =>
      (previous
              ? LocaleKeys.workspace_items_previous_page
              : LocaleKeys.workspace_items_next_page)
          .tr();
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: previous ? Icons.chevron_left : Icons.chevron_right,
    onPressed: () => pages._page(previous ? -1 : 1),
    disabled: _disabled,
    identifier: previous
        ? 'workspace_records_previous'
        : 'workspace_records_next',
    semanticLabel: _tooltip,
    tooltip: _tooltip,
  );
}

class const _Controls(final WorkspaceRecordBrowser owner, final _Draft draft)
    extends StatelessWidget {
  WorkspaceTable get table => owner.table;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    child: ListView(
      children: [
        WorkspaceQueryFilter(
          table: table,
          workspaceId: owner.workspaceId,
          query: draft.query,
        ),
        _SortColumn(table, draft),
        _Direction(draft),
        _QueryAvailability(table),
        for (final column in table.columns) _VisibleColumn(column, draft),
      ],
    ),
  );
}

class const _QueryAvailability(final WorkspaceTable table)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      table.columns.any((column) => !_supportsQuery(column))
      ? const TextLocale(LocaleKeys.workspace_items_query_type_unavailable)
      : const SizedBox.shrink();
}

class const _QueryDropdown(
  final WorkspaceTable table,
  final String value,
  final ValueChanged<String?> onChanged,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [for (final column in table.columns) _QueryColumnOption(column)],
    value: value,
    onChanged: onChanged,
    label: const TextLocale(LocaleKeys.common_sort_by),
  );
}

class _QueryColumnOption extends AuraDropdownOption<String> {
  new(WorkspaceColumn column)
    : super(
        value: column.id,
        isEnabled: _supportsQuery(column),
        child: Text(column.name),
      );
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
  final WorkspaceRecordBrowser browser,
  final List<WorkspaceRecord> records,
  final Set<String> columns,
  final ValueChanged<WorkspaceRecord> onRecord,
  final _Draft draft,
) extends StatelessWidget {
  WorkspaceTable get table => browser.table;

  List<WorkspaceColumn> get visible {
    final selected = table.columns
        .where((column) => columns.contains(column.id))
        .toList();

    return selected.isEmpty
        ? [
            table.columns.firstWhere(
              (column) => column.id == table.labelColumnId,
            ),
          ]
        : selected;
  }

  bool isSelecting() => table.canEditRecords && draft.selecting.value;
  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: TextLocale(LocaleKeys.workspace_items_no_records),
      );
    }

    return LayoutBuilder(builder: _layout);
  }

  Widget _layout(BuildContext _, BoxConstraints constraints) =>
      constraints.maxWidth < 600
      ? ListView(
          children: [for (final record in records) _RecordRow(this, record)],
        )
      : _Grid(this);
}

class const _RecordRow(final _Rows owner, final WorkspaceRecord record)
    extends StatelessWidget {
  bool get _selecting => owner.isSelecting();
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('workspace_record_${record.id}'),
    leading: _selecting ? _RecordCheckbox(owner, record) : null,
    title: Text(_value(record, owner.table.labelColumnId)),
    subtitle: _RecordDetails(owner, record),
    onTap: _tap,
    onLongPress: owner.table.canEditRecords ? _select : null,
  );
  void _select() => owner.draft.toggle(record);
  void _tap() {
    if (_selecting) {
      _select();
    } else {
      owner.onRecord(record);
    }
  }
}

class const _RecordCheckbox(final _Rows owner, final WorkspaceRecord record)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Checkbox(
    value: owner.draft.selected.value.containsKey(record.id),
    onChanged: owner.draft.canSelect(record)
        ? (checked) =>
              owner.draft.setSelected(record, checked: checked ?? false)
        : null,
  );
}

class const _RecordDetails(final _Rows owner, final WorkspaceRecord record)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      for (final column in owner.visible.where(
        (column) => column.id != owner.table.labelColumnId,
      ))
        _RecordDetail(owner, record, column),
    ],
  );
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
        dataRowMaxHeight: .infinity,
        rows: [for (final record in owner.records) _row(record)],
      ),
    ),
  );
  DataRow _row(WorkspaceRecord record) => _GridRecord(owner, record).create();
}

class const _GridRecord(final _Rows owner, final WorkspaceRecord record) {
  bool get _selecting => owner.isSelecting();
  bool get _selected => owner.draft.selected.value.containsKey(record.id);
  bool get _canSelect => _selecting && owner.draft.canSelect(record);
  DataRow create() => DataRow(
    selected: _selected,
    onSelectChanged: _canSelect ? _changed : null,
    onLongPress: owner.table.canEditRecords ? _select : null,
    cells: [for (final column in owner.visible) _cell(column)],
  );
  void _changed(bool? checked) =>
      owner.draft.setSelected(record, checked: checked ?? false);
  void _select() => owner.draft.toggle(record);
  void _tap() {
    if (_selecting) {
      _select();
    } else {
      owner.onRecord(record);
    }
  }

  DataCell _cell(WorkspaceColumn column) =>
      DataCell(_Cell(owner, record, column), onTap: _tap);
}

class const _RecordDetail(
  final _Rows owner,
  final WorkspaceRecord record,
  final WorkspaceColumn column,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    children: [
      Expanded(child: Text('${column.name}: ')),
      Expanded(flex: 2, child: _Cell(owner, record, column)),
    ],
  );
}

class const _Cell(
  final _Rows owner,
  final WorkspaceRecord record,
  final WorkspaceColumn column,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (record.restrictedReferenceColumns.contains(column.id)) {
      return const TextLocale(LocaleKeys.workspace_items_reference_unavailable);
    }
    if (column.type == WorkspaceColumnType.reference) {
      return _ReferenceCell(owner, record.values[column.id], column);
    }

    return Text(_value(record, column.id, column));
  }
}

class const _ReferenceCell(
  final _Rows owner,
  final Object? value,
  final WorkspaceColumn column,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (value) {
    final String id => _ReferenceLabel(owner, column, id),
    final List<Object?> ids => Wrap(
      children: [
        for (final id in ids.whereType<String>())
          _ReferenceLabel(owner, column, id),
      ],
    ),
    _ => const TextLocale(LocaleKeys.workspace_items_missing_value),
  };
}

class const _ReferenceLabel(
  final _Rows owner,
  final WorkspaceColumn column,
  final String id,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceReferenceLabel(
    workspaceId: owner.browser.workspaceId,
    targetTableId: column.targetTableId ?? '',
    recordId: id,
  );
}

String _value(
  WorkspaceRecord record,
  String columnId, [
  WorkspaceColumn? column,
]) {
  final value = record.values[columnId];
  if (value == null) return LocaleKeys.workspace_items_missing_value.tr();
  if (column?.type == WorkspaceColumnType.timestamp && value is String) {
    return WorkspaceTimeZones.display(value, column?.timeZone ?? 'UTC');
  }

  return _display(value);
}

String _display(Object value) => switch (value) {
  {'amount': final String amount, 'currency': final String currency} =>
    '$currency $amount',
  final List<Object?> values => values.join(', '),
  _ => value.toString(),
};
bool _supportsQuery(WorkspaceColumn column) =>
    WorkspaceQueryFilterValidation.supports(column);

class const _BulkToolbar(
  final WorkspaceRecordBrowser browser,
  final _Draft draft,
) extends ConsumerWidget {
  List<WorkspaceRecord> get _selected =>
      List.unmodifiable(draft.selected.value.values);
  @override
  Widget build(BuildContext context, WidgetRef ref) => draft.selecting.value
      ? _SelectedRecordsToolbar(this)
      : _StartSelection(draft);
  void _done() {
    draft.selecting.value = false;
    draft.selected.value = {};
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await WorkspaceBulkRecordDialog.open(
      context,
      browser.workspaceId,
      browser.table,
      _selected,
    );
    if (!context.mounted || !saved) return;
    ref.invalidate(workspaceRecordQueryUsecaseProvider(browser.workspaceId));
    _done();
  }
}

class const _StartSelection(final _Draft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => draft.selecting.value = true,
    child: const TextLocale(LocaleKeys.workspace_items_bulk_select),
    identifier: 'workspace_records_select',
  );
}

class const _SelectedRecordsToolbar(final _BulkToolbar owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: .center,
    children: [
      _SelectionCount(owner.draft),
      if (owner.draft.selected.value.length ==
          WorkspaceRecordChange.maxOperations)
        const TextLocale(LocaleKeys.workspace_items_bulk_limit),
      _EditSelection(owner),
      _DoneSelection(owner),
    ],
  );
}

class const _SelectionCount(final _Draft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.workspace_items_bulk_selected.tr(
      namedArgs: {'count': '${draft.selected.value.length}'},
    ),
  );
}

class const _EditSelection(final _BulkToolbar owner) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => unawaited(owner._edit(context, ref)),
    child: const TextLocale(LocaleKeys.workspace_items_bulk_edit),
    disabled: owner.draft.selected.value.isEmpty,
    identifier: 'workspace_records_bulk_edit',
  );
}

class const _DoneSelection(final _BulkToolbar owner) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: owner._done,
    child: const TextLocale(LocaleKeys.workspace_items_done),
    identifier: 'workspace_records_selection_done',
  );
}
