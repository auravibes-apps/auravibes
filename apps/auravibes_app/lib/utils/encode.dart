import 'dart:convert';

String? safeJsonEncode(Object? object) {
  if (object == null) return null;
  try {
    return jsonEncode(object);
  } on Exception catch (_) {}
  return null;
}

Map<String, dynamic>? safeJsonDecode(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
  } on Object catch (_) {}
  return null;
}
