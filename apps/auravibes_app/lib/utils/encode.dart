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
    return jsonDecode(source) as Map<String, dynamic>;
  } on Exception catch (_) {}
  return null;
}
