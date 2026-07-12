import 'package:async/async.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef AppSkillUrlGuard = Future<Uri> Function(String url);

class AppSkillHttpClientAdapter {
  AppSkillHttpClientAdapter(
    this._urlService, {
    AppSkillUrlGuard? requirePublicUri,
  }) : _requirePublicUri = requirePublicUri ?? requirePublicHttpsUri;

  final UrlService _urlService;
  final AppSkillUrlGuard _requirePublicUri;

  CancelableOperation<UrlResponse> execute(UrlRequest request) {
    CancelableOperation<UrlResponse>? operation;
    final completer = CancelableCompleter<UrlResponse>(
      onCancel: () => operation?.cancel(),
    );

    Future<void>(() async {
      try {
        final uri = await _requirePublicUri(request.url);
        if (completer.isCanceled) return;

        final currentOperation = _urlService.execute(
          UrlRequest(
            url: uri.toString(),
            method: request.method,
            headers: request.headers,
            body: request.body,
            timeout: request.timeout,
            format: request.format,
          ),
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
