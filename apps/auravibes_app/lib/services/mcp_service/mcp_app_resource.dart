import 'dart:convert';

class McpAppResource {
  const McpAppResource({required this.html, required this.csp});

  final String html;
  final Map<String, Object?> csp;

  factory McpAppResource.fromReadResult(
    Map<String, Object?> result, {
    required String resourceUri,
  }) {
    final contents = result['contents'];
    if (contents is! List) {
      throw const FormatException('MCP App resource has no content.');
    }
    final matchingContents = contents.where(
      (content) => content is Map && content['uri'] == resourceUri,
    );
    if (matchingContents.length != 1) {
      throw const FormatException('MCP App resource content did not match.');
    }
    final content = Map<String, Object?>.from(matchingContents.single as Map);
    if (content['mimeType'] != 'text/html;profile=mcp-app') {
      throw UnsupportedError('Unsupported MCP App resource MIME type.');
    }
    final text = content['text'];
    final blob = content['blob'];
    final String html;
    if (text is String) {
      html = text;
    } else if (blob is String) {
      try {
        html = utf8.decode(base64Decode(blob));
      } on FormatException {
        throw const FormatException('MCP App resource blob is invalid.');
      }
    } else {
      throw const FormatException('MCP App resource has no HTML content.');
    }

    return McpAppResource(html: html, csp: _resourceCsp(content['_meta']));
  }
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
}) {
  final appHtmlBase64 = base64Encode(utf8.encode(html));
  final appCspBase64 = base64Encode(utf8.encode(_contentSecurityPolicy(csp)));
  final hostContentSecurityPolicy = _hostContentSecurityPolicy(isWeb);
  final template = isWeb ? _webHostPage : _nativeHostPage;

  return template
      .replaceAll('__APP_HTML_BASE64__', appHtmlBase64)
      .replaceAll('__APP_CSP_BASE64__', appCspBase64)
      .replaceAll('__HOST_CONTENT_SECURITY_POLICY__', hostContentSecurityPolicy)
      .replaceAll(
        '__PROXY_HTML_BASE64__',
        base64Encode(utf8.encode(_webSandboxProxyPage)),
      );
}

String _hostContentSecurityPolicy(bool isWeb) => [
  "default-src 'none'",
  "script-src 'unsafe-inline'",
  "style-src 'unsafe-inline'",
  'frame-src ${isWeb ? 'data:' : "'self' data:"}',
  "img-src 'none'",
  "connect-src 'none'",
  "object-src 'none'",
  "base-uri 'none'",
  "form-action 'none'",
].join('; ');

String _contentSecurityPolicy(Map<String, Object?> csp) {
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
  final frames = _allowedDomains(csp['frameDomains'], const {'http', 'https'});
  final bases = _allowedDomains(csp['baseUriDomains'], const {'http', 'https'});

  return [
    "default-src 'none'",
    "script-src 'unsafe-inline' ${resources.join(' ')}".trim(),
    "style-src 'unsafe-inline' ${resources.join(' ')}".trim(),
    "img-src data: blob: ${resources.join(' ')}".trim(),
    'font-src ${resources.isEmpty ? "'none'" : resources.join(' ')}',
    'media-src ${resources.isEmpty ? "'none'" : resources.join(' ')}',
    'connect-src ${connections.isEmpty ? "'none'" : connections.join(' ')}',
    'frame-src ${frames.isEmpty ? "'none'" : frames.join(' ')}',
    'base-uri ${bases.isEmpty ? "'self'" : bases.join(' ')}',
    "object-src 'none'",
    "form-action 'none'",
  ].join('; ');
}

List<String> _allowedDomains(Object? value, Set<String> allowedSchemes) {
  if (value is! List) return const [];

  return [
    for (final domain in value.whereType<String>())
      if (_allowedDomain(domain, allowedSchemes) case final safeDomain?)
        safeDomain,
  ];
}

String? _allowedDomain(String value, Set<String> allowedSchemes) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !allowedSchemes.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  final host = uri.host;
  final wildcard = host.startsWith('*.');
  final hostWithoutWildcard = wildcard ? host.substring(2) : host;
  if ((!wildcard && host.contains('*')) ||
      !RegExp(r'^[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$')
          .hasMatch(hostWithoutWildcard) ||
      hostWithoutWildcard
          .split('.')
          .any((label) => label.startsWith('-') || label.endsWith('-'))) {
    return null;
  }

  return '${uri.scheme}://$host${uri.hasPort ? ':${uri.port}' : ''}';
}

const _nativeHostPage = '''
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
    const appDocument = (html) => '<meta http-equiv="Content-Security-Policy" content="' + escapeAttribute(appCsp) + '">' + html;
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

const _webSandboxProxyPage = '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; frame-src 'self'; connect-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'">
  <style>html,body{margin:0;width:100%;height:100%;overflow:hidden}iframe{border:0;width:100%;height:100%}</style>
</head>
<body>
  <script>
    let view;
    const escapeAttribute = (value) => value.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
    const appDocument = (html, csp) => {
      const tag = '<meta http-equiv="Content-Security-Policy" content="' + escapeAttribute(csp) + '">';
      const head = /<head(?:\\s[^>]*)?>/i;
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
