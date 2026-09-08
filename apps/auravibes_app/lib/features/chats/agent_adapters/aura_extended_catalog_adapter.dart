// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/chat_catalog_children.dart';
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
    icon: data['icon'] is String ? icon(data['icon'] as String) : null,
    tint: _tone(data['tone']),
  ),
  'Stat': (_, data) => AuraStat(
    value: _string(data['value']),
    label: _string(data['label']),
    delta: _nullableString(data['delta']),
    icon: data['icon'] is String ? icon(data['icon'] as String) : null,
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
      for (final index in (data['expanded'] as List? ?? const <Object?>[]))
        if (index is int) index,
    },
    items: [
      for (final item in (data['items'] as List? ?? const <Object?>[]))
        if (item is Map)
          AuraAccordionItem(
            title: _string(item['title']),
            child: context.buildChild(_string(item['content'])),
          ),
    ],
  ),
  'Stepper': (_, data) => AuraStepper(
    steps: [
      for (final value in (data['steps'] as List? ?? const <Object?>[]))
        if (value is Map)
          AuraStep(
            title: _string(value['title']),
            description: _nullableString(value['description']),
            state: AuraStepState.values.byName(
              value['state'] as String? ?? 'pending',
            ),
          ),
    ],
  ),
  'Timeline': (_, data) => AuraTimeline(
    entries: [
      for (final value in (data['entries'] as List? ?? const <Object?>[]))
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
    width: (data['width'] as num?)?.toDouble(),
    height: (data['height'] as num?)?.toDouble() ?? 16,
    circular: data['shape'] == 'circle',
    semanticLabel: _nullableString(data['label']),
  ),
  'Grid': (context, data) => buildChatCatalogChildren(
    context,
    data['children'],
    (children) => AuraGrid(
      minimumItemWidth: (data['minimumItemWidth'] as num?)?.toDouble() ?? 220,
      spacing: _gap(context, data['gap']),
      children: children,
    ),
  ),
  'Wrap': (context, data) => buildChatCatalogChildren(
    context,
    data['children'],
    (children) =>
        AuraWrap(spacing: _gap(context, data['gap']), children: children),
  ),
  'Spacer': (_, data) => AuraSpacer(
    size: (data['size'] as num?)?.toDouble(),
    flex: data['flex'] as int? ?? 1,
  ),
  'FlexItem': (context, data) => AuraFlexItem(
    flex: data['flex'] as int? ?? 1,
    fit: data['fit'] == 'tight' ? .tight : .loose,
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
          value: (value ?? 0).toInt(),
          max: data['max'] as int? ?? 5,
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
          value: value is List ? value.whereType<String>().toList() : const [],
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
      for (final value in (data['entries'] as List? ?? const <Object?>[]))
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
