import 'dart:convert';

import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chatbot_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:genkit/genkit.dart';

typedef EmptyCatalogModelGenerator = Future<ChatMessage> Function(
  List<ChatMessage> history,
  List<ToolSpec> tools,
);

typedef StubSubAgentRunner = Future<String> Function({
  required String title,
  required String prompt,
  required String? agentId,
});

typedef EmptyCatalogEvalCase = ({String provider, String model});
typedef _ProviderConfig = ({
  ModelProvidersType type,
  String apiKeyEnvironmentKey,
});

const _providerConfigs = <String, _ProviderConfig>{
  'openai': (
    type: ModelProvidersType.openai,
    apiKeyEnvironmentKey: 'OPENAI_API_KEY',
  ),
  'anthropic': (
    type: ModelProvidersType.anthropic,
    apiKeyEnvironmentKey: 'ANTHROPIC_API_KEY',
  ),
  'openrouter': (
    type: ModelProvidersType.openrouter,
    apiKeyEnvironmentKey: 'OPENROUTER_API_KEY',
  ),
};

const _userRequest =
    'Please delegate this evaluation task to a sub-agent. First inspect the '
    'configured agents. If the catalog is empty, you may still launch a '
    'general sub-agent and return its result. The child should return the '
    'evaluation marker it receives.';
const _stubResult = 'AURAVIBES_EVAL_CHILD_RESULT';

List<EmptyCatalogEvalCase> parseEmptyCatalogEvalCases(List<String> values) =>
    values.map(_parseEmptyCatalogEvalCase).toList(growable: false);

EmptyCatalogEvalCase _parseEmptyCatalogEvalCase(String value) {
  final parts = value.split(':');
  final provider = parts.firstOrNull;
  if (parts.length < 2 || provider == null || provider.isEmpty) {
    throw const FormatException(
      'Expected provider:model, for example openai:gpt-4o-mini.',
    );
  }

  final model = parts.skip(1).join(':');
  if (model.isEmpty) {
    throw const FormatException(
      'Expected provider:model, for example openai:gpt-4o-mini.',
    );
  }
  if (_providerConfigs[provider] == null) {
    throw FormatException('Unsupported provider: $provider.');
  }

  return (provider: provider, model: model);
}

String apiKeyEnvironmentKeyForProvider(String provider) {
  final configuration = _providerConfigs[provider];
  if (configuration == null) {
    throw FormatException('Unsupported provider: $provider.');
  }

  return configuration.apiKeyEnvironmentKey;
}

class const EmptyCatalogDelegationEval({
  required final String provider,
  required final String model,
  required final bool passed,
  final String? failureReason,
}) {
  String get outcome => passed ? 'passed' : 'failed';

  Map<String, Object?> toJson() => {
    'provider': provider,
    'model': model,
    'outcome': outcome,
    if (failureReason != null) 'failureReason': failureReason,
  };
}

Future<EmptyCatalogDelegationEval> runEmptyCatalogDelegationEval({
  required String provider,
  required String model,
  required EmptyCatalogModelGenerator generate,
  required StubSubAgentRunner runStubChild,
}) async {
  final history = <ChatMessage>[.user(_userRequest)];
  final catalogCall = await generate(.unmodifiable(history), subAgentToolSpecs);
  final catalogRequest = _singleToolRequest(catalogCall);
  if (catalogRequest == null || catalogRequest.name != listAgentsToolName) {
    return _failure(
      provider,
      model,
      'Model did not inspect the configured-agent catalog.',
    );
  }

  history
    ..add(catalogCall)
    ..add(
      _toolResponse(
        catalogRequest,
        jsonEncode({
          'agents': const <Object?>[],
          'nextCursor': null,
          'hint': generalSubAgentHint,
        }),
      ),
    );

  final childCall = await generate(.unmodifiable(history), subAgentToolSpecs);
  final childRequest = _singleToolRequest(childCall);
  if (childRequest == null || childRequest.name != runSubAgentToolName) {
    return _failure(
      provider,
      model,
      'Model did not call run_sub_agent after the empty catalog result.',
    );
  }

  final input = childRequest.input;
  if (input is! Map<String, Object?>) {
    return _failure(
      provider,
      model,
      'run_sub_agent did not provide object arguments.',
    );
  }
  final title = input['title'];
  final prompt = input['prompt'];
  if (title is! String || title.trim().isEmpty) {
    return _failure(provider, model, 'run_sub_agent did not include a title.');
  }
  if (prompt is! String || prompt.trim().isEmpty) {
    return _failure(provider, model, 'run_sub_agent did not include a prompt.');
  }
  if (!input.containsKey('agentId') || input['agentId'] != null) {
    return _failure(
      provider,
      model,
      'run_sub_agent must include agentId: null for the current schema.',
    );
  }

  final childResult = await runStubChild(
    title: title,
    prompt: prompt,
    agentId: null,
  );
  history
    ..add(childCall)
    ..add(_toolResponse(childRequest, jsonEncode({'result': childResult})));

  final finalMessage = await generate(
    .unmodifiable(history),
    subAgentToolSpecs,
  );
  if (!finalMessage.text.contains(childResult)) {
    return _failure(
      provider,
      model,
      'Final answer did not include the child result.',
    );
  }

  return .new(provider: provider, model: model, passed: true);
}

ToolRequest? _singleToolRequest(ChatMessage message) {
  final requests = message.parts
      .whereType<ToolRequestPart>()
      .map((part) => part.toolRequest)
      .toList(growable: false);
  if (requests.length != 1) return null;

  return requests.single;
}

ChatMessage _toolResponse(ToolRequest request, String output) => .new(
  role: .tool,
  parts: [
    ToolResponsePart(
      toolResponse: .new(ref: request.ref, name: request.name, output: output),
    ),
  ],
);

EmptyCatalogDelegationEval _failure(
  String provider,
  String model,
  String reason,
) => .new(
  provider: provider,
  model: model,
  passed: false,
  failureReason: reason,
);

Future<EmptyCatalogDelegationEval> runProviderModelEmptyCatalogDelegationEval({
  required String provider,
  required String model,
  required String apiKey,
}) async {
  final providerConfiguration = _providerConfigs[provider];
  if (providerConfiguration == null) {
    return _failure(
      provider,
      model,
      'Unsupported provider; expected openai, anthropic, or openrouter.',
    );
  }
  if (apiKey.trim().isEmpty) {
    return _failure(provider, model, 'Provider API key is empty.');
  }

  try {
    final config = _modelConfig(provider, model, providerConfiguration.type);
    final service = ChatbotService(
      serviceConnectionRepository: _EvalServiceConnectionRepository(apiKey),
    );

    return await runEmptyCatalogDelegationEval(
      provider: provider,
      model: model,
      generate: (history, tools) async =>
          (await service
                  .sendMessage(config, history, options: .new(tools: tools))
                  .last)
              .output,
      runStubChild: ({
        required title,
        required prompt,
        required agentId,
      }) async => _stubResult,
    );
  } on Object {
    return _failure(
      provider,
      model,
      'Model evaluation failed during generation.',
    );
  }
}

WorkspaceModelSelectionWithConnectionEntity _modelConfig(
  String provider,
  String model,
  ModelProvidersType providerType,
) {
  final now = DateTime.now();
  const connectionId = 'empty-catalog-eval';

  return .new(
    workspaceModelSelection: .new(
      id: 'empty-catalog-eval-selection',
      modelId: model,
      createdAt: now,
      updatedAt: now,
      modelConnectionId: connectionId,
    ),
    modelConnection: .new(
      id: connectionId,
      name: 'Empty catalog evaluation',
      modelId: model,
      createdAt: now,
      updatedAt: now,
      workspaceId: 'empty-catalog-eval',
      hasKey: true,
    ),
    modelsProvider: .new(id: provider, name: provider, type: providerType),
  );
}

class _EvalServiceConnectionRepository(final String _apiKey)
    implements ServiceConnectionRepository {
  @override
  Future<ServiceConnectionSecret> readSecret(String id) async =>
      ServiceConnectionSecretApiKey(apiKey: _apiKey);

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('This evaluation only reads the model API key.');
}
