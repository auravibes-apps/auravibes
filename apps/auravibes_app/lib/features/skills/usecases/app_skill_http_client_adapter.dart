import 'package:async/async.dart';
import 'package:auravibes_app/services/url/models/url_request_method.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_skills/auravibes_skills.dart';

typedef AppSkillUrlGuard = Future<Uri> Function(String url);

class AppSkillHttpClientAdapter {
  AppSkillHttpClientAdapter(
    this._urlService, {
    AppSkillUrlGuard? requirePublicUri,
  }) : _requirePublicUri = requirePublicUri ?? requirePublicHttpsUri;

  final UrlService _urlService;
  final AppSkillUrlGuard _requirePublicUri;

  CancelableOperation<AppSkillUrlResponse> execute(AppSkillUrlRequest request) {
    CancelableOperation<UrlResponse>? operation;
    final completer = CancelableCompleter<AppSkillUrlResponse>(
      onCancel: () => operation?.cancel(),
    );

    Future<void>(() async {
      try {
        final uri = await _requirePublicUri(request.url);
        if (completer.isCanceled) return;

        operation = _urlService.execute(
          UrlRequest(
            url: uri.toString(),
            method: request.method,
            headers: request.headers,
            body: request.body,
            timeout: request.timeout,
            format: request.format,
          ),
        );
        final response = await operation!.value;
        if (completer.isCanceled) return;

        completer.complete(
          AppSkillUrlResponse(
            statusCode: response.statusCode,
            body: response.body,
            headers: response.headers,
            elapsed: response.elapsed,
          ),
        );
      } on Object catch (error, stackTrace) {
        if (!completer.isCanceled) {
          completer.completeError(error, stackTrace);
        }
      }
    });

    return completer.operation;
  }
}
