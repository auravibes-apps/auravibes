import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('AccountEndpoint', (sessionBuilder, endpoints) {
    test('requires authentication', () async {
      expect(
        endpoints.account.currentUser(sessionBuilder),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.authenticationRequired,
          ),
        ),
      );
    });

    test('requires an email account', () async {
      final userId = const Uuid().v4().toString();
      final authenticatedSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );

      expect(
        endpoints.account.currentUser(authenticatedSession),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.emailAccountRequired,
          ),
        ),
      );
    });

    test('returns the authenticated email account', () async {
      final userId = const Uuid().v4().toString();
      final authenticatedSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      await AuthUser.db.insertRow(
        authenticatedSession.build(),
        AuthUser(
          id: UuidValue.fromString(userId),
          scopeNames: const {},
        ),
      );
      await EmailAccount.db.insertRow(
        authenticatedSession.build(),
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: 'user@example.com',
          passwordHash: 'unused',
        ),
      );

      final account = await endpoints.account.currentUser(
        authenticatedSession,
      );

      expect(account.userId, userId);
      expect(account.email, 'user@example.com');
    });
  });
}
