import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'repositories/codex_oauth_repository.dart';
import 'usecases/codex_oauth_usecases.dart';

class CodexOAuthEndpoint extends Endpoint {
  Future<StartCodexOAuthResult> start(
    Session session,
    StartCodexOAuthRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return CodexOAuthUseCases(CodexOAuthRepository()).start(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<CompleteCodexOAuthResult> complete(
    Session session,
    CompleteCodexOAuthRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return CodexOAuthUseCases(CodexOAuthRepository()).complete(
      session,
      userId: account.userId,
      request: request,
    );
  }
}
