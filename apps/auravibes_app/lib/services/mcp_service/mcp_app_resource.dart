import 'dart:convert';

typedef McpAppResource = ({String html, Map<String, Object?> csp});

const int maxMcpAppResourceBytes = 2 * 1024 * 1024;
const int _maxMcpAppResourceBase64Characters =
    ((maxMcpAppResourceBytes + 2) ~/ 3) * 4;
final _cspHostPattern = RegExp(r'^[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');

McpAppResource parseMcpAppResource(
  Map<String, Object?> result, {
  required String resourceUri,
}) {
  final content = _matchingResourceContent(result, resourceUri);

  return (html: _resourceHtml(content), csp: _resourceCsp(content['_meta']));
}

Map<String, Object?> _matchingResourceContent(
  Map<String, Object?> result,
  String resourceUri,
) => Map<String, Object?>.from(
  _singleMcpAppResourceContent(_resourceContents(result), resourceUri),
);

Map<Object?, Object?> _singleMcpAppResourceContent(
  List<Object?> contents,
  String resourceUri,
) {
  final matches = contents.whereType<Map<Object?, Object?>>().where(
    (content) => _hasMcpAppResourceUri(content, resourceUri),
  );
  if (matches.length != 1) {
    throw const FormatException('MCP App resource content did not match.');
  }

  return matches.single;
}

bool _hasMcpAppResourceUri(Map<Object?, Object?> content, String resourceUri) =>
    content['uri'] == resourceUri;

List<Object?> _resourceContents(Map<String, Object?> result) {
  final contents = result['contents'];
  if (contents is! List<Object?>) {
    throw const FormatException('MCP App resource has no content.');
  }

  return contents;
}

String _resourceHtml(Map<String, Object?> content) {
  if (content['mimeType'] != 'text/html;profile=mcp-app') {
    throw UnsupportedError('Unsupported MCP App resource MIME type.');
  }
  final text = content['text'];
  if (text is String) return _validatedResourceText(text);
  final blob = content['blob'];
  if (blob is String) return _decodedResourceBlob(blob);

  throw const FormatException('MCP App resource has no HTML content.');
}

String _validatedResourceText(String text) {
  if (text.length > maxMcpAppResourceBytes ||
      utf8.encode(text).length > maxMcpAppResourceBytes) {
    throw const FormatException('MCP App resource exceeds size limit.');
  }

  return text;
}

String _decodedResourceBlob(String blob) {
  if (blob.length > _maxMcpAppResourceBase64Characters) {
    throw const FormatException('MCP App resource exceeds size limit.');
  }
  final bytes = base64Decode(blob);
  if (bytes.length > maxMcpAppResourceBytes) {
    throw const FormatException('MCP App resource exceeds size limit.');
  }

  return utf8.decode(bytes);
}

Map<String, Object?> _resourceCsp(Object? metadata) {
  if (metadata is! Map) return const {};
  final ui = metadata['ui'];
  if (ui is! Map) return const {};
  final csp = ui['csp'];
  if (csp is! Map) return const {};

  return Map<String, Object?>.from(csp);
}

String buildMcpAppHostPage({
  required String html,
  required Map<String, Object?> csp,
  required bool isWeb,
}) => _renderHostPage(_hostPageData(html, csp, isWeb), isWeb);

typedef _McpAppHostPageData = ({
  String html,
  String csp,
  String hostCsp,
  String proxyHtml,
});

_McpAppHostPageData _hostPageData(
  String html,
  Map<String, Object?> csp,
  bool isWeb,
) {
  final appCsp = _contentSecurityPolicy(csp);
  final hostCsp = _hostContentSecurityPolicy(csp);
  final proxyHtml = isWeb
      ? _webSandboxProxyPage.replaceAll(
          '__PROXY_CONTENT_SECURITY_POLICY__',
          hostCsp,
        )
      : '';

  return (
    html: base64Encode(utf8.encode(html)),
    csp: base64Encode(utf8.encode(appCsp)),
    hostCsp: hostCsp,
    proxyHtml: base64Encode(utf8.encode(proxyHtml)),
  );
}

String _renderHostPage(_McpAppHostPageData data, bool isWeb) {
  final template = isWeb ? _webHostPage : _nativeHostPage;

  return template
      .replaceAll('__APP_HTML_BASE64__', data.html)
      .replaceAll('__APP_CSP_BASE64__', data.csp)
      .replaceAll('__HOST_CONTENT_SECURITY_POLICY__', data.hostCsp)
      .replaceAll('__PROXY_HTML_BASE64__', data.proxyHtml);
}

String _hostContentSecurityPolicy(Map<String, Object?> csp) =>
    _contentSecurityPolicy(csp, frameSources: [''' 'self' '''.trim(), 'data:']);

String _contentSecurityPolicy(
  Map<String, Object?> csp, {
  List<String> frameSources = const [],
}) => _cspDirectives(csp, frameSources).join('; ');

List<String> _cspDirectives(
  Map<String, Object?> csp,
  List<String> frameSources,
) => [
  '''default-src 'none' '''.trim(),
  ..._resourceDirectives(csp),
  ..._frameAndBaseDirectives(csp, frameSources),
  '''object-src 'none' '''.trim(),
  '''form-action 'none' '''.trim(),
];

List<String> _resourceDirectives(Map<String, Object?> csp) {
  final resources = _allowedDomains(csp['resourceDomains'], const {
    'http',
    'https',
  });
  final connections = _allowedDomains(csp['connectDomains'], const {
    'http',
    'https',
    'ws',
    'wss',
  });
  final resourceSources = resources.join(' ');

  return [
    '''script-src 'unsafe-inline' $resourceSources'''.trim(),
    '''style-src 'unsafe-inline' $resourceSources'''.trim(),
    'img-src data: blob: $resourceSources'.trim(),
    _sourceDirective('font-src', resources),
    _sourceDirective('media-src', resources),
    _sourceDirective('connect-src', connections),
  ];
}

List<String> _frameAndBaseDirectives(
  Map<String, Object?> csp,
  List<String> frameSources,
) {
  final frames = [
    ..._allowedDomains(csp['frameDomains'], const {'http', 'https'}),
    ...frameSources,
  ];
  final bases = _allowedDomains(csp['baseUriDomains'], const {'http', 'https'});
  final baseUriSources = bases.isEmpty
      ? ''' 'self' '''.trim()
      : bases.join(' ');

  return [_sourceDirective('frame-src', frames), 'base-uri $baseUriSources'];
}

String _sourceDirective(String name, List<String> sources) {
  final value = sources.isEmpty ? ''' 'none' '''.trim() : sources.join(' ');

  return '$name $value';
}

List<String> _allowedDomains(Object? value, Set<String> allowedSchemes) {
  if (value is! List) return const [];

  final domains = <String>[];
  for (final domain in value.whereType<String>()) {
    final safeDomain = _allowedDomain(domain, allowedSchemes);
    if (safeDomain != null) domains.add(safeDomain);
  }

  return domains;
}

String? _allowedDomain(String value, Set<String> allowedSchemes) {
  final uri = Uri.tryParse(value);
  if (uri == null || !_isAllowedCspOrigin(uri, allowedSchemes)) return null;
  final host = uri.host;
  if (!_isValidCspHost(host)) return null;

  return _formatCspOrigin(uri, host);
}

bool _isAllowedCspOrigin(Uri? uri, Set<String> allowedSchemes) =>
    uri != null &&
    allowedSchemes.contains(uri.scheme) &&
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty &&
    (!uri.path.isNotEmpty || uri.path == '/') &&
    !uri.hasQuery &&
    !uri.hasFragment;

bool _isValidCspHost(String host) {
  final wildcard = host.startsWith('*.');
  final hostWithoutWildcard = wildcard ? host.replaceFirst('*.', '') : host;
  if (!wildcard && host.contains('*')) return false;

  return _validCspHostLabels(hostWithoutWildcard);
}

bool _validCspHostLabels(String host) =>
    _cspHostPattern.hasMatch(host) &&
    host
        .split('.')
        .every((label) => !label.startsWith('-') && !label.endsWith('-'));

String _formatCspOrigin(Uri uri, String host) =>
    '${uri.scheme}://$host${uri.hasPort ? ':${uri.port}' : ''}';

const _nativeHostPage = r'''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Security-Policy" content="__HOST_CONTENT_SECURITY_POLICY__">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>html,body{margin:0;width:100%;height:100%;overflow:hidden}iframe{border:0;width:100%;height:100%}</style>
</head>
<body>
  <iframe id="mcp-app-view" sandbox="allow-scripts" referrerpolicy="no-referrer"></iframe>
  <script>
    const appHtmlBase64 = "__APP_HTML_BASE64__";
    const appCspBase64 = "__APP_CSP_BASE64__";
    const view = document.getElementById('mcp-app-view');
    const decode = (value) => new TextDecoder().decode(Uint8Array.from(atob(value), (char) => char.charCodeAt(0)));
    const appHtml = decode(appHtmlBase64);
    const appCsp = decode(appCspBase64);
    const escapeAttribute = (value) => value.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
    const appDocument = (html) => {
      const tag = '<meta http-equiv="Content-Security-Policy" content="' + escapeAttribute(appCsp) + '">';
      const head = /<head(?:\s[^>]*)?>/i;
      return head.test(html)
        ? html.replace(head, (match) => match + tag)
        : '<!doctype html><html><head>' + tag + '</head><body>' + html + '</body></html>';
    };
    const callHost = (message) => {
      const send = () => window.flutter_inappwebview.callHandler('mcpAppsMessage', JSON.stringify(message)).catch(() => {});
      if (window.flutter_inappwebview?.callHandler) send();
      else window.addEventListener('flutterInAppWebViewPlatformReady', send, {once: true});
    };
    view.srcdoc = appDocument(appHtml);
    window.addEventListener('message', (event) => {
      if (event.source === view.contentWindow) callHost(event.data);
    });
    window.mcpAppsReply = (message) => view.contentWindow.postMessage(message, '*');
  </script>
</body>
</html>
''';

const _webHostPage = '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Security-Policy" content="__HOST_CONTENT_SECURITY_POLICY__">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>html,body{margin:0;width:100%;height:100%;overflow:hidden}iframe{border:0;width:100%;height:100%}</style>
</head>
<body>
  <!-- data: URL keeps this proxy cross-origin from the host while it uses allow-same-origin -->
  <iframe id="mcp-app-sandbox" sandbox="allow-scripts allow-same-origin" referrerpolicy="no-referrer"></iframe>
  <script>
    const appHtmlBase64 = "__APP_HTML_BASE64__";
    const appCspBase64 = "__APP_CSP_BASE64__";
    const proxyHtmlBase64 = "__PROXY_HTML_BASE64__";
    const proxy = document.getElementById('mcp-app-sandbox');
    const decode = (value) => new TextDecoder().decode(Uint8Array.from(atob(value), (char) => char.charCodeAt(0)));
    const appHtml = decode(appHtmlBase64);
    const appCsp = decode(appCspBase64);
    const callHost = (message) => {
      const send = () => window.flutter_inappwebview.callHandler('mcpAppsMessage', JSON.stringify(message)).catch(() => {});
      if (window.flutter_inappwebview?.callHandler) send();
      else window.addEventListener('flutterInAppWebViewPlatformReady', send, {once: true});
    };
    proxy.src = 'data:text/html;base64,' + proxyHtmlBase64;
    window.addEventListener('message', (event) => {
      if (event.source !== proxy.contentWindow) return;
      const message = event.data;
      if (message?.method === 'ui/notifications/sandbox-proxy-ready') {
        proxy.contentWindow.postMessage({jsonrpc: '2.0', method: 'ui/notifications/sandbox-resource-ready', params: {html: appHtml, csp: appCsp}}, '*');
      } else {
        callHost(message);
      }
    });
    window.mcpAppsReply = (message) => proxy.contentWindow.postMessage(message, '*');
  </script>
</body>
</html>
''';

const _webSandboxProxyPage = r'''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Security-Policy" content="__PROXY_CONTENT_SECURITY_POLICY__">
  <style>html,body{margin:0;width:100%;height:100%;overflow:hidden}iframe{border:0;width:100%;height:100%}</style>
</head>
<body>
  <script>
    let view;
    const escapeAttribute = (value) => value.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
    const appDocument = (html, csp) => {
      const tag = '<meta http-equiv="Content-Security-Policy" content="' + escapeAttribute(csp) + '">';
      const head = /<head(?:\s[^>]*)?>/i;
      return head.test(html)
        ? html.replace(head, (match) => match + tag)
        : '<!doctype html><html><head>' + tag + '</head><body>' + html + '</body></html>';
    };
    window.parent.postMessage({jsonrpc: '2.0', method: 'ui/notifications/sandbox-proxy-ready', params: {}}, '*');
    window.addEventListener('message', (event) => {
      if (event.source === window.parent) {
        const message = event.data;
        if (message?.method === 'ui/notifications/sandbox-resource-ready') {
          const resource = message.params || {};
          if (typeof resource.html !== 'string' || typeof resource.csp !== 'string') return;
          const frame = document.createElement('iframe');
          frame.setAttribute('sandbox', 'allow-scripts');
          frame.setAttribute('referrerpolicy', 'no-referrer');
          frame.srcdoc = appDocument(resource.html, resource.csp);
          document.body.replaceChildren(frame);
          view = frame;
        } else if (view) {
          view.contentWindow.postMessage(message, '*');
        }
      } else if (view && event.source === view.contentWindow) {
        if (event.data?.method?.startsWith('ui/notifications/sandbox-')) return;
        window.parent.postMessage(event.data, '*');
      }
    });
  </script>
</body>
</html>
''';
