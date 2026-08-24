import 'dart:convert';

abstract final class ToolMetadataDecoder {
  static const _encoder = JsonEncoder.withIndent('  ');

  static String? decode(Object? metadata) {
    if (metadata == null) return null;

    Object? decoded;
    try {
      decoded = metadata is String ? jsonDecode(metadata) : metadata;
    } on Exception catch (_) {
      return metadata.toString();
    }

    if (decoded == null) return null;

    if (decoded is Map && decoded.length == 1) {
      return decode(decoded.values.first);
    }

    if (decoded is Map || decoded is List) {
      try {
        return _encoder.convert(decoded);
      } on Object {
        return decoded.toString();
      }
    }

    return decoded.toString();
  }
}
