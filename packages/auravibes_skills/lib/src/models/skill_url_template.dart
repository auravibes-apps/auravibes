import 'dart:convert';

import 'package:auravibes_skills/src/models/url_request_method.dart';
import 'package:auravibes_skills/src/models/url_response_format.dart';

class SkillUrlTemplate {
  const SkillUrlTemplate({
    required this.url,
    this.method = UrlRequestMethod.get,
    this.headers = const {},
    this.query = const {},
    this.body,
    this.bodyFormat = SkillUrlTemplateBodyFormat.infer,
    this.timeout = const Duration(seconds: 30),
    this.format = UrlResponseFormat.defaultFormat,
  });

  factory SkillUrlTemplate.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('URL template must be a JSON object.');
    }

    final url = decoded['url'];
    if (url is! String || url.trim().isEmpty) {
      throw const FormatException('URL template requires a url.');
    }

    final bodyValue = decoded['body'];
    if (bodyValue != null && bodyValue is! String) {
      throw const FormatException('URL template body must be a string.');
    }
    final body = bodyValue as String?;

    return SkillUrlTemplate(
      url: _canonicalizeTemplate(url),
      method: _methodFromJson(decoded['method']),
      headers: _canonicalizeMap(_stringMap(decoded['headers'])),
      query: _canonicalizeMap(_stringMap(decoded['query'])),
      body: body == null ? null : _canonicalizeBody(body),
      bodyFormat: _bodyFormatFromJson(decoded['bodyFormat']),
      timeout: Duration(
        seconds: _positiveInt(decoded['timeoutSeconds']) ?? 30,
      ),
      format: UrlResponseFormat.fromString('${decoded['format'] ?? ''}'),
    );
  }

  final String url;
  final UrlRequestMethod method;
  final Map<String, String> headers;
  final Map<String, String> query;
  final String? body;
  final SkillUrlTemplateBodyFormat bodyFormat;
  final Duration timeout;
  final UrlResponseFormat format;

  Map<String, Object> toJson() {
    return {
      'url': url,
      'method': method.value,
      if (query.isNotEmpty) 'query': query,
      if (headers.isNotEmpty) 'headers': headers,
      'body': ?body,
      if (body != null) 'bodyFormat': resolvedBodyFormat.value,
      if (timeout != const Duration(seconds: 30))
        'timeoutSeconds': timeout.inSeconds,
      if (format != UrlResponseFormat.defaultFormat) 'format': format.label,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  SkillUrlTemplateBodyFormat get resolvedBodyFormat {
    final body = this.body;
    if (body == null) return SkillUrlTemplateBodyFormat.text;
    if (bodyFormat != SkillUrlTemplateBodyFormat.infer) return bodyFormat;

    return _looksLikeJson(body)
        ? SkillUrlTemplateBodyFormat.json
        : SkillUrlTemplateBodyFormat.text;
  }

  static UrlRequestMethod _methodFromJson(Object? value) {
    final normalized = '${value ?? 'GET'}'.trim().toLowerCase();
    if (normalized
        case 'get' || 'post' || 'put' || 'delete' || 'patch' || 'head') {
      return UrlRequestMethod.values.byName(normalized);
    }

    throw FormatException('Unsupported method: $value.');
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value == null) return const {};
    if (value is! Map) {
      throw const FormatException('Expected a JSON object map.');
    }

    return value.map((key, value) {
      if (key is! String || value is! String) {
        throw const FormatException('Expected a string-to-string JSON map.');
      }

      return MapEntry(key, value);
    });
  }

  static int? _positiveInt(Object? value) {
    if (value == null) return null;
    final parsed = value is int ? value : int.tryParse('$value');
    if (parsed == null || parsed <= 0) {
      throw FormatException('Expected a positive integer, got $value.');
    }

    return parsed;
  }

  static SkillUrlTemplateBodyFormat _bodyFormatFromJson(Object? value) {
    if (value == null) return SkillUrlTemplateBodyFormat.infer;
    final normalized = '$value'.trim().toLowerCase();
    if (normalized case 'infer' || 'json' || 'text') {
      return SkillUrlTemplateBodyFormat.values.byName(normalized);
    }

    throw FormatException('Unsupported bodyFormat: $value.');
  }

  static Map<String, String> _canonicalizeMap(Map<String, String> value) {
    return value.map(
      (key, value) => MapEntry(key, _canonicalizeTemplate(value)),
    );
  }

  static String _canonicalizeBody(String value) {
    final wholePlaceholder = RegExp(
      r'"\{(input|credential):([A-Za-z0-9_]+)\}"',
    );

    return _canonicalizeTemplate(
      value.replaceAllMapped(wholePlaceholder, (match) {
        return '{{ ${match.group(1)}.${match.group(2)} | json }}';
      }),
    );
  }

  static String _canonicalizeTemplate(String value) {
    return value.replaceAllMapped(_legacyPlaceholderPattern, (match) {
      return '{{ ${match.group(1)}.${match.group(2)} }}';
    });
  }

  static bool _looksLikeJson(String value) {
    final trimmed = value.trimLeft();

    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}

enum SkillUrlTemplateBodyFormat {
  infer('infer'),
  json('json'),
  text('text');

  const SkillUrlTemplateBodyFormat(this.value);

  final String value;
}

final _legacyPlaceholderPattern = RegExp(
  r'\{(input|credential):([A-Za-z0-9_]+)\}',
);
