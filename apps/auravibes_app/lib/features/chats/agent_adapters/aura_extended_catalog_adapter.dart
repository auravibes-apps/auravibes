// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_form_scope.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adds domain-neutral Aura components implemented by the chat feature.
List<CatalogItem> auraExtendedCatalogItems({
  required IconData Function(String?) resolveIcon,
}) => [
  for (final entry in _builders(resolveIcon).entries)
    CatalogItem(
      name: entry.key,
      dataSchema: Schema.fromMap({
        ...a2uiChatComponentSchemas[entry.key]!,
        'required': [
          for (final property
              in a2uiChatComponentSchemas[entry.key]!['required']! as List)
            if (property != 'id') property,
        ],
      }),
      widgetBuilder: (context) => entry.value(context, _data(context)),
      exampleData: [
        () => jsonEncode([a2uiChatComponentExamples[entry.key]]),
      ],
    ),
];

typedef _Builder = Widget Function(
  CatalogItemContext context,
  Map<String, Object?> data,
);

Map<String, _Builder> _builders(IconData Function(String?) icon) => {
  'Form': (context, data) => context.buildChild(_string(data['child'])),
  'Fieldset': (context, data) => AuraFieldset(
    title: _string(data['legend']),
    description: _nullableString(data['description']),
    child: context.buildChild(_string(data['child'])),
  ),
  'Alert': (_, data) => AuraCallout(
    title: _string(data['title']),
    description: _nullableString(data['description']),
    icon: _resolveIcon(icon, data['icon']),
    tint: _tone(data['tone']),
  ),
  'Stat': (_, data) => AuraStat(
    value: _string(data['value']),
    label: _string(data['label']),
    delta: _nullableString(data['delta']),
    icon: _resolveIcon(icon, data['icon']),
    tint: _tone(data['tone']),
  ),
  'Link': (_, data) => AuraLink(
    label: _string(data['label']),
    semanticLabel: _nullableString(data['semanticLabel']),
    onPressed: switch (_httpsUri(data['href'])) {
      final uri? => () => unawaited(
        launchUrl(uri, mode: LaunchMode.externalApplication),
      ),
      null => null,
    },
  ),
  'Tooltip': (context, data) => AuraTooltip(
    message: _string(data['message']),
    child: context.buildChild(_string(data['child'])),
  ),
  'Accordion': (context, data) => AuraAccordion(
    initiallyExpanded: {
      for (final index in _asList(data['expanded']))
        if (index is int) index,
    },
    items: [
      for (final item in _asList(data['items']))
        if (item is Map)
          AuraAccordionItem(
            title: _string(item['title']),
            child: context.buildChild(_string(item['content'])),
          ),
    ],
  ),
  'Stepper': (_, data) => AuraStepper(
    steps: [
      for (final value in _asList(data['steps']))
        if (value is Map)
          AuraStep(
            title: _string(value['title']),
            description: _nullableString(value['description']),
            state: AuraStepState.values.byName(_asStringOr(value['state'])),
          ),
    ],
  ),
  'Timeline': (_, data) => AuraTimeline(
    entries: [
      for (final value in _asList(data['entries']))
        if (value is Map)
          AuraTimelineEntry(
            title: _string(value['title']),
            description: _nullableString(value['description']),
            time: _nullableString(value['time']),
            tint: _tone(value['tone']),
          ),
    ],
  ),
  'Skeleton': (_, data) => AuraSkeleton(
    width: _asDouble(data['width']),
    height: _asDoubleOr(data['height'], 16),
    circular: data['shape'] == 'circle',
    semanticLabel: _nullableString(data['label']),
  ),
  'Grid': (context, data) => _children(
    context,
    data['children'],
    (children) => AuraGrid(
      minimumItemWidth: _asDoubleOr(data['minimumItemWidth'], 220),
      spacing: _gap(context, data['gap']),
      children: children,
    ),
  ),
  'Wrap': (context, data) => _children(
    context,
    data['children'],
    (children) =>
        AuraWrap(spacing: _gap(context, data['gap']), children: children),
  ),
  'Spacer': (_, data) =>
      AuraSpacer(size: _asDouble(data['size']), flex: _asIntOr(data['flex'])),
  'FlexItem': (context, data) => AuraFlexItem(
    flex: _asIntOr(data['flex']),
    fit: _flexFit(data['fit']),
    child: context.buildChild(_string(data['child'])),
  ),
  'Rating': (context, data) => _fieldScope(
    data,
    BoundNumber(
      dataContext: context.dataContext,
      value: data['value'],
      builder: (_, value) {
        final path = _path(data['value'], '/${context.id}');
        return AuraRating(
          value: _asNumIntOr(value),
          max: _asIntOr(data['max'], 5),
          label: _nullableString(data['label']),
          onChanged: (next) => _updateData(context, path, next),
        );
      },
    ),
  ),
  'TagInput': (context, data) => _fieldScope(
    data,
    BoundObject(
      dataContext: context.dataContext,
      value: data['value'],
      builder: (_, value) {
        final path = _path(data['value'], '/${context.id}');
        return AuraTagInput(
          value: _stringList(value),
          removeLabel: (tag) => LocaleKeys
              .chats_screens_chat_conversation_remove_tag
              .tr(context: context.buildContext, namedArgs: {'tag': tag}),
          label: _nullableString(data['label']),
          placeholder: _nullableString(data['placeholder']),
          maxTags: data['maxSelections'] as int?,
          onChanged: (next) => _updateData(context, path, next),
        );
      },
    ),
  ),
  'CodeBlock': (_, data) => AuraCodeBlock(
    code: _string(data['code']),
    language: _nullableString(data['language']),
    semanticLabel: _nullableString(data['label']),
  ),
  'KeyValue': (_, data) => AuraKeyValue(
    entries: [
      for (final value in _asList(data['entries']))
        if (value is Map)
          AuraKeyValueEntry(
            label: _string(value['label']),
            value: _string(value['value']),
          ),
    ],
  ),
  'Section': (context, data) => AuraSection(
    title: _string(data['title']),
    description: _nullableString(data['description']),
    child: context.buildChild(_string(data['child'])),
  ),
  // A Tab is rendered by the Tabs template owner, never independently.
  'Tab': (_, _) => const SizedBox.shrink(),
};

Map<String, Object?> _data(CatalogItemContext context) =>
    Map<String, Object?>.from(context.data as Map<Object?, Object?>);

IconData? _resolveIcon(IconData Function(String?) icon, Object? value) =>
    value is String ? icon(value) : null;

List _asList(Object? value) => value as List? ?? const <Object?>[];

String _asStringOr(Object? value, [String fallback = 'pending']) =>
    value as String? ?? fallback;

double? _asDouble(Object? value) => (value as num?)?.toDouble();

double _asDoubleOr(Object? value, [double fallback = 0]) =>
    _asDouble(value) ?? fallback;

int _asIntOr(Object? value, [int fallback = 1]) => value as int? ?? fallback;

int _asNumIntOr(Object? value, [int fallback = 0]) =>
    (value as num?)?.toInt() ?? fallback;

List<String> _stringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

FlexFit _flexFit(Object? value) =>
    value == 'tight' ? FlexFit.tight : FlexFit.loose;

String _string(Object? value) => value is String ? value : '';

String? _nullableString(Object? value) => value is String ? value : null;

String _path(Object? value, String fallback) =>
    value is Map<Object?, Object?> && value['path'] is String
    ? value['path']! as String
    : fallback;

void _updateData(CatalogItemContext context, String path, Object value) {
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

AuraTint _tone(Object? value) =>
    AuraTint.values.byName(value as String? ?? 'primary');

Uri? _httpsUri(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

double? _gap(CatalogItemContext context, Object? value) => switch (value) {
  'none' => context.buildContext.auraTheme.spacing.none,
  'xs' => context.buildContext.auraTheme.spacing.xs,
  'sm' => context.buildContext.auraTheme.spacing.sm,
  'md' => context.buildContext.auraTheme.spacing.md,
  'lg' => context.buildContext.auraTheme.spacing.lg,
  'xl' => context.buildContext.auraTheme.spacing.xl,
  _ => null,
};

Widget _children(
  CatalogItemContext context,
  Object? children,
  Widget Function(List<Widget>) build,
) => ComponentChildrenBuilder(
  childrenData: children,
  dataContext: context.dataContext,
  buildChild: context.buildChild,
  getComponent: context.getComponent,
  explicitListBuilder: (ids, buildChild, _, dataContext) =>
      build([for (final id in ids) buildChild(id, dataContext)]),
  templateListWidgetBuilder: (buildContext, data, componentId, binding) {
    final list = data is List ? data : null;
    final map = data is Map<Object?, Object?> ? data : null;
    if (list == null && map == null) return const SizedBox.shrink();
    final values = list ?? map!.values.toList();
    final keys = list == null
        ? map!.keys.map((key) => '$key').toList()
        : List.generate(values.length, (index) => '$index');
    return build([
      for (var index = 0; index < values.length; index++)
        KeyedSubtree(
          key: ValueKey(keys[index]),
          child: context.buildChild(
            componentId,
            context.dataContext.nested(DataPath('$binding/${keys[index]}')),
          ),
        ),
    ]);
  },
);
