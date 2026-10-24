import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

class const LocalConnectorWriteJournal(
  final AppDatabase _database,
  final String _workspaceId,
) implements ConnectorWriteJournal {
  @override
  Future<ConnectorWriteReceipt?> claim(
    String operationId,
    String requestDigest,
  ) => _database.transaction(() => _claim(operationId, requestDigest));

  @override
  Future<void> save(ConnectorWriteReceipt receipt) =>
      _database.transaction(() => _save(receipt));

  Future<ConnectorWriteReceipt?> _claim(String id, String digest) async {
    final row = await _byId(id) ?? await _uncertain(digest);
    if (row != null) return _receipt(row);
    final _ = await _database
        .into(_database.connectorWrites)
        .insert(_pending(id, digest));

    return null;
  }

  SimpleSelectStatement<$ConnectorWritesTable, ConnectorWriteRow> _query() =>
      _database.select(_database.connectorWrites)
        ..where((row) => row.workspaceId.equals(_workspaceId));

  Future<ConnectorWriteRow?> _byId(String id) =>
      (_query()..where((row) => row.operationId.equals(id))).getSingleOrNull();

  Future<ConnectorWriteRow?> _uncertain(String digest) =>
      (_uncertainQuery(digest)..limit(1)).getSingleOrNull();

  SimpleSelectStatement<$ConnectorWritesTable, ConnectorWriteRow>
  _uncertainQuery(String digest) => _query()
    ..where((row) => row.requestDigest.equals(digest))
    ..where((row) => row.outcome.equals('uncertain'));

  ConnectorWritesCompanion _pending(String id, String digest) =>
      ConnectorWritesCompanion.insert(
        workspaceId: _workspaceId,
        operationId: id,
        requestDigest: digest,
        outcome: 'uncertain',
      );

  Future<void> _save(ConnectorWriteReceipt receipt) async {
    final row = await _byId(receipt.operationId);
    if (row == null) {
      throw StateError('Connector write receipt no longer exists.');
    }
    if (row.outcome != 'uncertain') return;
    final _ = await _update(receipt.operationId).write(_changes(receipt));
  }

  UpdateStatement<$ConnectorWritesTable, ConnectorWriteRow> _update(
    String id,
  ) => _database.update(_database.connectorWrites)
    ..where((row) => row.workspaceId.equals(_workspaceId))
    ..where((row) => row.operationId.equals(id));
}

ConnectorWritesCompanion _changes(ConnectorWriteReceipt receipt) =>
    ConnectorWritesCompanion(
      outcome: .new(receipt.outcome.name),
      statusCode: .new(receipt.statusCode),
    );

ConnectorWriteReceipt _receipt(ConnectorWriteRow row) => ConnectorWriteReceipt(
  operationId: row.operationId,
  requestDigest: row.requestDigest,
  outcome: ConnectorWriteOutcome.values.byName(row.outcome),
  statusCode: row.statusCode,
);
