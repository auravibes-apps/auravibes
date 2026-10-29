import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewSummary({
  required final WorkspaceViewData data,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => data.needsRepair
      ? const SizedBox.shrink()
      : ExpansionTile(
          title: const TextLocale(LocaleKeys.workspace_relational_summary),
          children: [_Count(data), _Columns(data)],
          expandedCrossAxisAlignment: .start,
          expandedAlignment: .centerLeft,
        );
}

class const _Count(final WorkspaceViewData data) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    LocaleKeys.workspace_relational_count,
    args: ['${data.summary['count'] ?? 0}'],
  );
}

class const _Columns(final WorkspaceViewData data) extends StatelessWidget {
  Map<Object?, Object?> get _columns =>
      data.summary['columns'] as Map<Object?, Object?>? ?? const {};
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      for (final column in data.table.columns)
        if (_columns.containsKey(column.id))
          _ColumnSummary(
            column.name,
            _columns[column.id] as Map<Object?, Object?>? ?? const {},
          ),
    ],
  );
}

class const _ColumnSummary(
  final String name,
  final Map<Object?, Object?> values,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      Text(name),
      TextLocale(
        LocaleKeys.workspace_relational_present,
        args: ['${values['present']}'],
      ),
      _Range(values),
      _Currencies(values),
    ],
  );
}

class const _Currencies(final Map<Object?, Object?> values)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currencies =
        values['currencies'] as Map<Object?, Object?>? ?? const {};

    return Column(
      crossAxisAlignment: .start,
      children: [
        for (final entry in currencies.entries)
          _Currency(entry.key.toString(), _summaryValues(entry.value)),
      ],
    );
  }
}

class const _Currency(final String code, final Map<Object?, Object?> values)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [Text(code), _Range(values)],
  );
}

class const _Range(final Map<Object?, Object?> values) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (values['sum'] case final Object sum)
        TextLocale(LocaleKeys.workspace_relational_sum, args: ['$sum']),
      if (values['minimum'] case final Object minimum)
        TextLocale(LocaleKeys.workspace_relational_minimum, args: ['$minimum']),
      if (values['maximum'] case final Object maximum)
        TextLocale(LocaleKeys.workspace_relational_maximum, args: ['$maximum']),
    ],
  );
}

Map<Object?, Object?> _summaryValues(Object? value) =>
    value as Map<Object?, Object?>? ?? const {};
