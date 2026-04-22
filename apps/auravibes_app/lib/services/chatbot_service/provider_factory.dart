import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:dartantic_ai/dartantic_ai.dart';

class ProviderFactory {
  const ProviderFactory();

  ChatModel call(
    WorkspaceModelSelectionWithConnectionEntity config, {
    required String apiKey,
    List<Tool>? tools,
  }) {
    final type = config.modelsProvider.type;
    final modelId = config.workspaceModelSelection.modelId;
    final baseUrl = config.modelConnection.url ?? config.modelsProvider.url;

    if (type == null) {
      if (baseUrl != null) {
        return _createChatModel(
          apiKey: apiKey,
          baseUrl: baseUrl,
          modelId: modelId,
          tools: tools,
        );
      }
      throw ArgumentError('Provider type is null and no baseUrl provided');
    }

    final resolvedBaseUrl =
        (_hasCustomUrl(config) ? baseUrl : null) ?? config.modelsProvider.url;

    return _createChatModel(
      apiKey: apiKey,
      modelId: modelId,
      providerType: type,
      baseUrl: resolvedBaseUrl,
      tools: tools,
    );
  }

  Agent createAgent(
    WorkspaceModelSelectionWithConnectionEntity config, {
    required String apiKey,
  }) {
    final type = config.modelsProvider.type;
    final modelId = config.workspaceModelSelection.modelId;
    final baseUrl = config.modelConnection.url ?? config.modelsProvider.url;

    if (type == null) {
      if (baseUrl == null) {
        throw ArgumentError('Provider type is null and no baseUrl provided');
      }
      return _createAgentOnly(
        apiKey: apiKey,
        baseUrl: baseUrl,
        modelId: modelId,
      );
    }

    final resolvedBaseUrl =
        (_hasCustomUrl(config) ? baseUrl : null) ?? config.modelsProvider.url;

    return _createAgentOnly(
      apiKey: apiKey,
      modelId: modelId,
      providerType: type,
      baseUrl: resolvedBaseUrl,
    );
  }

  ChatModel _createChatModel({
    required String apiKey,
    required String modelId,
    ModelProvidersType? providerType,
    String? baseUrl,
    List<Tool>? tools,
  }) {
    final provider = _createProvider(
      providerType: providerType,
      apiKey: apiKey,
      baseUrl: baseUrl,
    );
    return provider.createChatModel(name: modelId, tools: tools);
  }

  Agent _createAgentOnly({
    required String apiKey,
    required String modelId,
    ModelProvidersType? providerType,
    String? baseUrl,
  }) {
    final provider = _createProvider(
      providerType: providerType,
      apiKey: apiKey,
      baseUrl: baseUrl,
    );
    return Agent.forProvider(provider, chatModelName: modelId);
  }

  Provider _createProvider({
    required String apiKey,
    ModelProvidersType? providerType,
    String? baseUrl,
  }) {
    if (providerType == ModelProvidersType.anthropic && baseUrl == null) {
      return AnthropicProvider(apiKey: apiKey);
    }

    return OpenAIProvider(
      apiKey: apiKey,
      baseUrl: baseUrl != null ? Uri.parse(baseUrl) : null,
    );
  }

  bool _hasCustomUrl(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final connectionUrl = config.modelConnection.url;
    final providerUrl = config.modelsProvider.url;
    return connectionUrl != null && connectionUrl != providerUrl;
  }
}
