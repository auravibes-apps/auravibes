import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';

import '../../generated/protocol.dart';

typedef WorkspaceViewInput = ({
  Map<String, Object?> data,
  Map<String, String> bindings,
  Map<String, String> columnTypes,
  String tableId,
  String? parentId,
});
const _maximumSource = 131072;
const _maximumName = 200;
const _maximumId = 100;
const _maximumBindings = 50;
const _keys = {
  'id',
  'name',
  'tableId',
  'parentId',
  'bindings',
  'columnTypes',
  'definition',
  'revision',
};
final _bindingPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,63}$');

abstract final class WorkspaceViewValidation {
  static void requestId(String value) {
    if (value.isEmpty || value.length > _maximumId) _invalid();
  }

  static WorkspaceViewInput parse(String source, String id) {
    try {
      return _parse(source, id);
    } on FormatException {
      _invalid();
    } on TypeError {
      _invalid();
    }
  }

  static void columns(WorkspaceViewInput input, List<dynamic> columns) {
    if (input.columnTypes.length != input.bindings.values.toSet().length) {
      _invalid();
    }
    for (final id in input.bindings.values) {
      if (!_columnMatches(input, id, columns)) _invalid();
    }
  }
}

WorkspaceViewInput _parse(String source, String id) {
  _checkSize(source, id);
  final data = Map<String, Object?>.from(jsonDecode(source) as Map);
  _checkIdentity(data, id);
  _checkName(data['name'] as String);
  _checkDefinition(data['definition']);

  return _input(data);
}

WorkspaceViewInput _input(Map<String, Object?> data) => (
  data: data,
  bindings: _bindings(data['bindings']),
  columnTypes: _types(data['columnTypes']),
  tableId: data['tableId'] as String,
  parentId: data['parentId'] as String?,
);
void _checkSize(String source, String id) {
  if (source.length > _maximumSource || id.isEmpty || id.length > _maximumId) {
    _invalid();
  }
}

void _checkIdentity(Map<String, Object?> data, String id) {
  if (data.keys.any((key) => !_keys.contains(key)) || data['id'] != id) {
    _invalid();
  }
}

void _checkName(String name) {
  if (name.trim().isEmpty || name.length > _maximumName) _invalid();
}

void _checkDefinition(Object? value) {
  final _ = A2uiSavedDefinition.fromJson(
    Map<String, Object?>.from(value as Map),
  );
}

Map<String, String> _bindings(Object? value) {
  final bindings = _types(value);
  if (bindings.isEmpty || bindings.length > _maximumBindings) _invalid();
  if (!bindings.keys.every(_bindingName)) _invalid();

  return bindings;
}

Map<String, String> _types(Object? value) =>
    Map<String, String>.from(value as Map);
bool _bindingName(String name) =>
    _bindingPattern.hasMatch(name) && name != 'columns' && name != 'rows';
bool _columnMatches(
  WorkspaceViewInput input,
  String id,
  List<dynamic> columns,
) {
  final column = columns
      .cast<Map>()
      .where((column) => column['id'] == id)
      .firstOrNull;

  return column != null && column['type'] == input.columnTypes[id];
}

Never _invalid() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.validationFailed,
);
