// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/aura_dashboard_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/aura_extended_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_form_scope.dart';
import 'package:auravibes_app/features/chats/widgets/chat_catalog_text_field.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:auravibes_app/features/chats/agent_adapters/chat_catalog_image_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:url_launcher/url_launcher.dart';

const String auraChatCatalogId = a2uiChatCatalogId;
const String auraChatFormCatalogId = a2uiChatFormCatalogId;

const _responseA2uiRules =
    '''
Use A2UI v0.9 messages with catalogId "$auraChatCatalogId" and
interactionMode "passive". This catalog is for presentational response UI.
Do not include agent actions or editable form behavior. Every
updateComponents message MUST include a component with id "root"; send the
complete visible component tree when updating a surface. Never put protocol
JSON in ordinary text.
''';

const _formA2uiRules =
    '''
Use A2UI v0.9 messages with catalogId "$auraChatFormCatalogId" and
interactionMode "requiresUserAction". Use this catalog only when the human
must provide input. Put all editable values in the surface data model. The
application adds the submit control after the surface; do not emit agent
actions. Every updateComponents message MUST
include a component with id "root"; send the complete visible component tree
when updating a surface. Never put protocol JSON in ordinary text.
''';

const _implementedProperties = <String, Set<String>>{
  'Button': {'child', 'label', 'icon', 'disabled', 'href', 'variant'},
  'Card': {'child', 'title', 'subtitle', 'tone', 'style'},
  'CheckBox': {'label', 'value', 'disabled', 'readOnly'},
  'ChoicePicker': {
    'label',
    'options',
    'value',
    'variant',
    'presentation',
    'maxSelections',
    'minSelections',
    'disabled',
    'readOnly',
  },
  'Column': {'children', 'justify', 'align'},
  'DateTimeInput': {
    'variant',
    'value',
    'label',
    'min',
    'max',
    'disabled',
    'readOnly',
  },
  'Divider': {'axis'},
  'Icon': {'name', 'label', 'size', 'tone'},
  'Image': {
    'url',
    'fit',
    'variant',
    'label',
    'width',
    'height',
    'fallbackText',
    'fallbackIcon',
  },
  'List': {'children', 'direction', 'align'},
  'Modal': {'trigger', 'content', 'title', 'size', 'closeLabel'},
  'Row': {'children', 'justify', 'align'},
  'Slider': {
    'label',
    'value',
    'min',
    'max',
    'step',
    'precision',
    'unit',
    'showValue',
    'valueFormat',
    'marks',
    'disabled',
    'readOnly',
  },
  'Tabs': {'tabs', 'activeTab'},
  'Text': {'text', 'variant', 'tone', 'align', 'maxLines', 'truncation'},
  'TextField': {
    'label',
    'value',
    'variant',
    'required',
    'disabled',
    'readOnly',
    'placeholder',
    'helperText',
    'errorText',
    'minLength',
    'maxLength',
    'pattern',
  },
};

String auraChatCatalogSystemPrompt() => [
  PromptBuilder.custom(
    catalog: auraChatResponseCatalog(),
    allowedOperations: SurfaceOperations.createAndUpdate(dataModel: true),
  ).systemPromptJoined(),
  PromptBuilder.custom(
    catalog: auraChatFormCatalog(),
    allowedOperations: SurfaceOperations.createAndUpdate(dataModel: true),
  ).systemPromptJoined(),
  A2uiChatContract.systemPrompt,
].join('\n');

Catalog auraChatResponseCatalog() =>
    _buildCatalog(catalogId: auraChatCatalogId, rules: _responseA2uiRules);

Catalog auraChatFormCatalog() =>
    _buildCatalog(catalogId: auraChatFormCatalogId, rules: _formA2uiRules);

List<Catalog> auraChatCatalogs() => [
  auraChatResponseCatalog(),
  auraChatFormCatalog(),
];

Catalog _buildCatalog({required String catalogId, required String rules}) {
  CatalogItem replace(CatalogItem source, CatalogWidgetBuilder builder) =>
      _replace(
        source,
        builder,
        allowLiteralValues: catalogId == auraChatCatalogId,
      );

  return BasicCatalogItems.asCatalog()
      .copyWithout(
        itemsToRemove: [BasicCatalogItems.audioPlayer, BasicCatalogItems.video],
      )
      .copyWith(
        catalogId: catalogId,
        newItems: [
          replace(BasicCatalogItems.button, _button),
          replace(BasicCatalogItems.card, _card),
          replace(BasicCatalogItems.checkBox, _checkBox),
          replace(BasicCatalogItems.column, _column),
          replace(BasicCatalogItems.dateTimeInput, _dateTimeInput),
          replace(BasicCatalogItems.divider, _divider),
          replace(BasicCatalogItems.icon, _icon),
          replace(BasicCatalogItems.image, _image),
          replace(BasicCatalogItems.list, _list),
          replace(BasicCatalogItems.modal, _modal),
          replace(BasicCatalogItems.choicePicker, _choicePicker),
          replace(BasicCatalogItems.row, _row),
          replace(BasicCatalogItems.slider, _slider),
          replace(BasicCatalogItems.tabs, _tabs),
          replace(BasicCatalogItems.text, _text),
          replace(BasicCatalogItems.textField, _textField),
          ...auraDashboardCatalogItems(resolveIcon: auraChatIconData),
          ...auraExtendedCatalogItems(resolveIcon: auraChatIconData),
        ],
        systemPromptFragments: [rules],
      );
}

CatalogItem _replace(
  CatalogItem source,
  CatalogWidgetBuilder builder, {
  required bool allowLiteralValues,
}) => CatalogItem(
  name: source.name,
  dataSchema: _schemaFor(source, allowLiteralValues: allowLiteralValues),
  widgetBuilder: builder,
  exampleData: source.name == 'Image'
      ? [chatCatalogImageExample]
      : [
          () => jsonEncode([
            {
              ...a2uiChatComponentExamples[source.name]!,
              if (source.name == 'Tabs' && !allowLiteralValues)
                'activeTab': {'path': '/activeTab'},
            },
          ]),
        ],
  isImplicitlyFlexible: source.isImplicitlyFlexible,
);

Schema _schemaFor(CatalogItem source, {required bool allowLiteralValues}) {
  final sourceSchema = source.dataSchema.value;
  final sourceProperties = Map<String, Object?>.from(
    sourceSchema['properties']! as Map<Object?, Object?>,
  );
  final allowed = {..._implementedProperties[source.name]!};
  final contractProperties = Map<String, Object?>.from(
    a2uiChatComponentSchemas[source.name]!['properties']!
        as Map<Object?, Object?>,
  );
  final properties = _schemaProperties(
    source.name,
    sourceProperties,
    contractProperties,
    allowed,
    allowLiteralValues,
  );
  final required = _schemaRequired(
    sourceSchema,
    source.name,
    allowed,
    allowLiteralValues,
  );

  return Schema.fromMap({
    ...sourceSchema,
    'properties': properties,
    'required': ?required,
  });
}

Map<String, Object?> _schemaProperties(
  String name,
  Map<String, Object?> sourceProperties,
  Map<String, Object?> contractProperties,
  Set<String> allowed,
  bool allowLiteralValues,
) {
  final mergedProperties = allowLiteralValues
      ? {...sourceProperties, ...contractProperties}
      : {...contractProperties, ...sourceProperties};
  final properties = {
    for (final entry in mergedProperties.entries)
      if (entry.key == 'component' || allowed.contains(entry.key))
        entry.key: entry.value,
  };
  switch (name) {
    case 'Icon':
      properties['name'] = {'type': 'string', 'enum': a2uiChatIconNames};
    case 'Button':
      properties['variant'] = contractProperties['variant'];
    case 'Image':
      properties.addAll(chatCatalogImageProperties);
  }
  return properties;
}

List<String>? _schemaRequired(
  Map<String, Object?> sourceSchema,
  String name,
  Set<String> allowed,
  bool allowLiteralValues,
) {
  final required = (sourceSchema['required'] as List?)
      ?.whereType<String>()
      .where((name) => name == 'component' || allowed.contains(name))
      .toList();
  if (name != 'Tabs') return required;
  if (allowLiteralValues) {
    final _ = required?.remove('activeTab');
  } else if (required != null && !required.contains('activeTab')) {
    required.add('activeTab');
  }
  return required;
}

Map<String, Object?> _data(CatalogItemContext context) =>
    Map<String, Object?>.from(context.data as Map<Object?, Object?>);

String _path(Object? reference, String fallback) =>
    reference is Map<Object?, Object?> && reference['path'] is String
    ? reference['path']! as String
    : fallback;

String _string(Object? value) => value is String ? value : '';

String? _nullableString(Object? value) => value is String ? value : null;

Uri? _httpsUri(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
      ? uri
      : null;
}

String _formatSliderValue(
  double value, {
  required int precision,
  required String unit,
  required String? format,
}) {
  final rendered = format == 'percent'
      ? '${(value * 100).toStringAsFixed(precision)}%'
      : value.toStringAsFixed(precision);
  return unit.isEmpty ? rendered : '$rendered $unit';
}

DateTime? _dateTimeValue(String? value, String? variant) {
  if (value == null || value.isEmpty) return null;
  if (variant == 'time') {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    return DateTime(2000, 1, 1, int.parse(match[1]!), int.parse(match[2]!));
  }
  return DateTime.tryParse(value);
}

String? _formatDateTimeValue(DateTime? value, String? variant) {
  if (value == null) return null;
  if (variant == 'date') {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
  if (variant == 'time') {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
  return value.toUtc().toIso8601String();
}

void _updateData(CatalogItemContext context, String path, Object? value) {
  ChatA2uiFormScope.markTouched(context.buildContext, path);
  context.dataContext.update(DataPath(path), value);
}

Widget _fieldScope(Map<String, Object?> data, Widget child) {
  if (data['disabled'] == true) {
    return AuraInteractionScope(
      policy: const AuraInteractionPolicy.disabled(),
      child: child,
    );
  }
  if (data['readOnly'] == true) {
    return AuraInteractionScope(
      policy: const AuraInteractionPolicy.readOnly(),
      child: child,
    );
  }
  return child;
}

MainAxisAlignment _mainAxis(String? value) => switch (value) {
  'center' => .center,
  'end' => .end,
  'spaceBetween' => .spaceBetween,
  'spaceAround' => .spaceAround,
  'spaceEvenly' => .spaceEvenly,
  _ => .start,
};

CrossAxisAlignment _crossAxis(String? value) => switch (value) {
  'center' => .center,
  'end' => .end,
  'stretch' => .stretch,
  _ => .start,
};

AuraTint? _tone(Object? value) {
  final name = value as String?;
  return name == null ? null : AuraTint.values.byName(name);
}

Widget _children(
  CatalogItemContext context,
  Object? children,
  Widget Function(List<Widget>) build, {
  Widget Function(String id, Widget child)? decorate,
}) => ComponentChildrenBuilder(
  childrenData: children,
  dataContext: context.dataContext,
  buildChild: context.buildChild,
  getComponent: context.getComponent,
  explicitListBuilder: (ids, buildChild, _, dataContext) => build([
    for (final id in ids)
      decorate?.call(id, buildChild(id, dataContext)) ??
          buildChild(id, dataContext),
  ]),
  templateListWidgetBuilder: (buildContext, data, componentId, binding) {
    final list = data is List ? data : null;
    final map = data is Map<Object?, Object?> ? data : null;
    if (list == null && map == null) {
      return const SizedBox.shrink();
    }
    final values = list ?? map!.values.toList();
    final keys = list != null
        ? List.generate(values.length, (index) => '$index')
        : map!.keys.map((key) => '$key').toList();

    return build([
      for (var index = 0; index < values.length; index++)
        KeyedSubtree(
          key: ValueKey(keys[index]),
          child: (decorate ?? (_, child) => child)(
            componentId,
            context.buildChild(
              componentId,
              context.dataContext.nested(DataPath('$binding/${keys[index]}')),
            ),
          ),
        ),
    ]);
  },
);

Widget _text(CatalogItemContext context) {
  final data = _data(context);

  return BoundString(
    dataContext: context.dataContext,
    value: data['text'],
    builder: (_, value) => AuraText(
      child: Text(
        value ?? '',
        maxLines: data['maxLines'] as int?,
        overflow: data['truncation'] == 'ellipsis'
            ? TextOverflow.ellipsis
            : TextOverflow.visible,
        textAlign: switch (data['align']) {
          'center' => TextAlign.center,
          'end' => TextAlign.end,
          'justify' => TextAlign.justify,
          _ => TextAlign.start,
        },
      ),
      style: switch (data['variant']) {
        'h1' => AuraTextStyle.heading1,
        'h2' => AuraTextStyle.heading2,
        'h3' => AuraTextStyle.heading3,
        'h4' => AuraTextStyle.heading4,
        'h5' => AuraTextStyle.heading5,
        'caption' => AuraTextStyle.caption,
        _ => AuraTextStyle.body,
      },
      tint: _tone(data['tone']),
      textAlign: switch (data['align']) {
        'center' => TextAlign.center,
        'end' => TextAlign.end,
        'justify' => TextAlign.justify,
        _ => TextAlign.start,
      },
    ),
  );
}

Widget _image(CatalogItemContext context) {
  return ChatCatalogImageAdapter.build(context, resolveIcon: auraChatIconData);
}

Widget _icon(CatalogItemContext context) {
  final data = _data(context);

  return BoundString(
    dataContext: context.dataContext,
    value: data['name'],
    builder: (_, value) => AuraIcon(
      auraChatIconData(value),
      semanticLabel: _string(data['label']).isEmpty
          ? value
          : _string(data['label']),
      size: switch (data['size']) {
        'small' => AuraIconSize.small,
        'large' => AuraIconSize.large,
        'extraLarge' => AuraIconSize.extraLarge,
        _ => AuraIconSize.medium,
      },
      tint: _tone(data['tone']),
    ),
  );
}

final Map<String, IconData> auraChatIcons = Map.unmodifiable({
  for (final icon in AvailableIcons.values) icon.name: icon.iconData,
  'dashboard': Icons.dashboard,
  'checkCircle': Icons.check_circle,
  'schedule': Icons.schedule,
  'radioButtonUnchecked': Icons.radio_button_unchecked,
  'trendingUp': Icons.trending_up,
  'groups': Icons.groups,
  'timer': Icons.timer,
  'bugReport': Icons.bug_report,
  'speed': Icons.speed,
  'pending': Icons.pending,
  'merge': Icons.merge,
  'rocketLaunch': Icons.rocket_launch,
  'comment': Icons.comment,
});

IconData auraChatIconData(String? name) {
  final normalized = name?.replaceAll(RegExp('[-_]'), '').toLowerCase();
  for (final entry in auraChatIcons.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value;
  }
  if (kDebugMode) {
    debugPrint('[A2UI icon] unsupported name=${jsonEncode(name)}');
  }
  return Icons.circle_outlined;
}

Widget _divider(CatalogItemContext context) =>
    _data(context)['axis'] == 'vertical'
    ? LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: constraints.hasBoundedHeight
              ? constraints.maxHeight
              : context.auraTheme.fromSpacing(AuraSpacing.xl2),
          child: const AuraDivider.vertical(),
        ),
      )
    : const AuraDivider();

Widget _card(CatalogItemContext context) {
  final data = _data(context);
  final content = context.buildChild(_string(data['child']));
  final title = _string(data['title']);
  final subtitle = _string(data['subtitle']);
  return AuraCard(
    style: data['style'] == 'outlined'
        ? AuraCardStyle.border
        : AuraCardStyle.elevated,
    tint: _tone(data['tone']),
    child: AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          AuraText(child: Text(title), style: AuraTextStyle.heading5),
        if (subtitle.isNotEmpty)
          AuraText(child: Text(subtitle), style: AuraTextStyle.bodySmall),
        content,
      ],
    ),
  );
}

Widget _row(CatalogItemContext context) {
  final data = _data(context);
  final hasFlexChild = _hasFlexChild(context, data['children']);

  return LayoutBuilder(
    builder: (_, constraints) =>
        _buildRow(context, data, constraints, hasFlexChild),
  );
}

bool _hasFlexChild(CatalogItemContext context, Object? children) {
  final childIds = children as List?;
  if (childIds == null) return false;
  return childIds.whereType<String>().any(
    (id) => switch (context.getComponent(id)?.type) {
      'FlexItem' || 'Spacer' => true,
      _ => false,
    },
  );
}

Widget _buildRow(
  CatalogItemContext context,
  Map<String, Object?> data,
  BoxConstraints constraints,
  bool hasFlexChild,
) {
  final alignment = _rowAlignment(data, constraints);
  if (constraints.hasBoundedWidth && !hasFlexChild) {
    return _buildWrappedRow(context, data, constraints, alignment);
  }
  return _children(
    context,
    data['children'],
    (children) => AuraRow(
      children: children,
      mainAxisAlignment: _mainAxis(data['justify'] as String?),
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
    ),
    decorate: (id, child) =>
        _decorateRowChild(context, constraints, hasFlexChild, id, child),
  );
}

Widget _buildWrappedRow(
  CatalogItemContext context,
  Map<String, Object?> data,
  BoxConstraints constraints,
  CrossAxisAlignment alignment,
) => _children(
  context,
  data['children'],
  (children) => Wrap(
    spacing: context.buildContext.auraTheme.spacing.base,
    runSpacing: context.buildContext.auraTheme.spacing.base,
    alignment: _wrapAlignment(data['justify'] as String?),
    crossAxisAlignment: switch (alignment) {
      CrossAxisAlignment.center => WrapCrossAlignment.center,
      CrossAxisAlignment.end => WrapCrossAlignment.end,
      _ => WrapCrossAlignment.start,
    },
    children: children,
  ),
  decorate: (id, child) =>
      _decorateRowChild(context, constraints, false, id, child),
);

CrossAxisAlignment _rowAlignment(
  Map<String, Object?> data,
  BoxConstraints constraints,
) => data['align'] == 'stretch' && !constraints.hasBoundedHeight
    ? CrossAxisAlignment.start
    : _crossAxis(data['align'] as String?);

Widget _decorateRowChild(
  CatalogItemContext context,
  BoxConstraints constraints,
  bool hasFlexChild,
  String id,
  Widget child,
) {
  final component = context.getComponent(id);
  final type = component?.type;
  final intrinsic =
      type == 'Icon' ||
      (type == 'Divider' && component?.properties['axis'] == 'vertical');
  final isFlexChild = type == 'FlexItem' || type == 'Spacer';
  return constraints.hasBoundedWidth &&
          hasFlexChild &&
          !intrinsic &&
          !isFlexChild
      ? Flexible(fit: FlexFit.loose, child: child)
      : child;
}

WrapAlignment _wrapAlignment(String? value) => switch (value) {
  'center' => .center,
  'end' => .end,
  'spaceBetween' => .spaceBetween,
  'spaceAround' => .spaceAround,
  'spaceEvenly' => .spaceEvenly,
  _ => .start,
};

Widget _column(CatalogItemContext context) {
  final data = _data(context);

  return _children(
    context,
    data['children'],
    (children) => AuraColumn(
      children: children,
      mainAxisAlignment: _mainAxis(data['justify'] as String?),
      crossAxisAlignment: _crossAxis(data['align'] as String?),
      mainAxisSize: MainAxisSize.min,
    ),
  );
}

Widget _list(CatalogItemContext context) {
  final data = _data(context);

  return _children(
    context,
    data['children'],
    (children) => AuraList(
      children: children,
      direction: data['direction'] == 'horizontal'
          ? Axis.horizontal
          : Axis.vertical,
      alignment: _crossAxis(data['align'] as String?),
    ),
  );
}

Widget _button(CatalogItemContext context) {
  final data = _data(context);
  final href = _httpsUri(data['href']);
  final childId = _string(data['child']);

  return BoundString(
    dataContext: context.dataContext,
    value: data['label'],
    builder: (_, label) => AuraButton(
      variant: switch (data['variant']) {
        'text' => AuraButtonVariant.text,
        'outlined' => AuraButtonVariant.outlined,
        _ => AuraButtonVariant.primary,
      },
      disabled: data['disabled'] == true || href == null,
      onPressed: href == null
          ? () {}
          : () => unawaited(
              launchUrl(href, mode: LaunchMode.externalApplication),
            ),
      child: label != null
          ? AuraRow(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['icon'] case final String name)
                  AuraIcon(auraChatIconData(name)),
                Text(label),
              ],
            )
          : childId.isEmpty
          ? const SizedBox.shrink()
          : context.buildChild(childId),
    ),
  );
}

Widget _checkBox(CatalogItemContext context) {
  final data = _data(context);
  final path = _path(data['value'], '/${context.id}');

  return _fieldScope(
    data,
    BoundString(
      dataContext: context.dataContext,
      value: data['label'],
      builder: (_, label) => BoundBool(
        dataContext: context.dataContext,
        value: data['value'],
        builder: (_, value) => AuraRow(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraCheckbox(
              value: value ?? false,
              onChanged: (next) => _updateData(context, path, next),
              disabled: data['disabled'] == true,
              semanticLabel: label,
            ),
            AuraText(child: Text(label ?? '')),
          ],
        ),
      ),
    ),
  );
}

Widget _slider(CatalogItemContext context) {
  final data = _data(context);
  final valueReference = data['value'];
  final path = _path(valueReference, '/${context.id}');
  final min = _sliderNumber(data['min'], 0);
  final max = _sliderNumber(data['max'], 1);
  final step = _sliderNumber(data['step'], 1);
  final precision = _sliderPrecision(data['precision']);

  return _fieldScope(
    data,
    BoundNumber(
      dataContext: context.dataContext,
      value: valueReference,
      builder: (_, value) => BoundString(
        dataContext: context.dataContext,
        value: data['label'],
        builder: (_, label) => AuraLabeledSlider(
          value: _sliderValue(value, valueReference, min, max),
          onChanged: (next) => _updateData(context, path, next),
          min: min,
          max: max,
          step: step,
          precision: precision,
          label: label,
          semanticLabel: label,
          enabled: data['disabled'] != true,
          valueFormatter: (next) => _formatSliderValue(
            next,
            precision: precision,
            unit: _string(data['unit']),
            format: data['valueFormat'] as String?,
          ),
          marks: _sliderMarks(data['marks']),
        ),
      ),
    ),
  );
}

double _sliderNumber(Object? value, double fallback) =>
    (value as num?)?.toDouble() ?? fallback;

int _sliderPrecision(Object? value) => (value as num?)?.toInt() ?? 2;

double _sliderValue(
  num? value,
  Object? valueReference,
  double min,
  double max,
) => (value ?? (valueReference is num ? valueReference : min)).toDouble().clamp(
  min,
  max,
);

List<AuraSliderMark> _sliderMarks(Object? value) {
  final marks = value as List? ?? const <Object?>[];
  return [
    for (final mark in marks)
      if (mark is Map && mark['value'] is num)
        AuraSliderMark(
          value: (mark['value']! as num).toDouble(),
          label: _nullableString(mark['label']),
        ),
  ];
}

Widget _textField(CatalogItemContext context) {
  final data = _data(context);
  final path = _path(data['value'], '/${context.id}');
  final variant = data['variant'];

  return _fieldScope(
    data,
    BoundString(
      dataContext: context.dataContext,
      value: data['value'],
      builder: (_, value) => BoundString(
        dataContext: context.dataContext,
        value: data['label'],
        builder: (_, label) => ChatCatalogTextField(
          value: value,
          label: label,
          variant: variant as String?,
          placeholder: _string(data['placeholder']),
          helperText: _string(data['helperText']),
          errorText:
              ChatA2uiFormScope.errorFor(context.buildContext, path) ??
              _nullableString(data['errorText']),
          required: data['required'] == true,
          maxLength: data['maxLength'] as int?,
          onChanged: (next) => _updateData(context, path, next),
        ),
      ),
    ),
  );
}

Widget _dateTimeInput(CatalogItemContext context) {
  final data = _data(context);
  final path = _path(data['value'], '/${context.id}');
  final variant = data['variant'];

  return _fieldScope(
    data,
    BoundString(
      dataContext: context.dataContext,
      value: data['value'],
      builder: (_, value) => BoundString(
        dataContext: context.dataContext,
        value: data['label'],
        builder: (_, label) => AuraColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) AuraText(child: Text(label)),
            AuraDateTimeInput(
              value: _dateTimeValue(value, variant as String?),
              enableDate: variant != 'time',
              enableTime: variant != 'date',
              enabled: data['disabled'] != true,
              minimum: _dateTimeValue(
                data['min'] as String?,
                variant as String?,
              ),
              maximum: _dateTimeValue(
                data['max'] as String?,
                variant as String?,
              ),
              semanticLabel: label,
              onChanged: (next) => _updateData(
                context,
                path,
                _formatDateTimeValue(next, variant as String?),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _choicePicker(CatalogItemContext context) {
  final data = _data(context);
  final options = data['options'];
  final path = _path(data['value'], '/${context.id}');
  final variant = data['variant'] == 'multiple'
      ? AuraChoicePickerVariant.multipleSelection
      : AuraChoicePickerVariant.mutuallyExclusive;
  final optionMaps = options is List
      ? options.whereType<Map<Object?, Object?>>().toList()
      : const <Map<Object?, Object?>>[];
  final optionWidgets = [
    for (final option in optionMaps)
      AuraChoiceOption<String>(
        value: _string(option['value']),
        label: AuraText(child: Text(_string(option['label']))),
        disabled: option['disabled'] == true,
      ),
  ];

  return _fieldScope(
    data,
    BoundObject(
      dataContext: context.dataContext,
      value: data['value'],
      builder: (_, value) {
        final selected = value is List
            ? value.whereType<String>().toList()
            : value is String
            ? [value]
            : const <String>[];

        return BoundString(
          dataContext: context.dataContext,
          value: data['label'],
          builder: (_, label) => AuraChoicePicker<String>(
            options: optionWidgets,
            value: selected,
            variant: variant,
            presentation: data['presentation'] == 'chips'
                ? AuraChoicePickerPresentation.chips
                : AuraChoicePickerPresentation.list,
            label: label == null ? null : AuraText(child: Text(label)),
            maxAllowedSelections: data['maxSelections'] as int?,
            onChanged: (next) => _updateData(
              context,
              path,
              variant == AuraChoicePickerVariant.mutuallyExclusive
                  ? next.firstOrNull
                  : next,
            ),
          ),
        );
      },
    ),
  );
}

Widget _tabs(CatalogItemContext context) {
  final data = _data(context);
  final tabs = data['tabs'];
  if (tabs is Map<Object?, Object?>) {
    return _templateTabs(context, data, tabs);
  }
  if (tabs is! List || tabs.isEmpty) return const SizedBox.shrink();
  return _literalTabs(context, data, tabs);
}

Widget _templateTabs(
  CatalogItemContext context,
  Map<String, Object?> data,
  Map<Object?, Object?> tabs,
) {
  final template = _findTabTemplate(context, tabs);
  if (template == null) return const SizedBox.shrink();
  final content = template.properties['content']! as String;
  final label = template.properties['label'];
  final activeTab = data['activeTab'];
  return BoundNumber(
    dataContext: context.dataContext,
    value: activeTab,
    builder: (_, active) => BoundObject(
      dataContext: context.dataContext,
      value: tabs,
      builder: (_, resolved) => _buildTemplateTabs(
        context,
        tabs,
        activeTab,
        active,
        content,
        label,
        resolved,
      ),
    ),
  );
}

Component? _findTabTemplate(
  CatalogItemContext context,
  Map<Object?, Object?> tabs,
) {
  final templateId = tabs['componentId'];
  if (templateId is! String) return null;
  final template = context.getComponent(templateId);
  if (template == null) return null;
  if (template.type != 'Tab') return null;
  if (template.properties['content'] is! String) return null;
  if (template.properties['label'] == null) return null;
  return template;
}

Widget _buildTemplateTabs(
  CatalogItemContext context,
  Map<Object?, Object?> tabs,
  Object? activeTab,
  num? active,
  String content,
  Object? label,
  Object? resolved,
) {
  final values = _tabValues(resolved);
  final keys = _tabKeys(resolved, values.length);
  final path = _path(tabs, '');
  return AuraTabs<void>(
    selectedIndex: active?.toInt(),
    items: [
      for (var index = 0; index < values.length; index++)
        AuraTabItem(
          title: BoundString(
            dataContext: context.dataContext.nested(
              DataPath('$path/${keys[index]}'),
            ),
            value: label,
            builder: (_, value) => AuraText(child: Text(value ?? '')),
          ),
          child: context.buildChild(
            content,
            context.dataContext.nested(DataPath('$path/${keys[index]}')),
          ),
        ),
    ],
    onChanged: (next) => _updateTemplateTabData(context, activeTab, next),
  );
}

List<Object?> _tabValues(Object? resolved) {
  if (resolved is List) return resolved.cast<Object?>();
  if (resolved is Map) return resolved.values.cast<Object?>().toList();
  return const <Object?>[];
}

List<String> _tabKeys(Object? resolved, int length) {
  if (resolved is Map) {
    return resolved.keys.map((key) => '$key').toList();
  }
  return List.generate(length, (index) => '$index');
}

void _updateTemplateTabData(
  CatalogItemContext context,
  Object? activeTab,
  int next,
) {
  if (activeTab is! Map<Object?, Object?>) return;
  _updateData(context, _path(activeTab, '/activeTab'), next);
}

Widget _literalTabs(
  CatalogItemContext context,
  Map<String, Object?> data,
  List tabs,
) {
  final items = [
    for (final tab in tabs.whereType<Map<Object?, Object?>>())
      AuraTabItem(
        title: BoundString(
          dataContext: context.dataContext,
          value: tab['label'],
          builder: (_, label) => AuraText(child: Text(label ?? '')),
        ),
        child: context.buildChild(_string(tab['content'])),
      ),
  ];
  final activeTab = data['activeTab'];
  if (activeTab is! Map<Object?, Object?>) {
    return AuraTabs<void>(
      items: items,
      initialIndex: (activeTab as num?)?.toInt() ?? 0,
    );
  }
  final activePath = _path(activeTab, '/activeTab');

  return BoundNumber(
    dataContext: context.dataContext,
    value: activeTab,
    builder: (_, active) => AuraTabs<void>(
      selectedIndex: active?.toInt(),
      items: items,
      onChanged: (next) =>
          context.dataContext.update(DataPath(activePath), next),
    ),
  );
}

Widget _modal(CatalogItemContext context) {
  final data = _data(context);

  return BoundString(
    dataContext: context.dataContext,
    value: data['title'],
    builder: (_, title) => BoundString(
      dataContext: context.dataContext,
      value: data['closeLabel'],
      builder: (_, closeLabel) => AuraModal(
        entryPointChild: context.buildChild(_string(data['trigger'])),
        contentChild: context.buildChild(_string(data['content'])),
        barrierLabel: MaterialLocalizations.of(context.buildContext)
            .modalBarrierDismissLabel,
        title: title == null ? null : AuraText(child: Text(title)),
        closeLabel: closeLabel,
        size: switch (data['size']) {
          'small' => AuraModalSize.small,
          'large' => AuraModalSize.large,
          _ => AuraModalSize.medium,
        },
      ),
    ),
  );
}

extension on Iterable<AvailableIcons> {
  AvailableIcons? get firstOrNull => isEmpty ? null : first;
}

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
