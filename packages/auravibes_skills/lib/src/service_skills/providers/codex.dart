import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/models/url_request.dart';
import 'package:auravibes_skills/src/models/url_request_method.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

const codexSkill = AppSkillDefinition(
  identifier: 'codex',
  slug: 'codex',
  title: 'OpenAI Codex',
  description: 'Use Codex subscription web search.',
  content: '''
Use Codex when the user wants current web information through their Codex or
ChatGPT account. Return the answer and cite sources when available.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['openai-codex'],
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using Codex subscription web search.',
      inputJsonSchema: _codexWebSearchInputSchema,
      requiresCredential: true,
      callback: _webSearch,
    ),
  ],
);

const Map<String, Object> _codexWebSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string'},
    'searchContextSize': {
      'type': 'string',
      'enum': ['low', 'medium', 'high'],
      'description': 'Amount of web context to request.',
    },
    'webSearchMode': {
      'type': 'string',
      'enum': ['cached', 'indexed', 'live'],
      'description': 'Search freshness mode.',
    },
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'Optional domains to restrict results to.',
    },
    'blockedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'Optional domains to exclude from results.',
    },
    'country': {
      'type': 'string',
      'description': 'Optional approximate user country code.',
    },
    'region': {
      'type': 'string',
      'description': 'Optional approximate user region.',
    },
    'city': {
      'type': 'string',
      'description': 'Optional approximate user city.',
    },
    'timezone': {
      'type': 'string',
      'description': 'Optional approximate user timezone.',
    },
    'includeImages': {
      'type': 'boolean',
      'description': 'Whether image search content may be included.',
    },
    'maxOutputTokens': {
      'type': 'integer',
      'minimum': 1,
      'description': 'Optional response token cap.',
    },
  },
  'required': ['question'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _webSearch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return context(
    AppSkillUrlRequest(
      url: 'https://chatgpt.com/backend-api/codex/responses',
      method: UrlRequestMethod.post,
      headers: {
        'authorization': 'Bearer ${apiKey(input)}',
        if (_credentialValue(input, 'accountId') case final accountId?
            when accountId.isNotEmpty)
          'ChatGPT-Account-Id': accountId,
        'OpenAI-Beta': 'responses=experimental',
        'accept': 'text/event-stream',
        'content-type': 'application/json',
        'originator': 'auravibes',
        'user-agent': 'AuraVibes',
      },
      body: jsonEncode({
        'model': stringInput(input, 'model', defaultValue: 'gpt-5.5'),
        'stream': true,
        'store': false,
        'input': [
          {
            'type': 'message',
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': textInput(input, 'question')},
            ],
          },
        ],
        'tools': [_webSearchTool(input)],
        'tool_choice': {'type': 'web_search'},
        'max_output_tokens': ?positiveIntInput(input, 'maxOutputTokens'),
        'instructions':
            'Answer the question with current web information '
            'and cite sources.',
      }),
    ),
  ).then<Object?>((response) => _codexSearchJson(response.body));
}

String? _credentialValue(Map<String, dynamic> input, String key) {
  final credential = input['credential'];
  if (credential is Map) {
    final value = credential[key];
    if (value is String) return value;
  }

  return null;
}

String _searchContextSize(Map<String, dynamic> input) {
  return switch (input['searchContextSize']) {
    'low' => 'low',
    'medium' => 'medium',
    _ => 'high',
  };
}

Map<String, Object> _webSearchTool(Map<String, dynamic> input) {
  final mode = _webSearchMode(input);
  return {
    'type': 'web_search',
    'search_context_size': _searchContextSize(input),
    'external_web_access': mode != 'cached',
    if (mode == 'indexed') 'index_gated_web_access': true,
    if (_domainFilters(input) case final filters? when filters.isNotEmpty)
      'filters': filters,
    'user_location': ?approximateLocation(input),
    'search_content_types': [
      'text',
      if (input['includeImages'] == true) 'image',
    ],
  };
}

String _webSearchMode(Map<String, dynamic> input) {
  return switch (input['webSearchMode']) {
    'cached' => 'cached',
    'indexed' => 'indexed',
    _ => 'live',
  };
}

Map<String, Object>? _domainFilters(Map<String, dynamic> input) {
  final filters = <String, Object>{};
  putIfPresent(
    filters,
    'allowed_domains',
    stringListInput(input, 'allowedDomains'),
  );
  putIfPresent(
    filters,
    'blocked_domains',
    stringListInput(input, 'blockedDomains'),
  );

  return filters.isEmpty ? null : filters;
}

String _codexSearchJson(String body) {
  final jsonResponse = _decodeObject(body);
  if (jsonResponse != null) return _codexJsonResponse(jsonResponse);

  final streamedTextParts = <String>[];
  final finalTextParts = <String>[];
  final sources = <Map<String, String>>[];

  for (final line in const LineSplitter().convert(body)) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) continue;
    final data = trimmed.substring('data:'.length).trim();
    if (data.isEmpty || data == '[DONE]') continue;

    final decoded = _decodeObject(data);
    if (decoded == null) continue;
    switch (decoded['type']) {
      case 'response.output_text.delta':
        final delta = decoded['delta'];
        if (delta is String) streamedTextParts.add(delta);
      case 'response.output_text.annotation.added':
        _addAnnotation(decoded['annotation'], sources);
      case 'response.output_item.done':
        _addOutputItem(decoded['item'], finalTextParts, sources);
      case 'response.failed':
        throw StateError(_failureMessage(decoded));
      case 'error':
        throw StateError(_failureMessage(decoded));
    }
  }

  final finalAnswer = finalTextParts.join().trim();
  final streamedAnswer = streamedTextParts.join().trim();
  return jsonEncode({
    'answer': finalAnswer.isNotEmpty ? finalAnswer : streamedAnswer,
    'sources': sources,
  });
}

String _codexJsonResponse(Map<String, dynamic> response) {
  final textParts = <String>[];
  final sources = <Map<String, String>>[];

  final outputText = response['output_text'];
  if (outputText is String) textParts.add(outputText);

  final output = response['output'];
  if (output is List) {
    for (final item in output) {
      _addOutputItem(item, textParts, sources);
    }
  }

  return jsonEncode({
    'answer': textParts.join().trim(),
    'sources': sources,
  });
}

Map<String, dynamic>? _decodeObject(String data) {
  try {
    final decoded = jsonDecode(data);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

void _addOutputItem(
  Object? item,
  List<String> textParts,
  List<Map<String, String>> sources,
) {
  if (item is! Map) return;
  final content = item['content'];
  if (content is! List) return;
  for (final part in content) {
    if (part is! Map) continue;
    final text = part['text'];
    if (text is String) textParts.add(text);
    final annotations = part['annotations'];
    if (annotations is List) {
      for (final annotation in annotations) {
        _addAnnotation(annotation, sources);
      }
    }
  }
}

void _addAnnotation(Object? annotation, List<Map<String, String>> sources) {
  if (annotation is! Map) return;
  if (annotation['type'] != 'url_citation') return;
  final url = annotation['url'];
  if (url is! String || url.isEmpty) return;
  if (sources.any((source) => source['url'] == url)) return;
  final title = annotation['title'];
  sources.add({
    'url': url,
    'title': title is String && title.isNotEmpty ? title : url,
  });
}

String _failureMessage(Map<String, dynamic> event) {
  final message = event['message'];
  if (message is String && message.isNotEmpty) return message;
  final response = event['response'];
  if (response is Map) {
    final error = response['error'];
    if (error is Map) {
      final nestedMessage = error['message'];
      if (nestedMessage is String && nestedMessage.isNotEmpty) {
        return nestedMessage;
      }
    }
  }

  return 'Codex search failed.';
}
