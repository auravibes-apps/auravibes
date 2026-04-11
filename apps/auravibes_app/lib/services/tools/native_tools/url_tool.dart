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
      if (completer.isCanceled) {
        return;
      }

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
        .map((e) => '${e.key}: ${e.value.join(', ')}')
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

    final resolvedHost = await _ensurePublicHost(uri.host);

    final headers = _parseHeaders(json['headers']);
    final effectiveHeaders = <String, String>{
      ...?headers,
      if (uri.scheme == 'http') 'Host': uri.host,
    };

    final effectiveUrl = uri.scheme == 'https'
        ? uri.toString()
        : uri.replace(host: resolvedHost).toString();

    return UrlRequest(
      url: effectiveUrl,
      method: _parseMethod(json['method'] as String?),
      headers: effectiveHeaders,
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
    if (method == null) return .get;
    return UrlRequestMethod.values.firstWhere(
      (m) => m.value.toUpperCase() == method.toUpperCase(),
      orElse: () => .get,
    );
  }

  Map<String, String>? _parseHeaders(dynamic headers) {
    if (headers == null) return null;
    if (headers is Map) {
      return headers.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  Future<String> _ensurePublicHost(String host) async {
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
      return literalAddress.address;
    }

    final addresses = await InternetAddress.lookup(host);
    if (addresses.isEmpty || addresses.any(_isPrivateAddress)) {
      throw const FormatException(
        'Private or local network URLs are not allowed.',
      );
    }
    return addresses.first.address;
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
          raw[0] == 0 &&
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

    return raw[0] == 0xfc ||
        raw[0] == 0xfd ||
        (raw[0] == 0xfe && (raw[1] & 0xc0) == 0x80);
  }

  bool _isPrivateIPv4(List<int> b) {
    return b[0] == 10 ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 192 && b[1] == 168) ||
        (b[0] == 169 && b[1] == 254) ||
        b[0] == 127 ||
        b[0] == 0 ||
        (b[0] == 100 && b[1] >= 64 && b[1] <= 127);
  }

  @override
  NativeToolType get type => NativeToolType.url;
}
