import 'package:async/async.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef AppSkillUrlGuard = Future<PublicUrlResolution> Function(String url);

class AppSkillHttpClientAdapter {
  new(this._urlService, {AppSkillUrlGuard? requirePublicUri})
    : _requirePublicUri = requirePublicUri ?? PublicUrlGuard.resolveHttpsUri;

  final UrlService _urlService;
  final AppSkillUrlGuard _requirePublicUri;

  CancelableOperation<UrlResponse> execute(UrlRequest request) {
    CancelableOperation<UrlResponse>? operation;
    final completer = CancelableCompleter<UrlResponse>(
      onCancel: () => operation?.cancel(),
    );

    Future<void>(() async {
      try {
        final resolved = await _requirePublicUri(request.url);
        if (completer.isCanceled) return;

        final currentOperation = _urlService.execute(
          .new(
            url: resolved.uri.toString(),
            method: request.method,
            headers: request.headers,
            body: request.body,
            timeout: request.timeout,
            format: request.format,
          ),
          resolvedAddresses: resolved.addresses,
        );
        operation = currentOperation;
        final response = await currentOperation.valueOrCancellation();
        if (response == null || completer.isCanceled) return;

        completer.complete(response);
      } on Object catch (error, stackTrace) {
        if (!completer.isCanceled) {
          completer.completeError(error, stackTrace);
        }
      }
    });

    return completer.operation;
  }
}
