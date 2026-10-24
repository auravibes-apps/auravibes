import 'dart:convert';

import 'a2ui_chat_contract.dart';

/// Persistable host-catalog surface without external effects or model access.
class A2uiSavedDefinition {
  A2uiSavedDefinition._(this.components);

  factory A2uiSavedDefinition.fromJson(Map<String, Object?> value) {
    if (value.length != 2 || value['version'] != 1) {
      throw const FormatException('Unsupported surface definition');
    }
    final components = value['components'];
    if (components is! List || components.isEmpty || components.length > 100) {
      throw const FormatException('Invalid surface components');
    }
    _validateSavedValue(components, 0);
    final copied = components.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Invalid component');
      }
      if (!supportedA2uiChatComponents.contains(item['component']) ||
          _externalComponents.contains(item['component'])) {
        throw const FormatException('Unsupported saved component');
      }
      return Map<String, Object?>.unmodifiable(item);
    }).toList(growable: false);
    final issue = A2uiChatContract.validateInitialSurface({
      'surfaceId': 'view',
      'catalogId': a2uiChatCatalogId,
      'components': copied,
      'dataModel': <String, Object?>{},
    }, interactionMode: 'passive');
    if (issue != null || utf8.encode(jsonEncode(value)).length > 65536) {
      throw const FormatException('Invalid saved surface');
    }
    return A2uiSavedDefinition._(List.unmodifiable(copied));
  }

  final List<Map<String, Object?>> components;

  Map<String, Object?> toJson() => {'version': 1, 'components': components};
}

const _externalComponents = {'Image', 'Avatar', 'AvatarGroup', 'Link', 'SkillSuggestion'};
const _forbiddenKeys = {
  'action', 'actions', 'href', 'url', 'expression', 'javascript', 'script',
  'sql', 'endpoint', 'destination', 'sendDataModel', 'native',
};

void _validateSavedValue(Object? value, int depth) {
  if (depth > 24) throw const FormatException('Surface nesting limit');
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key is! String || _forbiddenKeys.contains(entry.key)) {
        throw const FormatException('External surface effect');
      }
      _validateSavedValue(entry.value, depth + 1);
    }
  } else if (value is List) {
    for (final item in value) {
      _validateSavedValue(item, depth + 1);
    }
  } else if (value != null && value is! String && value is! num && value is! bool) {
    throw const FormatException('Invalid surface value');
  }
}
