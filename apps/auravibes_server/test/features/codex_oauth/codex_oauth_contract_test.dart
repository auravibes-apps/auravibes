import 'package:auravibes_server/src/features/codex_oauth/usecases/codex_oauth_usecases.dart';
import 'package:test/test.dart';

void main() {
  test(
    'state comparison and token response contract reject invalid values',
    () async {
      final hash = await hashValue('state');
      expect(constantTimeEquals(hash, await hashValue('state')), isTrue);
      expect(constantTimeEquals(hash, await hashValue('other')), isFalse);
      expect(
        validateTokenResponse({
          'access_token': 'token',
          'refresh_token': 'refresh',
          'expires_in': 3600,
        })['access_token'],
        'token',
      );
      expect(
        () => validateTokenResponse({'refresh_token': 'missing access token'}),
        throwsA(anything),
      );
    },
  );
}
