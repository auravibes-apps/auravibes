import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_query_filter_validation.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_connected_validation.dart';
import 'package:auravibes_server/src/generated/protocol.dart';

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
const _maximumPageSize = 100;
const _maximumSearchLength = 200;
const _keys = {
  'id',
  'name',
  'tableId',
  'parentId',
  'bindings',
  'columnTypes',
  'definition',
  'revision',
  'query',
  'summaryColumnIds',
  'connected',
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
    } on AgentToolExecutionFailure {
      _invalid();
    }
  }

  static void columns(WorkspaceViewInput input, List<dynamic> columns) {
    final dependencies = _dependencies(input);
    if (input.columnTypes.length != dependencies.length) {
      _invalid();
    }
    _queryColumns(input, columns);
    for (final id in dependencies) {
      if (!_columnMatches(input, id, columns)) _invalid();
    }
  }
}

WorkspaceViewInput _parse(String source, String id) {
  _checkSize(source, id);
  final data = Map<String, Object?>.from(jsonDecode(source) as Map);
  _checkIdentity(data, id);
  _checkContent(data);
  _checkConnected(data);

  return _input(data);
}

void _checkContent(Map<String, Object?> data) {
  _checkName(data['name'] as String);
  _checkDefinition(data['definition']);
  _checkQuery(data['query']);
  _checkSummary(data['summaryColumnIds']);
}

void _checkConnected(Map<String, Object?> data) {
  if (data['connected'] != null) {
    WorkspaceConnectedValidation.arguments(data['connected']);
  }
  if (data['tableId'] != '') return;
  final bindings = _bindings(data['bindings'], connected: true);
  for (final path in bindings.values) {
    _checkPointer(path);
  }
}

void _checkPointer(String path) {
  if (path.length > 512 ||
      (path.isNotEmpty && !path.startsWith('/')) ||
      path.split('/').length > 16) {
    _invalid();
  }
}

WorkspaceViewInput _input(Map<String, Object?> data) => (
  data: data,
  bindings: _bindings(data['bindings'], connected: data['tableId'] == ''),
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

Map<String, String> _bindings(Object? value, {bool connected = false}) {
  final bindings = _types(value);
  if (bindings.isEmpty || bindings.length > _maximumBindings) _invalid();
  if (!bindings.keys.every(
    connected ? _bindingPattern.hasMatch : _bindingName,
  )) {
    _invalid();
  }

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

void _checkQuery(Object? value) {
  if (value == null) return;
  if (value is! Map || value.keys.any((key) => !_queryKeys.contains(key))) {
    _invalid();
  }
  _checkPage(value);
  _checkText(value);
  _checkOperands(value);
}

void _checkPage(Map<dynamic, dynamic> value) {
  final limit = value['limit'];
  if (limit is! int ||
      limit < 1 ||
      limit > _maximumPageSize ||
      value['offset'] != 0) {
    _invalid();
  }
}

void _checkText(Map<dynamic, dynamic> value) {
  final search = value['search'];
  if (search is! String ||
      search.length > _maximumSearchLength ||
      value['descending'] is! bool) {
    _invalid();
  }
}

void _checkOperands(Map<dynamic, dynamic> value) {
  if (!{'equals', 'contains'}.contains(value['filterOperator'])) _invalid();
  for (final key in ['filterColumnId', 'filterValue', 'sortColumnId']) {
    final operand = value[key];
    if (operand != null && operand is! String) _invalid();
  }
}

const _queryKeys = {
  'search',
  'filterColumnId',
  'filterValue',
  'filterOperator',
  'sortColumnId',
  'descending',
  'offset',
  'limit',
};
Set<String> _dependencies(WorkspaceViewInput input) => {
  ...input.bindings.values,
  ..._summaryColumns(input.data),
  ..._queryDependencies(input.data),
};
List<String> _summaryColumns(Map<String, Object?> data) =>
    (data['summaryColumnIds'] as List<dynamic>? ?? const []).cast<String>();
Set<String> _queryDependencies(Map<String, Object?> data) {
  final query = data['query'] as Map<dynamic, dynamic>? ?? const {};

  return {
    ?query['filterColumnId'] as String?,
    ?query['sortColumnId'] as String?,
  };
}

void _queryColumns(WorkspaceViewInput input, List<dynamic> columns) {
  final query = input.data['query'] as Map<dynamic, dynamic>?;
  if (query == null) return;
  _querySort(query, columns);
  _queryFilter(query, columns);
}

void _querySort(Map<dynamic, dynamic> query, List<dynamic> columns) {
  final sort = query['sortColumnId'] as String?;
  if (sort == null) return;
  final column = _queryColumn(columns, sort);
  if ({'reference', 'attachment', 'multiSelect'}.contains(column['type'])) {
    _invalid();
  }
}

void _queryFilter(Map<dynamic, dynamic> query, List<dynamic> columns) {
  final id = query['filterColumnId'] as String?;
  if (id == null) return;
  WorkspaceQueryFilterValidation.validate(
    _queryColumn(columns, id),
    query['filterValue'] as String? ?? '',
    operator: query['filterOperator'] as String,
  );
}

Map<String, dynamic> _queryColumn(List<dynamic> columns, String id) {
  final column = columns
      .cast<Map<String, dynamic>>()
      .where((column) => column['id'] == id)
      .firstOrNull;
  if (column == null) _invalid();

  return column;
}

void _checkSummary(Object? value) {
  if (value == null) return;
  if (value is! List ||
      value.length > _maximumBindings ||
      value.any((id) => id is! String)) {
    _invalid();
  }
  if (value.length != value.toSet().length) _invalid();
}
