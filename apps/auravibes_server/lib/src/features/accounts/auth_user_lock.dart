import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

class const AuthUserLock() {
  Future<AuthUser?> lock(
    Session session, {
    required String userId,
    required Transaction transaction,
  }) => AuthUser.db.findById(
    session,
    UuidValue.fromString(userId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
}
