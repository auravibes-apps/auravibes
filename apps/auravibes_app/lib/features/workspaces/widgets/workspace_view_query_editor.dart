import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_query_filter_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_query_filter.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewQueryEditor({
  required final String workspaceId,
  required final WorkspaceViewData data,
  required final ValueNotifier<WorkspaceRecordQuery> query,
  required final TextEditingController layout,
  required final ValueNotifier<Set<String>> summary,
  required final Map<String, String> bindings,
  final ValueNotifier<A2uiSavedAction?>? action,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const TextLocale(LocaleKeys.workspace_relational_query),
    children: [
      _Search(query),
      WorkspaceQueryFilter(
        table: data.table,
        workspaceId: workspaceId,
        query: query,
      ),
      _Sort(data, query),
      _Descending(query),
      _PageSize(query),
      _SummarySelection(data.table, summary),
      _Presentation(data.table, bindings, layout, action),
    ],
  );
}

class const _Search(final ValueNotifier<WorkspaceRecordQuery> query)
    extends HookWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: useTextEditingController(text: query.value.search),
    label: const TextLocale(LocaleKeys.workspace_items_search),
    onChanged: (value) => query.value = query.value.change(search: value),
    identifier: 'workspace_view_search',
  );
}

class _Sort extends AuraDropdownSelector<String> {
  new(WorkspaceViewData data, ValueNotifier<WorkspaceRecordQuery> query)
    : super(
        options: _sortColumns(data.table)
            .map<AuraDropdownOption<String>>(_SortOption.new)
            .toList(),
        value: query.value.sortColumnId ?? data.table.labelColumnId,
        onChanged: (id) => query.value = query.value.change(sort: id),
        label: const TextLocale(LocaleKeys.workspace_relational_sort),
      );
}

Iterable<WorkspaceColumn> _sortColumns(WorkspaceTable table) =>
    table.columns.where(WorkspaceQueryFilterValidation.supports);

class const _Descending(final ValueNotifier<WorkspaceRecordQuery> query)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: query.value.descending,
    onChanged: (value) =>
        query.value = query.value.change(descending: value == true),
    title: const TextLocale(LocaleKeys.workspace_relational_descending),
  );
}

class const _PageSize(final ValueNotifier<WorkspaceRecordQuery> query)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<int>(
    options: [
      for (final size in {1, 10, 25, 50, 100, query.value.limit})
        AuraDropdownOption(value: size, child: Text('$size')),
    ],
    value: query.value.limit,
    onChanged: _change,
    label: const TextLocale(LocaleKeys.workspace_relational_page_size),
  );
  void _change(int? size) {
    if (size == null) return;
    query.value = WorkspaceRecordQuery.fromJson({
      ...query.value.toJson(),
      'limit': size,
    });
  }
}

class const _SummarySelection(
  final WorkspaceTable table,
  final ValueNotifier<Set<String>> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const TextLocale(LocaleKeys.workspace_relational_summary),
    children: [
      for (final column in table.columns.where(_summarySelectable))
        _SummaryField(column, selected),
    ],
  );
}

class const _SummaryField(
  final WorkspaceColumn column,
  final ValueNotifier<Set<String>> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: selected.value.contains(column.id),
    onChanged: _change,
    title: Text(column.name),
  );
  void _change(bool? value) {
    final next = {...selected.value};
    if (value == true) {
      final _ = next.add(column.id);
    } else {
      final _ = next.remove(column.id);
    }
    selected.value = next;
  }
}

class const _Presentation(
  final WorkspaceTable table,
  final Map<String, String> bindings,
  final TextEditingController layout,
  final ValueNotifier<A2uiSavedAction?>? action,
) extends StatelessWidget {
  bool get _hasNumbers => table.columns.any(
    (column) => column.type == .number && bindings.containsValue(column.id),
  );
  bool get _hasFormFields => bindings.isNotEmpty;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (final mode in ['list', 'detail', 'chart', 'form'])
        AuraButton(
          onPressed: () => _preset(mode),
          child: TextLocale(_modeKey(mode)),
          disabled:
              (mode == 'chart' && !_hasNumbers) ||
              (mode == 'form' && !_hasFormFields),
          identifier: 'workspace_view_layout_$mode',
        ),
    ],
  );
  void _preset(String mode) {
    if (mode == 'form') {
      action?.value = A2uiSavedAction(
        type: .updateSelectedRecord,
        inputs: {
          for (final entry in bindings.entries) entry.value: '/${entry.key}',
        },
      );
    } else if (action?.value?.type ==
        A2uiSavedActionType.updateSelectedRecord) {
      action?.value = null;
    }
    layout.text = const JsonEncoder.withIndent(
      '  ',
    ).convert({'version': 1, 'components': _components(mode, table, bindings)});
  }
}

List<Map<String, Object?>> _components(
  String mode,
  WorkspaceTable table,
  Map<String, String> bindings,
) {
  final fields = bindings.keys;
  if (mode == 'detail') {
    return [
      {
        'id': 'root',
        'component': 'Column',
        'children': [
          for (final field in fields) ...['label_$field', 'detail_$field'],
        ],
      },
      for (final field in fields) ...[
        {
          'id': 'label_$field',
          'component': 'Text',
          'text': {'path': '/fieldLabels/$field'},
        },
        {
          'id': 'detail_$field',
          'component': 'Text',
          'text': {'path': '/$field'},
        },
      ],
    ];
  }
  if (mode == 'form') {
    return [
      {
        'id': 'root',
        'component': 'Column',
        'children': [for (final field in fields) 'input_$field'],
      },
      for (final entry in bindings.entries)
        _formComponent(entry.key, entry.value, table),
    ];
  }

  return [
    switch (mode) {
      'chart' => {
        'id': 'root',
        'component': 'Chart',
        'variant': 'bar',
        'labels': {'path': '/chartLabels'},
        'series': {'path': '/chartSeries'},
      },
      _ => {
        'id': 'root',
        'component': 'Table',
        'columns': {'path': '/columns'},
        'rows': {'path': '/rows'},
      },
    },
  ];
}

Map<String, Object?> _formComponent(
  String field,
  String columnId,
  WorkspaceTable table,
) {
  final column = table.columns.where((item) => item.id == columnId).firstOrNull;
  if (column?.type == .checkbox) {
    return {
      'id': 'input_$field',
      'component': 'CheckBox',
      'label': {'path': '/fieldLabels/$field'},
      'value': {'path': '/$field'},
    };
  }

  return {
    'id': 'input_$field',
    'component': 'TextField',
    'label': {'path': '/fieldLabels/$field'},
    'value': {'path': '/$field'},
  };
}

String _modeKey(String mode) => switch (mode) {
  'chart' => LocaleKeys.workspace_relational_chart,
  'detail' => LocaleKeys.workspace_relational_detail,
  'form' => LocaleKeys.workspace_items_save_record,
  _ => LocaleKeys.workspace_relational_list,
};

class _SortOption extends AuraDropdownOption<String> {
  new(WorkspaceColumn column)
    : super(value: column.id, child: Text(column.name));
}

bool _summarySelectable(WorkspaceColumn column) =>
    column.type != .reference && column.type.name != 'attachment';
