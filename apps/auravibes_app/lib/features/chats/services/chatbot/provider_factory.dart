import 'dart:convert';

import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_encoder.dart';
import 'package:auravibes_app/features/chats/services/chatbot/app_anthropic_plugin.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_completions_plugin.dart';
import 'package:auravibes_app/features/chats/services/chatbot/openai_codex_plugin.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:genkit/genkit.dart';
import 'package:genkit/plugin.dart' show GenkitPlugin;
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_openai/genkit_openai.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

typedef UntypedModelRef = ModelRef<Object?>;
typedef _ProviderToolSampling = ({
  bool officialOpenAI,
  bool strictToolSampling,
  StrictToolSamplingProfile? profile,
});
typedef _ProviderSamplingContext = ({
  String? connectionUrl,
  _ProviderToolSampling toolSampling,
  ToolSamplingPolicy policy,
});
typedef _ProviderRequestContext = ({
  String apiKey,
  String? connectionUrl,
  String? sessionId,
  ReasoningConfiguration? reasoningConfiguration,
  _ProviderToolSampling toolSampling,
  ToolSamplingPolicy toolSamplingPolicy,
  List<AgentTranscriptContextEntry> transcriptContextEntries,
});
typedef _ProviderRequestInput = ({
  WorkspaceModelSelectionWithConnectionEntity config,
  String? sessionId,
  ReasoningConfiguration? reasoningConfiguration,
  List<AgentTranscriptContextEntry> transcriptContextEntries,
});
typedef _OpenAICompatPluginOptions = ({
  String name,
  ChatCompletionsCodec codec,
  bool modelSupportsStrictToolSampling,
  http.Client? httpClient,
});
typedef _ProviderRequest = ({
  WorkspaceModelSelectionWithConnectionEntity config,
  String apiKey,
  String? baseUrl,
  ProviderRuntimeSelection runtime,
  String modelId,
  String? sessionId,
  ReasoningConfiguration? reasoningConfiguration,
  _ProviderToolSampling toolSampling,
  ToolSamplingPolicy toolSamplingPolicy,
  List<AgentTranscriptContextEntry> transcriptContextEntries,
});
typedef _RuntimeRequest = ({
  String providerId,
  bool hasCustomUrl,
  bool supportsReasoning,
  bool usesOAuth,
  bool isCodexOAuth,
  String modelId,
});

class const ProviderFactory({
  required final ServiceConnectionRepository serviceConnectionRepository,
  final Future<String> Function(String id)? resolveOAuthAccessToken,
  final http.Client? httpClient,
}) {
  static const _openAIReasoningNamespace = 'openai_reasoning';
  Future<Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config, {
    String? sessionId,
    ReasoningConfiguration? reasoningConfiguration,
    List<AgentTranscriptContextEntry> transcriptContextEntries = const [],
  }) async {
    final request = await _providerRequest((
      config: config,
      sessionId: sessionId,
      reasoningConfiguration: reasoningConfiguration,
      transcriptContextEntries: transcriptContextEntries,
    ));

    return _createGenkit(request);
  }

  UntypedModelRef getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final runtime = _runtimeSelection(config, config.modelConnection.url);

    return _modelReference(config, runtime);
  }

  T? getGenerationConfig<T>(
    WorkspaceModelSelectionWithConnectionEntity config, [
    ReasoningConfiguration? reasoningConfiguration,
  ]) {
    final runtime = _runtimeSelection(config, config.modelConnection.url);
    final selectedConfiguration = _validConfiguration(
      config,
      reasoningConfiguration,
    );
    if (selectedConfiguration == null) return null;

    return _generationConfigFor<T>(config, runtime, selectedConfiguration);
  }

  @visibleForTesting
  String? resolvedBaseUrl(WorkspaceModelSelectionWithConnectionEntity config) {
    final connectionUrl = _blankToNull(config.modelConnection.url);
    if (connectionUrl != null) return connectionUrl;
    if (config.modelsProvider.type == ModelProvidersType.openrouter) {
      return null;
    }

    return _blankToNull(config.modelsProvider.url);
  }

  /// Returns affinity headers for supported provider transports only.
  @visibleForTesting
  Map<String, String> sessionAffinityHeaders({
    required ModelProvidersType? providerType,
    required String? baseUrl,
    required String? sessionId,
  }) {
    if (sessionId == null || sessionId.isEmpty) return const {};
    if (_supportsOpenRouterSessionAffinity(providerType, baseUrl)) {
      return {'x-session-id': sessionId};
    }
    if (_supportsAnthropicSessionAffinity(providerType, baseUrl)) {
      return {'x-session-affinity': sessionId};
    }

    return const {};
  }

  ReasoningConfiguration? _validConfiguration(
    WorkspaceModelSelectionWithConnectionEntity config,
    ReasoningConfiguration? value,
  ) {
    if (value == null ||
        !value.isValidFor(config.workspaceModelSelection.reasoningOptions)) {
      return null;
    }

    return value;
  }
}

bool _supportsOpenRouterSessionAffinity(
  ModelProvidersType? providerType,
  String? baseUrl,
) => providerType == .openrouter && baseUrl == null;

bool _supportsAnthropicSessionAffinity(
  ModelProvidersType? providerType,
  String? baseUrl,
) {
  if (providerType != .anthropic) return false;
  if (baseUrl == null) return true;
  final uri = Uri.tryParse(baseUrl);

  return uri?.scheme == 'https' &&
      uri?.host == 'api.anthropic.com' &&
      uri?.port == 443;
}

extension _ProviderFactoryGenerationConfig on ProviderFactory {
  T? _generationConfigFor<T>(
    WorkspaceModelSelectionWithConnectionEntity config,
    ProviderRuntimeSelection runtime,
    ReasoningConfiguration configuration,
  ) {
    if (runtime.runtime == ProviderRuntime.openAiReasoning) {
      return _openAIReasoningGenerationConfig<T>(configuration);
    }
    if (runtime.runtime == ProviderRuntime.anthropic) {
      return _anthropicGenerationConfig<T>(configuration);
    }
    if (config.modelsProvider.type == ModelProvidersType.openrouter) {
      return _openRouterGenerationConfig<T>(configuration);
    }

    return null;
  }
}

extension _ProviderFactoryRequest on ProviderFactory {
  Future<_ProviderRequest> _providerRequest(_ProviderRequestInput input) async {
    final context = await _providerRequestContext(input);

    return _createProviderRequest(input.config, context);
  }

  Future<_ProviderRequestContext> _providerRequestContext(
    _ProviderRequestInput input,
  ) async {
    final config = input.config;
    final sampling = _providerSamplingContext(config);
    final apiKey = await _resolveCredential(config);

    return (
      apiKey: apiKey,
      connectionUrl: sampling.connectionUrl,
      sessionId: input.sessionId,
      reasoningConfiguration: input.reasoningConfiguration,
      toolSampling: sampling.toolSampling,
      toolSamplingPolicy: sampling.policy,
      transcriptContextEntries: input.transcriptContextEntries,
    );
  }

  _ProviderSamplingContext _providerSamplingContext(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final connectionUrl = _blankToNull(config.modelConnection.url);
    final toolSampling = _providerToolSampling(config, connectionUrl);

    return (
      connectionUrl: connectionUrl,
      toolSampling: toolSampling,
      policy: _validatedToolSamplingPolicy(config, toolSampling),
    );
  }

  _ProviderRequest _createProviderRequest(
    WorkspaceModelSelectionWithConnectionEntity config,
    _ProviderRequestContext context,
  ) => (
    config: config,
    apiKey: context.apiKey,
    baseUrl: resolvedBaseUrl(config),
    runtime: _runtimeSelection(config, context.connectionUrl),
    modelId: config.workspaceModelSelection.modelId,
    sessionId: context.sessionId,
    reasoningConfiguration: context.reasoningConfiguration,
    toolSampling: context.toolSampling,
    toolSamplingPolicy: context.toolSamplingPolicy,
    transcriptContextEntries: context.transcriptContextEntries,
  );

  _ProviderToolSampling _providerToolSampling(
    WorkspaceModelSelectionWithConnectionEntity config,
    String? connectionUrl,
  ) {
    final selection = config.workspaceModelSelection;
    final providerType = config.modelsProvider.type;
    final profile = _strictToolSamplingProfileFor(config, providerType);

    return (
      officialOpenAI: _isOfficialOpenAI(config, connectionUrl),
      strictToolSampling: selection.supportsToolCalls && profile != null,
      profile: profile,
    );
  }

  bool _isOfficialOpenAI(
    WorkspaceModelSelectionWithConnectionEntity config,
    String? connectionUrl,
  ) =>
      config.modelsProvider.type == ModelProvidersType.openai &&
      !_hasCustomUrl(config, connectionUrl);

  StrictToolSamplingProfile? _strictToolSamplingProfileFor(
    WorkspaceModelSelectionWithConnectionEntity config,
    ModelProvidersType? providerType,
  ) => strictToolSamplingProfile(
    providerType?.name ?? '',
    config.workspaceModelSelection.modelId,
    _providerToolSamplingBaseUrl(config),
  );

  String? _providerToolSamplingBaseUrl(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final baseUrl = resolvedBaseUrl(config);
    if (baseUrl != null) return baseUrl;
    if (config.modelsProvider.type != ModelProvidersType.openai) return null;

    return providerProfile('openai').defaultUrl;
  }

  ToolSamplingPolicy _validatedToolSamplingPolicy(
    WorkspaceModelSelectionWithConnectionEntity config,
    _ProviderToolSampling capabilities,
  ) {
    final selection = config.workspaceModelSelection;
    final policy =
        selection.toolSamplingPolicy ??
        _strictToolSamplingPolicy(capabilities.strictToolSampling);
    if (policy == ToolSamplingPolicy.require &&
        !capabilities.strictToolSampling) {
      _throwUnsupportedToolSampling(capabilities);
    }

    return policy;
  }

  Never _throwUnsupportedToolSampling(_ProviderToolSampling capabilities) {
    throw ToolSamplingValidationException(
      reason: capabilities.profile == null
          ? ToolSamplingValidationReason.unsupportedProvider
          : ToolSamplingValidationReason.unsupportedModel,
      detail: 'Selected provider or model does not support strict sampling.',
    );
  }
}

extension _ProviderFactoryPluginSelection on ProviderFactory {
  Genkit _createGenkit(_ProviderRequest request) {
    return Genkit(plugins: _plugins(request));
  }

  List<GenkitPlugin> _plugins(_ProviderRequest request) => [_plugin(request)];

  GenkitPlugin _plugin(_ProviderRequest request) {
    final runtime = request.runtime;
    if (runtime.runtime == ProviderRuntime.anthropic) {
      return _anthropicPlugin(request);
    }
    if (request.config.modelsProvider.type == ModelProvidersType.openrouter) {
      return _openRouterPlugin(request);
    }

    return _nonRouterPlugin(request, runtime.runtime);
  }

  GenkitPlugin _nonRouterPlugin(
    _ProviderRequest request,
    ProviderRuntime runtime,
  ) {
    if (runtime == ProviderRuntime.codexOAuth) return _codexPlugin(request);
    if (runtime == ProviderRuntime.openAiReasoning) {
      return _openAIReasoningPlugin(request);
    }

    return _openAIPlugin(request);
  }
}

extension _ProviderFactoryPlugins on ProviderFactory {
  GenkitPlugin _anthropicPlugin(_ProviderRequest request) {
    return AppAnthropicPlugin(
      apiKey: request.apiKey,
      encoder: _anthropicEncoder(request),
      baseUrl: request.baseUrl,
      headers: sessionAffinityHeaders(
        providerType: request.config.modelsProvider.type,
        baseUrl: request.baseUrl,
        sessionId: request.sessionId,
      ),
      httpClient: httpClient,
    );
  }

  AnthropicRequestEncoder _anthropicEncoder(_ProviderRequest request) {
    if (!_supportsAnthropicSessionAffinity(
      request.config.modelsProvider.type,
      request.baseUrl,
    )) {
      return const .new();
    }
    final selection = request.config.workspaceModelSelection;

    return .new(
      supportsPromptCacheMarkers: selection.supportsPromptCacheMarkers,
      supportsMidConversationSystemMessages:
          selection.supportsMidConversationSystemMessages,
      supportsToolDeltas: selection.supportsToolDeltas,
      entries: request.transcriptContextEntries,
    );
  }

  GenkitPlugin _openRouterPlugin(_ProviderRequest request) {
    return AppChatCompletionsPlugin(
      name: 'openrouter',
      baseUrl: request.baseUrl ?? 'https://openrouter.ai/api/v1',
      apiKey: request.apiKey,
      codec: _openRouterCodec(),
      models: [ChatCompletionsModelDefinition(name: request.modelId)],
      headers: {
        'HTTP-Referer': 'https://auravibes.me',
        'X-OpenRouter-Title': 'AuraVibes',
        'X-OpenRouter-Categories': 'personal-agent',
        ...sessionAffinityHeaders(
          providerType: request.config.modelsProvider.type,
          baseUrl: request.baseUrl,
          sessionId: request.sessionId,
        ),
      },
      httpClient: httpClient,
      defaultToolSamplingPolicy: request.toolSamplingPolicy,
    );
  }

  GenkitPlugin _codexPlugin(_ProviderRequest request) {
    return AppOpenAICodexPlugin(
      accessToken: request.apiKey,
      accountId: request.config.modelConnection.oauthMetadata?.accountId,
      sessionId: request.sessionId,
      models: [request.modelId],
      reasoningConfiguration: request.reasoningConfiguration,
    );
  }

  GenkitPlugin _openAIReasoningPlugin(_ProviderRequest request) {
    final toolSampling = request.toolSampling;

    return _openAICompatPlugin(request, (
      name: ProviderFactory._openAIReasoningNamespace,
      codec: _openAICompatReasoningCodec(
        toolSampling.officialOpenAI,
        toolSampling.profile,
      ),
      modelSupportsStrictToolSampling: toolSampling.strictToolSampling,
      httpClient: null,
    ));
  }

  GenkitPlugin _openAIPlugin(_ProviderRequest request) {
    final profile = request.toolSampling.profile;
    if (profile == null &&
        request.config.workspaceModelSelection.toolSamplingPolicy == null) {
      return openAI(apiKey: request.apiKey, baseUrl: request.baseUrl);
    }

    return _openAICompatPlugin(request, (
      name: 'openai',
      codec: _openAICodec(profile),
      modelSupportsStrictToolSampling: request.toolSampling.strictToolSampling,
      httpClient: httpClient,
    ));
  }

  AppChatCompletionsPlugin _openAICompatPlugin(
    _ProviderRequest request,
    _OpenAICompatPluginOptions options,
  ) => AppChatCompletionsPlugin(
    name: options.name,
    baseUrl: request.baseUrl ?? providerProfile('openai').defaultUrl,
    apiKey: request.apiKey,
    codec: options.codec,
    models: [ChatCompletionsModelDefinition(name: request.modelId)],
    httpClient: options.httpClient,
    modelSupportsStrictToolSampling: options.modelSupportsStrictToolSampling,
    defaultToolSamplingPolicy: request.toolSamplingPolicy,
    onToolSamplingDecision: _logToolSamplingDecision,
  );
}

extension _ProviderFactoryResolution on ProviderFactory {
  UntypedModelRef _modelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
    ProviderRuntimeSelection runtime,
  ) {
    final modelId = config.workspaceModelSelection.modelId;
    if (runtime.runtime == ProviderRuntime.anthropic) {
      return anthropic.model(modelId);
    }
    if (config.modelsProvider.type == ModelProvidersType.openrouter) {
      return modelRef('openrouter/$modelId');
    }

    return _nonProviderModelReference(modelId, runtime);
  }

  UntypedModelRef _nonProviderModelReference(
    String modelId,
    ProviderRuntimeSelection runtime,
  ) {
    if (runtime.runtime == ProviderRuntime.codexOAuth) {
      return openAICodexModel(modelId);
    }
    if (runtime.runtime == ProviderRuntime.openAiReasoning) {
      return modelRef('${runtime.modelNamespace}/$modelId');
    }

    return openAI.model(modelId);
  }

  T? _anthropicGenerationConfig<T>(ReasoningConfiguration configuration) {
    if (configuration.enabled == false) {
      return AnthropicOptions(thinking: .new(type: 'disabled')) as T;
    }
    if (configuration.effort == null && configuration.budgetTokens == null) {
      return null;
    }

    return _anthropicOptions(configuration) as T;
  }

  AnthropicOptions _anthropicOptions(ReasoningConfiguration configuration) =>
      AnthropicOptions(
        thinking: configuration.budgetTokens == null
            ? null
            : .new(type: 'enabled', budgetTokens: configuration.budgetTokens),
        outputConfig: configuration.effort == null
            ? null
            : .new(effort: configuration.effort),
      );

  T? _openAIReasoningGenerationConfig<T>(ReasoningConfiguration configuration) {
    if (configuration.enabled == false) {
      return OpenAICompatReasoningOptions(reasoningEffort: 'none') as T;
    }

    final effort = configuration.effort;
    if (effort == null) return null;

    return OpenAICompatReasoningOptions(reasoningEffort: effort) as T;
  }

  T? _openRouterGenerationConfig<T>(ReasoningConfiguration configuration) {
    return OpenRouterOptions(
      reasoningMaxTokens: configuration.enabled == false
          ? null
          : configuration.budgetTokens,
      reasoningEffort: configuration.enabled == false
          ? null
          : configuration.effort,
      reasoningEnabled: configuration.enabled == false ? false : null,
    ) as T;
  }
}

extension _ProviderFactoryCredentials on ProviderFactory {
  Future<String> _resolveCredential(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    if (config.modelConnection.authMode == ModelProviderAuthMode.oauth2) {
      return _resolveOAuthCredential(config);
    }

    return _resolveApiKeyCredential(config);
  }

  Future<String> _resolveOAuthCredential(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final resolver = resolveOAuthAccessToken;
    if (resolver == null) {
      throw const FormatException('OAuth token resolver is not configured.');
    }

    return resolver(config.modelConnection.id);
  }

  Future<String> _resolveApiKeyCredential(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) async {
    if (!config.modelConnection.hasKey) {
      throw const FormatException('Model connection has no API key.');
    }
    final secret = await serviceConnectionRepository.readSecret(
      config.modelConnection.id,
    );
    if (secret is! ServiceConnectionSecretApiKey) {
      throw const FormatException('Model connection is not an API key.');
    }

    return secret.apiKey;
  }

  ProviderRuntimeSelection _runtimeSelection(
    WorkspaceModelSelectionWithConnectionEntity config,
    String? connectionUrl,
  ) => _selectRuntime((
    providerId: config.modelsProvider.type?.name ?? 'openai',
    hasCustomUrl: _hasCustomUrl(config, connectionUrl),
    supportsReasoning: config.workspaceModelSelection.supportsReasoning,
    usesOAuth: config.modelConnection.authMode == ModelProviderAuthMode.oauth2,
    isCodexOAuth: ModelProviderOAuthProfiles.isCodexProvider(
      config.modelConnection.modelId,
    ),
    modelId: config.workspaceModelSelection.modelId,
  ));

  ProviderRuntimeSelection _selectRuntime(_RuntimeRequest request) =>
      selectProviderRuntime(
        providerId: request.providerId,
        hasCustomUrl: request.hasCustomUrl,
        supportsReasoning: request.supportsReasoning,
        usesOAuth: request.usesOAuth,
        isCodexOAuth: request.isCodexOAuth,
        modelId: request.modelId,
      );

  bool _hasCustomUrl(
    WorkspaceModelSelectionWithConnectionEntity config,
    String? connectionUrl,
  ) {
    if (connectionUrl != null) return true;
    if (config.modelsProvider.type != ModelProvidersType.openai) return false;

    final providerUrl = _blankToNull(config.modelsProvider.url);

    return providerUrl != null &&
        providerUrl.replaceFirst(RegExp(r'/$'), '') !=
            providerProfile('openai').defaultUrl;
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return trimmed;
  }
}

ChatCompletionsCodec _openRouterCodec() => const ChatCompletionsCodec(
  errorLabel: 'OpenRouter',
  customize: _customizeOpenRouter,
);

ChatCompletionsCodec _openAICodec(StrictToolSamplingProfile? profile) =>
    ChatCompletionsCodec(
      errorLabel: 'OpenAI',
      customize: _customizeOpenAI,
      supportsStrictToolSampling: profile != null,
      strictToolSamplingProfile: profile,
    );

({String model, Map<String, dynamic> extraBody}) _customizeOpenAI(
  String modelName,
  Map<String, dynamic>? config,
) => (
  model: modelName,
  extraBody: OpenAICompatChatOptions.fromJson(config).toSamplingBody(),
);

({String model, Map<String, dynamic> extraBody}) _customizeOpenRouter(
  String modelName,
  Map<String, dynamic>? config,
) {
  final options = OpenRouterOptions.fromJson(config);

  return (model: modelName, extraBody: _openRouterBody(options));
}

Map<String, dynamic> _openRouterBody(OpenRouterOptions options) {
  final reasoning = _openRouterReasoningBody(options);

  return {...options.toSamplingBody(), 'reasoning': ?reasoning};
}

Map<String, dynamic>? _openRouterReasoningBody(OpenRouterOptions options) {
  if (options.reasoningEnabled != false &&
      options.reasoningEffort == null &&
      options.reasoningMaxTokens == null) {
    return null;
  }

  return {
    if (options.reasoningEnabled == false) 'enabled': false,
    'effort': ?options.reasoningEffort,
    'max_tokens': ?options.reasoningMaxTokens,
  };
}

ChatCompletionsCodec _openAICompatReasoningCodec(
  bool officialOpenAI,
  StrictToolSamplingProfile? profile,
) => ChatCompletionsCodec(
  errorLabel: 'OpenAI-compatible',
  customize: _customizeOpenAICompatReasoning,
  supportsStrictToolSampling: officialOpenAI || profile != null,
  strictToolSamplingProfile: profile,
);

final _toolSamplingLogger = Logger('tool_sampling');

void _logToolSamplingDecision(List<ToolSamplingDecision> decisions) {
  for (final decision in decisions) {
    if (decision.policy == ToolSamplingPolicy.off) continue;
    _toolSamplingLogger.fine(
      'Tool sampling: ${jsonEncode(decision.toDiagnostic())}',
    );
  }
}

ToolSamplingPolicy _strictToolSamplingPolicy(bool supportsStrict) =>
    supportsStrict ? .prefer : .off;

({String model, Map<String, dynamic> extraBody})
_customizeOpenAICompatReasoning(
  String modelName,
  Map<String, dynamic>? config,
) {
  final options = OpenAICompatReasoningOptions.fromJson(config);

  return (
    model: options.version ?? modelName,
    extraBody: {...options.toSamplingBody(), ...options.toReasoningBody()},
  );
}
