import 'package:auravibes_app/app_env_config.dart';

enum ModelProviderAuthMode { apiKey, oauth2 }

abstract final class ModelProviderOAuthProfiles {
  static const providerId = 'openai-codex';
  static const displayName = 'OpenAI Codex';
  static const authorizationEndpoint =
      'https://auth.openai.com/oauth/authorize';
  static const tokenEndpoint = 'https://auth.openai.com/oauth/token';
  static const issuer = 'https://auth.openai.com';
  static const String clientId = AppEnvConfig.openAICodexOAuthClientId;
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'api.connectors.read',
    'api.connectors.invoke',
  ];
  static const Map<String, String> extraAuthorizeParameters = {
    'id_token_add_organizations': 'true',
    'codex_cli_simplified_flow': 'true',
    'originator': 'auravibes',
  };

  static bool isCodexProvider(String? providerId) =>
      providerId == ModelProviderOAuthProfiles.providerId;
}
