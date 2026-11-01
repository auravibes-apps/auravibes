import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/router/task_return.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical target accepts compatible legacy and generated spelling', () {
    final target = CloudAuthTarget.fromQuery({
      'serverUrl': 'https://a.test/api',
      'server-url': 'https://a.test',
      'accountId': 'user',
      'account-id': 'user',
      'email': 'a@test.example',
    });
    expect(target.serverUrl, 'https://a.test');
    expect(target.accountId, 'user');
    expect(target.email, 'a@test.example');
    expect(target.isValid, isTrue);
  });
  test('conflicting targets fail closed', () {
    expect(
      CloudAuthTarget.fromQuery({
        'serverUrl': 'https://a.test',
        'server-url': 'https://b.test',
      }).isValid,
      isFalse,
    );
    expect(
      CloudAuthTarget.fromQuery({'accountId': 'a', 'account-id': 'b'}).isValid,
      isFalse,
    );
  });
  test('return accepts recognized same-workspace context', () {
    const path =
        '/workspaces/w/service-connections/new?type=connector&connectorId=jina';
    expect(TaskReturn.validate(path, workspaceId: 'w'), path);
    for (final destination in [
      'tools',
      'models',
      'agents',
      'agents/new',
      'agents/agent',
      'skills',
      'skills/new',
      'skills/skill',
      'skills/skill/resources/resource',
      'service-connections',
      'service-connections/connection',
      'manage-workspaces?view=connect',
      'manage-workspaces/create',
      'manage-workspaces/cloud/account/42',
      'cloud-accounts',
    ]) {
      final location = '/workspaces/w/$destination';
      expect(
        TaskReturn.validate(location, workspaceId: 'w'),
        location,
        reason: location,
      );
    }
  });

  test('legacy same-workspace task return filters canonical query keys', () {
    const path =
        '/workspaces/w/more/service-connections/new'
        '?type=connector&connectorId=jina&view=providers&discard=1';

    expect(
      TaskReturn.validate(path, workspaceId: 'w'),
      '/workspaces/w/service-connections/new?type=connector&connectorId=jina',
    );
  });

  test('rejects unsafe or unrecognized legacy task returns', () {
    for (final path in [
      '/workspaces/w/more/../chat/new',
      '/workspaces/w/more/%2e%2e/chat/new',
      '/workspaces/w/more/%252e%252e/chat/new',
      '/workspaces/w/more/skills/skill%2Fother',
      '/workspaces/w/more/skills/skill%252Fother',
      '/workspaces/w/more/chat/new#fragment',
      'https://evil.test/workspaces/w/more/chat/new',
      '//evil.test/workspaces/w/more/chat/new',
      '/workspaces/other/more/chat/new',
      '/workspaces/w/more/unknown',
    ]) {
      expect(TaskReturn.validate(path, workspaceId: 'w'), isNull, reason: path);
    }
  });

  test('return rejects unsafe, unknown and other-workspace paths', () {
    for (final path in [
      'https://evil.test/workspaces/w/chat/new',
      '//evil.test/a',
      '/workspaces/other/chat/new',
      '/workspaces/w/unknown',
      '/workspaces/w/../chat/new',
      '/workspaces/w/%2e%2e/chat/new',
      '/workspaces/w/%252e%252e/chat/new',
      '/workspaces/w/skills/skill%2Fother',
      '/workspaces/w/skills/skill%252Fother',
      '/workspaces/w/skills//resource',
      '/workspaces/w/manage-workspaces/cloud/account/not-an-id',
      '/workspaces/w/cloud-accounts/login/editor',
      '/workspaces/w/tools#fragment',
    ]) {
      expect(TaskReturn.validate(path, workspaceId: 'w'), isNull, reason: path);
    }
  });
}
