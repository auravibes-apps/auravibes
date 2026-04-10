import 'dart:convert';

const JsonEncoder _toolMetadataEncoder = JsonEncoder.withIndent('  ');

String? tryDecodeToolMetadata(Object? metadata) {
  if (metadata == null) return null;

  dynamic decoded;
  try {
    decoded = metadata is String ? jsonDecode(metadata) : metadata;
  } on Exception catch (_) {
    return metadata.toString();
  }

  if (decoded == null) return null;

  if (decoded is Map && decoded.length == 1) {
    return tryDecodeToolMetadata(decoded.values.first);
  }

  if (decoded is Map || decoded is List) {
    return _toolMetadataEncoder.convert(decoded);
  }

  return decoded.toString();
}
