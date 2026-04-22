import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/url/models/url_request.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:auravibes_app/services/url/url_service.dart';

final class UrlTool extends NativeToolEntity<String, String> {
  UrlTool({UrlService? urlService}) : _urlService = urlService;

  final UrlService? _urlService;

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
                '"body" (optional) - request body for POST/PUT/PATCH.',
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
      responseOperation = service.execute(request);

      final response = await responseOperation!.valueOrCancellation();
      if (response == null || completer.isCanceled) {
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

  String _formatResponse(UrlResponse response) {
    final headerLines = response.headers.entries
        .expand((e) => e.value.map((v) => '${e.key}: $v'))
        .join('\n');

    return 'Status: ${response.statusCode}\n'
        'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
        'Headers:\n$headerLines\n\n'
        '${response.body}';
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
    );
  }

  Map<String, dynamic> _parseInput(String input) {
    final trimmedInput = input.trim();
    if (trimmedInput.startsWith('{')) {
      final decoded = const JsonDecoder().convert(trimmedInput);
      if (decoded is! Map) {
        throw const FormatException('Tool input JSON must be an object.');
      }
      return Map<String, dynamic>.from(decoded);
    }
    return {'url': trimmedInput};
  }

  UrlRequestMethod _parseMethod(dynamic method) {
    if (method == null) return .get;
    if (method is! String) {
      throw FormatException('HTTP method must be a string: $method');
    }
    final normalized = method.trim().toUpperCase();
    return UrlRequestMethod.values.firstWhere(
      (m) => m.value == normalized,
      orElse: () => throw FormatException(
        'Unsupported HTTP method: $method',
      ),
    );
  }

  Map<String, String>? _parseHeaders(dynamic headers) {
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

    final isUnspecified = raw.every((b) => b == 0);
    return isUnspecified ||
        raw[0] == 0xfc ||
        raw[0] == 0xfd ||
        raw[0] == 0xff ||
        (raw[0] == 0xfe && (raw[1] & 0xc0) == 0x80);
  }

  bool _isPrivateIPv4(List<int> b) {
    return b[0] == 10 ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 192 && b[1] == 168) ||
        (b[0] == 169 && b[1] == 254) ||
        b[0] == 127 ||
        b[0] == 0 ||
        (b[0] == 100 && b[1] >= 64 && b[1] <= 127) ||
        (b[0] >= 224 && b[0] <= 239) ||
        b[0] >= 240;
  }

  @override
  NativeToolType get type => .url;
}
