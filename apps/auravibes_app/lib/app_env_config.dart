class AppEnvConfig {
  static const openAICodexOAuthClientId = String.fromEnvironment(
    'OPENAI_CODEX_OAUTH_CLIENT_ID',
    defaultValue: 'app_EMoamEEZ73f0CkXaXp7hrann',
  );

  static const dbHashSource = String.fromEnvironment('DB_HASH_SOURCE');

  static const auravibesServerUrl = String.fromEnvironment(
    'AURAVIBES_SERVER_URL',
  );

  const AppEnvConfig._();
}
