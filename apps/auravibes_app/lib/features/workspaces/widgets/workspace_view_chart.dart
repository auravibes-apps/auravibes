import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewChart({
  required final WorkspaceViewData data,
  final String? workspaceId,
  super.key,
}) extends StatelessWidget {
  List<WorkspaceColumn> get _columns => data.table.columns
      .where(
        (column) =>
            column.type == .number &&
            data.view.bindings.containsValue(column.id),
      )
      .toList();
  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    if (columns.isEmpty ||
        columns.every((column) => _samples(data, column).isEmpty)) {
      return const TextLocale(LocaleKeys.workspace_relational_no_numbers);
    }

    return _ChartContent(data, columns, workspaceId);
  }
}

class const _ChartContent(
  final WorkspaceViewData data,
  final List<WorkspaceColumn> columns,
  final String? workspaceId,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.workspace_relational_chart_scope),
      WorkspaceViewSurface(data: data, workspaceId: workspaceId),
      for (final column in columns) _ChartValues(data, column),
    ],
  );
}

class const _ChartValues(
  final WorkspaceViewData data,
  final WorkspaceColumn column,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(column.name),
    children: [
      for (final row in _samples(data, column)) _ChartValue(data, column, row),
    ],
  );
}

class const _ChartValue(
  final WorkspaceViewData data,
  final WorkspaceColumn column,
  final WorkspaceRecord record,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(record.values[data.table.labelColumnId]?.toString() ?? '-'),
    subtitle: Text('${record.values[column.id]}'),
  );
}

Iterable<WorkspaceRecord> _samples(
  WorkspaceViewData data,
  WorkspaceColumn column,
) => data.records.where((record) => record.values[column.id] is num);
