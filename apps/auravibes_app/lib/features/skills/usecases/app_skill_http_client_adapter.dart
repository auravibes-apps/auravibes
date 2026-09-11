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
    final pending = _newPendingRequest();

    Future<void>(() => _completeRequest(request, pending));

    return pending.completer.operation;
  }

  _PendingAppSkillRequest _newPendingRequest() {
    _PendingAppSkillRequest? pending;
    final completer = CancelableCompleter<UrlResponse>(
      onCancel: () => pending?.operation?.cancel(),
    );

    return pending = _PendingAppSkillRequest(completer);
  }

  Future<void> _completeRequest(
    UrlRequest request,
    _PendingAppSkillRequest pending,
  ) async {
    try {
      final resolved = await _requirePublicUri(request.url);
      if (pending.completer.isCanceled) return;

      await _completeResolvedRequest(request, resolved, pending);
    } on Object catch (error, stackTrace) {
      _completeError(pending, error, stackTrace);
    }
  }

  Future<void> _completeResolvedRequest(
    UrlRequest request,
    PublicUrlResolution resolved,
    _PendingAppSkillRequest pending,
  ) async {
    final operation = _executeResolvedRequest(request, resolved);
    pending.operation = operation;
    await _completeResponse(operation, pending);
  }

  CancelableOperation<UrlResponse> _executeResolvedRequest(
    UrlRequest request,
    PublicUrlResolution resolved,
  ) => _urlService.execute(
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

  Future<void> _completeResponse(
    CancelableOperation<UrlResponse> operation,
    _PendingAppSkillRequest pending,
  ) async {
    final response = await operation.valueOrCancellation();
    if (response == null || pending.completer.isCanceled) return;

    pending.completer.complete(response);
  }

  void _completeError(
    _PendingAppSkillRequest pending,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!pending.completer.isCanceled) {
      pending.completer.completeError(error, stackTrace);
    }
  }
}

class _PendingAppSkillRequest {
  new(this.completer);

  final CancelableCompleter<UrlResponse> completer;
  CancelableOperation<UrlResponse>? operation;
}
