// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:auravibes_app/services/model_provider_services/models/antropic_response_models_item.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';

class const ModelProvider({
  required final CredentialsModelType type,
  required final String key,
  final String? url,
});

class ModelProviderServices {
  Future<List<WorkspaceModelSelectionToCreate>?> getWorkspaceModelSelections(
    ModelProvider provider,
  ) => switch (provider.type) {
    .openai => _openAiSelections(provider),
    .openrouter => _openRouterSelections(provider),
    .anthropic => _anthropicSelections(provider),
    _ => Future.value(),
  };
}

Future<List<WorkspaceModelSelectionToCreate>> _openAiSelections(
  ModelProvider provider,
) async {
  final baseUrl = await _providerBaseUrl(
    provider.url,
    fallback: 'https://api.openai.com/v1',
  );
  final client = OpenAIClient.withApiKey(provider.key, baseUrl: baseUrl);
  final models = await client.models.list();

  return models.data.map(_openAiSelection).toList();
}

WorkspaceModelSelectionToCreate _openAiSelection(Model model) =>
    _selection(model.id);

Future<List<WorkspaceModelSelectionToCreate>?> _openRouterSelections(
  ModelProvider provider,
) async {
  if (!await _validateOpenRouterKey(provider)) return null;
  final models = await _openRouterModels(provider);

  return models?.map(_selection).toList();
}

Future<List<WorkspaceModelSelectionToCreate>> _anthropicSelections(
  ModelProvider provider,
) async =>
    (await _anthopicAllModels(provider))
        .map((model) => _selection(model.id))
        .toList();

WorkspaceModelSelectionToCreate _selection(String modelId) =>
    WorkspaceModelSelectionToCreate(modelId: modelId, modelConnectionId: '');

Future<bool> _validateOpenRouterKey(ModelProvider provider) async {
  try {
    final request = await _openRouterGet(provider, '/key');

    return _isSuccessStatus(request.statusCode);
  } on Exception {
    return false;
  }
}

Future<List<String>?> _openRouterModels(ModelProvider provider) async {
  try {
    final request = await _openRouterGet(provider, '/models');
    if (!_isSuccessStatus(request.statusCode)) return null;

    return _openRouterModelIds(request.body);
  } on Exception {
    return null;
  }
}

bool _isSuccessStatus(int statusCode) => statusCode >= 200 && statusCode < 300;

List<String>? _openRouterModelIds(String body) {
  final json = jsonDecode(body);
  if (json is! Map<String, dynamic>) return null;

  final data = json['data'];
  if (data is! List) return null;

  return data.map(_modelId).nonNulls.toList();
}

Future<http.Response> _openRouterGet(
  ModelProvider provider,
  String path,
) async {
  final url = await _providerBaseUrl(
    provider.url,
    fallback: 'https://openrouter.ai/api/v1',
  );

  return await http
      .get(_openRouterUri(url, path), headers: _openRouterHeaders(provider.key))
      .timeout(const Duration(seconds: 10));
}

Uri _openRouterUri(String baseUrl, String path) =>
    Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');

Map<String, String> _openRouterHeaders(String key) => {
  'authorization': 'Bearer $key',
  'accept': 'application/json',
};

String? _modelId(Object? model) {
  if (model is! Map<String, dynamic>) return null;
  final id = model['id'];

  return id is String ? id : null;
}

Future<List<AntropicResponseModelsItem>> _anthopicAllModels(
  ModelProvider provider,
) => _collectAnthropicModels(provider, []);

Future<List<AntropicResponseModelsItem>> _collectAnthropicModels(
  ModelProvider provider,
  List<AntropicResponseModelsItem> foundModels, [
  String? afterId,
]) async {
  final response = await _anthopicModels(provider, afterId);
  final page = _appendAnthropicPage(foundModels, response);
  if (!page.hasMore) return foundModels;

  return await _collectAnthropicModels(provider, foundModels, page.lastId);
}

({bool hasMore, String? lastId}) _appendAnthropicPage(
  List<AntropicResponseModelsItem> foundModels,
  AntropicResponseModels response,
) {
  if (response case AntropicResponseModelsData(
    data: final models,
    :final hasMore,
    :final lastId,
  )) {
    foundModels.addAll(models);

    return (hasMore: hasMore, lastId: lastId);
  }

  return (hasMore: false, lastId: null);
}

Future<AntropicResponseModels> _anthopicModels(
  ModelProvider provider, [
  String? afterId,
]) async {
  final request = await _anthropicGet(provider, afterId);

  final json = jsonDecode(request.body) as Map<String, dynamic>;

  return AntropicResponseModels.fromJson(json);
}

Future<http.Response> _anthropicGet(
  ModelProvider provider,
  String? afterId,
) async {
  final url = await _providerBaseUrl(
    provider.url,
    fallback: 'https://api.anthropic.com/v1',
  );

  return await http.get(
    _anthropicModelsUri(url, afterId),
    headers: _anthropicHeaders(provider.key),
  );
}

Uri _anthropicModelsUri(String baseUrl, String? afterId) =>
    Uri.parse('$baseUrl/models')
        .replace(queryParameters: {'limit': '1000', 'after_id': ?afterId});

Map<String, String> _anthropicHeaders(String key) => {
  'x-api-key': key,
  'anthropic-version': '2023-06-01',
};

Future<String> _providerBaseUrl(String? url, {required String fallback}) async {
  final uri = await PublicUrlGuard.requireHttpsUri(url ?? fallback);

  return uri.toString().replaceFirst(RegExp(r'/$'), '');
}
