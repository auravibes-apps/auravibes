const _maximumIdLength = 200;

abstract final class WorkspaceReferenceValue {
  static bool valid(Map<String, Object?> column, Object? value) =>
      column['referenceMultiple'] == true
      ? value is List &&
            value.toSet().length == value.length &&
            value.every(_id)
      : _id(value);

  static bool schema(Map<dynamic, dynamic> column) =>
      column['type'] == 'reference'
      ? _dependency(column) &&
            _id(column['targetTableId']) &&
            (column['referenceMultiple'] == null ||
                column['referenceMultiple'] is bool)
      : column['targetTableId'] == null &&
            column['referenceMultiple'] != true &&
            column['dependsOnColumnId'] == null &&
            column['targetMatchColumnId'] == null;

  static bool _id(Object? value) =>
      value is String && value.isNotEmpty && value.length <= _maximumIdLength;
}

bool _dependency(Map column) {
  final parent = column['dependsOnColumnId'];
  final match = column['targetMatchColumnId'];
  if (parent == null && match == null) return true;

  return parent is String &&
      parent.isNotEmpty &&
      parent.length <= _maximumIdLength &&
      match is String &&
      match.isNotEmpty &&
      match.length <= _maximumIdLength;
}
