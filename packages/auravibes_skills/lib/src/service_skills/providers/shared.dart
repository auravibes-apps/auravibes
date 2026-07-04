import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_skills/src/execution/skill_http_client.dart';
import 'package:auravibes_skills/src/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_skills/src/models/skill_template_input_definition.dart';
import 'package:auravibes_skills/src/models/url_request.dart';
import 'package:auravibes_skills/src/models/url_request_method.dart';

const Map<String, Object> searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'maxResults': {'type': 'integer', 'minimum': 1},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> fetchInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
  },
  'required': ['url'],
  'additionalProperties': false,
};

const Map<String, Object> answerInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const Map<String, Object> rerankInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'documents': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['query', 'documents'],
  'additionalProperties': false,
};

const queryInputs = {
  'query': SkillTemplateInputDefinition(description: 'Search query.'),
  'maxResults': SkillTemplateInputDefinition(
    description: 'Maximum number of results.',
    type: 'integer',
    optional: true,
  ),
};

const urlInputs = {
  'url': SkillTemplateInputDefinition(description: 'URL to fetch.'),
};

const questionInputs = {
  'question': SkillTemplateInputDefinition(description: 'Question to answer.'),
};

const rerankInputs = {
  'query': SkillTemplateInputDefinition(description: 'Search query.'),
  'documents': SkillTemplateInputDefinition(
    description: 'JSON array of documents to rerank.',
    type: 'array',
  ),
};

const apiKeyCredentialDefinitions = {
  'apiKey': SkillCredentialAttributeDefinition(description: 'API key.'),
};

CancelableOperation<Object?> postJson(
  SkillHttpClient request,
  String url,
  Map<String, String> headers,
  Map<String, Object?> body,
) {
  return request(
    AppSkillUrlRequest(
      url: url,
      method: UrlRequestMethod.post,
      headers: {'content-type': 'application/json', ...headers},
      body: jsonEncode(body),
    ),
  ).then<Object?>((response) => response.body);
}

String apiKey(Map<String, dynamic> input) {
  final credential = input['credential'];
  if (credential is Map) {
    final apiKey = credential['apiKey'];
    if (apiKey is String && apiKey.trim().isNotEmpty) return apiKey;
  }

  throw const FormatException('Credential apiKey is required.');
}

String textInput(Map<String, dynamic> input, String key) {
  final value = input[key];
  return value is String ? value : '';
}

String stringInput(
  Map<String, dynamic> input,
  String key, {
  String defaultValue = '',
}) {
  final value = input[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();

  return defaultValue;
}

int? positiveIntInput(Map<String, dynamic> input, String key) {
  final value = input[key];
  return value is int && value > 0 ? value : null;
}

bool? boolInput(Map<String, dynamic> input, String key) {
  final value = input[key];
  return value is bool ? value : null;
}

List<String>? stringListInput(Map<String, dynamic> input, String key) {
  final value = input[key];
  if (value is! List) return null;
  final strings = [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];

  return strings.isEmpty ? null : strings;
}

void putIfPresent(Map<String, Object?> target, String key, Object? value) {
  if (value == null) return;
  if (value is String && value.trim().isEmpty) return;
  if (value is List && value.isEmpty) return;
  if (value is Map && value.isEmpty) return;
  target[key] = value;
}

Map<String, Object>? approximateLocation(Map<String, dynamic> input) {
  final location = <String, Object>{'type': 'approximate'};
  putIfPresent(location, 'country', stringInput(input, 'country'));
  putIfPresent(location, 'region', stringInput(input, 'region'));
  putIfPresent(location, 'city', stringInput(input, 'city'));
  putIfPresent(location, 'timezone', stringInput(input, 'timezone'));

  return location.length == 1 ? null : location;
}
