/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class ConnectorWrite
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ConnectorWrite._({
    this.id,
    required this.workspaceId,
    required this.operationId,
    required this.requestDigest,
    required this.outcome,
    this.statusCode,
  });

  factory ConnectorWrite({
    int? id,
    required int workspaceId,
    required String operationId,
    required String requestDigest,
    required String outcome,
    int? statusCode,
  }) = _ConnectorWriteImpl;

  factory ConnectorWrite.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConnectorWrite(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      operationId: jsonSerialization['operationId'] as String,
      requestDigest: jsonSerialization['requestDigest'] as String,
      outcome: jsonSerialization['outcome'] as String,
      statusCode: jsonSerialization['statusCode'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String operationId;

  String requestDigest;

  String outcome;

  int? statusCode;

  /// Returns a shallow copy of this [ConnectorWrite]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConnectorWrite copyWith({
    int? id,
    int? workspaceId,
    String? operationId,
    String? requestDigest,
    String? outcome,
    int? statusCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectorWrite',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'operationId': operationId,
      'requestDigest': requestDigest,
      'outcome': outcome,
      if (statusCode != null) 'statusCode': statusCode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConnectorWrite',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'operationId': operationId,
      'requestDigest': requestDigest,
      'outcome': outcome,
      if (statusCode != null) 'statusCode': statusCode,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConnectorWriteImpl extends ConnectorWrite {
  _ConnectorWriteImpl({
    int? id,
    required int workspaceId,
    required String operationId,
    required String requestDigest,
    required String outcome,
    int? statusCode,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         operationId: operationId,
         requestDigest: requestDigest,
         outcome: outcome,
         statusCode: statusCode,
       );

  /// Returns a shallow copy of this [ConnectorWrite]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConnectorWrite copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? operationId,
    String? requestDigest,
    String? outcome,
    Object? statusCode = _Undefined,
  }) {
    return ConnectorWrite(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      operationId: operationId ?? this.operationId,
      requestDigest: requestDigest ?? this.requestDigest,
      outcome: outcome ?? this.outcome,
      statusCode: statusCode is int? ? statusCode : this.statusCode,
    );
  }
}
