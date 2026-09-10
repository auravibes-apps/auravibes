import 'dart:convert';

abstract final class ToolMetadataDecoder {
  static const _encoder = JsonEncoder.withIndent('  ');

  static String? decode(Object? metadata) {
    if (metadata == null) return null;

    final decoded = _decodeInput(metadata);
    if (decoded is _DecodeFailure) return decoded.value;

    return _decodeValue(decoded);
  }

  static Object? _decodeInput(Object metadata) {
    if (metadata is! String) return metadata;

    try {
      return jsonDecode(metadata);
    } on Exception catch (_) {
      return _DecodeFailure(metadata);
    }
  }

  static String? _decodeValue(Object? decoded) {
    if (decoded == null) return null;

    if (decoded is Map && decoded.length == 1) {
      return decode(decoded.values.first);
    }

    if (decoded is Map || decoded is List) return _encodeComplexValue(decoded);

    return decoded.toString();
  }

  static String _encodeComplexValue(Object value) {
    try {
      return _encoder.convert(value);
    } on Object {
      return value.toString();
    }
  }
}

class const _DecodeFailure(final String value);
