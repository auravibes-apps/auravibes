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
    final supportsReasoning = config.workspaceModelSelection.supportsReasoning;
    final baseUrl = config.modelConnection.url ?? config.modelsProvider.url;

    if (type == null) {
      if (baseUrl != null) {
        return _createChatModel(
          apiKey: apiKey,
          baseUrl: baseUrl,
          modelId: modelId,
          supportsReasoning: supportsReasoning,
          tools: tools,
        );
      }
      throw ArgumentError('Provider type is null and no baseUrl provided');
    }

    final resolvedBaseUrl = _resolveBaseUrl(config);

    return _createChatModel(
      apiKey: apiKey,
      modelId: modelId,
      providerType: type,
      baseUrl: resolvedBaseUrl,
      supportsReasoning: supportsReasoning,
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

    final resolvedBaseUrl = _resolveBaseUrl(config);

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
    bool supportsReasoning = false,
    List<Tool>? tools,
  }) {
    final provider = _createProvider(
      providerType: providerType,
      apiKey: apiKey,
      baseUrl: baseUrl,
      supportsReasoning: supportsReasoning,
    );
    return provider.createChatModel(
      name: modelId,
      tools: tools,
      enableThinking: _canEnableThinking(
        providerType: providerType,
        baseUrl: baseUrl,
        supportsReasoning: supportsReasoning,
      ),
    );
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
    bool supportsReasoning = false,
  }) {
    if (_usesOpenAIResponses(
      providerType: providerType,
      baseUrl: baseUrl,
      supportsReasoning: supportsReasoning,
    )) {
      return OpenAIResponsesProvider(
        apiKey: apiKey,
        baseUrl: _openAIResponsesBaseUrl(providerType, baseUrl),
      );
    }

    // AnthropicProvider doesn't accept baseUrl in its constructor.
    // When a custom URL is set, fall through to OpenAIProvider which
    // supports custom endpoints (most Anthropic proxies are OpenAI-compatible).
    if (providerType == ModelProvidersType.anthropic && baseUrl == null) {
      return AnthropicProvider(apiKey: apiKey);
    }

    return OpenAIProvider(
      apiKey: apiKey,
      baseUrl: baseUrl != null ? Uri.parse(baseUrl) : null,
    );
  }

  bool _canEnableThinking({
    required ModelProvidersType? providerType,
    required String? baseUrl,
    required bool supportsReasoning,
  }) {
    if (!supportsReasoning) return false;
    if (providerType == ModelProvidersType.anthropic && baseUrl == null) {
      return true;
    }
    return _usesOpenAIResponses(
      providerType: providerType,
      baseUrl: baseUrl,
      supportsReasoning: supportsReasoning,
    );
  }

  bool _usesOpenAIResponses({
    required ModelProvidersType? providerType,
    required String? baseUrl,
    required bool supportsReasoning,
  }) {
    return supportsReasoning &&
        providerType == ModelProvidersType.openai &&
        _isOfficialProviderUrl(providerType, baseUrl);
  }

  bool _hasCustomUrl(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final connectionUrl = config.modelConnection.url;
    final providerUrl = config.modelsProvider.url;
    return connectionUrl != null && connectionUrl != providerUrl;
  }

  String? _resolveBaseUrl(WorkspaceModelSelectionWithConnectionEntity config) {
    final connectionUrl = config.modelConnection.url;
    final providerUrl = config.modelsProvider.url;

    if (_hasCustomUrl(config)) return connectionUrl;
    return providerUrl;
  }

  Uri? _openAIResponsesBaseUrl(ModelProvidersType? type, String? baseUrl) {
    if (_isOfficialProviderUrl(type, baseUrl)) return null;
    return baseUrl != null ? Uri.parse(baseUrl) : null;
  }

  bool _isOfficialProviderUrl(ModelProvidersType? type, String? url) {
    final host = url == null ? null : Uri.tryParse(url)?.host;
    return switch (type) {
      ModelProvidersType.openai => host == null || host == 'api.openai.com',
      ModelProvidersType.anthropic =>
        host == null || host == 'api.anthropic.com',
      null => false,
    };
  }
}
