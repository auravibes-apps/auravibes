// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'package:async/async.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

final class UrlTool({final UrlService? _urlService})
    extends NativeToolEntity<String, String> {
  @override
  NativeToolType get type => .url;

  @override
  ToolSpec getTool() => urlToolSpec;

  @override
  CancelableOperation<String> runner(String toolInput) {
    CancelableOperation<UrlResponse>? responseOperation;
    final completer = CancelableCompleter<String>(
      onCancel: () => responseOperation?.cancel(),
    );

    _run(
      toolInput,
      completer,
      (operation) => responseOperation = operation,
    ).catchError(_completeError(completer));

    return completer.operation;
  }

  Future<void> _run(
    String toolInput,
    CancelableCompleter<String> completer,
    void Function(CancelableOperation<UrlResponse>) onOperation,
  ) async {
    final resolved = await _buildRequest(toolInput);
    if (completer.isCanceled) return;
    await _completeRequest(resolved, completer, onOperation);
  }

  Future<void> _completeRequest(
    ({UrlRequest request, List<String>? addresses}) resolved,
    CancelableCompleter<String> completer,
    void Function(CancelableOperation<UrlResponse>) onOperation,
  ) async {
    final operation = (_urlService ?? UrlService()).execute(
      resolved.request,
      resolvedAddresses: resolved.addresses,
    );
    onOperation(operation);
    final response = await operation.valueOrCancellation();
    if (response == null || completer.isCanceled) return;
    completer.complete(
      formatUrlToolResponse(response, requestedFormat: resolved.request.format),
    );
  }

  void Function(Object, StackTrace) _completeError(
    CancelableCompleter<String> completer,
  ) => (Object error, StackTrace stackTrace) {
    if (!completer.isCanceled) completer.completeError(error, stackTrace);
  };

  Future<({UrlRequest request, List<String>? addresses})> _buildRequest(
    String toolInput,
  ) async {
    final request = parseUrlToolInput(toolInput);
    final resolved = await PublicUrlGuard.resolvePublicUri(
      request.url,
      requireHttps: request.headers.isNotEmpty,
    );

    return (request: request, addresses: resolved.addresses);
  }
}
