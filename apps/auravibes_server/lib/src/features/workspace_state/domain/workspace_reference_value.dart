abstract final class WorkspaceReferenceValue {
  static bool valid(Map<String, Object?> column, Object? value) =>
      column['referenceMultiple'] == true
      ? value is List &&
            value.toSet().length == value.length &&
            value.every(_id)
      : _id(value);

  static bool schema(Map<dynamic, dynamic> column) =>
      column['type'] == 'reference'
      ? _id(column['targetTableId']) &&
            (column['referenceMultiple'] == null ||
                column['referenceMultiple'] is bool)
      : column['targetTableId'] == null && column['referenceMultiple'] != true;

  static bool _id(Object? value) =>
      value is String && value.isNotEmpty && value.length <= 200;
}
