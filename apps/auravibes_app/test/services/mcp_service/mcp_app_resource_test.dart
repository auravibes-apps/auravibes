import 'dart:convert';

import 'package:auravibes_app/services/mcp_service/mcp_app_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads declared HTML and CSP from the matching resource content', () {
    final result = <String, Object?>{
      'contents': [
        {
          'uri': 'ui://weather/view',
          'mimeType': 'text/html;profile=mcp-app',
          'text': '<html><script>render()</script></html>',
          '_meta': {
            'ui': {
              'csp': {
                'connectDomains': ['https://api.example.com'],
                'resourceDomains': ['https://cdn.example.com'],
              },
            },
          },
        },
      ],
    };
    final resource = McpAppResource.fromReadResult(
      result,
      resourceUri: 'ui://weather/view',
    );

    expect(resource.html, '<html><script>render()</script></html>');
    expect(resource.csp['connectDomains'], ['https://api.example.com']);
  });

  test('decodes a base64 MCP App resource', () {
    final result = <String, Object?>{
      'contents': [
        {
          'uri': 'ui://weather/view',
          'mimeType': 'text/html;profile=mcp-app',
          'blob': base64Encode(utf8.encode('<html>app</html>')),
        },
      ],
    };
    final resource = McpAppResource.fromReadResult(
      result,
      resourceUri: 'ui://weather/view',
    );

    expect(resource.html, '<html>app</html>');
  });

  test('rejects oversized text and base64 app resources', () {
    for (final content in [
      {'text': 'x' * (maxMcpAppResourceBytes + 1)},
      {'blob': base64Encode(List<int>.filled(maxMcpAppResourceBytes + 1, 120))},
    ]) {
      final result = <String, Object?>{
        'contents': [
          {
            'uri': 'ui://weather/view',
            'mimeType': 'text/html;profile=mcp-app',
            ...content,
          },
        ],
      };
      expect(
        () => McpAppResource.fromReadResult(
          result,
          resourceUri: 'ui://weather/view',
        ),
        throwsFormatException,
      );
    }
  });

  test('rejects mismatched or unsupported resource content', () {
    final mismatchedResult = <String, Object?>{
      'contents': [
        {
          'uri': 'ui://other/view',
          'mimeType': 'text/html;profile=mcp-app',
          'text': '<html></html>',
        },
      ],
    };
    expect(
      () => McpAppResource.fromReadResult(
        mismatchedResult,
        resourceUri: 'ui://weather/view',
      ),
      throwsFormatException,
    );
    final unsupportedResult = <String, Object?>{
      'contents': [
        {
          'uri': 'ui://weather/view',
          'mimeType': 'text/html',
          'text': '<html></html>',
        },
      ],
    };
    expect(
      () => McpAppResource.fromReadResult(
        unsupportedResult,
        resourceUri: 'ui://weather/view',
      ),
      throwsUnsupportedError,
    );
  });

  test('embeds app HTML in a sandboxed native view with declared CSP', () {
    const appHtml =
        '<!doctype html><html><head><title>App</title></head><body>View</body></html>';
    final page = buildMcpAppHostPage(
      html: appHtml,
      csp: const {
        'resourceDomains': ['https://cdn.example.com'],
        'connectDomains': ['https://api.example.com'],
      },
      isWeb: false,
    );

    expect(page, contains('sandbox="allow-scripts"'));
    expect(page, isNot(contains('allow-same-origin')));
    final appCsp = utf8.decode(_scriptPayload(page, 'appCspBase64'));
    expect(appCsp, contains('connect-src https://api.example.com'));
    expect(
      appCsp,
      contains('''script-src 'unsafe-inline' https://cdn.example.com'''),
    );
    expect(page, contains(r'const head = /<head(?:\s[^>]*)?>/i;'));
    expect(page, contains('html.replace(head, (match) => match + tag)'));
    expect(page, isNot(contains(appHtml)));
    expect(utf8.decode(_scriptPayload(page, 'appHtmlBase64')), appHtml);
  });

  test('ignores unsafe domains when building app CSP', () {
    final page = buildMcpAppHostPage(
      html: '<p>app</p>',
      csp: const {
        'resourceDomains': [
          'https://cdn.example.com',
          'https://*.assets.example.com',
          'https://*',
          'https://foo.*.example.com',
          'javascript:alert(1)',
          'https://example.com/path',
          'https://user:pass@example.com',
        ],
        'connectDomains': ['data:text/html'],
      },
      isWeb: false,
    );
    final appCsp = utf8.decode(_scriptPayload(page, 'appCspBase64'));

    expect(appCsp, contains('https://cdn.example.com'));
    expect(appCsp, contains('https://*.assets.example.com'));
    expect(appCsp, isNot(contains('https://* ')));
    expect(appCsp, isNot(contains('javascript:')));
    expect(appCsp, isNot(contains('https://example.com/path')));
    expect(appCsp, isNot(contains('user:pass')));
    expect(appCsp, contains('''connect-src 'none' '''.trim()));
  });

  test('uses a separate sandbox proxy for web hosts', () {
    final page = buildMcpAppHostPage(
      html: '<p>app</p>',
      csp: const {},
      isWeb: true,
    );

    expect(page, contains('sandbox="allow-scripts allow-same-origin"'));
    final proxyPage = utf8.decode(_scriptPayload(page, 'proxyHtmlBase64'));
    expect(proxyPage, contains('ui/notifications/sandbox-proxy-ready'));
    expect(proxyPage, contains('ui/notifications/sandbox-resource-ready'));
    expect(proxyPage, contains('''setAttribute('sandbox', 'allow-scripts')'''));
    expect(proxyPage, isNot(contains('allow-same-origin')));
    expect(proxyPage, contains('''startsWith('ui/notifications/sandbox-')'''));
  });
}

List<int> _scriptPayload(String html, String name) {
  final match = RegExp('$name = "([A-Za-z0-9+/=]*)"').firstMatch(html);
  if (match == null) throw StateError('Missing $name payload.');

  final payload = match.group(1);
  if (payload == null) throw StateError('Missing $name payload.');

  return base64Decode(payload);
}
