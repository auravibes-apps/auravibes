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
    CredentialsModelType.openai => _openAiSelections(provider),
    CredentialsModelType.openrouter => _openRouterSelections(provider),
    CredentialsModelType.anthropic => _anthropicSelections(provider),
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
  final models = await OpenAIClient.withApiKey(
    provider.key,
    baseUrl: baseUrl,
  ).models.list();
  return models.data.map((model) => _selection(model.id)).toList();
}

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
  return http
      .get(
        .parse('${url.replaceFirst(RegExp(r'/$'), '')}$path'),
        headers: <String, String>{
          'authorization': 'Bearer ${provider.key}',
          'accept': 'application/json',
        },
      )
      .timeout(const Duration(seconds: 10));
}

String? _modelId(Object? model) {
  if (model is! Map<String, dynamic>) return null;
  final id = model['id'];
  return id is String ? id : null;
}

Future<List<AntropicResponseModelsItem>> _anthopicAllModels(
  ModelProvider provider,
) async {
  var fetchMore = true;
  String? afterId;
  final foundModels = <AntropicResponseModelsItem>[];

  while (fetchMore) {
    final modelsResponse = await _anthopicModels(provider, afterId);

    if (modelsResponse case AntropicResponseModelsData(
      data: final models,
      :final hasMore,
      :final lastId,
    )) {
      foundModels.addAll(models);
      fetchMore = hasMore;
      afterId = lastId;
    }
  }

  return foundModels;
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
  final queryParameters = <String, dynamic>{'limit': '1000'};
  if (afterId != null) queryParameters['after_id'] = afterId;

  return http.get(
    Uri.parse('$url/models').replace(queryParameters: queryParameters),
    headers: <String, String>{
      'x-api-key': provider.key,
      'anthropic-version': '2023-06-01',
    },
  );
}

Future<String> _providerBaseUrl(String? url, {required String fallback}) async {
  final uri = await PublicUrlGuard.requireHttpsUri(url ?? fallback);

  return uri.toString().replaceFirst(RegExp(r'/$'), '');
}
