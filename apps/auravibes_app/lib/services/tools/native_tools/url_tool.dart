// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

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
  CancelableOperation<String> runner(String toolInput) =>
      _startUrlRun(this, toolInput);
}

CancelableOperation<String> _startUrlRun(UrlTool tool, String toolInput) {
  final controller = _urlRunController(tool);

  _startUrlOperation(tool, toolInput, controller);

  return controller.completer.operation;
}

void _startUrlOperation(
  UrlTool tool,
  String toolInput,
  _UrlRunController controller,
) => _runUrlOperation((
  tool: tool,
  toolInput: toolInput,
  completer: controller.completer,
  onOperation: controller.onOperation,
));

typedef _UrlRunRequest = ({
  UrlTool tool,
  String toolInput,
  CancelableCompleter<String> completer,
  void Function(CancelableOperation<UrlResponse>) onOperation,
});

typedef _UrlRunController = ({
  CancelableCompleter<String> completer,
  void Function(CancelableOperation<UrlResponse>) onOperation,
});

_UrlRunController _urlRunController(UrlTool tool) {
  CancelableOperation<UrlResponse>? responseOperation;
  final completer = tool._urlCompleter(
    () => _cancelUrlOperation(responseOperation),
  );

  void onOperation(CancelableOperation<UrlResponse> operation) {
    responseOperation = operation;
  }

  return (completer: completer, onOperation: onOperation);
}

Future<void> _cancelUrlOperation(
  CancelableOperation<UrlResponse>? operation,
) async {
  final _ = await operation?.cancel();
}

void _runUrlOperation(_UrlRunRequest request) {
  unawaited(
    request.tool
        ._run(request.toolInput, request.completer, request.onOperation)
        .catchError(request.tool._completeError(request.completer)),
  );
}

extension on UrlTool {
  CancelableCompleter<String> _urlCompleter(Future<void> Function() onCancel) =>
      CancelableCompleter<String>(onCancel: onCancel);

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
    final operation = _executeRequest(resolved);
    onOperation(operation);
    final response = await operation.valueOrCancellation();
    if (response == null || completer.isCanceled) return;
    completer.complete(_formatResponse(response, resolved.request));
  }

  CancelableOperation<UrlResponse> _executeRequest(
    ({UrlRequest request, List<String>? addresses}) resolved,
  ) => (_urlService ?? UrlService()).execute(
    resolved.request,
    resolvedAddresses: resolved.addresses,
  );

  String _formatResponse(UrlResponse response, UrlRequest request) =>
      formatUrlToolResponse(response, requestedFormat: request.format);

  void Function(Object, StackTrace) _completeError(
    CancelableCompleter<String> completer,
  ) => (error, stackTrace) {
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
