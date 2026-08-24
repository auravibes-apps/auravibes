// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'package:async/async.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

final class UrlTool extends NativeToolEntity<String, String> {
  UrlTool({this._urlService});

  final UrlService? _urlService;

  @override
  ToolSpec getTool() => urlToolSpec;

  @override
  CancelableOperation<String> runner(String toolInput) {
    CancelableOperation<UrlResponse>? responseOperation;
    final completer = CancelableCompleter<String>(
      onCancel: () => responseOperation?.cancel(),
    );

    () async {
      final request = await _buildRequest(toolInput);
      if (completer.isCanceled) {
        return;
      }

      final service = _urlService ?? UrlService();
      final operation = service.execute(request);
      responseOperation = operation;

      final response = await operation.valueOrCancellation();
      if (response == null || completer.isCanceled) {
        return;
      }

      completer.complete(
        formatUrlToolResponse(response, requestedFormat: request.format),
      );
    }().catchError((Object error, StackTrace stackTrace) {
      if (completer.isCanceled) {
        return;
      }

      completer.completeError(error, stackTrace);
    });

    return completer.operation;
  }

  Future<UrlRequest> _buildRequest(String toolInput) async {
    final request = parseUrlToolInput(toolInput);
    final uri = Uri.parse(request.url);
    if (request.headers.isEmpty) {
      await PublicUrlGuard.ensureHost(uri.host);
    } else {
      final _ = await PublicUrlGuard.requireHttpsUri(uri.toString());
    }

    return request;
  }

  @override
  NativeToolType get type => .url;
}
