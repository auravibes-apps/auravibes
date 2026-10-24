import 'package:auravibes_engine/src/connectors/models/url_response.dart';

/// Runs only after the host validates current authorization and input schema.
class const ConnectorWriteExecutor(final ConnectorWriteJournal _journal) {
  Future<ConnectorWriteReceipt> call({
    required String operationId,
    required String requestDigest,
    required Future<UrlResponse> Function() execute,
    ConnectorWriteReconciler? reconcile,
  }) async {
    final previous = await _journal.claim(operationId, requestDigest);
    if (previous != null) {
      _validateDigest(previous, requestDigest);
      return await _reconcile(previous, reconcile);
    }
    final receipt = await _send(operationId, requestDigest, execute);
    return await _persist(receipt, _uncertain(receipt));
  }

  Future<ConnectorWriteReceipt> _reconcile(
    ConnectorWriteReceipt previous,
    ConnectorWriteReconciler? reconcile,
  ) async {
    if (previous.outcome != ConnectorWriteOutcome.uncertain ||
        reconcile == null) {
      return previous;
    }
    ConnectorWriteReceipt result;
    try {
      result = await reconcile(previous);
    } on Object {
      return previous;
    }
    _validateIdentity(previous, result);
    return await _persist(result, previous);
  }

  Future<ConnectorWriteReceipt> _persist(
    ConnectorWriteReceipt receipt,
    ConnectorWriteReceipt fallback,
  ) async {
    try {
      await _journal.save(receipt);
      return receipt;
    } on Object {
      // Claim is durable; failed final persistence must not invite a retry.
      return fallback;
    }
  }

  Future<ConnectorWriteReceipt> _send(
    String operationId,
    String digest,
    Future<UrlResponse> Function() execute,
  ) async {
    try {
      final response = await execute();
      return ConnectorWriteReceipt(
        operationId: operationId,
        requestDigest: digest,
        outcome: _outcome(response),
        statusCode: response.statusCode,
      );
    } on Object {
      // Transport failure cannot prove that the provider did not apply a write.
      return ConnectorWriteReceipt(
        operationId: operationId,
        requestDigest: digest,
        outcome: ConnectorWriteOutcome.uncertain,
      );
    }
  }
}

ConnectorWriteOutcome _outcome(UrlResponse response) {
  if (response.isOk && !const {202, 207}.contains(response.statusCode)) {
    return ConnectorWriteOutcome.completed;
  }
  if (response.isClientError && response.statusCode != 408) {
    return ConnectorWriteOutcome.failed;
  }
  return ConnectorWriteOutcome.uncertain;
}

/// Uncertain includes an in-flight or interrupted request until reconciled.
enum ConnectorWriteOutcome { completed, failed, uncertain }

class const ConnectorWriteReceipt({
  required final String operationId,
  required final String requestDigest,
  required final ConnectorWriteOutcome outcome,
  final int? statusCode,
}) {
  Map<String, Object?> toJson() => {
    'kind': 'connectorWrite',
    'operationId': operationId,
    'outcome': outcome.name,
    if (statusCode != null) 'statusCode': statusCode,
    'retryBlocked': outcome == ConnectorWriteOutcome.uncertain,
    'undoSupported': false,
  };
}

/// Hosts atomically claim before sending. Stored receipts contain no payloads,
/// URLs, headers or credentials. Same-digest uncertain writes block new IDs.
abstract interface class ConnectorWriteJournal {
  Future<ConnectorWriteReceipt?> claim(
    String operationId,
    String requestDigest,
  );
  Future<void> save(ConnectorWriteReceipt receipt);
}

typedef ConnectorWriteReconciler = Future<ConnectorWriteReceipt> Function(
  ConnectorWriteReceipt receipt,
);

void _validateIdentity(
  ConnectorWriteReceipt previous,
  ConnectorWriteReceipt result,
) {
  if (result.operationId != previous.operationId ||
      result.requestDigest != previous.requestDigest) {
    throw const FormatException(
      'Reconciliation must retain operation identity.',
    );
  }
}

void _validateDigest(ConnectorWriteReceipt previous, String digest) {
  if (previous.requestDigest != digest) {
    throw const FormatException('Operation ID belongs to another request.');
  }
}

ConnectorWriteReceipt _uncertain(ConnectorWriteReceipt receipt) =>
    ConnectorWriteReceipt(
      operationId: receipt.operationId,
      requestDigest: receipt.requestDigest,
      outcome: ConnectorWriteOutcome.uncertain,
    );
