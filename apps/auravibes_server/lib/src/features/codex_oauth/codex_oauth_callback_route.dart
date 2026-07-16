import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/codex_oauth_repository.dart';
import 'usecases/codex_oauth_usecases.dart';

class CodexOAuthCallbackRoute extends Route {
  CodexOAuthCallbackRoute();

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final query = request.url.queryParameters;
    try {
      final state = query['state'];
      final code = query['code'];
      if (state == null || code == null) return _page(false);
      final transaction = await CodexOAuthRepository().findByState(
        session,
        await hashValue(state),
      );
      if (transaction == null) return _page(false);
      await CodexOAuthUseCases(CodexOAuthRepository()).complete(
        session,
        userId: transaction.userId,
        request: CompleteCodexOAuthRequest(
          transactionId: transaction.transactionId,
          state: state,
          code: code,
        ),
      );
      return _page(true, deepLink: session.passwords['codexOAuthDeepLink']);
    } on Object {
      return _page(false);
    }
  }
}

Result _page(bool success, {String? deepLink}) {
  final title = success ? 'Codex connected' : 'Codex connection failed';
  final message = success
      ? 'You can return to AuraVibes.'
      : 'Return to AuraVibes and try again.';
  final deepLinkUri = deepLink == null ? null : Uri.tryParse(deepLink);
  final link = success && deepLinkUri?.scheme == 'auravibes'
      ? '<p><a href="${htmlEscape.convert(deepLink!)}">Return to AuraVibes</a></p>'
      : '';
  return Response.ok(
    headers: Headers.build((headers) {
      headers.cacheControl = CacheControlHeader(noStore: true);
    }),
    body: Body.fromString(
      '<!doctype html><html><head><meta charset="utf-8"><title>$title</title>'
      '</head><body><main><h1>$title</h1><p>$message</p>$link</main></body></html>',
      mimeType: MimeType.html,
    ),
  );
}
