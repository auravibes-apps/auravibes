import 'dart:convert';

import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_app/features/chats/widgets/chat_catalog_avatar.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

const _percentageScale = 100.0;

typedef _DashboardTableContent = ({
  List<String> columns,
  List<List<Object?>> rows,
});

typedef _DashboardTableOptions = ({
  Widget? caption,
  List<AuraTableAlignment> columnAlignments,
  List<AuraTableValueFormat> columnFormats,
  List<bool> sortableColumns,
  List<AuraTint?> rowTints,
  String? emptyText,
  String noValueLabel,
});

typedef _DashboardTableData = ({
  _DashboardTableContent content,
  _DashboardTableOptions options,
});

typedef _DashboardChartContent = ({
  List<String> labels,
  List<AuraChartSeries> series,
  String semanticLabel,
});

typedef _DashboardChartAxes = ({String? x, String? y, String? unit});

typedef _DashboardChartOptions = ({
  AuraChartType type,
  bool stacked,
  double? minY,
  double? maxY,
  _DashboardChartAxes axes,
  List<AuraTint> palette,
});

typedef _DashboardChartData = ({
  _DashboardChartContent content,
  _DashboardChartOptions options,
});

typedef _DashboardBuilder = Widget Function(
  CatalogItemContext context,
  Map<String, Object?> data,
);

abstract final class AuraDashboardCatalogAdapter {
  /// Adds app-rendered dashboard items to either chat catalog.
  static List<CatalogItem> items({
    required IconData Function(String?) resolveIcon,
  }) => _DashboardCatalog.items(resolveIcon);
}

abstract final class _DashboardCatalog {
  static List<CatalogItem> items(IconData Function(String?) resolveIcon) {
    final builders = <String, _DashboardBuilder>{
      ..._dashboardBuilders,
      'EmptyState': (context, data) =>
          _DashboardPrimitiveBuilders.emptyState(context, data, resolveIcon),
    };

    return [for (final entry in builders.entries) _catalogItem(entry)];
  }

  static CatalogItem _catalogItem(MapEntry<String, _DashboardBuilder> entry) {
    return CatalogItem(
      name: entry.key,
      dataSchema: _dataSchema(entry.key),
      widgetBuilder: (context) => _boundData(context, entry.value),
      exampleData: [
        () => jsonEncode([a2uiChatComponentExamples[entry.key]]),
      ],
    );
  }

  static Schema _dataSchema(String name) {
    final schema = a2uiChatComponentSchemas[name]!;

    return .fromMap({
      ...schema,
      'required': [
        for (final property in schema['required']! as List)
          if (property != 'id') property,
      ],
    });
  }

  static Widget _boundData(
    CatalogItemContext context,
    _DashboardBuilder builder,
  ) {
    final data = Map<String, Object?>.from(context.data as Map);
    final boundKeys = _boundKeys(data);

    return _BoundDashboardData(
      context: context,
      data: data,
      boundKeys: boundKeys,
      builder: builder,
    ).build();
  }

  static List<String> _boundKeys(Map<String, Object?> data) => data.entries
      .where((entry) {
        final value = entry.value;

        return value is Map && value['path'] is String;
      })
      .map((entry) => entry.key)
      .toList(growable: false);
}

class const _BoundDashboardData({
  required final CatalogItemContext context,
  required final Map<String, Object?> data,
  required final List<String> boundKeys,
  required final _DashboardBuilder builder,
}) {
  Widget build() => _resolve(0, data);

  Widget _resolve(int index, Map<String, Object?> resolved) {
    if (index >= boundKeys.length) return _buildResolved(resolved);

    final key = boundKeys[index];

    return BoundObject(
      dataContext: context.dataContext,
      value: data[key],
      builder: (_, value) => _resolve(index + 1, {...resolved, key: value}),
    );
  }

  Widget _buildResolved(Map<String, Object?> resolved) {
    if (boundKeys.any((key) => resolved[key] is Map)) {
      return _warning('malformedPayload');
    }

    final issue = A2uiChatContract.validateMessage({
      'version': a2uiChatWireVersion,
      'updateComponents': {
        'surfaceId': context.surfaceId,
        'components': [
          {...resolved, 'id': context.id, 'component': context.type},
        ],
      },
    });
    if (issue != null) return _warning(issue.name);

    return builder(context, resolved);
  }

  Widget _warning(String issue) =>
      ChatA2uiWarning(details: 'component: ${context.id}\nissue: $issue');
}

final _dashboardBuilders = <String, _DashboardBuilder>{
  'Progress': _DashboardPrimitiveBuilders.progress,
  'Badge': _DashboardPrimitiveBuilders.badge,
  'Avatar': _DashboardPrimitiveBuilders.avatar,
  'AvatarGroup': _DashboardPrimitiveBuilders.avatarGroup,
  'Table': _DashboardTableBuilder.table,
  'Chart': _DashboardChartBuilder.chart,
  'LoadingIndicator': _DashboardLoadingBuilder.loading,
  'AnimatedContent': _DashboardAnimationBuilder.animated,
};

abstract final class _DashboardPrimitiveBuilders {
  static Widget emptyState(
    CatalogItemContext context,
    Map<String, Object?> data,
    IconData Function(String?) resolveIcon,
  ) => AuraEmptyState(
    title: Text(data['title']! as String),
    description: switch (data['description']) {
      final String description => Text(description),
      _ => null,
    },
    icon: AuraIcon(resolveIcon(data['icon'] as String? ?? 'info')),
  );

  static Widget progress(
    CatalogItemContext context,
    Map<String, Object?> data,
  ) {
    final label = data['label'] as String?;
    final value = _progressValue(data);

    return AuraColumn(
      children: [
        _ProgressLabel(data: data, label: label, value: value),
        AuraLinearProgressIndicator(
          value: value,
          tint: _DashboardValues.tone(data['tone']),
          semanticLabel: label,
          semanticValue: _progressSemanticValue(value),
        ),
      ],
      crossAxisAlignment: .stretch,
    );
  }

  static Widget badge(CatalogItemContext _, Map<String, Object?> data) =>
      AuraBadge.text(
        child: Text(data['label']! as String),
        variant: AuraBadgeVariant.values.byName(
          data['tone'] as String? ?? 'primary',
        ),
        size: AuraBadgeSize.values.byName(data['size'] as String? ?? 'medium'),
      );

  static Widget avatar(CatalogItemContext _, Map<String, Object?> data) =>
      ChatCatalogAvatar(
        name: data['name']! as String,
        url: data['url'] as String?,
        size: switch (data['size']) {
          'small' => .xl,
          'large' => .xl3,
          _ => .xl2,
        },
      );

  static Widget avatarGroup(
    CatalogItemContext context,
    Map<String, Object?> data,
  ) {
    final avatars = (data['avatars']! as List).cast<Map<Object?, Object?>>();
    final maxVisible = data['maxVisible'] as int? ?? 5;

    return AuraAvatarGroup(
      children: _avatarChildren(context, avatars),
      maxVisible: maxVisible,
      overflowSemanticLabel: _avatarOverflow(avatars, maxVisible),
    );
  }

  static List<Widget> _avatarChildren(
    CatalogItemContext context,
    List<Map<Object?, Object?>> avatars,
  ) => [
    for (final avatar in avatars)
      _DashboardPrimitiveBuilders.avatar(
        context,
        Map<String, Object?>.from(avatar),
      ),
  ];

  static String _avatarOverflow(
    List<Map<Object?, Object?>> avatars,
    int maxVisible,
  ) => avatars.skip(maxVisible).map((avatar) => avatar['name']).join(', ');
}

class const _ProgressLabel({
  required final Map<String, Object?> data,
  required final String? label,
  required final double? value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (label == null && data['showValue'] != true) {
      return const SizedBox.shrink();
    }

    return _ProgressLabelRow(
      label: label,
      value: value,
      showValue: data['showValue'] == true,
    );
  }
}

class const _ProgressLabelRow({
  required final String? label,
  required final double? value,
  required final bool showValue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: .spaceBetween,
    spacing: context.auraTheme.spacing.base,
    runSpacing: context.auraTheme.spacing.xs,
    children: [
      if (label case final labelValue?) _ProgressLabelText(labelValue),
      if (showValue)
        if (value case final valueValue?) _ProgressLabelValue(valueValue),
    ],
  );
}

class const _ProgressLabelText(final String label) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(child: Text(label));
}

class const _ProgressLabelValue(final double value) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraText(child: Text('${(value * _percentageScale).round()}%'));
}

double? _progressValue(Map<String, Object?> data) =>
    data['indeterminate'] == true ? null : (data['value'] as num?)?.toDouble();

String? _progressSemanticValue(double? value) =>
    value == null ? null : '${(value * _percentageScale).round()}%';

abstract final class _DashboardTableBuilder {
  static Widget table(CatalogItemContext _, Map<String, Object?> data) =>
      _DashboardTable(data);

  static _DashboardTableData _tableData(Map<String, Object?> data) {
    final columns = _tableColumns(data);
    final rows = _tableRows(data);

    return (
      content: (
        columns: _tableColumnLabels(columns),
        rows: _tableRowCells(rows),
      ),
      options: _tableOptions(data, columns, rows),
    );
  }

  static _DashboardTableOptions _tableOptions(
    Map<String, Object?> data,
    List<Map<Object?, Object?>> columns,
    List<Map<Object?, Object?>> rows,
  ) => (
    caption: _tableCaption(data),
    columnAlignments: _tableColumnAlignments(columns),
    columnFormats: _tableColumnFormats(columns),
    sortableColumns: _sortableColumns(columns),
    rowTints: _rowTints(rows),
    emptyText: _DashboardValues.nullableString(data['emptyText']),
    noValueLabel:
        _DashboardValues.nullableString(data['noValueLabel']) ?? 'No value',
  );

  static AuraTable _buildTable(_DashboardTableData values) {
    final content = values.content;
    final options = values.options;

    return AuraTable(
      columns: content.columns,
      rows: content.rows,
      caption: options.caption,
      columnAlignments: options.columnAlignments,
      columnFormats: options.columnFormats,
      sortableColumns: options.sortableColumns,
      rowTints: options.rowTints,
      emptyText: options.emptyText,
      noValueLabel: options.noValueLabel,
    );
  }

  static List<Map<Object?, Object?>> _tableColumns(Map<String, Object?> data) =>
      (data['columns']! as List)
          .map(
            (value) =>
                value is Map ? value : <Object?, Object?>{'label': value},
          )
          .toList(growable: false);

  static List<Map<Object?, Object?>> _tableRows(Map<String, Object?> data) =>
      (data['rows']! as List)
          .map(
            (value) =>
                value is Map ? value : <Object?, Object?>{'cells': value},
          )
          .toList(growable: false);

  static List<String> _tableColumnLabels(List<Map<Object?, Object?>> columns) =>
      [for (final column in columns) _DashboardValues.string(column['label'])];

  static List<List<Object?>> _tableRowCells(List<Map<Object?, Object?>> rows) =>
      [for (final row in rows) (row['cells']! as List).cast<Object?>()];

  static Widget? _tableCaption(Map<String, Object?> data) =>
      switch (data['caption']) {
        final String caption => Text(caption),
        _ => null,
      };
}

List<bool> _sortableColumns(List<Map<Object?, Object?>> columns) => [
  for (final column in columns) column['sortable'] == true,
];

List<AuraTint?> _rowTints(List<Map<Object?, Object?>> rows) => [
  for (final row in rows) _DashboardValues.nullableTone(row['tone']),
];

List<AuraTableAlignment> _tableColumnAlignments(
  List<Map<Object?, Object?>> columns,
) => [
  for (final column in columns)
    switch (column['align']) {
      'center' => AuraTableAlignment.center,
      'end' => AuraTableAlignment.end,
      _ => AuraTableAlignment.start,
    },
];

List<AuraTableValueFormat> _tableColumnFormats(
  List<Map<Object?, Object?>> columns,
) => [
  for (final column in columns)
    switch (column['format']) {
      'number' => AuraTableValueFormat.number,
      'percent' => AuraTableValueFormat.percent,
      _ => AuraTableValueFormat.plain,
    },
];

class _DashboardTable extends StatelessWidget {
  new(Map<String, Object?> data) : _table = _DashboardTableConfig(data).build();

  final AuraTable _table;

  @override
  Widget build(BuildContext context) => _table;
}

class _DashboardTableConfig {
  const new(this.data);

  final Map<String, Object?> data;

  AuraTable build() => _DashboardTableBuilder._buildTable(
    _DashboardTableBuilder._tableData(data),
  );
}

abstract final class _DashboardLoadingBuilder {
  static Widget loading(CatalogItemContext _, Map<String, Object?> data) {
    final label = data['label']! as String;
    final indicator = _loadingIndicator(data, label);

    return data['inline'] == true
        ? AuraRow(
            children: [
              indicator,
              AuraText(child: Text(label)),
            ],
            mainAxisSize: .min,
          )
        : AuraColumn(
            children: [
              indicator,
              AuraText(child: Text(label)),
            ],
          );
  }

  static Widget _loadingIndicator(Map<String, Object?> data, String label) {
    final value = (data['value'] as num?)?.toDouble();
    if (value == null) {
      return AuraSpinner(
        size: switch (data['size']) {
          'small' => AuraSpinnerSize.small,
          'large' => AuraSpinnerSize.large,
          _ => AuraSpinnerSize.medium,
        },
        semanticLabel: label,
      );
    }

    return AuraLinearProgressIndicator(
      value: value,
      semanticLabel: label,
      semanticValue: '${(value * _percentageScale).round()}%',
    );
  }
}

abstract final class _DashboardChartBuilder {
  static Widget chart(CatalogItemContext _, Map<String, Object?> data) =>
      _DashboardChart(.new(data));

  static _DashboardChartData _chartData(Map<String, Object?> data) {
    return (content: _chartContent(data), options: _chartOptions(data));
  }

  static _DashboardChartContent _chartContent(Map<String, Object?> data) {
    final labels = (data['labels']! as List).cast<String>();
    final series = _chartSeries(data);

    return (
      labels: labels,
      series: series,
      semanticLabel: _chartSummary(data, labels, series),
    );
  }

  static _DashboardChartOptions _chartOptions(Map<String, Object?> data) => (
    type: _chartType(data),
    stacked: data['stacked'] == true,
    minY: (data['minY'] as num?)?.toDouble(),
    maxY: (data['maxY'] as num?)?.toDouble(),
    axes: _chartAxes(data),
    palette: _chartPalette(data),
  );

  static _DashboardChartAxes _chartAxes(Map<String, Object?> data) => (
    x: _DashboardValues.nullableString(data['xAxisTitle']),
    y: _DashboardValues.nullableString(data['yAxisTitle']),
    unit: _DashboardValues.nullableString(data['unit']),
  );

  static List<AuraChartSeries> _chartSeries(Map<String, Object?> data) => [
    for (final item in (data['series']! as List).cast<Map<Object?, Object?>>())
      AuraChartSeries(
        label: item['label']! as String,
        values: _chartValues(item['values']),
        tint: _DashboardValues.tone(item['tone']),
      ),
  ];

  static String _chartSummary(
    Map<String, Object?> data,
    List<String> labels,
    List<AuraChartSeries> series,
  ) => [
    if (data['label'] case final String label) label,
    for (final item in series) _chartSeriesSummary(item, labels),
  ].join('\n');

  static String _chartSeriesSummary(AuraChartSeries item, List<String> labels) {
    final values = [
      for (var i = 0; i < labels.length; i++) '${labels[i]}: ${item.values[i]}',
    ].join(', ');

    return '${item.label}: $values';
  }

  static AuraChartType _chartType(Map<String, Object?> data) =>
      switch (data['variant']) {
        'bar' => .bar,
        'pie' => .pie,
        'donut' => .donut,
        _ => .line,
      };

  static List<AuraTint> _chartPalette(Map<String, Object?> data) => [
    for (final tone in data['palette'] as List? ?? const <Object?>[])
      if (tone is String) _DashboardValues.tone(tone),
  ];
}

abstract final class _DashboardAnimationBuilder {
  static Widget animated(
    CatalogItemContext context,
    Map<String, Object?> data,
  ) => AuraAnimatedContent(
    child: KeyedSubtree(
      key: ValueKey(
        data['trigger'] == 'keyChange' ? data['child'] : context.id,
      ),
      child: context.buildChild(data['child']! as String),
    ),
    transition: switch (data['transition']) {
      'none' => .none,
      'slide' => .slide,
      'scale' => .scale,
      _ => .fade,
    },
  );
}

List<double> _chartValues(Object? values) => values is List
    ? [for (final value in values) (value as num).toDouble()]
    : const [];

class _DashboardChart extends StatelessWidget {
  const new(this.config);

  final _DashboardChartConfig config;

  @override
  Widget build(BuildContext context) => config.build();
}

class _DashboardChartConfig {
  const new(this.data);

  final Map<String, Object?> data;

  AuraChart build() =>
      _DashboardAuraChart(_DashboardChartBuilder._chartData(data));
}

class _DashboardAuraChart extends AuraChart {
  new(_DashboardChartData values)
    : super(
        labels: values.content.labels,
        series: values.content.series,
        semanticLabel: values.content.semanticLabel,
        type: values.options.type,
        stacked: values.options.stacked,
        minY: values.options.minY,
        maxY: values.options.maxY,
        xAxisTitle: values.options.axes.x,
        yAxisTitle: values.options.axes.y,
        unit: values.options.axes.unit,
        palette: values.options.palette,
      );
}

abstract final class _DashboardValues {
  static AuraTint tone(Object? value) =>
      AuraTint.values.byName(value as String? ?? 'primary');

  static String string(Object? value) => value is String ? value : '';

  static String? nullableString(Object? value) =>
      value is String ? value : null;

  static AuraTint? nullableTone(Object? value) =>
      value is String ? tone(value) : null;
}
