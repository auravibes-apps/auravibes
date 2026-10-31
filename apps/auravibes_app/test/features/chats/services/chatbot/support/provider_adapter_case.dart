import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_encoder.dart';
import 'package:auravibes_app/features/chats/services/chatbot/app_anthropic_plugin.dart';
import 'package:auravibes_app/features/chats/services/chatbot/app_open_ai_codex_plugin.dart';
import 'package:auravibes_app/features/chats/services/chatbot/app_open_ai_plugin.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_completions_plugin.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_openai/genkit_openai.dart';

import 'provider_fault_client.dart';
import 'provider_fault_protocol.dart';

enum ProviderPluginPath { upstreamOpenAi, appChatCompletions, codex, anthropic }

/// A runtime alone does not identify its adapter. Default OpenAI and OpenAI
/// with explicit tool sampling select different production plugins.
final class ProviderAdapterCase {
  const ProviderAdapterCase(this.runtime, this.path);

  final ProviderRuntime runtime;
  final ProviderPluginPath path;

  String get name => '${runtime.name}/${path.name}';
  bool get retriesTransport => path == ProviderPluginPath.appChatCompletions;
  bool get losesHttpMetadata =>
      path == ProviderPluginPath.upstreamOpenAi ||
      path == ProviderPluginPath.anthropic;

  ProviderFaultProtocol get protocol => switch (path) {
    ProviderPluginPath.codex => .codex,
    ProviderPluginPath.anthropic => .anthropic,
    _ => .chat,
  };

  String get namespace => switch (runtime) {
    ProviderRuntime.openAi => 'openai',
    ProviderRuntime.openRouter => 'openrouter',
    ProviderRuntime.openAiReasoning => 'openai_reasoning',
    ProviderRuntime.codexOAuth => 'openai_codex',
    ProviderRuntime.anthropic => 'anthropic',
  };

  String get modelName => '$namespace/contract-model';

  Genkit createGenkit(
    ProviderFaultClient client, {
    Future<void> Function(Duration)? retryWait,
    Duration requestTimeout = const Duration(seconds: 30),
  }) => Genkit(
    plugins: [
      createPlugin(
        client,
        retryWait: retryWait,
        requestTimeout: requestTimeout,
      ),
    ],
    isDevEnv: false,
  );

  GenkitPlugin createPlugin(
    ProviderFaultClient client, {
    Future<void> Function(Duration)? retryWait,
    Duration requestTimeout = const Duration(seconds: 30),
  }) => switch (path) {
    ProviderPluginPath.upstreamOpenAi => AppOpenAIPlugin(
      upstream: openAI(
        apiKey: 'fixture-key',
        baseUrl: 'https://provider.invalid/v1',
      ),
      // Factory supplies no client normally. The contract supplies its fake
      // through http.runWithClient, retaining generation client ownership.
    ),
    ProviderPluginPath.codex => AppOpenAICodexPlugin(
      accessToken: 'fixture-key',
      sessionId: 'session-contract',
      baseUrl: 'https://provider.invalid/responses',
      httpClient: client,
      requestTimeout: requestTimeout,
    ),
    ProviderPluginPath.anthropic => AppAnthropicPlugin(
      apiKey: 'fixture-key',
      baseUrl: 'https://provider.invalid',
      encoder: const AnthropicRequestEncoder(),
      httpClient: client,
    ),
    ProviderPluginPath.appChatCompletions => AppChatCompletionsPlugin(
      name: namespace,
      apiKey: 'fixture-key',
      baseUrl: 'https://provider.invalid/v1',
      httpClient: client,
      requestTimeout: requestTimeout,
      retryWait: retryWait,
      headers: runtime == ProviderRuntime.openRouter
          ? const {'x-session-id': 'session-contract'}
          : null,
      codec: ChatCompletionsCodec(
        errorLabel: namespace,
        customize: (model, config) => _customize(model, config),
      ),
    ),
  };

  ({String model, Map<String, dynamic> extraBody}) _customize(
    String model,
    Map<String, dynamic>? config,
  ) {
    if (runtime == ProviderRuntime.openAiReasoning) {
      final options = OpenAICompatReasoningOptions.fromJson(config);
      return (
        model: options.version ?? model,
        extraBody: {
          ...options.toSamplingBody(),
          ...options.toReasoningBody(),
        },
      );
    }
    if (runtime == ProviderRuntime.openRouter) {
      final options = OpenRouterOptions.fromJson(config);
      return (
        model: model,
        extraBody: {
          ...options.toSamplingBody(),
          if (options.reasoningEffort != null)
            'reasoning': {'effort': options.reasoningEffort},
        },
      );
    }
    return (
      model: model,
      extraBody: OpenAICompatChatOptions.fromJson(config).toSamplingBody(),
    );
  }
}

const providerAdapterCases = [
  ProviderAdapterCase(.openAi, .upstreamOpenAi),
  ProviderAdapterCase(.openAi, .appChatCompletions),
  ProviderAdapterCase(.openRouter, .appChatCompletions),
  ProviderAdapterCase(.openAiReasoning, .appChatCompletions),
  ProviderAdapterCase(.codexOAuth, .codex),
  ProviderAdapterCase(.anthropic, .anthropic),
];
