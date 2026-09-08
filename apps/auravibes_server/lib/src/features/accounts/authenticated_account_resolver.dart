import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';

class const AuthenticatedAccountResolver() {
  Future<AccountSummary> call(Session session) async {
    final auth = session.authenticated;
    if (auth == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.authenticationRequired,
      );
    }

    final emailAccount = await EmailAccount.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(auth.authUserId),
    );
    if (emailAccount == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.emailAccountRequired,
      );
    }

    return AccountSummary(
      userId: auth.authUserId.uuid,
      email: emailAccount.email,
    );
  }
}
