import 'dart:convert';

import 'package:auravibes_engine/src/skills/models/url_request.dart';
import 'package:auravibes_engine/src/skills/models/url_request_method.dart';
import 'package:auravibes_engine/src/skills/models/url_response.dart';
import 'package:auravibes_engine/src/skills/models/url_response_format.dart';
import 'package:auravibes_engine/src/tool_spec.dart';
import 'package:auravibes_engine/src/url_content_transformer.dart';

final urlToolSpec = ToolSpec(
  name: 'url',
  description:
      'Fetches content from a URL. Returns the response body text, '
      'status code, and headers. Useful for reading web pages, APIs, '
      'or any accessible HTTP endpoint.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'input': {
        'type': 'string',
        'description':
            'A JSON object with: "url" (required), "method" '
            '(GET or HEAD), "headers", and "format" (markdown, text, html).',
      },
    },
    'required': ['input'],
  },
);

UrlRequest parseUrlToolInput(String input) {
  final raw = input.trim();
  final json = raw.startsWith('{')
      ? _jsonObject(raw)
      : <String, Object?>{'url': raw};
  final rawUrl = json['url'];
  if (rawUrl is! String || rawUrl.trim().isEmpty) {
    throw const FormatException('A non-empty URL is required.');
  }
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException('URL must be an absolute URI.');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw const FormatException('Only HTTP and HTTPS URLs are allowed.');
  }
  if (uri.userInfo.isNotEmpty) {
    throw const FormatException(
      'URLs with embedded credentials are not allowed.',
    );
  }
  final method = _method(json['method']);
  if (method != UrlRequestMethod.get && method != UrlRequestMethod.head) {
    throw const FormatException('Only GET and HEAD are allowed.');
  }
  return UrlRequest(
    url: uri.toString(),
    method: method,
    headers: _headers(json['headers']),
    format: switch (json['format']) {
      null => UrlResponseFormat.defaultFormat,
      final String value => UrlResponseFormat.fromString(value),
      _ => throw const FormatException('Format must be a string.'),
    },
  );
}

String formatUrlToolResponse(
  UrlResponse response, {
  required UrlResponseFormat requestedFormat,
  UrlContentTransformer transformer = const UrlContentTransformer(),
}) {
  final transformed = transformer.transform(
    response,
    requestedFormat: requestedFormat,
  );
  final headers = response.headers.entries
      .where((entry) => !_sensitiveHeader(entry.key))
      .expand((entry) => entry.value.map((value) => '${entry.key}: $value'))
      .join('\n');
  String meta({required bool truncated}) =>
      'Status: ${response.statusCode}\n'
      'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
      'Content-Type: ${transformed.contentType ?? 'unknown'}\n'
      'Format: ${transformed.format.label}${truncated ? ' (truncated)' : ''}\n'
      'Headers:\n$headers\n\n';
  final reserve = meta(truncated: true);
  final body = _truncate(
    transformed.body,
    maxBytes: (50 * 1024 - utf8.encode(reserve).length).clamp(0, 50 * 1024),
    maxLines: (2000 - const LineSplitter().convert(reserve).length).clamp(
      0,
      2000,
    ),
  );
  final truncated = transformed.truncated || body != transformed.body;
  final result = '${meta(truncated: truncated)}$body';
  return _truncate(result, maxBytes: 50 * 1024, maxLines: 2000);
}

Map<String, Object?> _jsonObject(String input) {
  final decoded = const JsonDecoder().convert(input);
  if (decoded is! Map) {
    throw const FormatException('Tool input JSON must be an object.');
  }
  return Map<String, Object?>.from(decoded);
}

UrlRequestMethod _method(Object? value) {
  if (value == null) return UrlRequestMethod.get;
  if (value is! String) {
    throw const FormatException('HTTP method must be a string.');
  }
  return UrlRequestMethod.values.firstWhere(
    (method) => method.name == value.trim().toLowerCase(),
    orElse: () => throw FormatException('Unsupported HTTP method: $value'),
  );
}

Map<String, String> _headers(Object? value) {
  if (value == null) return const {};
  if (value is! Map) {
    throw const FormatException('Headers must be a JSON object.');
  }
  final headers = <String, String>{};
  for (final entry in value.entries) {
    final name = entry.key.toString();
    if (name.toLowerCase() == 'host') {
      throw const FormatException('The Host header is derived from the URL.');
    }
    headers[name] = entry.value.toString();
  }
  return headers;
}

bool _sensitiveHeader(String name) => const {
  'set-cookie',
  'authorization',
  'proxy-authorization',
  'www-authenticate',
  'proxy-authenticate',
}.contains(name.toLowerCase());

String _truncate(String text, {required int maxBytes, required int maxLines}) {
  final bytes = utf8.encode(text);
  final lines = const LineSplitter().convert(text).length;
  if (bytes.length <= maxBytes && lines <= maxLines) return text;
  final lineText = text
      .split('\n')
      .take(maxLines > 0 ? maxLines - 1 : 0)
      .join('\n');
  final capped = _utf8Prefix(lineText, (maxBytes - 55).clamp(0, maxBytes));
  final omitted = bytes.length - utf8.encode(capped).length;
  final result = '$capped\n... [truncated: $omitted bytes omitted]';
  return _utf8Prefix(result, maxBytes);
}

String _utf8Prefix(String value, int maxBytes) {
  final bytes = utf8.encode(value);
  if (bytes.length <= maxBytes) return value;
  var end = maxBytes;
  while (end > 0 && (bytes[end - 1] & 0xc0) == 0x80) {
    end--;
  }
  if (end > 0 && bytes[end - 1] >= 0xc0) end--;
  return utf8.decode(bytes.sublist(0, end));
}
