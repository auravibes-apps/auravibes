import 'package:auravibes_app/app_env_config.dart';

enum ModelProviderAuthMode { apiKey, oauth2 }

const openAICodexProviderId = 'openai-codex';
const openAICodexDisplayName = 'OpenAI Codex';
const openAICodexAuthorizationEndpoint =
    'https://auth.openai.com/oauth/authorize';
const openAICodexTokenEndpoint = 'https://auth.openai.com/oauth/token';
const openAICodexIssuer = 'https://auth.openai.com';
const String openAICodexClientId = AppEnvConfig.openAICodexOAuthClientId;
const List<String> openAICodexScopes = [
  'openid',
  'profile',
  'email',
  'offline_access',
  'api.connectors.read',
  'api.connectors.invoke',
];
const Map<String, String> openAICodexExtraAuthorizeParameters = {
  'id_token_add_organizations': 'true',
  'codex_cli_simplified_flow': 'true',
  'originator': 'auravibes',
};

bool isOpenAICodexProvider(String? providerId) {
  return providerId == openAICodexProviderId;
}
