import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/features/conversations/workers/conversation_worker.dart';
import 'src/features/codex_oauth/codex_oauth_callback_route.dart';
import 'src/features/model_connections/workers/model_catalog_sync_worker.dart';
import 'src/features/objects/object_cleanup_service.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      EmailIdpConfigFromPasswords(
        sendRegistrationVerificationCode: _sendRegistrationCode,
        sendPasswordResetVerificationCode: _sendPasswordResetCode,
      ),
    ],
  );

  pod.registerFutureCall(
    ConversationWorkerFutureCall(),
    conversationWorkerFutureCallName,
  );
  pod.registerFutureCall(
    ModelCatalogSyncWorkerFutureCall(),
    modelCatalogSyncWorkerFutureCallName,
  );
  pod.registerFutureCall(
    ObjectCleanupFutureCall(),
    objectCleanupFutureCallName,
  );
  pod.webServer.addRoute(
    CodexOAuthCallbackRoute(),
    '/auth/codex/callback',
  );

  // Start the server.
  await pod.start();
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay(
    conversationWorkerFutureCallName,
    null,
    Duration.zero,
    identifier: conversationWorkerFutureCallIdentifier,
  );
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay(
    modelCatalogSyncWorkerFutureCallName,
    null,
    Duration.zero,
    identifier: modelCatalogSyncWorkerFutureCallIdentifier,
  );
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay(
    objectCleanupFutureCallName,
    null,
    Duration.zero,
    identifier: objectCleanupFutureCallIdentifier,
  );
}

void _sendRegistrationCode(
  Session session, {
  required String email,
  required UuidValue accountRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  if (session.serverpod.runMode != ServerpodRunMode.development) return;
  session.log('[EmailIdp] Registration code ($email): $verificationCode');
}

void _sendPasswordResetCode(
  Session session, {
  required String email,
  required UuidValue passwordResetRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  if (session.serverpod.runMode != ServerpodRunMode.development) return;
  session.log('[EmailIdp] Password reset code ($email): $verificationCode');
}
