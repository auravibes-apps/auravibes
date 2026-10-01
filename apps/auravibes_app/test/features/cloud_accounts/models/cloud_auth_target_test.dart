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
        '/workspaces/w/more/service-connections/new?credential-definition-id=cred&app-skill-id=skill';
    expect(TaskReturn.validate(path, workspaceId: 'w'), path);
    expect(
      TaskReturn.validate(
        '/workspaces/w/more/manage-workspaces?view=connect',
        workspaceId: 'w',
      ),
      isNotNull,
    );
  });
  test('return rejects unsafe, unknown and other-workspace paths', () {
    for (final path in [
      'https://evil.test/workspaces/w/chat/new',
      '//evil.test/a',
      '/workspaces/other/chat/new',
      '/workspaces/w/unknown',
      '/workspaces/w/more/../chat/new',
      '/workspaces/w/more/%2e%2e/chat/new',
      '/workspaces/w/more/%252e%252e/chat/new',
    ]) {
      expect(TaskReturn.validate(path, workspaceId: 'w'), isNull, reason: path);
    }
  });
}
