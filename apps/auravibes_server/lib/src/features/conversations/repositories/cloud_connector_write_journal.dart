import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

class const CloudConnectorWriteJournal(
  final Session _session,
  final int _workspaceId,
) implements ConnectorWriteJournal {
  @override
  Future<ConnectorWriteReceipt?> claim(
    String operationId,
    String requestDigest,
  ) => _session.db.transaction(
    (transaction) => _claim(operationId, requestDigest, transaction),
  );

  @override
  Future<void> save(ConnectorWriteReceipt receipt) =>
      _session.db.transaction((transaction) => _save(receipt, transaction));

  Future<ConnectorWriteReceipt?> _claim(
    String id,
    String digest,
    Transaction transaction,
  ) async {
    await _lock(transaction);
    final row =
        await _byId(id, transaction) ?? await _uncertain(digest, transaction);
    if (row != null) return _receipt(row);
    await ConnectorWrite.db.insertRow(
      _session,
      _pending(id, digest),
      transaction: transaction,
    );
    return null;
  }

  Future<void> _lock(Transaction transaction) async {
    final workspace = await CloudWorkspace.db.findFirstRow(
      _session,
      where: (row) =>
          row.id.equals(_workspaceId) &
          row.deletedAt.equals(null) &
          row.erasureRequestedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) throw StateError('Workspace is unavailable.');
  }

  Future<ConnectorWrite?> _byId(String id, Transaction transaction) =>
      ConnectorWrite.db.findFirstRow(
        _session,
        where: (row) => _scope(row) & row.operationId.equals(id),
        transaction: transaction,
      );

  Future<ConnectorWrite?> _uncertain(String digest, Transaction transaction) =>
      ConnectorWrite.db.findFirstRow(
        _session,
        where: (row) => _unknown(row, digest),
        transaction: transaction,
      );

  Expression<dynamic> _scope(ConnectorWriteTable row) =>
      row.workspaceId.equals(_workspaceId);

  Expression<dynamic> _unknown(ConnectorWriteTable row, String digest) =>
      _scope(row) &
      row.requestDigest.equals(digest) &
      row.outcome.equals('uncertain');

  ConnectorWrite _pending(String id, String digest) => ConnectorWrite(
    workspaceId: _workspaceId,
    operationId: id,
    requestDigest: digest,
    outcome: 'uncertain',
  );

  Future<void> _save(
    ConnectorWriteReceipt receipt,
    Transaction transaction,
  ) async {
    await _lock(transaction);
    final row = await _byId(receipt.operationId, transaction);
    if (row == null) {
      throw StateError('Connector write receipt no longer exists.');
    }
    if (row.outcome != 'uncertain') return;
    await ConnectorWrite.db.updateRow(
      _session,
      _changes(row, receipt),
      transaction: transaction,
    );
  }
}

ConnectorWrite _changes(ConnectorWrite row, ConnectorWriteReceipt receipt) =>
    row.copyWith(
      outcome: receipt.outcome.name,
      statusCode: receipt.statusCode,
    );

ConnectorWriteReceipt _receipt(ConnectorWrite row) => ConnectorWriteReceipt(
  operationId: row.operationId,
  requestDigest: row.requestDigest,
  outcome: ConnectorWriteOutcome.values.byName(row.outcome),
  statusCode: row.statusCode,
);
