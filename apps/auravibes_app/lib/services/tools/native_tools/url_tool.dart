import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/url/models/url_request.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:langchain/langchain.dart';

final class UrlTool extends NativeToolEntity<String, Object, String> {
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
    final request = _buildRequest(toolInput);
    final service = _urlService ?? UrlService();
    final responseOperation = service.execute(request);
    final completer = CancelableCompleter<String>(
      onCancel: responseOperation.cancel,
    );

    responseOperation.value
        .then((response) {
          if (completer.isCanceled) {
            return;
          }

          final headerLines = response.headers.entries
              .map((e) => '${e.key}: ${e.value}')
              .join('\n');

          completer.complete(
            'Status: ${response.statusCode}\n'
            'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
            'Headers:\n$headerLines\n\n'
            '${response.body}',
          );
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (completer.isCanceled) {
            return;
          }

          completer.completeError(error, stackTrace);
        });

    return completer.operation;
  }

  Future<String> _execute(String toolInput) async {
    final service = _urlService ?? UrlService();
    final response = await service.execute(_buildRequest(toolInput)).value;

    final headerLines = response.headers.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    return 'Status: ${response.statusCode}\n'
        'Elapsed: ${response.elapsed.inMilliseconds}ms\n'
        'Headers:\n$headerLines\n\n'
        '${response.body}';
  }

  UrlRequest _buildRequest(String toolInput) {
    final json = _parseInput(toolInput);

    return UrlRequest(
      url: json['url'] as String? ?? '',
      method: _parseMethod(json['method'] as String?),
      headers: _parseHeaders(json['headers']),
      body: json['body'] as String?,
    );
  }

  Map<String, dynamic> _parseInput(String input) {
    if (input.startsWith('{')) {
      try {
        return Map<String, dynamic>.from(
          const JsonDecoder().convert(input) as Map,
        );
      } on FormatException {
        return {'url': input};
      }
    }
    return {'url': input};
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

  @override
  NativeToolType get type => NativeToolType.url;
}
