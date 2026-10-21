enum StrictToolSamplingWireMode { explicitStrictFlag, implicitStrict }

class const StrictToolSchemaLimits({
  final int maxObjectDepth = 10,
  final int maxPropertyCount = 5000,
  final int maxAggregateStringLength = 120000,
  final int maxEnumCount = 1000,
  final int? maxPropertiesConstraint,
  final int? maxStringLength,
  final int? maxArrayItems,
});

class const StrictToolSamplingProfile({
  required final String id,
  required final int version,
  required final String providerId,
  required final String modelId,
  required final String baseUrl,
  required final StrictToolSamplingWireMode wireMode,
  required final StrictToolSchemaLimits schemaLimits,
  required final String evidenceUrl,
  required final String verificationDate,
}) {
  ({String providerId, String modelId, String baseUrl}) get exactMatch =>
      (providerId: providerId, modelId: modelId, baseUrl: baseUrl);

  bool matches(String providerId, String modelId, String? baseUrl) {
    if (this.providerId != providerId || this.modelId != modelId) return false;
    final canonicalBaseUrl = baseUrl != null && baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return this.baseUrl == canonicalBaseUrl;
  }
}

const _openAIBaseUrl = 'https://api.openai.com/v1';
const _openAIFunctionCallingDocs =
    'https://developers.openai.com/api/docs/guides/function-calling';
const _xaiStructuredOutputDocs =
    'https://docs.x.ai/developers/model-capabilities/text/structured-outputs';
const _verificationDate = '2026-09-29';

const _profiles = [
  StrictToolSamplingProfile(
    id: 'openai-gpt-4o-chat-completions-strict',
    version: 1,
    providerId: 'openai',
    modelId: 'gpt-4o',
    baseUrl: _openAIBaseUrl,
    wireMode: .explicitStrictFlag,
    schemaLimits: StrictToolSchemaLimits(),
    evidenceUrl: _openAIFunctionCallingDocs,
    verificationDate: _verificationDate,
  ),
  StrictToolSamplingProfile(
    id: 'openai-gpt-4o-2024-08-06-chat-completions-strict',
    version: 1,
    providerId: 'openai',
    modelId: 'gpt-4o-2024-08-06',
    baseUrl: _openAIBaseUrl,
    wireMode: .explicitStrictFlag,
    schemaLimits: StrictToolSchemaLimits(),
    evidenceUrl: _openAIFunctionCallingDocs,
    verificationDate: _verificationDate,
  ),
  StrictToolSamplingProfile(
    id: 'openai-gpt-4o-mini-chat-completions-strict',
    version: 1,
    providerId: 'openai',
    modelId: 'gpt-4o-mini',
    baseUrl: _openAIBaseUrl,
    wireMode: .explicitStrictFlag,
    schemaLimits: StrictToolSchemaLimits(),
    evidenceUrl: _openAIFunctionCallingDocs,
    verificationDate: _verificationDate,
  ),
  StrictToolSamplingProfile(
    id: 'openai-gpt-4o-mini-2024-07-18-chat-completions-strict',
    version: 1,
    providerId: 'openai',
    modelId: 'gpt-4o-mini-2024-07-18',
    baseUrl: _openAIBaseUrl,
    wireMode: .explicitStrictFlag,
    schemaLimits: StrictToolSchemaLimits(),
    evidenceUrl: _openAIFunctionCallingDocs,
    verificationDate: _verificationDate,
  ),
  StrictToolSamplingProfile(
    id: 'xai-grok-4.7-chat-completions-strict',
    version: 1,
    providerId: 'openai',
    modelId: 'grok-4.7',
    baseUrl: 'https://api.x.ai/v1',
    wireMode: .implicitStrict,
    schemaLimits: StrictToolSchemaLimits(
      maxPropertiesConstraint: 64,
      maxStringLength: 2048,
      maxArrayItems: 256,
    ),
    evidenceUrl: _xaiStructuredOutputDocs,
    verificationDate: _verificationDate,
  ),
];

StrictToolSamplingProfile? strictToolSamplingProfile(
  String providerId,
  String modelId,
  String? baseUrl,
) {
  for (final profile in _profiles) {
    if (profile.matches(providerId, modelId, baseUrl)) return profile;
  }

  return null;
}

bool verifiedStrictToolSampling(String providerId, String modelId) =>
    strictToolSamplingProfile(
      providerId,
      modelId,
      providerId == 'openai' ? _openAIBaseUrl : null,
    ) !=
    null;
