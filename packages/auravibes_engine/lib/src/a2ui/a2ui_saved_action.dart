import 'package:auravibes_engine/src/connector_command.dart';
import 'package:auravibes_engine/src/connectors/connector_definition.dart';
import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/connectors/execution/connector_request_execution.dart';

/// A persisted, declarative mapping from form input paths to one host action.
///
/// This contract carries no code, query, permission, or provider grant. The
/// host resolves the target again and applies its current authorization rules
/// when the user submits the form.
class A2uiSavedAction({
  required A2uiSavedActionType type,
  required Map<String, String> inputs,
  String? toolId,
  String? revision,
  String? connectionId,
}) {
  factory fromJson(Map<String, Object?> value) {
    final version = value['version'];
    final rawType = value['type'];
    if (version != 1 || rawType is! String) _invalid();
    final type = switch (rawType) {
      'updateSelectedRecord' => A2uiSavedActionType.updateSelectedRecord,
      'connectorWrite' => A2uiSavedActionType.connectorWrite,
      _ => null,
    };
    if (type == null) _invalid();

    final expectedKeys = switch (type) {
      A2uiSavedActionType.updateSelectedRecord => const {
        'version',
        'type',
        'inputs',
      },
      A2uiSavedActionType.connectorWrite => const {
        'version',
        'type',
        'toolId',
        'revision',
        'connectionId',
        'inputs',
      },
    };
    final requiredKeys = switch (type) {
      A2uiSavedActionType.updateSelectedRecord => const {
        'version',
        'type',
        'inputs',
      },
      A2uiSavedActionType.connectorWrite => const {
        'version',
        'type',
        'toolId',
        'revision',
        'inputs',
      },
    };
    if (value.keys.any((key) => !expectedKeys.contains(key)) ||
        !value.keys.toSet().containsAll(requiredKeys)) {
      _invalid();
    }

    final inputs = _inputs(value['inputs'], type);
    final toolId = value['toolId'];
    final revision = value['revision'];
    final connectionId = value['connectionId'];
    if (type == A2uiSavedActionType.connectorWrite) {
      if (toolId is! String ||
          toolId.isEmpty ||
          toolId.length > 200 ||
          !toolId.startsWith('connector/') ||
          revision is! String ||
          revision.isEmpty ||
          revision.length > 200 ||
          connectionId != null &&
              (connectionId is! String ||
                  connectionId.isEmpty ||
                  connectionId.length > 200)) {
        _invalid();
      }
    } else if (toolId != null || revision != null || connectionId != null) {
      _invalid();
    }

    return A2uiSavedAction(
      type: type,
      inputs: inputs,
      toolId: toolId as String?,
      revision: revision as String?,
      connectionId: connectionId as String?,
    );
  }

  final A2uiSavedActionType type = type;

  /// Maps target field IDs or Connector argument names to JSON Pointer paths.
  final Map<String, String> inputs = Map.unmodifiable(
    _validatedInputs(inputs, type, toolId, revision, connectionId),
  );
  final String? toolId = toolId;
  final String? revision = revision;
  final String? connectionId = connectionId;

  Map<String, Object?> toJson() => {
    'version': 1,
    'type': type.name,
    if (toolId != null) 'toolId': toolId,
    if (revision != null) 'revision': revision,
    if (connectionId != null) 'connectionId': connectionId,
    'inputs': inputs,
  };
}

enum A2uiSavedActionType { updateSelectedRecord, connectorWrite }

/// Ensures a saved action reads only declared form controls in the surface.
void validateA2uiSavedActionInputs(
  A2uiSavedAction action,
  Iterable<Map<String, Object?>> components,
) {
  final paths = <String>{};
  for (final component in components) {
    if (!_savedFormInputs.contains(component['component'])) continue;
    final value = component['value'];
    if (value is! Map || value['path'] is! String) continue;
    final path = value['path']! as String;
    if (_validPath(path)) paths.add(path);
  }
  if (!action.inputs.values.every(paths.contains)) _invalid();
}

/// Maps form values to the action's named targets without accepting extra data.
Map<String, Object?> a2uiSavedActionInputs(
  A2uiSavedAction action,
  Map<String, Object?> formValues,
) {
  final result = <String, Object?>{};
  for (final entry in action.inputs.entries) {
    final value = _atPath(formValues, entry.value);
    if (!identical(value, _missing) && value != null) {
      result[entry.key] = value;
    }
  }
  if (result.isEmpty) _invalid();
  return Map.unmodifiable(result);
}

/// Resolves and validates a Connector target without granting access to it.
void validateA2uiSavedActionConnector(
  A2uiSavedAction action,
  Iterable<ConnectorDefinition> connectors,
) {
  if (action.type != A2uiSavedActionType.connectorWrite) return;
  final toolId = action.toolId;
  final revision = action.revision;
  ConnectorDefinition? connector;
  ConnectorToolDefinition? tool;
  for (final candidate in connectors) {
    for (final candidateTool in candidate.tools) {
      if (connectorToolId(candidate, candidateTool) != toolId) continue;
      connector = candidate;
      tool = candidateTool;
    }
  }
  if (connector == null ||
      tool == null ||
      tool.urlTemplate == null ||
      !connectorToolWrites(tool) ||
      connectorToolRevision(connector, tool) != revision) {
    _invalid();
  }
  final properties = tool.inputJsonSchema['properties'];
  if (properties is! Map ||
      action.inputs.keys.any((key) => !properties.containsKey(key))) {
    _invalid();
  }
  final required = tool.inputJsonSchema['required'];
  if (required is! List ||
      required.any((key) => key is! String) ||
      !action.inputs.keys.toSet().containsAll(required.cast<String>())) {
    _invalid();
  }
  if (!tool.requiresConnection && action.connectionId != null) _invalid();
}

const _savedFormInputs = {
  'CheckBox',
  'ChoicePicker',
  'DateTimeInput',
  'Rating',
  'Slider',
  'TagInput',
  'TextField',
};

Map<String, String> _inputs(Object? value, A2uiSavedActionType type) {
  if (value is! Map || value.isEmpty || value.length > 50) _invalid();
  final result = <String, String>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! String) _invalid();
    final target = entry.key! as String;
    final path = entry.value! as String;
    if (!_validTarget(target, type) || !_validPath(path)) _invalid();
    result[target] = path;
  }
  return result;
}

Map<String, String> _validatedInputs(
  Map<String, String> inputs,
  A2uiSavedActionType type,
  String? toolId,
  String? revision,
  String? connectionId,
) {
  final validated = _inputs(inputs, type);
  if (type == A2uiSavedActionType.connectorWrite) {
    if (toolId == null ||
        toolId.isEmpty ||
        toolId.length > 200 ||
        !toolId.startsWith('connector/') ||
        revision == null ||
        revision.isEmpty ||
        revision.length > 200 ||
        connectionId != null &&
            (connectionId.isEmpty || connectionId.length > 200)) {
      _invalid();
    }
  } else if (toolId != null || revision != null || connectionId != null) {
    _invalid();
  }

  return validated;
}

bool _validTarget(String value, A2uiSavedActionType type) => switch (type) {
  A2uiSavedActionType.updateSelectedRecord => RegExp(
    r'^[A-Za-z0-9_-]{1,100}$',
  ).hasMatch(value),
  A2uiSavedActionType.connectorWrite => RegExp(
    r'^[A-Za-z_][A-Za-z0-9_]{0,63}$',
  ).hasMatch(value),
};

bool _validPath(String value) {
  if (value.length > 512 || !value.startsWith('/')) return false;
  final segments = value.substring(1).split('/');
  return segments.length <= 16 &&
      segments.every((segment) => segment.isNotEmpty) &&
      !RegExp('~(?![01])').hasMatch(value);
}

Object? _atPath(Map<String, Object?> values, String path) {
  Object? current = values;
  for (final segment in path.substring(1).split('/')) {
    final key = _unescape(segment);
    if (current is! Map || !current.containsKey(key)) return _missing;
    current = current[key];
  }
  return current;
}

String _unescape(String value) =>
    value.replaceAll('~1', '/').replaceAll('~0', '~');

const Object _missing = Object();

Never _invalid() => throw const FormatException('Invalid saved host action');
