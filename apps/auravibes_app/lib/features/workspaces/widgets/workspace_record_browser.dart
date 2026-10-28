import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_query_filter_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_bulk_record_dialog.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_type_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_minimum_viewport.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_query_filter.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_fields.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/widgets/confirmed_external_link.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _minColumnWidth = 120.0;
const _maxColumnWidth = 500.0;
const _defaultColumnWidth = 200.0;
const _columnIconSize = 18.0;
const _resizeIconSize = 16.0;
const _cellHeight = 48.0;
const _inlineEditorHeight = 24.0;
const _selectionToolbarSpacing = 8.0;

class const WorkspaceRecordBrowser({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final ValueChanged<WorkspaceRecord> onRecord,
  final ValueNotifier<bool>? selectionMode,
  final ValueNotifier<bool>? draftOpen,
  final VoidCallback? onAddRow,
  final ValueChanged<WorkspaceColumnType>? onAddColumn,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _Draft.use(selectionMode, draftOpen);
    _useSavedColumnWidths(ref, this, draft);
    final records = ref.watch(
      workspaceRecordQueryProvider(workspaceId, table.id, draft.query.value),
    );

    return _Frame(this, draft, records);
  }
}

void _useSavedColumnWidths(
  WidgetRef ref,
  WorkspaceRecordBrowser browser,
  _Draft draft,
) {
  useEffect(() => _loadSavedColumnWidths(ref, browser, draft), [
    browser.workspaceId,
    browser.table.id,
  ]);
}

VoidCallback _loadSavedColumnWidths(
  WidgetRef ref,
  WorkspaceRecordBrowser browser,
  _Draft draft,
) => _ColumnWidthLoad(ref, browser, draft).start();

class _ColumnWidthLoad(
  final WidgetRef ref,
  final WorkspaceRecordBrowser browser,
  final _Draft draft,
) {
  bool _mounted = true;

  VoidCallback start() {
    unawaited(_load());

    return () => _mounted = false;
  }

  Future<void> _load() async {
    final widths = await _loadColumnWidths(
      ref,
      browser.workspaceId,
      browser.table.id,
    );
    if (_mounted) {
      draft.columnWidths.value = {...widths, ...draft.columnWidths.value};
    }
  }
}

Future<void> createEmptyWorkspaceRecord(
  WidgetRef ref, {
  required String workspaceId,
  required WorkspaceTable table,
}) async {
  final usecase = await ref.read(
    workspaceTableUsecaseProvider(workspaceId).future,
  );
  final _ = await usecase.createRecord(
    table: table,
    values: {for (final column in table.columns) column.id: null},
  );
  if (ref.context.mounted) {
    ref.invalidate(workspaceRecordQueryUsecaseProvider(workspaceId));
  }
}

class _Draft {
  new(this.selecting, this.draftOpen)
    : query = useState(const WorkspaceRecordQuery()),
      controls = useState(false),
      selected = useState<Map<String, WorkspaceRecord>>({}),
      hiddenColumns = useState(<String>{}),
      columnWidths = useState<Map<String, double>>({}),
      active = useState<({String record, String column})?>(null),
      hovered = useState<String?>(null),
      nextSelection = useRef<VoidCallback?>(null),
      cellPointer = useRef<int?>(null),
      editing = useState(false),
      values = useState<Map<String, Object?>>({}),
      focusNodes = useRef(<String, FocusNode>{});

  factory use(
    ValueNotifier<bool>? selectionMode,
    ValueNotifier<bool>? draftOpen,
  ) {
    final localSelection = useState(false);
    final localDraft = useState(false);

    return _Draft(selectionMode ?? localSelection, draftOpen ?? localDraft);
  }

  final ValueNotifier<WorkspaceRecordQuery> query;
  final ValueNotifier<bool> controls;
  final ValueNotifier<bool> selecting;
  final ValueNotifier<bool> draftOpen;
  final ValueNotifier<Map<String, WorkspaceRecord>> selected;
  final ValueNotifier<Set<String>> hiddenColumns;
  final ValueNotifier<Map<String, double>> columnWidths;
  final ValueNotifier<({String record, String column})?> active;
  final ValueNotifier<String?> hovered;
  final ObjectRef<VoidCallback?> nextSelection;
  final ObjectRef<int?> cellPointer;
  final ValueNotifier<bool> editing;
  final ValueNotifier<Map<String, Object?>> values;
  final ObjectRef<Map<String, FocusNode>> focusNodes;
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
  static const _minimumHeight = 360.0;
  @override
  Widget build(BuildContext context) => WorkspaceMinimumViewport(
    minimumHeight: MediaQuery.textScalerOf(context).scale(_minimumHeight),
    child: _FrameContent(owner, draft, records),
  );
}

class const _FrameContent(
  final WorkspaceRecordBrowser owner,
  final _Draft draft,
  final AsyncValue<WorkspaceRecordPage> records,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Search(draft),
      _TableControls(owner, draft),
      Expanded(child: _RecordState(owner, draft, records)),
      IgnorePointer(
        ignoring: draft.draftOpen.value,
        child: _Pages(draft.query, more: records.value?.hasMore ?? false),
      ),
    ],
  );
}

class const _TableControls(
  final WorkspaceRecordBrowser owner,
  final _Draft draft,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: draft.draftOpen.value,
    child: Column(
      children: [
        if (owner.table.canEditRecords) _BulkToolbar(owner, draft),
        if (draft.controls.value) _Controls(owner, draft),
      ],
    ),
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
  Widget build(BuildContext context) {
    if (records case AsyncError(:final error)) {
      return SingleChildScrollView(child: WorkspaceItemFailure(error: error));
    }
    final value = records.value;
    if (value == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _Rows(
      owner,
      value.records,
      draft.hiddenColumns.value,
      owner.onRecord,
      draft,
    );
  }
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
        for (final column in table.columns)
          _VisibleColumn(column, draft, table),
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

class const _VisibleColumn(
  final WorkspaceColumn column,
  final _Draft draft,
  final WorkspaceTable table,
) extends StatelessWidget {
  bool get _canHide =>
      table.columns
          .where(
            (candidate) => !draft.hiddenColumns.value.contains(candidate.id),
          )
          .length >
      1;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: !draft.hiddenColumns.value.contains(column.id),
    onChanged: _change,
    title: Text(column.name),
  );

  void _change(bool? checked) {
    if (checked == true) {
      draft.hiddenColumns.value = {...draft.hiddenColumns.value}
        ..remove(column.id);

      return;
    }
    if (!_canHide) return;
    draft.hiddenColumns.value = {...draft.hiddenColumns.value, column.id};
  }
}

class const _Rows(
  final WorkspaceRecordBrowser browser,
  final List<WorkspaceRecord> records,
  final Set<String> hiddenColumns,
  final ValueChanged<WorkspaceRecord> onRecord,
  final _Draft draft,
) extends StatelessWidget {
  WorkspaceTable get table => browser.table;

  List<WorkspaceColumn> get visible {
    final selected = table.columns
        .where((column) => !hiddenColumns.contains(column.id))
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
  Widget build(BuildContext context) => Listener(
    onPointerDown: _clearSelection,
    behavior: .opaque,
    child: _Grid(this),
  );
  void _clearSelection(PointerDownEvent event) {
    if (draft.cellPointer.value == event.pointer) {
      draft.cellPointer.value = null;

      return;
    }
    if (!draft.draftOpen.value) draft.active.value = null;
  }
}

Future<Map<String, double>> _loadColumnWidths(
  WidgetRef ref,
  String workspaceId,
  String tableId,
) async {
  final preferences = await ref.read(sharedPreferencesProvider.future);
  final saved = preferences.getString(_columnWidthKey(workspaceId, tableId));
  if (saved == null) return {};

  return _decodeColumnWidths(saved);
}

Map<String, double> _decodeColumnWidths(String saved) {
  try {
    final decoded = jsonDecode(saved);
    if (decoded is! Map<String, dynamic>) return {};

    return {
      for (final entry in decoded.entries)
        if (entry.value is num)
          entry.key: (entry.value as num).toDouble().clamp(
            _minColumnWidth,
            _maxColumnWidth,
          ),
    };
  } on FormatException {
    return {};
  }
}

Future<void> _saveColumnWidths(
  WidgetRef ref,
  String workspaceId,
  String tableId,
  Map<String, double> widths,
) async {
  final preferences = await ref.read(sharedPreferencesProvider.future);
  final _ = await preferences.setString(
    _columnWidthKey(workspaceId, tableId),
    jsonEncode(widths),
  );
}

String _columnWidthKey(String workspaceId, String tableId) =>
    'workspace_table_column_widths_${workspaceId}_$tableId';

class const _Grid(final _Rows owner) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TapRegion(
    child: Align(
      alignment: .topLeft,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          child: _GridDataTable(this),
        ),
      ),
    ),
    onTapOutside: _clearSelection,
  );

  List<DataColumn> _columns() => [
    for (final column in owner.visible)
      DataColumn(label: _ResizableColumnHeading(owner, column)),
    if (owner.table.canManage && owner.browser.onAddColumn != null)
      DataColumn(label: _AddColumnMenu(owner)),
  ];

  List<DataRow> _rows(BuildContext context) => [
    for (final record in owner.records)
      _GridRecord(owner, record, Theme.of(context).colorScheme).create(),
    if (owner.table.canEditRecords && owner.browser.onAddRow != null)
      _emptyRow(),
  ];

  DataRow _emptyRow() => DataRow(
    cells: [
      DataCell(_AddEmptyRecord(owner)),
      for (var i = 1; i < owner.visible.length; i++) DataCell.empty,
      if (owner.table.canManage && owner.browser.onAddColumn != null)
        DataCell.empty,
    ],
  );

  void _clearSelection(PointerDownEvent _) {
    if (owner.draft.editing.value) {
      owner.draft.nextSelection.value = () => owner.draft.active.value = null;
    } else if (!owner.draft.draftOpen.value) {
      owner.draft.active.value = null;
    }
  }
}

class const _GridDataTable(final _Grid grid) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final line = BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
    );

    return DataTable(
      columns: grid._columns(),
      dataRowMaxHeight: .infinity,
      horizontalMargin: 0,
      columnSpacing: 0,
      rows: grid._rows(context),
      border: .new(bottom: line, horizontalInside: line, verticalInside: line),
    );
  }
}

class const _ResizableColumnHeading(
  final _Rows owner,
  final WorkspaceColumn column,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _ColumnHeading(
    column: column,
    width: owner.draft.columnWidths.value[column.id] ?? _defaultColumnWidth,
    onResize: _resize,
    onResizeEnd: () => _save(ref),
  );

  void _resize(double width) => owner.draft.columnWidths.value = {
    ...owner.draft.columnWidths.value,
    column.id: width,
  };

  void _save(WidgetRef ref) => unawaited(
    _saveColumnWidths(
      ref,
      owner.browser.workspaceId,
      owner.table.id,
      owner.draft.columnWidths.value,
    ),
  );
}

class const _ColumnHeading({
  required final WorkspaceColumn column,
  required final double width,
  required final ValueChanged<double> onResize,
  required final VoidCallback onResizeEnd,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey('workspace_column_heading_${column.id}'),
    width: width,
    child: Row(
      children: [
        Icon(
          WorkspaceColumnTypeLabel.iconFor(column.type),
          size: _columnIconSize,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(column.name, overflow: .ellipsis)),
        _ColumnResizeHandle(width, onResize, onResizeEnd),
      ],
    ),
  );
}

class const _ColumnResizeHandle(
  final double width,
  final ValueChanged<double> onResize,
  final VoidCallback onResizeEnd,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeLeftRight,
    child: GestureDetector(
      child: Icon(
        Icons.drag_indicator,
        size: _resizeIconSize,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      onHorizontalDragUpdate: _resize,
      onHorizontalDragEnd: (_) => onResizeEnd(),
      behavior: .opaque,
    ),
  );

  void _resize(DragUpdateDetails event) => onResize(
    (width + event.delta.dx).clamp(_minColumnWidth, _maxColumnWidth),
  );
}

class const _AddColumnMenu(final _Rows owner) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: owner.draft.draftOpen.value
        ? null
        : () => owner.browser.onAddColumn?.call(.text),
    tooltip: LocaleKeys.workspace_items_create_column.tr(),
    icon: const Icon(Icons.add),
  );
}

class const _AddEmptyRecord(final _Rows owner) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);

    return Row(
      children: [
        IconButton(
          onPressed: _addCallback(ref, action),
          tooltip: LocaleKeys.workspace_items_create_record.tr(),
          icon: const Icon(Icons.add),
        ),
        if (action.error case final error?) WorkspaceItemFailure(error: error),
      ],
    );
  }

  VoidCallback? _addCallback(WidgetRef ref, WorkspaceTableAction action) {
    if (action.pending || owner.draft.draftOpen.value) return null;

    return () => unawaited(action.run(() => _create(ref)));
  }

  Future<void> _create(WidgetRef ref) async {
    await createEmptyWorkspaceRecord(
      ref,
      workspaceId: owner.browser.workspaceId,
      table: owner.table,
    );
  }
}

class const _GridRecord(
  final _Rows owner,
  final WorkspaceRecord record,
  final ColorScheme colors,
) {
  bool get _selecting => owner.isSelecting();
  bool get _selected => owner.draft.selected.value.containsKey(record.id);
  bool get _canSelect => _selecting && owner.draft.canSelect(record);
  WidgetStateProperty<Color?>? get _hoverColor =>
      owner.draft.hovered.value == record.id
      ? WidgetStatePropertyAll(colors.onSurface.withValues(alpha: 0.08))
      : null;

  DataRow create() => DataRow(
    selected: _selected,
    onSelectChanged: _canSelect ? _changed : null,
    color: _hoverColor,
    cells: [
      for (final column in owner.visible) _cell(column),
      if (owner.table.canManage && owner.browser.onAddColumn != null)
        DataCell.empty,
    ],
  );

  void _changed(bool? checked) =>
      owner.draft.setSelected(record, checked: checked ?? false);
  DataCell _cell(WorkspaceColumn column) =>
      DataCell(_SpreadsheetCell(owner, record, column));
}

class const _SpreadsheetCell(
  final _Rows owner,
  final WorkspaceRecord record,
  final WorkspaceColumn column,
) extends HookConsumerWidget {
  bool get _canEdit =>
      owner.table.canEditRecords &&
      !record.restrictedReferenceColumns.contains(column.id);
  bool get _selected =>
      owner.draft.active.value == (record: record.id, column: column.id);
  bool get _editing => _selected && owner.draft.editing.value;
  bool get _guide {
    final active = owner.draft.active.value;

    return active != null &&
        (active.record == record.id || active.column == column.id);
  }

  bool get _showRecordAction =>
      column.id == owner.table.labelColumnId &&
      (owner.draft.hovered.value == record.id ||
          owner.draft.selected.value.containsKey(record.id) ||
          _selected);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);
    final colors = Theme.of(context).colorScheme;
    final link = useMemoized(LayerLink.new);
    final focus = useFocusNode();
    useEffect(() => _registerFocus(focus), [focus]);

    return MouseRegion(
      onEnter: _hover,
      onExit: _leave,
      child: Focus(
        child: Listener(
          onPointerDown: (event) {
            owner.draft.cellPointer.value = event.pointer;
            _select(context, focus);
          },
          child: GestureDetector(
            child: CompositedTransformTarget(
              link: link,
              child: Container(
                key: ValueKey('workspace_cell_${record.id}_${column.id}'),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color(colors),
                  border: _border(colors),
                ),
                width:
                    owner.draft.columnWidths.value[column.id] ??
                    _defaultColumnWidth,
                height: _cellHeight,
                child: DefaultTextStyle.merge(
                  style: .new(
                    color: _editing
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                  child: _cellContent(action, ref, link),
                ),
              ),
            ),
            onDoubleTap: _canEdit && column.type != .checkbox ? _edit : null,
            onLongPress: owner.table.canEditRecords && column.type != .checkbox
                ? _selectRow
                : null,
            behavior: .opaque,
          ),
        ),
        focusNode: focus,
        onFocusChange: _focusChanged,
        onKeyEvent: _key,
      ),
    );
  }

  VoidCallback _registerFocus(FocusNode focus) {
    final key = _focusKey(record.id, column.id);
    final nodes = owner.draft.focusNodes.value;
    nodes[key] = focus;

    return () {
      if (identical(nodes[key], focus)) {
        final _ = nodes.remove(key);
      }
    };
  }

  void _hover(PointerEnterEvent _) => owner.draft.hovered.value = record.id;
  void _focusChanged(bool hasFocus) {
    if (hasFocus || !_selected) return;
    if (owner.draft.editing.value) {
      owner.draft.nextSelection.value ??= () => owner.draft.active.value = null;
    } else if (!owner.draft.draftOpen.value) {
      owner.draft.active.value = null;
    }
  }

  void _leave(PointerExitEvent _) {
    if (owner.draft.hovered.value == record.id) {
      owner.draft.hovered.value = null;
    }
  }

  Color? _color(ColorScheme colors) {
    if (_editing) return colors.primaryContainer;
    if (_selected) return colors.primary.withValues(alpha: 0.12);
    if (_guide) return colors.surfaceContainerHighest;

    return null;
  }

  Border? _border(ColorScheme colors) {
    if (!_selected) return null;

    return Border.all(color: colors.primary, width: _editing ? 3 : 1);
  }

  void _selectRow() {
    if (owner.draft.draftOpen.value) return;
    owner.draft.toggle(record);
  }

  Widget _cellContent(
    WorkspaceTableAction action,
    WidgetRef ref,
    LayerLink link,
  ) {
    if (column.type == .checkbox) return _CheckboxCell(this, action, ref);
    if (column.type == .url) return _UrlCell(this, showMenu: _selected);
    if (_editing) return _SpreadsheetEditor(this, action, ref, link);

    return _CellContent(this);
  }

  void _select(BuildContext context, FocusNode focus) {
    if (owner.draft.editing.value) {
      if (_selected) return;
      owner.draft.nextSelection.value = () {
        if (!context.mounted) return;
        _focus(focus);
      };

      return;
    }
    if (owner.isSelecting()) {
      _selectRow();

      return;
    }
    _focus(focus);
  }

  void _focus(FocusNode focus) {
    owner.draft.active.value = (record: record.id, column: column.id);
    focus.requestFocus();
  }

  void _edit() {
    if (owner.draft.editing.value) return;
    owner.draft.active.value = (record: record.id, column: column.id);
    owner.draft.values.value = {...record.values};
    owner.draft.editing.value = true;
    owner.draft.draftOpen.value = true;
  }

  KeyEventResult _key(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _editing) {
      _cancel();

      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        _canEdit) {
      _edit();

      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        !_editing &&
        _isGridNavigationKey(event.logicalKey)) {
      final rows = owner.records;
      final columns = owner.visible;
      final rowIndex = rows.indexWhere((row) => row.id == record.id);
      final columnIndex = columns.indexWhere((item) => item.id == column.id);
      var nextRow = rowIndex;
      var nextColumnIndex = columnIndex;
      switch (event.logicalKey) {
        case .arrowLeft:
          nextColumnIndex--;
        case .arrowRight:
          nextColumnIndex++;
        case .arrowUp:
          nextRow--;
        case .arrowDown:
          nextRow++;
        case .tab:
          if (HardwareKeyboard.instance.isShiftPressed) {
            if (nextColumnIndex == 0) {
              nextRow--;
              nextColumnIndex = columns.length - 1;
            } else {
              nextColumnIndex--;
            }
          } else if (nextColumnIndex == columns.length - 1) {
            nextRow++;
            nextColumnIndex = 0;
          } else {
            nextColumnIndex++;
          }
      }
      if (nextRow >= 0 &&
          nextRow < rows.length &&
          nextColumnIndex >= 0 &&
          nextColumnIndex < columns.length) {
        final nextRecord = rows[nextRow];
        final nextColumn = columns[nextColumnIndex];
        owner.draft.active.value = (
          record: nextRecord.id,
          column: nextColumn.id,
        );
        owner.draft.focusNodes.value[_focusKey(nextRecord.id, nextColumn.id)]
            ?.requestFocus();

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _cancel() {
    owner.draft.nextSelection.value = null;
    owner.draft.editing.value = false;
    owner.draft.draftOpen.value = false;
  }

  void _submit(WidgetRef ref, WorkspaceTableAction action) =>
      unawaited(action.run(() => _save(ref)));
  Future<void> _save(WidgetRef ref) async {
    final usecase = await ref.read(
      workspaceTableUsecaseProvider(owner.browser.workspaceId).future,
    );
    final _ = await usecase.updateRecord(
      table: owner.table,
      record: record,
      values: owner.draft.values.value,
    );
    if (!ref.context.mounted) return;
    _finishSave(ref);
  }

  void _finishSave(WidgetRef ref) {
    final draft = owner.draft;
    draft.editing.value = false;
    draft.draftOpen.value = false;
    final next = draft.nextSelection.value;
    draft.nextSelection.value = null;
    next?.call();
    _refreshReferences(ref);
  }

  void _refreshReferences(WidgetRef ref) {
    final workspaceId = owner.browser.workspaceId;
    ref
      ..invalidate(workspaceRecordQueryUsecaseProvider(workspaceId))
      ..invalidate(workspaceReferencedRecordProvider)
      ..invalidate(workspaceReferencesUsecaseProvider(workspaceId));
  }
}

String _focusKey(String recordId, String columnId) => '$recordId:$columnId';

bool _isGridNavigationKey(LogicalKeyboardKey key) =>
    key == LogicalKeyboardKey.arrowLeft ||
    key == LogicalKeyboardKey.arrowRight ||
    key == LogicalKeyboardKey.arrowUp ||
    key == LogicalKeyboardKey.arrowDown ||
    key == LogicalKeyboardKey.tab;

class const _CheckboxCell(
  final _SpreadsheetCell cell,
  final WorkspaceTableAction action,
  final WidgetRef ref,
) extends StatelessWidget {
  bool get _checked => cell.record.values[cell.column.id] == true;
  bool get _enabled => cell._canEdit && !action.pending;

  @override
  Widget build(BuildContext context) {
    final checked = _checked;
    final enabled = _enabled;
    final toggle = enabled ? () => _change(!checked) : null;

    return _CheckboxSemantics(
      checked: checked,
      enabled: enabled,
      onTap: toggle,
      error: action.error,
    );
  }

  void _change(bool value) {
    cell.owner.draft.active.value = (
      record: cell.record.id,
      column: cell.column.id,
    );
    unawaited(action.run(() => _persist(value)));
  }

  Future<void> _persist(bool value) async {
    final workspaceId = cell.owner.browser.workspaceId;
    final usecase = await ref.read(
      workspaceTableUsecaseProvider(workspaceId).future,
    );
    await _update(usecase, value);
    if (!ref.context.mounted) return;
    ref.invalidate(workspaceRecordQueryUsecaseProvider(workspaceId));
  }

  Future<void> _update(
    OrganizeWorkspaceTablesUsecase usecase,
    bool value,
  ) async {
    final record = cell.record;
    final _ = await usecase.updateRecord(
      table: cell.owner.table,
      record: record,
      values: {...record.values, cell.column.id: value},
    );
  }
}

class const _CheckboxSemantics({
  required final bool checked,
  required final bool enabled,
  required final VoidCallback? onTap,
  required final Object? error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      child: _CheckboxHitTarget(checked: checked, onTap: onTap, error: error),
      enabled: enabled,
      checked: checked,
      onTap: onTap,
    ),
  );
}

class const _CheckboxHitTarget({
  required final bool checked,
  required final VoidCallback? onTap,
  required final Object? error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => InkWell(
    child: Row(
      mainAxisSize: .min,
      children: [
        _CheckboxIndicator(checked: checked),
        if (error case final failure?) _CellErrorIndicator(failure),
      ],
    ),
    onTap: onTap,
  );
}

class const _CheckboxIndicator({required final bool checked})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Checkbox(
        value: checked,
        onChanged: null,
        fillColor: WidgetStatePropertyAll(colors.primary),
        checkColor: colors.onPrimary,
      ),
    );
  }
}

class const _CellErrorIndicator(final Object error) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message: _workspaceErrorText(error),
    child: Icon(
      Icons.error_outline,
      size: _columnIconSize,
      color: Theme.of(context).colorScheme.error,
    ),
  );
}

String _workspaceErrorText(Object error) => switch (error) {
  final WorkspaceTableException failure => failure.localizationKey.tr(),
  _ => CloudAppErrors.localizationKey(error).tr(),
};

enum _UrlAction { edit, copy, open }

class const _UrlCell(
  final _SpreadsheetCell cell, {
  required final bool showMenu,
}) extends StatelessWidget {
  String get _value => cell.record.values[cell.column.id]?.toString() ?? '';

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(_value, overflow: .ellipsis)),
      if (showMenu) _UrlMenu(this),
    ],
  );

  List<PopupMenuEntry<_UrlAction>> _menuItems(BuildContext _) => [
    if (cell._canEdit)
      PopupMenuItem(value: .edit, child: Text(LocaleKeys.common_edit.tr())),
    PopupMenuItem(
      value: .copy,
      child: Text(
        LocaleKeys.models_screens_add_provider_device_code_copy_link.tr(),
      ),
    ),
    PopupMenuItem(
      value: .open,
      child: Text(LocaleKeys.markdown_editor_external_link_open.tr()),
    ),
  ];

  void _select(BuildContext context, _UrlAction action, String value) {
    switch (action) {
      case .edit:
        cell._edit();
      case .copy:
        unawaited(Clipboard.setData(.new(text: value)));
      case .open:
        unawaited(
          ConfirmedExternalLink.open(
            context: context,
            url: value,
            confirm: (uri) => _confirm(context, uri),
            onLaunchFailure: () => _showFailure(context),
          ),
        );
    }
  }

  Future<bool?> _confirm(BuildContext context, Uri uri) => AuraDialogs.confirm(
    context: context,
    title: Text(LocaleKeys.markdown_editor_external_link_title.tr()),
    message: AuraSelectableText(
      LocaleKeys.markdown_editor_external_link_message.tr(
        namedArgs: {'host': uri.host, 'url': uri.toString()},
      ),
    ),
    actions: .new(
      confirmLabel: Text(LocaleKeys.markdown_editor_external_link_open.tr()),
      cancelLabel: Text(LocaleKeys.common_cancel.tr()),
    ),
  );

  void _showFailure(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(
        .new(
          content: Text(LocaleKeys.markdown_editor_external_link_error.tr()),
        ),
      );
}

class const _UrlMenu(final _UrlCell owner) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _UrlPopup(
    owner,
    Theme.of(context).colorScheme.surface,
    (action) => owner._select(context, action, owner._value),
  );
}

class const _UrlPopup(
  final _UrlCell owner,
  final Color color,
  final ValueChanged<_UrlAction> onSelected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PopupMenuButton<_UrlAction>(
    itemBuilder: owner._menuItems,
    onSelected: onSelected,
    tooltip: LocaleKeys.workspace_items_type_url.tr(),
    icon: const Icon(Icons.arrow_drop_down),
    color: color,
  );
}

class const _SpreadsheetEditor(
  final _SpreadsheetCell cell,
  final WorkspaceTableAction action,
  final WidgetRef ref,
  final LayerLink link,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (switch (cell.column.type) {
      .text || .number || .url || .email || .phone => true,
      _ => false,
    }) {
      return _InlineScalarEditor(cell, action, ref);
    }

    return _ComplexCellOverlay(cell, action, ref, link);
  }
}

class const _ComplexCellOverlay(
  final _SpreadsheetCell cell,
  final WorkspaceTableAction action,
  final WidgetRef ref,
  final LayerLink link,
) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final portal = _useOverlayPortal(context);

    return OverlayPortal(
      controller: portal,
      overlayChildBuilder: (overlayContext) =>
          _ComplexOverlayLayout(anchorContext: context, editor: this),
      child: ClipRect(child: _Cell(cell.owner, cell.record, cell.column)),
    );
  }
}

OverlayPortalController _useOverlayPortal(BuildContext context) {
  final portal = useMemoized(OverlayPortalController.new);
  VoidCallback? show() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) portal.show();
    });

    return null;
  }

  useEffect(show, const []);

  return portal;
}

class const _ComplexOverlayLayout({
  required final BuildContext anchorContext,
  required final _ComplexCellOverlay editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bounds = _overlayBounds(context, anchorContext);
    final position = _overlayPosition(
      bounds,
      MediaQuery.viewInsetsOf(context).bottom,
    );

    return _OverlayFollower(editor, position);
  }
}

typedef _OverlayPosition = ({
  double width,
  double height,
  bool flipHorizontal,
  bool flipVertical,
});
typedef _OverlayBounds = ({double right, double top, double bottom, Size size});

_OverlayPosition _overlayPosition(_OverlayBounds bounds, double keyboard) {
  final horizontal = _horizontalPlacement(bounds.right, bounds.size.width);
  final vertical = _verticalPlacement(
    bounds.top,
    bounds.bottom,
    bounds.size.height,
    keyboard,
  );

  return (
    width: horizontal.size,
    height: vertical.size,
    flipHorizontal: horizontal.flip,
    flipVertical: vertical.flip,
  );
}

_OverlayBounds _overlayBounds(
  BuildContext context,
  BuildContext anchorContext,
) {
  final box = anchorContext.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final topLeft = _overlayOffset(box, overlay);

  return _boundsFromBox(
    topLeft,
    box?.size,
    overlay?.size ?? MediaQuery.sizeOf(context),
  );
}

Offset _overlayOffset(RenderBox? box, RenderBox? overlay) =>
    (box?.localToGlobal(.zero) ?? .zero) -
    (overlay?.localToGlobal(.zero) ?? .zero);

_OverlayBounds _boundsFromBox(Offset offset, Size? anchorSize, Size size) {
  const fallback = Size(32, 32);
  final anchor = anchorSize ?? fallback;

  return (
    right: offset.dx + anchor.width,
    top: offset.dy,
    bottom: offset.dy + anchor.height,
    size: size,
  );
}

({double size, bool flip}) _horizontalPlacement(double right, double width) {
  const maximumWidth = 280.0;
  final after = (width - right - 8).clamp(0.0, maximumWidth);
  final before = (right - 8).clamp(0.0, maximumWidth);
  final flip = after < maximumWidth && before > after;

  return (size: (flip ? before : after).clamp(0.0, maximumWidth), flip: flip);
}

({double size, bool flip}) _verticalPlacement(
  double top,
  double bottom,
  double height,
  double keyboard,
) {
  final availableBottom = (height - keyboard).clamp(0.0, height);
  final after = (availableBottom - bottom - 8).clamp(0.0, 240.0);
  final before = (top - 8).clamp(0.0, 240.0);
  final flip = after < 240 && before > after;

  return (size: flip ? before : after, flip: flip);
}

class const _OverlayFollower(
  final _ComplexCellOverlay editor,
  final _OverlayPosition position,
) extends StatelessWidget {
  Alignment get _target => Alignment(
    position.flipHorizontal ? 1 : -1,
    position.flipVertical ? -1 : 1,
  );
  Alignment get _follower => Alignment(
    position.flipHorizontal ? 1 : -1,
    position.flipVertical ? 1 : -1,
  );

  @override
  Widget build(BuildContext context) => TapRegion(
    child: Align(
      alignment: .topLeft,
      child: CompositedTransformFollower(
        link: editor.link,
        showWhenUnlinked: false,
        targetAnchor: _target,
        followerAnchor: _follower,
        child: _OverlayContent(editor, position),
      ),
    ),
    onTapOutside: _dismiss,
  );

  void _dismiss(PointerDownEvent _) {
    if (!editor.action.pending && editor.cell._editing) {
      editor.cell._submit(editor.ref, editor.action);
    }
  }
}

class const _OverlayContent(
  final _ComplexCellOverlay editor,
  final _OverlayPosition position,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    elevation: 6,
    child: SizedBox(
      key: const ValueKey('workspace_cell_type_popup'),
      width: position.width,
      child: ConstrainedBox(
        constraints: .new(maxHeight: position.height),
        child: SingleChildScrollView(child: _OverlayForm(editor)),
      ),
    ),
  );
}

class const _OverlayForm(final _ComplexCellOverlay editor)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cell = editor.cell;
    final action = editor.action;

    return Column(
      mainAxisSize: .min,
      children: [
        _OverlayFields(editor),
        if (cell.column.type == .reference) const _OverlayReferenceHint(),
        if (action.error case final error?) WorkspaceItemFailure(error: error),
        _OverlayActions(editor),
      ],
    );
  }
}

class const _OverlayReferenceHint() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: TextLocale(LocaleKeys.workspace_items_reference_apply_row_hint),
  );
}

class const _OverlayFields(final _ComplexCellOverlay editor)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cell = editor.cell;
    final owner = cell.owner;

    return WorkspaceRecordFields(
      table: owner.table,
      workspaceId: owner.browser.workspaceId,
      restricted: cell.record.restrictedReferenceColumns,
      draft: owner.draft.values,
      disabled: editor.action.pending,
      columnId: cell.column.id,
    );
  }
}

class const _OverlayActions(final _ComplexCellOverlay editor)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: editor.action.pending ? null : _submit,
        tooltip: LocaleKeys.workspace_items_save_record.tr(),
        icon: const Icon(Icons.check),
      ),
      IconButton(
        onPressed: editor.action.pending ? null : editor.cell._cancel,
        tooltip: LocaleKeys.common_cancel.tr(),
        icon: const Icon(Icons.close),
      ),
    ],
  );
  void _submit() => editor.cell._submit(editor.ref, editor.action);
}

class const _InlineScalarEditor(
  final _SpreadsheetCell cell,
  final WorkspaceTableAction action,
  final WidgetRef ref,
) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final focus = useFocusNode();
    final controller = useTextEditingController(
      text: cell.owner.draft.values.value[cell.column.id]?.toString() ?? '',
    );
    useEffect(
      () => _InlineEditorFocus(this, context, focus, controller).attach(),
      [focus],
    );

    return _InlineEditorForm(this, focus, controller);
  }

  String _errorText(Object error) => switch (error) {
    final WorkspaceTableException failure => failure.localizationKey.tr(),
    _ => CloudAppErrors.localizationKey(error).tr(),
  };

  void _change(String text) {
    final values = cell.owner.draft.values;
    values.value = {
      ...values.value,
      cell.column.id: _parseInlineValue(text, cell.column.type),
    };
  }
}

class _InlineEditorFocus(
  final _InlineScalarEditor owner,
  final BuildContext context,
  final FocusNode focus,
  final TextEditingController controller,
) {
  bool _hadFocus = false;

  VoidCallback attach() {
    focus
      ..addListener(_onFocus)
      ..requestFocus();

    return () => focus.removeListener(_onFocus);
  }

  void _onFocus() {
    if (focus.hasFocus) {
      if (_hadFocus) return;
      _hadFocus = true;
      WidgetsBinding.instance.addPostFrameCallback(_selectText);

      return;
    }
    if (_hadFocus && context.mounted && owner.cell._editing) {
      _hadFocus = false;
      owner.cell._submit(owner.ref, owner.action);
    }
  }

  void _selectText(Duration _) {
    if (!context.mounted || !focus.hasFocus || !owner.cell._editing) return;
    controller.selection = .new(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }
}

class const _InlineEditorForm(
  final _InlineScalarEditor owner,
  final FocusNode focus,
  final TextEditingController controller,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: _inlineEditorHeight,
    child: Row(
      children: [
        Expanded(child: _InlineEditorInput(owner, focus, controller)),
        if (owner.action.error case final error?)
          _InlineEditorError(owner, error),
      ],
    ),
  );
}

class const _InlineEditorInput(
  final _InlineScalarEditor owner,
  final FocusNode focus,
  final TextEditingController controller,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _InlineTextField(
      this,
      Theme.of(context).colorScheme.onPrimaryContainer,
    ),
    label: owner.cell.column.name,
  );
}

class const _InlineTextField(final _InlineEditorInput editor, final Color color)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('workspace_inline_record_value'),
      controller: editor.controller,
      focusNode: editor.focus,
      decoration: const .collapsed(hintText: ''),
      style: .new(color: color),
      onChanged: editor.owner._change,
      onSubmitted: _submit,
      enabled: !editor.owner.action.pending,
      cursorColor: color,
      onTapOutside: _unfocus,
    );
  }

  void _submit(String _) =>
      editor.owner.cell._submit(editor.owner.ref, editor.owner.action);
  void _unfocus(PointerDownEvent _) => editor.focus.unfocus();
}

class const _InlineEditorError(
  final _InlineScalarEditor owner,
  final Object error,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message: owner._errorText(error),
    child: Icon(
      Icons.error_outline,
      size: _columnIconSize,
      color: Theme.of(context).colorScheme.error,
    ),
  );
}

Object? _parseInlineValue(String text, WorkspaceColumnType type) {
  if (text.isEmpty) return null;
  if (type == .number) return num.tryParse(text) ?? text;

  return text;
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
    if (record.values[column.id] == null) return const SizedBox.shrink();
    if (column.type == WorkspaceColumnType.reference) {
      return _ReferenceCell(owner, record.values[column.id], column);
    }

    return Text(_value(record, column.id, column));
  }
}

class const _CellContent(final _SpreadsheetCell cell) extends StatelessWidget {
  bool get _canShowEdit =>
      cell._selected && cell._canEdit && cell.column.type != .url;

  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      ClipRect(child: _Cell(cell.owner, cell.record, cell.column)),
      if (_canShowEdit || cell._showRecordAction)
        _CellActionOverlay(cell, showEdit: _canShowEdit),
    ],
  );
}

class const _CellActionOverlay(
  final _SpreadsheetCell cell, {
  required final bool showEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: .centerRight,
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: _CellActions(cell, showEdit: showEdit),
    ),
  );
}

class const _CellActions(
  final _SpreadsheetCell cell, {
  required final bool showEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      if (showEdit) _EditCellButton(cell),
      if (cell._showRecordAction) _OpenRecordButton(cell),
    ],
  );
}

class const _EditCellButton(final _SpreadsheetCell cell)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    visualDensity: .compact,
    onPressed: cell._edit,
    tooltip: LocaleKeys.common_edit.tr(),
    icon: const Icon(Icons.edit_outlined),
  );
}

class const _OpenRecordButton(final _SpreadsheetCell cell)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    visualDensity: .compact,
    onPressed: cell.owner.draft.draftOpen.value ? null : _open,
    tooltip: LocaleKeys.common_show_more.tr(),
    icon: const Icon(Icons.more_horiz),
  );
  void _open() => cell.owner.onRecord(cell.record);
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

String _value(WorkspaceRecord record, String columnId, WorkspaceColumn column) {
  final value = record.values[columnId];
  if (value == null) return LocaleKeys.workspace_items_missing_value.tr();
  if (column.type == WorkspaceColumnType.timestamp && value is String) {
    return WorkspaceTimeZones.display(value, column.timeZone);
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
      : const SizedBox.shrink();
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

class const _SelectedRecordsToolbar(final _BulkToolbar owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _selectionToolbarSpacing,
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
