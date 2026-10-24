/// Extract only authoritative attachment fields; arbitrary lists are not assets.
abstract final class ObjectAssetReferences {
  static Iterable<String> defaults(Map<String, dynamic> data) =>
      _columns(data).expand((column) => _ids(column['defaultValue']));

  static Iterable<String> record(
    Map<String, dynamic> schema,
    Map<String, dynamic> data,
  ) {
    final values = data['values'];
    if (values is! Map) return const [];
    return _columns(schema).expand((column) => _ids(values[column['id']]));
  }

  static Iterable<String> historicalRecord(Map<String, dynamic> data) {
    final columns = data['historyAttachmentColumns'];
    final values = data['values'];
    if (columns is! List || values is! Map) return const [];
    return columns.whereType<String>().expand((column) => _ids(values[column]));
  }
}

Iterable<Map> _columns(Map<String, dynamic> data) {
  final columns = data['columns'];
  if (columns is! List) return const [];
  return columns.whereType<Map>().where(
    (column) => column['type'] == 'attachment',
  );
}

Iterable<String> _ids(Object? value) =>
    value is List ? value.whereType<String>() : const [];
