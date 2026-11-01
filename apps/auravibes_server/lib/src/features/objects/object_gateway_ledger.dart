import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

enum ObjectGatewayLedgerFailure { unknown, closed, replay }

class ObjectGatewayLedgerStatus {
  const ObjectGatewayLedgerStatus({
    required this.closed,
    required this.pendingOperations,
  });

  final bool closed;
  final int pendingOperations;
}

class ObjectGatewayLedgerException implements Exception {
  const ObjectGatewayLedgerException(this.failure);

  final ObjectGatewayLedgerFailure failure;
}

abstract interface class ObjectGatewayLedger {
  Future<void> register(Session session, String key, String registrationId);

  Future<void> allow(Session session, String key, String registrationId);

  Future<void> start(
    Session session,
    String key,
    String registrationId,
    String operationId,
  );

  Future<void> finish(Session session, String key, String operationId);

  Future<ObjectGatewayLedgerStatus> status(
    Session session,
    String key,
    String registrationId,
  );

  Future<bool> close(Session session, String key, String registrationId);
}

class PostgresObjectGatewayLedger implements ObjectGatewayLedger {
  const PostgresObjectGatewayLedger();

  @override
  Future<void> register(
    Session session,
    String key,
    String registrationId,
  ) async {
    final rows = await session.db.unsafeQuery(
      'INSERT INTO object_gateway.keys '
      '(key_hash, registration_hash, closed) '
      "VALUES (decode(@keyHash, 'hex'), decode(@registrationHash, 'hex'), false) "
      'ON CONFLICT (key_hash) DO UPDATE SET '
      'registration_hash = object_gateway.keys.registration_hash '
      "WHERE object_gateway.keys.registration_hash = EXCLUDED.registration_hash "
      'RETURNING true AS registered',
      parameters: QueryParameters.named({
        'keyHash': _digest(key),
        'registrationHash': _digest(registrationId),
      }),
    );
    if (rows.isEmpty) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.replay,
      );
    }
  }

  @override
  Future<void> allow(Session session, String key, String registrationId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT closed FROM object_gateway.keys '
      "WHERE key_hash = decode(@keyHash, 'hex') AND "
      "registration_hash = decode(@registrationHash, 'hex')",
      parameters: QueryParameters.named({
        'keyHash': _digest(key),
        'registrationHash': _digest(registrationId),
      }),
    );
    if (rows.isEmpty) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    if (rows.first.toColumnMap()['closed']! as bool) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.closed,
      );
    }
  }

  @override
  Future<void> start(
    Session session,
    String key,
    String registrationId,
    String operationId,
  ) => session.db.transaction((transaction) async {
    final rows = await session.db.unsafeQuery(
      'SELECT closed FROM object_gateway.keys '
      "WHERE key_hash = decode(@keyHash, 'hex') AND "
      "registration_hash = decode(@registrationHash, 'hex') "
      'FOR UPDATE',
      parameters: QueryParameters.named({
        'keyHash': _digest(key),
        'registrationHash': _digest(registrationId),
      }),
      transaction: transaction,
    );
    if (rows.isEmpty) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    if (rows.first.toColumnMap()['closed']! as bool) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.closed,
      );
    }

    final inserted = await session.db.unsafeQuery(
      'INSERT INTO object_gateway.uploads (nonce_hash, key_hash, pending) '
      "VALUES (decode(@nonceHash, 'hex'), decode(@keyHash, 'hex'), true) "
      'ON CONFLICT (nonce_hash) DO NOTHING RETURNING true AS inserted',
      parameters: QueryParameters.named({
        'nonceHash': _digest(operationId),
        'keyHash': _digest(key),
      }),
      transaction: transaction,
    );
    if (inserted.isEmpty) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.replay,
      );
    }
  });

  @override
  Future<void> finish(Session session, String key, String operationId) async {
    final rows = await session.db.unsafeQuery(
      'UPDATE object_gateway.uploads SET pending = false '
      "WHERE key_hash = decode(@keyHash, 'hex') AND "
      "nonce_hash = decode(@nonceHash, 'hex') AND pending "
      'RETURNING true AS finished',
      parameters: QueryParameters.named({
        'keyHash': _digest(key),
        'nonceHash': _digest(operationId),
      }),
    );
    if (rows.isEmpty) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
  }

  @override
  Future<ObjectGatewayLedgerStatus> status(
    Session session,
    String key,
    String registrationId,
  ) async {
    final rows = await session.db.unsafeQuery(
      'SELECT key_row.closed, '
      'count(upload_row.nonce_hash) AS pending_operations '
      'FROM object_gateway.keys AS key_row '
      'LEFT JOIN object_gateway.uploads AS upload_row '
      'ON upload_row.key_hash = key_row.key_hash AND upload_row.pending '
      "WHERE key_row.key_hash = decode(@keyHash, 'hex') AND "
      "key_row.registration_hash = decode(@registrationHash, 'hex') "
      'GROUP BY key_row.closed',
      parameters: QueryParameters.named({
        'keyHash': _digest(key),
        'registrationHash': _digest(registrationId),
      }),
    );
    if (rows.isEmpty) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    final row = rows.first.toColumnMap();
    return ObjectGatewayLedgerStatus(
      closed: row['closed']! as bool,
      pendingOperations: row['pending_operations']! as int,
    );
  }

  @override
  Future<bool> close(Session session, String key, String registrationId) =>
      session.db.transaction((transaction) async {
        final rows = await session.db.unsafeQuery(
          'SELECT closed FROM object_gateway.keys '
          "WHERE key_hash = decode(@keyHash, 'hex') AND "
          "registration_hash = decode(@registrationHash, 'hex') "
          'FOR UPDATE',
          parameters: QueryParameters.named({
            'keyHash': _digest(key),
            'registrationHash': _digest(registrationId),
          }),
          transaction: transaction,
        );
        if (rows.isEmpty) {
          throw const ObjectGatewayLedgerException(
            ObjectGatewayLedgerFailure.unknown,
          );
        }

        await session.db.unsafeQuery(
          'UPDATE object_gateway.keys SET closed = true '
          "WHERE key_hash = decode(@keyHash, 'hex')",
          parameters: QueryParameters.named({'keyHash': _digest(key)}),
          transaction: transaction,
        );
        final pending = await session.db.unsafeQuery(
          'SELECT EXISTS (SELECT 1 FROM object_gateway.uploads '
          "WHERE key_hash = decode(@keyHash, 'hex') AND pending) AS pending",
          parameters: QueryParameters.named({'keyHash': _digest(key)}),
          transaction: transaction,
        );
        return !(pending.first.toColumnMap()['pending']! as bool);
      });

  static String _digest(String value) =>
      sha256.convert(utf8.encode(value)).toString();
}
