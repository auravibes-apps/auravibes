// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.

import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/url/models/url_request_method.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:auravibes_app/services/url/url_content_transformer.dart';
import 'package:auravibes_app/services/url/url_service.dart';

const _privateNetworkUrlError =
    'Private or local network URLs are not allowed.';

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
                '(GET, POST, PUT, DELETE, PATCH, HEAD), '
                '"headers" (optional) - JSON object of HTTP headers, '
                '"body" (optional) - request body for POST/PUT/PATCH, '
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
        .expand((e) => e.value.map((v) => '${e.key}: $v'))
        .join('\n');

    final formatLabel = transformed.format.label;
    final metadataOverhead = utf8
        .encode(
          'Status: ${response.statusCode}\n'
          'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
          'Content-Type: ${transformed.contentType ?? 'unknown'}\n'
          'Format: $formatLabel (truncated)\n'
          'Headers:\n$headerLines\n\n',
        )
        .length;

    final metaLines = const LineSplitter()
        .convert(
          'Status:${response.statusCode}\n'
          'Elapsed:${response.elapsed.inMilliseconds}ms\n'
          'Content-Type:${transformed.contentType ?? 'unknown'}\n'
          'Format:$formatLabel (truncated)\n'
          'Headers:\n$headerLines\n\n',
        )
        .length;

    final bodyBudget = (_maxToolOutputBytes - metadataOverhead).clamp(
      0,
      _maxToolOutputBytes,
    );
    final bodyLineBudget = (_maxToolOutputLines - metaLines).clamp(
      0,
      _maxToolOutputLines,
    );

    final bodyResult = bodyBudget > 0
        ? _truncateBody(
            transformed.body,
            maxBytes: bodyBudget,
            maxLines: bodyLineBudget,
          )
        : (body: '', truncated: transformed.body.isNotEmpty);
    var wasTruncated = transformed.truncated || bodyResult.truncated;

    var result =
        'Status: ${response.statusCode}\n'
        'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
        'Content-Type: ${transformed.contentType ?? 'unknown'}\n'
        'Format: $formatLabel${wasTruncated ? ' (truncated)' : ''}\n'
        'Headers:\n$headerLines\n\n'
        '${bodyResult.body}';

    final resultBytes = utf8.encode(result).length;
    final resultLines = _takeLines(result, _maxToolOutputLines + 1).length;

    if (resultBytes > _maxToolOutputBytes ||
        resultLines > _maxToolOutputLines) {
      wasTruncated = true;
      result = _truncateTotal(
        'Status: ${response.statusCode}\n'
        'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
        'Content-Type: ${transformed.contentType ?? 'unknown'}\n'
        'Format: $formatLabel (truncated)\n'
        'Headers:\n$headerLines\n\n'
        '${bodyResult.body}',
      );
    }

    return result;
  }

  static const int _maxToolOutputBytes = 50 * 1024;
  static const int _maxToolOutputLines = 2000;
  static const int _truncationNoteReserve = 55;

  List<String> _takeLines(String text, int limit) {
    final lines = text.split('\n');
    if (lines.isNotEmpty && text.endsWith('\n')) {
      final _ = lines.removeLast();
    }

    return lines.take(limit + 1).toList();
  }

  ({String body, bool truncated}) _truncateBody(
    String body, {
    required int maxBytes,
    required int maxLines,
  }) {
    final originalByteCount = utf8.encode(body).length;
    final allLines = _takeLines(body, maxLines);

    if (allLines.length <= maxLines && originalByteCount <= maxBytes) {
      return (body: body, truncated: false);
    }

    var result = allLines.length > maxLines
        ? allLines.sublist(0, maxLines).join('\n')
        : body;

    final maxContentBytes = (maxBytes - _truncationNoteReserve).clamp(
      0,
      maxBytes,
    );
    if (utf8.encode(result).length > maxContentBytes) {
      result = _truncateUtf8(result, maxContentBytes);
    }

    final omitted = originalByteCount - utf8.encode(result).length;
    final note = '\n... [truncated: $omitted bytes omitted]';
    final combined = '$result$note';

    if (utf8.encode(combined).length > maxBytes) {
      return (
        body: _truncateUtf8(combined, maxBytes),
        truncated: true,
      );
    }

    return (body: combined, truncated: true);
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

  String _truncateTotal(String text) {
    var output = text;

    final lines = _takeLines(output, _maxToolOutputLines + 1);
    if (lines.length > _maxToolOutputLines) {
      output = lines.sublist(0, _maxToolOutputLines).join('\n');
    }

    final originalBytes = utf8.encode(output).length;
    output = _truncateUtf8(
      output,
      _maxToolOutputBytes - _truncationNoteReserve,
    );

    final omitted = originalBytes - utf8.encode(output).length;

    return '$output\n... [truncated: $omitted bytes omitted]';
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
    final headers = _parseHeaders(json['headers']);
    final rawBody = json['body'];
    final body = switch (rawBody) {
      null => null,
      final String s => s,
      _ => jsonEncode(rawBody),
    };
    final isStructuredBody = rawBody != null && rawBody is! String;

    final format = switch (json['format']) {
      null => UrlResponseFormat.defaultFormat,
      final String s => UrlResponseFormat.fromString(s),
      _ => throw const FormatException(
        'Format must be a string: markdown, text, or html.',
      ),
    };

    final resolvedHost = await _ensurePublicHost(uri.host);

    final effectiveHeaders = <String, String>{
      ...?headers,
      if (isStructuredBody &&
          !(headers?.keys.any((k) => k.toLowerCase() == 'content-type') ??
              false))
        'Content-Type': 'application/json',
      if (uri.scheme == 'http') 'Host': uri.authority,
    };

    final effectiveUrl = uri.scheme == 'https'
        ? uri.toString()
        : uri.replace(host: resolvedHost).toString();

    return UrlRequest(
      url: effectiveUrl,
      method: method,
      headers: effectiveHeaders,
      body: body,
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

  Future<String> _ensurePublicHost(String host) async {
    if (_isBlockedHostLabel(host)) {
      throw const FormatException(
        _privateNetworkUrlError,
      );
    }

    final literalAddress = InternetAddress.tryParse(host);
    if (literalAddress != null) {
      if (_isPrivateAddress(literalAddress)) {
        throw const FormatException(
          _privateNetworkUrlError,
        );
      }

      return literalAddress.address;
    }

    final addresses = await InternetAddress.lookup(host);
    final firstAddress = addresses.firstOrNull;
    if (firstAddress == null || addresses.any(_isPrivateAddress)) {
      throw const FormatException(
        _privateNetworkUrlError,
      );
    }

    return firstAddress.address;
  }

  bool _isBlockedHostLabel(String host) {
    final normalizedHost = host.toLowerCase();

    return normalizedHost == 'localhost' ||
        normalizedHost.endsWith('.localhost');
  }

  bool _isPrivateAddress(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal) {
      return true;
    }

    final raw = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      return _isPrivateIPv4(raw);
    }

    if (address.type == InternetAddressType.IPv6 && raw.length == 16) {
      final isMapped =
          raw.firstOrNull == 0 &&
          raw[1] == 0 &&
          raw[2] == 0 &&
          raw[3] == 0 &&
          raw[4] == 0 &&
          raw[5] == 0 &&
          raw[6] == 0 &&
          raw[7] == 0 &&
          raw[8] == 0 &&
          raw[9] == 0 &&
          raw[10] == 0xff &&
          raw[11] == 0xff;
      if (isMapped) {
        return _isPrivateIPv4(raw.sublist(12));
      }
    }

    final isUnspecified = raw.every((b) => b == 0);

    return isUnspecified ||
        raw.firstOrNull == 0xfc ||
        raw.firstOrNull == 0xfd ||
        raw.firstOrNull == 0xff ||
        (raw.firstOrNull == 0xfe && (raw[1] & 0xc0) == 0x80);
  }

  bool _isPrivateIPv4(List<int> b) {
    final firstByte = b.firstOrNull;
    if (firstByte == null) {
      return false;
    }

    return firstByte == 10 ||
        (firstByte == 172 && b[1] >= 16 && b[1] <= 31) ||
        (firstByte == 192 && b[1] == 168) ||
        (firstByte == 169 && b[1] == 254) ||
        firstByte == 127 ||
        firstByte == 0 ||
        (firstByte == 100 && b[1] >= 64 && b[1] <= 127) ||
        (firstByte >= 224 && firstByte <= 239) ||
        firstByte >= 240;
  }

  @override
  NativeToolType get type => .url;
}
