import 'dart:convert';

import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_app/features/chats/widgets/chat_catalog_avatar.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

const _percentageScale = 100.0;

/// Adds app-rendered dashboard items to either chat catalog.
// Required: Public catalog adapter API.
// ignore: prefer-static-class
List<CatalogItem> auraDashboardCatalogItems({
  required IconData Function(String?) resolveIcon,
}) => [
  for (final entry in {
    ..._AuraDashboardCatalogAdapter._builders,
    'EmptyState': (CatalogItemContext context, Map<String, Object?> data) =>
        AuraEmptyState(
          title: Text(data['title']! as String),
          description: switch (data['description']) {
            final String description => Text(description),
            _ => null,
          },
          icon: AuraIcon(resolveIcon(data['icon'] as String? ?? 'info')),
        ),
  }.entries)
    CatalogItem(
      name: entry.key,
      dataSchema: .fromMap({
        ...a2uiChatComponentSchemas[entry.key]!,
        'required': [
          for (final property
              in a2uiChatComponentSchemas[entry.key]!['required']! as List)
            if (property != 'id') property,
        ],
      }),
      widgetBuilder: (context) =>
          _AuraDashboardCatalogAdapter._boundData(context, entry.value),
      exampleData: [
        () => jsonEncode([a2uiChatComponentExamples[entry.key]]),
      ],
    ),
];

typedef _DashboardBuilder = Widget Function(
  CatalogItemContext context,
  Map<String, Object?> data,
);

abstract final class _AuraDashboardCatalogAdapter {
  static final _builders = <String, _DashboardBuilder>{
    'Progress': _progress,
    'Badge': _badge,
    'Avatar': _avatar,
    'AvatarGroup': _avatarGroup,
    'Table': _table,
    'Chart': _chart,
    'LoadingIndicator': _loading,
    'AnimatedContent': _animated,
  };

  static Widget _boundData(
    CatalogItemContext context,
    _DashboardBuilder builder,
  ) {
    final data = Map<String, Object?>.from(context.data as Map);
    final boundKeys = data.entries
        .where((entry) {
          final value = entry.value;

          return value is Map && value['path'] is String;
        })
        .map((entry) => entry.key)
        .toList(growable: false);

    Widget resolve(int index, Map<String, Object?> resolved) {
      if (index < boundKeys.length) {
        final key = boundKeys[index];

        return BoundObject(
          dataContext: context.dataContext,
          value: data[key],
          builder: (_, value) => resolve(index + 1, {...resolved, key: value}),
        );
      }
      if (boundKeys.any((key) => resolved[key] is Map)) {
        return ChatA2uiWarning(
          details: 'component: ${context.id}\nissue: malformedPayload',
        );
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
      if (issue != null) {
        return ChatA2uiWarning(
          details: 'component: ${context.id}\nissue: ${issue.name}',
        );
      }

      return builder(context, resolved);
    }

    return resolve(0, data);
  }

  static AuraTint _tone(Object? value) =>
      AuraTint.values.byName(value as String? ?? 'primary');

  static String _string(Object? value) => value is String ? value : '';

  static String? _nullableString(Object? value) =>
      value is String ? value : null;

  static Widget _progress(
    CatalogItemContext context,
    Map<String, Object?> data,
  ) {
    final label = data['label'] as String?;
    final indeterminate = data['indeterminate'] == true;
    final value = indeterminate ? null : (data['value'] as num?)?.toDouble();

    return AuraColumn(
      children: [
        if (label != null || data['showValue'] == true)
          Wrap(
            alignment: .spaceBetween,
            spacing: context.buildContext.auraTheme.spacing.base,
            runSpacing: context.buildContext.auraTheme.spacing.xs,
            children: [
              if (label != null) AuraText(child: Text(label)),
              if (data['showValue'] == true && value != null)
                AuraText(child: Text('${(value * _percentageScale).round()}%')),
            ],
          ),
        AuraLinearProgressIndicator(
          value: value,
          tint: _tone(data['tone']),
          semanticLabel: label,
          semanticValue: value == null
              ? null
              : '${(value * _percentageScale).round()}%',
        ),
      ],
      crossAxisAlignment: .stretch,
    );
  }

  static Widget _badge(CatalogItemContext _, Map<String, Object?> data) =>
      AuraBadge.text(
        child: Text(data['label']! as String),
        variant: AuraBadgeVariant.values.byName(
          data['tone'] as String? ?? 'primary',
        ),
        size: AuraBadgeSize.values.byName(data['size'] as String? ?? 'medium'),
      );

  static Widget _avatar(CatalogItemContext _, Map<String, Object?> data) {
    return ChatCatalogAvatar(
      name: data['name']! as String,
      url: data['url'] as String?,
      size: switch (data['size']) {
        'small' => .xl,
        'large' => .xl3,
        _ => .xl2,
      },
    );
  }

  static Widget _avatarGroup(
    CatalogItemContext context,
    Map<String, Object?> data,
  ) {
    final avatars = (data['avatars']! as List).cast<Map<Object?, Object?>>();
    final maxVisible = data['maxVisible'] as int? ?? 5;

    return AuraAvatarGroup(
      children: [
        for (final avatar in avatars)
          _avatar(context, Map<String, Object?>.from(avatar)),
      ],
      maxVisible: maxVisible,
      overflowSemanticLabel: avatars
          .skip(maxVisible)
          .map((avatar) => avatar['name'])
          .join(', '),
    );
  }

  static Widget _table(CatalogItemContext _, Map<String, Object?> data) {
    final columns = (data['columns']! as List)
        .map(
          (value) => value is Map ? value : <Object?, Object?>{'label': value},
        )
        .toList(growable: false);
    final rows = (data['rows']! as List)
        .map(
          (value) => value is Map ? value : <Object?, Object?>{'cells': value},
        )
        .toList(growable: false);

    return AuraTable(
      columns: [for (final column in columns) _string(column['label'])],
      rows: [for (final row in rows) (row['cells']! as List).cast<Object?>()],
      caption: switch (data['caption']) {
        final String caption => Text(caption),
        _ => null,
      },
      columnAlignments: [
        for (final column in columns)
          switch (column['align']) {
            'center' => AuraTableAlignment.center,
            'end' => AuraTableAlignment.end,
            _ => AuraTableAlignment.start,
          },
      ],
      columnFormats: [
        for (final column in columns)
          switch (column['format']) {
            'number' => AuraTableValueFormat.number,
            'percent' => AuraTableValueFormat.percent,
            _ => AuraTableValueFormat.plain,
          },
      ],
      sortableColumns: [
        for (final column in columns) column['sortable'] == true,
      ],
      rowTints: [for (final row in rows) _nullableTone(row['tone'])],
      emptyText: _nullableString(data['emptyText']),
      noValueLabel: _nullableString(data['noValueLabel']) ?? 'No value',
    );
  }

  static Widget _loading(CatalogItemContext _, Map<String, Object?> data) {
    final label = data['label']! as String;
    final value = (data['value'] as num?)?.toDouble();
    final indicator = value == null
        ? AuraSpinner(
            size: switch (data['size']) {
              'small' => AuraSpinnerSize.small,
              'large' => AuraSpinnerSize.large,
              _ => AuraSpinnerSize.medium,
            },
            semanticLabel: label,
          )
        : AuraLinearProgressIndicator(
            value: value,
            semanticLabel: label,
            semanticValue: '${(value * 100).round()}%',
          );

    if (data['inline'] == true) {
      return AuraRow(
        children: [
          indicator,
          AuraText(child: Text(label)),
        ],
        mainAxisSize: .min,
      );
    }

    return AuraColumn(
      children: [
        indicator,
        AuraText(child: Text(label)),
      ],
    );
  }

  static Widget _chart(CatalogItemContext _, Map<String, Object?> data) {
    final labels = (data['labels']! as List).cast<String>();
    final series = [
      for (final item
          in (data['series']! as List).cast<Map<Object?, Object?>>())
        AuraChartSeries(
          label: item['label']! as String,
          values: [
            for (final value in item['values']! as List)
              (value as num).toDouble(),
          ],
          tint: _tone(item['tone']),
        ),
    ];
    final descriptions = <String>[];
    for (final item in series) {
      final values = [
        for (var i = 0; i < labels.length; i++)
          '${labels[i]}: ${item.values[i]}',
      ];
      descriptions.add('${item.label}: ${values.join(', ')}');
    }
    final summary = [
      if (data['label'] case final String label) label,
      ...descriptions,
    ].join('\n');

    return AuraChart(
      labels: labels,
      series: series,
      semanticLabel: summary,
      type: switch (data['variant']) {
        'bar' => .bar,
        'pie' => .pie,
        'donut' => .donut,
        _ => .line,
      },
      stacked: data['stacked'] == true,
      minY: (data['minY'] as num?)?.toDouble(),
      maxY: (data['maxY'] as num?)?.toDouble(),
      xAxisTitle: _nullableString(data['xAxisTitle']),
      yAxisTitle: _nullableString(data['yAxisTitle']),
      unit: _nullableString(data['unit']),
      palette: [
        for (final tone in data['palette'] as List? ?? const <Object?>[])
          if (tone is String) _tone(tone),
      ],
    );
  }

  static Widget _animated(
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

  static AuraTint? _nullableTone(Object? value) =>
      value is String ? _tone(value) : null;
}
