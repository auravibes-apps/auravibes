import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('skill eligibility requires enabled and credential-ready state', () {
    expect(
      isSkillLoadable(
        isEnabled: true,
        isLoaded: false,
        isCredentialReady: true,
      ),
      isTrue,
    );
    expect(
      isSkillLoadable(
        isEnabled: false,
        isLoaded: false,
        isCredentialReady: true,
      ),
      isFalse,
    );
    expect(
      isSkillLoadable(
        isEnabled: true,
        isLoaded: true,
        isCredentialReady: true,
      ),
      isFalse,
    );
    expect(
      isSkillLoadable(
        isEnabled: true,
        isLoaded: false,
        isCredentialReady: false,
      ),
      isFalse,
    );
  });
}
