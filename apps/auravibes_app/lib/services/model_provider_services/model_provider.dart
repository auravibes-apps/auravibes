// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:auravibes_app/services/model_provider_services/models/antropic_response_models_item.dart';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';

class ModelProvider {
  const ModelProvider({required this.type, required this.key, this.url});
  final CredentialsModelType type;
  final String key;
  final String? url;
}

class ModelProviderServices {
  Future<List<WorkspaceModelSelectionToCreate>?> getWorkspaceModelSelections(
    ModelProvider provider,
  ) async {
    if (provider.type == CredentialsModelType.openai) {
      final client = OpenAIClient.withApiKey(
        provider.key,
        baseUrl: provider.url ?? 'https://api.openai.com/v1',
      );

      final modelsResponse = await client.models.list();

      return modelsResponse.data
          .map(
            (model) => WorkspaceModelSelectionToCreate(
              modelId: model.id,
              modelConnectionId: '',
            ),
          )
          .toList();
    }

    if (provider.type == CredentialsModelType.openrouter) {
      final isValidKey = await _validateOpenRouterKey(provider);
      if (!isValidKey) return null;

      final models = await _openRouterModels(provider);
      if (models == null) return null;

      return models
          .map(
            (modelId) => WorkspaceModelSelectionToCreate(
              modelId: modelId,
              modelConnectionId: '',
            ),
          )
          .toList();
    }

    if (provider.type == CredentialsModelType.anthropic) {
      // Models.values.
      final models = await _anthopicAllModels(provider);

      return models
          .map(
            (model) => WorkspaceModelSelectionToCreate(
              modelId: model.id,
              modelConnectionId: '',
            ),
          )
          .toList();
    }

    return null;
  }
}

Future<bool> _validateOpenRouterKey(ModelProvider provider) async {
  final url = provider.url ?? 'https://openrouter.ai/api/v1';
  try {
    final request = await http
        .get(
          Uri.parse('${url.replaceFirst(RegExp(r'/$'), '')}/key'),
          headers: <String, String>{
            'authorization': 'Bearer ${provider.key}',
            'accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    return request.statusCode >= 200 && request.statusCode < 300;
  } on Exception {
    return false;
  }
}

Future<List<String>?> _openRouterModels(ModelProvider provider) async {
  final url = provider.url ?? 'https://openrouter.ai/api/v1';
  try {
    final request = await http
        .get(
          Uri.parse('${url.replaceFirst(RegExp(r'/$'), '')}/models'),
          headers: <String, String>{
            'authorization': 'Bearer ${provider.key}',
            'accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (request.statusCode < 200 || request.statusCode >= 300) return null;

    final json = jsonDecode(request.body);
    if (json is! Map<String, dynamic>) return null;

    final data = json['data'];
    if (data is! List) return null;

    return data
        .map((model) {
          if (model is! Map<String, dynamic>) return null;

          final id = model['id'];

          return id is String ? id : null;
        })
        .nonNulls
        .toList();
  } on Exception {
    return null;
  }
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
  final url = provider.url ?? 'https://api.anthropic.com/v1';
  final qp = <String, dynamic>{'limit': '1000'};

  if (afterId != null) {
    qp.addAll({'after_id': afterId});
  }
  final request = await http.get(
    Uri.parse('$url/models').replace(queryParameters: qp),
    headers: <String, String>{
      'x-api-key': provider.key,
      'anthropic-version': '2023-06-01',
    },
  );

  final json = jsonDecode(request.body) as Map<String, dynamic>;

  return AntropicResponseModels.fromJson(json);
}
