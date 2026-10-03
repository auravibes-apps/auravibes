import 'dart:convert';

Map<String, String> parseMcpHttpHeaders(String? encoded) {
  if (encoded == null) return const {};
  if (encoded.length > 8192) {
    throw const FormatException('MCP headers are too large.');
  }
  final decoded = jsonDecode(encoded);
  if (decoded is! Map || decoded.length > 32) {
    throw const FormatException('Invalid MCP headers.');
  }
  final headers = <String, String>{};
  final names = <String>{};
  final namePattern = RegExp(r'^[!#$%&\x27*+.^_`|~0-9A-Za-z-]+$');
  const reserved = {
    'host',
    'content-type',
    'content-length',
    'transfer-encoding',
    'accept',
    'connection',
    'mcp-session-id',
  };
  for (final entry in decoded.entries) {
    final name = entry.key;
    final value = entry.value;
    if (name is! String ||
        value is! String ||
        value.isEmpty ||
        !namePattern.hasMatch(name) ||
        reserved.contains(name.toLowerCase()) ||
        name.toLowerCase().startsWith('proxy-') ||
        !names.add(name.toLowerCase()) ||
        value.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid MCP header.');
    }
    headers[name] = value;
  }
  return Map.unmodifiable(headers);
}
