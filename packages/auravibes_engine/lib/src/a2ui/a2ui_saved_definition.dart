import 'dart:convert';

import 'package:auravibes_engine/src/a2ui/a2ui_chat_contract.dart';

/// Persistable host-catalog surface without external effects or model access.
class A2uiSavedDefinition {
  new _(this.components);

  factory fromJson(
    Map<String, Object?> value, {
    bool requiresUserAction = false,
  }) {
    _checkVersion(value);
    final components = _components(value['components']);
    _checkCatalog(components, requiresUserAction: requiresUserAction);
    _checkGraph(components);

    return A2uiSavedDefinition._(List.unmodifiable(components));
  }

  final List<Map<String, Object?>> components;

  A2uiSavedDefinition applyPatch({
    Iterable<Map<String, Object?>>? updateComponents,
    Iterable<String>? removeComponentIds,
    bool requiresUserAction = false,
  }) {
    final removed = removeComponentIds?.toSet() ?? const <String>{};
    if (removed.any((id) => id.isEmpty)) _invalid();
    final updatedById = <String, Map<String, Object?>>{};
    for (final component
        in updateComponents ?? const <Map<String, Object?>>[]) {
      final id = component['id'];
      if (id is! String || id.isEmpty || updatedById.containsKey(id)) {
        _invalid();
      }
      updatedById[id] = component;
    }
    final next = <Map<String, Object?>>[
      for (final existing in components)
        if (!removed.contains(existing['id']))
          updatedById.remove(existing['id']! as String) ?? existing,
      for (final added in updatedById.entries)
        if (!removed.contains(added.key)) added.value,
    ];

    return A2uiSavedDefinition.fromJson({
      'version': 1,
      'components': next,
    }, requiresUserAction: requiresUserAction);
  }

  Map<String, Object?> toJson() => {'version': 1, 'components': components};
}

const savedSurfaceExcludedComponents = <String>{
  'Image',
  'Avatar',
  'AvatarGroup',
  'Link',
  'SkillSuggestion',
};

const _maximumComponents = 100;
const _maximumBytes = 65536;
const _maximumDepth = 24;
const _forbiddenKeys = {
  'action',
  'actions',
  'onSubmittedAction',
  'href',
  'url',
  'expression',
  'javascript',
  'script',
  'sql',
  'endpoint',
  'destination',
  'sendDataModel',
  'native',
};

void _checkVersion(Map<String, Object?> value) {
  if (value.length != 2 || value['version'] != 1) _invalid();
  if (utf8.encode(jsonEncode(value)).length > _maximumBytes) _invalid();
}

List<Map<String, Object?>> _components(Object? value) {
  if (value is! List || value.isEmpty || value.length > _maximumComponents) {
    _invalid();
  }
  _validateSavedValue(value, 0);

  return value.map(_component).toList(growable: false);
}

Map<String, Object?> _component(Object? value) {
  if (value is! Map<String, Object?>) _invalid();
  final type = value['component'];
  if (!supportedA2uiChatComponents.contains(type) ||
      savedSurfaceExcludedComponents.contains(type)) {
    _invalid();
  }

  return _freezeMap(value);
}

void _checkCatalog(
  List<Map<String, Object?>> components, {
  required bool requiresUserAction,
}) {
  final interactionMode = requiresUserAction ? 'requiresUserAction' : 'passive';
  final issue = A2uiChatContract.validateInitialSurface({
    'surfaceId': 'view',
    'catalogId': requiresUserAction ? a2uiChatFormCatalogId : a2uiChatCatalogId,
    'components': components,
    'dataModel': <String, Object?>{},
  }, interactionMode: interactionMode);
  if (issue != null) _invalid();
}

void _checkGraph(List<Map<String, Object?>> components) {
  final graph = {
    for (final component in components) component['id']! as String: component,
  };
  if (!A2uiChatContract.isRenderableComponentGraph(graph)) _invalid();
}

void _validateSavedValue(Object? value, int depth) {
  if (depth > _maximumDepth) _invalid();
  if (value is Map) {
    _validateMap(value, depth);

    return;
  }
  if (value is List) {
    for (final item in value) {
      _validateSavedValue(item, depth + 1);
    }

    return;
  }
  if (!_scalar(value)) _invalid();
}

void _validateMap(Map<Object?, Object?> value, int depth) {
  for (final entry in value.entries) {
    if (entry.key is! String || _forbiddenKeys.contains(entry.key)) _invalid();
    _validateSavedValue(entry.value, depth + 1);
  }
}

bool _scalar(Object? value) =>
    value == null || value is String || value is num || value is bool;

Object? _freeze(Object? value) => switch (value) {
  final Map<String, Object?> object => _freezeMap(object),
  final List<dynamic> list => List<Object?>.unmodifiable(list.map(_freeze)),
  _ => value,
};
Map<String, Object?> _freezeMap(Map<String, Object?> value) =>
    Map<String, Object?>.unmodifiable(
      value.map((key, value) => MapEntry(key, _freeze(value))),
    );

Never _invalid() => throw const FormatException('Invalid saved surface');
