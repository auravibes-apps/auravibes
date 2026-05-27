// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';

String? safeJsonEncode(Object? object) {
  if (object == null) return null;
  try {
    return jsonEncode(object);
  } on Object catch (_) {}
  return null;
}

Map<String, dynamic>? safeJsonDecode(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
  } on Object catch (_) {}
  return null;
}
