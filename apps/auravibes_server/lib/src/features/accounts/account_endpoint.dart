import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';

class AccountEndpoint extends Endpoint {
  Future<AccountSummary> currentUser(Session session) async {
    final auth = session.authenticated;
    if (auth == null) throw Exception('Authentication required.');

    final authUserId = auth.authUserId;
    final emailAccount = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    if (emailAccount == null) throw Exception('Email account required.');

    return AccountSummary(userId: authUserId.uuid, email: emailAccount.email);
  }
}
