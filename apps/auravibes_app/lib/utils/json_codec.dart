import 'dart:convert';

abstract final class JsonCodec {
  static String? encode(Object? object) {
    if (object == null) return null;
    try {
      return jsonEncode(object);
    } on Object catch (_) {}

    return null;
  }

  static Map<String, dynamic>? decode(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) return decoded;
    } on Object catch (_) {}

    return null;
  }
}
