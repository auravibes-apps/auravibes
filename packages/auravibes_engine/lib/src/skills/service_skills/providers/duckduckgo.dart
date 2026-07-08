import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/url_request.dart';
import 'package:auravibes_engine/src/skills/models/url_request_method.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const duckDuckGoSkill = AppSkillDefinition(
  identifier: 'duckduckgo',
  slug: 'duckduckgo',
  title: 'DuckDuckGo Search',
  description: 'Search DuckDuckGo web results without an API key.',
  content: '''
Use DuckDuckGo for key-free web search results. This integration gathers
results from DuckDuckGo's no-script search pages, so it is experimental and
can fail if DuckDuckGo changes markup or blocks automated traffic.
''',
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search DuckDuckGo web results for a query.',
      inputJsonSchema: _searchInputSchema,
      callback: _search,
    ),
  ],
);

const _endpoint = 'https://html.duckduckgo.com/html/';
const _defaultMaxResults = 10;
const _maxResults = 20;

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'maxResults': {'type': 'integer', 'minimum': 1},
    'region': {'type': 'string'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _search(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final query = textInput(input, 'query');
  final maxResults = _maxResultCount(input['maxResults']);
  final region = stringInput(input, 'region', defaultValue: 'us-en');
  final body = '${Uri(queryParameters: {'q': query, 'kl': region}).query}&b=';

  return context(
    AppSkillUrlRequest(
      url: _endpoint,
      method: UrlRequestMethod.post,
      headers: const {
        'accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'accept-language': 'en,en-US;q=0.9',
        'cache-control': 'max-age=0',
        'content-type': 'application/x-www-form-urlencoded',
        'referer': 'https://html.duckduckgo.com/',
        'user-agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
      },
      body: body,
    ),
  ).then<Object?>((response) {
    final html = response.body;
    if (_isAnomalyResponse(html)) {
      throw StateError(
        'DuckDuckGo blocked the search with a bot-detection challenge. '
        'Use Brave, Tavily, Exa, Kagi, or SearXNG for reliable web search.',
      );
    }

    final results = _parseHtmlResults(html)
        .take(maxResults)
        .map(
          (result) => {
            'title': result.title,
            'url': result.url,
            if (result.snippet != null) 'snippet': result.snippet,
          },
        )
        .toList();

    return jsonEncode({
      'provider': 'duckduckgo',
      'query': query,
      'sources': results,
    });
  });
}

int _maxResultCount(Object? value) {
  final parsed = switch (value) {
    final int count => count,
    final num count => count.toInt(),
    final String count => int.tryParse(count) ?? _defaultMaxResults,
    _ => _defaultMaxResults,
  };

  return parsed.clamp(1, _maxResults);
}

List<_DuckDuckGoResult> _parseHtmlResults(String html) {
  final results = <_DuckDuckGoResult>[];
  final seen = <String>{};
  final blockRegex = RegExp(
    r'<div\b[^>]*\bclass="[^"]*\bresult\b[^"]*"[^>]*>([\s\S]*?)'
    r'(?=<div\b[^>]*\bclass="[^"]*\bresult\b|'
    r'<div\b[^>]*\bclass="[^"]*\bnav-link\b|$)',
  );
  final titleRegex = RegExp(
    r'<a\b[^>]*\bclass="[^"]*\bresult__a\b[^"]*"[^>]*'
    r'\bhref="([^"]+)"[^>]*>([\s\S]*?)</a>',
  );
  final snippetRegex = RegExp(
    r'<(?:a|div|span)\b[^>]*\bclass="[^"]*\bresult__snippet\b[^"]*"'
    r'[^>]*>([\s\S]*?)</(?:a|div|span)>',
  );

  for (final blockMatch in blockRegex.allMatches(html)) {
    final block = blockMatch.group(1) ?? '';
    final titleMatch = titleRegex.firstMatch(block);
    if (titleMatch == null) continue;

    final url = _unwrapResultUrl(titleMatch.group(1) ?? '');
    if (url == null || seen.contains(url)) continue;

    final title = _decodeHtmlText(titleMatch.group(2) ?? '');
    if (title.isEmpty) continue;

    final snippetMatch = snippetRegex.firstMatch(block);
    final snippet = snippetMatch == null
        ? null
        : _decodeHtmlText(snippetMatch.group(1) ?? '');

    seen.add(url);
    results.add(
      _DuckDuckGoResult(
        title: title,
        url: url,
        snippet: snippet == null || snippet.isEmpty ? null : snippet,
      ),
    );
  }

  return results;
}

String _decodeHtmlText(String value) {
  return value
      .replaceAll(RegExp('<[^>]*>'), ' ')
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (match) => String.fromCharCode(int.parse(match.group(1)!)),
      )
      .replaceAllMapped(
        RegExp('&#x([0-9a-f]+);', caseSensitive: false),
        (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
      )
      .replaceAll(RegExp('&nbsp;', caseSensitive: false), ' ')
      .replaceAll(RegExp('&amp;', caseSensitive: false), '&')
      .replaceAll(RegExp('&lt;', caseSensitive: false), '<')
      .replaceAll(RegExp('&gt;', caseSensitive: false), '>')
      .replaceAll(RegExp('&quot;', caseSensitive: false), '"')
      .replaceAll(RegExp('&#39;|&apos;', caseSensitive: false), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _unwrapResultUrl(String href) {
  if (href.isEmpty) return null;

  final decoded = href.replaceAll(RegExp('&amp;', caseSensitive: false), '&');
  final wrapped = RegExp('[?&]uddg=([^&]+)').firstMatch(decoded);
  if (wrapped != null) {
    try {
      return Uri.decodeComponent(wrapped.group(1)!);
    } on FormatException {
      return null;
    }
  }

  if (decoded.startsWith('//')) return 'https:$decoded';
  if (decoded.startsWith('http://') || decoded.startsWith('https://')) {
    return decoded;
  }

  return null;
}

bool _isAnomalyResponse(String html) {
  return html.contains('anomaly-modal') || html.contains('anomaly.js');
}

class _DuckDuckGoResult {
  const _DuckDuckGoResult({
    required this.title,
    required this.url,
    this.snippet,
  });

  final String title;
  final String url;
  final String? snippet;
}
