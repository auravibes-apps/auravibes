import 'package:auravibes_app/app_env_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses default Codex OAuth client id', () {
    expect(
      AppEnvConfig.openAICodexOAuthClientId,
      'app_EMoamEEZ73f0CkXaXp7hrann',
    );
  });
}
