import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'authenticated_account_resolver.dart';

class AccountEndpoint extends Endpoint {
  Future<AccountSummary> currentUser(Session session) {
    return const AuthenticatedAccountResolver()(session);
  }
}
