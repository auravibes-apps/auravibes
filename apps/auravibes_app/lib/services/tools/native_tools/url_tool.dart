import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/url/models/url_request.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:langchain/langchain.dart';

final class UrlTool extends NativeToolEntity<String, String> {
  UrlTool({UrlService? urlService}) : _urlService = urlService;

  final UrlService? _urlService;

  @override
  Tool<Object, ToolOptions, Object> getTool() {
    return Tool.fromFunction<String, String>(
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
                '"body" (optional) - request body for POST/PUT/PATCH.',
          },
        },
        'required': ['input'],
      },
      func: (toolInput) async {
        final result = await _execute(toolInput);
        return result;
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
      final service = _urlService ?? UrlService();
      responseOperation = service.execute(request);

      final response = await responseOperation!.value;
      if (completer.isCanceled) {
        return;
      }

      completer.complete(_formatResponse(response));
    }().catchError((Object error, StackTrace stackTrace) {
      if (completer.isCanceled) {
        return;
      }

      completer.completeError(error, stackTrace);
    });

    return completer.operation;
  }

  Future<String> _execute(String toolInput) async {
    final service = _urlService ?? UrlService();
    final request = await _buildRequest(toolInput);
    final response = await service.execute(request).value;

    return _formatResponse(response);
  }

  String _formatResponse(UrlResponse response) {
    final headerLines = response.headers.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    return 'Status: ${response.statusCode}\n'
        'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
        'Headers:\n$headerLines\n\n'
        '${response.body}';
  }

  Future<UrlRequest> _buildRequest(String toolInput) async {
    final json = _parseInput(toolInput);
    final url = (json['url'] as String? ?? '').trim();
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

    await _ensurePublicHost(uri.host);

    return UrlRequest(
      url: uri.toString(),
      method: _parseMethod(json['method'] as String?),
      headers: _parseHeaders(json['headers']),
      body: json['body'] as String?,
    );
  }

  Map<String, dynamic> _parseInput(String input) {
    final trimmedInput = input.trim();
    if (trimmedInput.startsWith('{')) {
      try {
        final decoded = const JsonDecoder().convert(trimmedInput);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } on FormatException {
        return {'url': trimmedInput};
      }
    }
    return {'url': trimmedInput};
  }

  UrlRequestMethod _parseMethod(String? method) {
    if (method == null) return UrlRequestMethod.get;
    return UrlRequestMethod.values.firstWhere(
      (m) => m.value.toUpperCase() == method.toUpperCase(),
      orElse: () => UrlRequestMethod.get,
    );
  }

  Map<String, String>? _parseHeaders(dynamic headers) {
    if (headers == null) return null;
    if (headers is Map) {
      return headers.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  Future<void> _ensurePublicHost(String host) async {
    if (_isBlockedHostLabel(host)) {
      throw const FormatException(
        'Private or local network URLs are not allowed.',
      );
    }

    final literalAddress = InternetAddress.tryParse(host);
    if (literalAddress != null) {
      if (_isPrivateAddress(literalAddress)) {
        throw const FormatException(
          'Private or local network URLs are not allowed.',
        );
      }
      return;
    }

    final addresses = await InternetAddress.lookup(host);
    if (addresses.isEmpty || addresses.any(_isPrivateAddress)) {
      throw const FormatException(
        'Private or local network URLs are not allowed.',
      );
    }
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
      return raw[0] == 10 ||
          (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) ||
          (raw[0] == 192 && raw[1] == 168) ||
          (raw[0] == 169 && raw[1] == 254) ||
          raw[0] == 127 ||
          raw[0] == 0;
    }

    return raw[0] == 0xfc ||
        raw[0] == 0xfd ||
        (raw[0] == 0xfe && (raw[1] & 0xc0) == 0x80);
  }

  @override
  NativeToolType get type => NativeToolType.url;
}
