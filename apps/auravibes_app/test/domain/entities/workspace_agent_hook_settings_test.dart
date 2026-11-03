import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path = '/tmp/hooks.json';
  const digest = 'trusted';
  for (final enabled in [false, true]) {
    test('source trust matching is independent of opt-in=$enabled', () {
      final settings = WorkspaceAgentHookSettings(
        workspaceId: 'workspace',
        enabled: enabled,
        configPath: path,
        trustedSourcePath: path,
        trustedDigest: digest,
      );
      expect(
        settings.trustsSource(canonicalPath: path, digest: digest),
        isTrue,
      );
      expect(
        settings.trustsSource(canonicalPath: '/tmp/other.json', digest: digest),
        isFalse,
      );
      expect(
        settings.trustsSource(canonicalPath: path, digest: 'changed'),
        isFalse,
      );
    });
  }
  for (final trustedPath in [null, '/tmp/other.json']) {
    test('a missing or different trusted path cannot match: $trustedPath', () {
      final settings = WorkspaceAgentHookSettings(
        workspaceId: 'workspace',
        enabled: true,
        configPath: path,
        trustedSourcePath: trustedPath,
        trustedDigest: digest,
      );
      expect(
        settings.trustsSource(canonicalPath: path, digest: digest),
        isFalse,
      );
    });
  }
  test('a missing trusted digest cannot match', () {
    const settings = WorkspaceAgentHookSettings(
      workspaceId: 'workspace',
      enabled: true,
      configPath: path,
      trustedSourcePath: path,
    );
    expect(settings.trustsSource(canonicalPath: path, digest: digest), isFalse);
  });
}
