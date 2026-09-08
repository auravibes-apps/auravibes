class const ProviderProfile({
  required final String id,
  required final String defaultUrl,
  required final String catalogPath,
  required final bool usesApiKeyHeader,
});

enum ProviderRuntime {
  openAi,
  openRouter,
  anthropic,
  codexOAuth,
  openAiReasoning,
}

class const ProviderRuntimeSelection({
  required final ProviderRuntime runtime,
  required final String modelNamespace,
  required final bool usesAdaptiveThinking,
});

ProviderRuntimeSelection selectProviderRuntime({
  required String providerId,
  required bool hasCustomUrl,
  required bool supportsReasoning,
  required bool usesOAuth,
  required bool isCodexOAuth,
  required String modelId,
}) {
  final adaptive =
      modelId.startsWith('claude-mythos-preview') ||
      modelId.startsWith('claude-opus-4-7') ||
      modelId.startsWith('claude-opus-4-6') ||
      modelId.startsWith('claude-sonnet-4-6');
  if (usesOAuth && isCodexOAuth) {
    return const ProviderRuntimeSelection(
      runtime: ProviderRuntime.codexOAuth,
      modelNamespace: 'openai',
      usesAdaptiveThinking: false,
    );
  }
  if (providerId == 'anthropic' && !hasCustomUrl) {
    return ProviderRuntimeSelection(
      runtime: ProviderRuntime.anthropic,
      modelNamespace: 'anthropic',
      usesAdaptiveThinking: adaptive,
    );
  }
  if (providerId == 'openrouter') {
    return const ProviderRuntimeSelection(
      runtime: ProviderRuntime.openRouter,
      modelNamespace: 'openrouter',
      usesAdaptiveThinking: false,
    );
  }
  if (providerId == 'openai' && supportsReasoning && hasCustomUrl) {
    return const ProviderRuntimeSelection(
      runtime: ProviderRuntime.openAiReasoning,
      modelNamespace: 'openai_reasoning',
      usesAdaptiveThinking: false,
    );
  }
  return const ProviderRuntimeSelection(
    runtime: ProviderRuntime.openAi,
    modelNamespace: 'openai',
    usesAdaptiveThinking: false,
  );
}

ProviderProfile providerProfile(String id) => switch (id) {
  'openai-codex' => const ProviderProfile(
    id: 'openai-codex',
    defaultUrl: 'https://chatgpt.com/backend-api/codex/',
    catalogPath: 'models',
    usesApiKeyHeader: false,
  ),
  'openai' => const ProviderProfile(
    id: 'openai',
    defaultUrl: 'https://api.openai.com/v1',
    catalogPath: 'models',
    usesApiKeyHeader: false,
  ),
  'openrouter' => const ProviderProfile(
    id: 'openrouter',
    defaultUrl: 'https://openrouter.ai/api/v1',
    catalogPath: 'models',
    usesApiKeyHeader: false,
  ),
  'anthropic' => const ProviderProfile(
    id: 'anthropic',
    defaultUrl: 'https://api.anthropic.com/v1',
    catalogPath: 'models',
    usesApiKeyHeader: true,
  ),
  _ => throw FormatException('Unsupported provider: $id'),
};

Map<String, String> providerAuthorizationHeaders(String id, String credential) {
  final profile = providerProfile(id);
  return profile.usesApiKeyHeader
      ? {'x-api-key': credential, 'anthropic-version': '2023-06-01'}
      : id == 'openai-codex'
      ? {
          'authorization': 'Bearer $credential',
          'originator': 'auravibes',
          'user-agent': 'AuraVibes',
        }
      : {'authorization': 'Bearer $credential'};
}

Uri providerModelCatalogUri(String id, Uri baseUri, {required int maxModels}) {
  final profile = providerProfile(id);
  final path = baseUri.path.replaceFirst(RegExp(r'/$'), '');
  return baseUri.replace(
    path: '$path/${profile.catalogPath}',
    queryParameters: id == 'anthropic' ? {'limit': '$maxModels'} : null,
  );
}

List<String> parseProviderModelIds(Object? response, {required int maxModels}) {
  if (response is! Map || response['data'] is! List) {
    throw const FormatException('Invalid model response.');
  }
  final ids = <String>[];
  for (final item in response['data'] as List) {
    if (item is! Map ||
        item['id'] is! String ||
        (item['id'] as String).isEmpty) {
      throw const FormatException('Invalid model response.');
    }
    if (ids.length == maxModels) break;
    ids.add(item['id'] as String);
  }
  return List.unmodifiable(ids);
}
