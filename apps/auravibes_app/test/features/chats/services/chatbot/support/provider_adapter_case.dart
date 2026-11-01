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
final class const ProviderAdapterCase(
  final ProviderRuntime runtime,
  final ProviderPluginPath path,
) {
  String get name => '${runtime.name}/${path.name}';
  bool get retriesTransport => path == ProviderPluginPath.appChatCompletions;
  bool get losesHttpMetadata =>
      path == ProviderPluginPath.upstreamOpenAi ||
      path == ProviderPluginPath.anthropic;

  ProviderFaultProtocol get protocol => switch (path) {
    .codex => .codex,
    .anthropic => .anthropic,
    _ => .chat,
  };

  String get namespace => switch (runtime) {
    .openAi => 'openai',
    .openRouter => 'openrouter',
    .openAiReasoning => 'openai_reasoning',
    .codexOAuth => 'openai_codex',
    .anthropic => 'anthropic',
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
    .upstreamOpenAi => AppOpenAIPlugin(
      upstream: openAI(
        apiKey: 'fixture-key',
        baseUrl: 'https://provider.invalid/v1',
      ),
      // Factory supplies no client normally. The contract supplies its fake
      // through http.runWithClient, retaining generation client ownership.
    ),
    .codex => AppOpenAICodexPlugin(
      accessToken: 'fixture-key',
      sessionId: 'session-contract',
      baseUrl: 'https://provider.invalid/responses',
      httpClient: client,
      requestTimeout: requestTimeout,
    ),
    .anthropic => AppAnthropicPlugin(
      apiKey: 'fixture-key',
      encoder: const AnthropicRequestEncoder(),
      baseUrl: 'https://provider.invalid',
      httpClient: client,
    ),
    .appChatCompletions => AppChatCompletionsPlugin(
      name: namespace,
      baseUrl: 'https://provider.invalid/v1',
      apiKey: 'fixture-key',
      codec: .new(errorLabel: namespace, customize: _customize),
      headers: runtime == .openRouter
          ? const {'x-session-id': 'session-contract'}
          : null,
      httpClient: client,
      requestTimeout: requestTimeout,
      retryWait: retryWait,
    ),
  };

  ({String model, Map<String, dynamic> extraBody}) _customize(
    String model,
    Map<String, dynamic>? config,
  ) {
    if (runtime == .openAiReasoning) {
      final options = OpenAICompatReasoningOptions.fromJson(config);

      return (
        model: options.version ?? model,
        extraBody: {...options.toSamplingBody(), ...options.toReasoningBody()},
      );
    }
    if (runtime == .openRouter) {
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
