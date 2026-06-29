// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/url/models/url_request_method.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/services/url/url_content_transformer.dart';
import 'package:auravibes_app/services/url/url_service.dart';

final class UrlTool extends NativeToolEntity<String, String> {
  UrlTool({this._urlService, UrlContentTransformer? transformer})
    : _transformer = transformer ?? const UrlContentTransformer();

  final UrlService? _urlService;
  final UrlContentTransformer _transformer;

  @override
  ToolSpec getTool() {
    return const ToolSpec(
      name: 'url',
      description:
          'Fetches content from a URL. '
          'Returns the response body text, status code, and headers. '
          'Useful for reading web pages, APIs, '
          'or any accessible HTTP endpoint.',
      inputJsonSchema: {
        'type': 'object',
        'properties': {
          'input': {
            'type': 'string',
            'description':
                'A JSON object with: '
                '"url" (required) - the URL to fetch, '
                '"method" (optional) - HTTP method '
                '(GET or HEAD), '
                '"headers" (optional) - JSON object of HTTP headers, '
                '"format" (optional) - markdown, text, html, '
                'or omit for default (markdown). '
                'Controls the Accept header sent and how the response '
                'body is transformed before being returned.',
          },
        },
        'required': ['input'],
      },
    );
  }

  @override
  CancelableOperation<String> runner(String toolInput) {
    CancelableOperation<UrlResponse>? responseOperation;
    final completer = CancelableCompleter<String>(
      onCancel: () => responseOperation?.cancel(),
    );

    () async {
      final request = await _buildRequest(toolInput);
      if (completer.isCanceled) {
        return;
      }

      final service = _urlService ?? UrlService();
      final operation = service.execute(request);
      responseOperation = operation;

      final response = await operation.valueOrCancellation();
      if (response == null || completer.isCanceled) {
        return;
      }

      completer.complete(_formatResponse(response, request.format));
    }().catchError((Object error, StackTrace stackTrace) {
      if (completer.isCanceled) {
        return;
      }

      completer.completeError(error, stackTrace);
    });

    return completer.operation;
  }

  String _formatResponse(
    UrlResponse response,
    UrlResponseFormat requestedFormat,
  ) {
    final transformed = _transformer.transform(
      response,
      requestedFormat: requestedFormat,
    );
    final headerLines = response.headers.entries
        .where((e) => !_isSensitiveHeader(e.key))
        .expand((e) => e.value.map((v) => '${e.key}: $v'))
        .join('\n');

    // ponytail: metadata built once; reserve "(truncated)" for budget.
    String meta({required bool truncated}) {
      final marker = truncated ? ' (truncated)' : '';

      return 'Status: ${response.statusCode}\n'
          'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
          'Content-Type: ${transformed.contentType ?? 'unknown'}\n'
          'Format: ${transformed.format.label}$marker\n'
          'Headers:\n$headerLines\n\n';
    }

    final metaForBudget = meta(truncated: true);
    final metaBytes = utf8.encode(metaForBudget).length;
    final metaLineCount = const LineSplitter().convert(metaForBudget).length;
    final body = _truncate(
      transformed.body,
      maxBytes: (_maxToolOutputBytes - metaBytes).clamp(
        0,
        _maxToolOutputBytes,
      ),
      maxLines: (_maxToolOutputLines - metaLineCount).clamp(
        0,
        _maxToolOutputLines,
      ),
    );
    final truncated =
        transformed.truncated || !identical(body, transformed.body);

    final result = '${meta(truncated: truncated)}$body';
    if (utf8.encode(result).length <= _maxToolOutputBytes &&
        const LineSplitter().convert(result).length <= _maxToolOutputLines) {
      return result;
    }

    return _truncate(
      result,
      maxBytes: _maxToolOutputBytes,
      maxLines: _maxToolOutputLines,
    );
  }

  bool _isSensitiveHeader(String name) {
    final normalized = name.toLowerCase();

    return normalized == 'set-cookie' ||
        normalized == 'authorization' ||
        normalized == 'proxy-authorization' ||
        normalized == 'www-authenticate' ||
        normalized == 'proxy-authenticate';
  }

  static const int _maxToolOutputBytes = 50 * 1024;
  static const int _maxToolOutputLines = 2000;
  static const int _truncationNoteReserve = 55;

  String _truncate(
    String text, {
    required int maxBytes,
    required int maxLines,
  }) {
    if (maxBytes <= 0) return text.isEmpty ? text : '';

    final originalBytes = utf8.encode(text).length;
    final parts = text.split('\n');
    final originalLines = text.endsWith('\n') ? parts.length - 1 : parts.length;

    if (originalBytes <= maxBytes && originalLines <= maxLines) return text;

    // Reserve one line + note bytes for the "... [truncated]" marker so the
    // returned value never exceeds maxBytes / maxLines.
    final lineCap = (maxLines - 1).clamp(0, maxLines);
    final byteCap = (maxBytes - _truncationNoteReserve).clamp(0, maxBytes);

    var result = originalLines > lineCap
        ? parts.sublist(0, lineCap).join('\n')
        : text;
    if (utf8.encode(result).length > byteCap) {
      result = _truncateUtf8(result, byteCap);
    }

    final omitted = originalBytes - utf8.encode(result).length;
    final combined = '$result\n... [truncated: $omitted bytes omitted]';

    return utf8.encode(combined).length > maxBytes
        ? _truncateUtf8(combined, maxBytes)
        : combined;
  }

  String _truncateUtf8(String text, int maxBytes) {
    final bytes = utf8.encode(text);
    if (bytes.length <= maxBytes) return text;

    var end = maxBytes;
    while (end > 0 && (bytes[end - 1] & 0xC0) == 0x80) {
      end--;
    }
    if (end > 0 && bytes[end - 1] >= 0xC0) {
      end--;
    }

    return utf8.decode(bytes.sublist(0, end));
  }

  Future<UrlRequest> _buildRequest(String toolInput) async {
    final json = _parseInput(toolInput);
    final rawUrl = json['url'];
    if (rawUrl is! String) {
      throw FormatException('URL must be a string: ${rawUrl.runtimeType}');
    }
    final url = rawUrl.trim();
    if (url.isEmpty) {
      throw const FormatException('A non-empty URL is required.');
    }

    final uri = Uri.tryParse(url);
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

    final method = _parseMethod(json['method']);
    if (method != UrlRequestMethod.get && method != UrlRequestMethod.head) {
      throw const FormatException('Only GET and HEAD are allowed.');
    }
    final headers = _parseHeaders(json['headers']);

    final format = switch (json['format']) {
      null => UrlResponseFormat.defaultFormat,
      final String s => UrlResponseFormat.fromString(s),
      _ => throw const FormatException(
        'Format must be a string: markdown, text, or html.',
      ),
    };

    await ensurePublicHost(uri.host);

    return UrlRequest(
      url: uri.toString(),
      method: method,
      headers: headers ?? const {},
      format: format,
    );
  }

  Map<String, Object?> _parseInput(String input) {
    final trimmedInput = input.trim();
    if (trimmedInput.startsWith('{')) {
      final decoded = const JsonDecoder().convert(trimmedInput);
      if (decoded is! Map) {
        throw const FormatException('Tool input JSON must be an object.');
      }

      return Map<String, Object?>.from(decoded);
    }

    return {'url': trimmedInput};
  }

  UrlRequestMethod _parseMethod(Object? method) {
    if (method == null) return .get;
    if (method is! String) {
      throw FormatException('HTTP method must be a string: $method');
    }
    final normalized = method.trim().toLowerCase();
    if (!UrlRequestMethod.values
        .map((entry) => entry.name)
        .contains(normalized)) {
      throw FormatException('Unsupported HTTP method: $method');
    }

    return UrlRequestMethod.values.byName(normalized);
  }

  Map<String, String>? _parseHeaders(Object? headers) {
    if (headers == null) return null;
    if (headers is! Map) {
      throw const FormatException('Headers must be a JSON object.');
    }

    return headers.entries.fold<Map<String, String>>({}, (result, entry) {
      final name = entry.key.toString();
      if (name.toLowerCase() == 'host') {
        throw const FormatException(
          'The Host header is derived from the URL.',
        );
      }
      result[name] = entry.value.toString();

      return result;
    });
  }

  @override
  NativeToolType get type => .url;
}
