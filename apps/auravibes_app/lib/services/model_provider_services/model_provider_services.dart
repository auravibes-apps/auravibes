import 'dart:convert';

import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/enums/chat_models_type.dart';
import 'package:auravibes_app/services/model_provider_services/models/antropic_responses.dart';
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

    if (provider.type == CredentialsModelType.anthropic) {
      // Models.values
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
