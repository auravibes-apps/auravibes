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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class WorkspaceMutationReceipt._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  var int? workspaceId,
  required var String scopeKey,
  required var String actorUserId,
  required var String endpoint,
  required var String requestId,
  required var String requestHash,
  required var String responseJson,
  required var DateTime createdAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    int? workspaceId,
    required String scopeKey,
    required String actorUserId,
    required String endpoint,
    required String requestId,
    required String requestHash,
    required String responseJson,
    required DateTime createdAt,
  }) = _WorkspaceMutationReceiptImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceMutationReceipt(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int?,
      scopeKey: jsonSerialization['scopeKey'] as String,
      actorUserId: jsonSerialization['actorUserId'] as String,
      endpoint: jsonSerialization['endpoint'] as String,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      responseJson: jsonSerialization['responseJson'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [WorkspaceMutationReceipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceMutationReceipt copyWith({
    int? id,
    int? workspaceId,
    String? scopeKey,
    String? actorUserId,
    String? endpoint,
    String? requestId,
    String? requestHash,
    String? responseJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceMutationReceipt',
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'scopeKey': scopeKey,
      'actorUserId': actorUserId,
      'endpoint': endpoint,
      'requestId': requestId,
      'requestHash': requestHash,
      'responseJson': responseJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _WorkspaceMutationReceiptImpl({
  int? id,
  int? workspaceId,
  required String scopeKey,
  required String actorUserId,
  required String endpoint,
  required String requestId,
  required String requestHash,
  required String responseJson,
  required DateTime createdAt,
}) extends WorkspaceMutationReceipt {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        scopeKey: scopeKey,
        actorUserId: actorUserId,
        endpoint: endpoint,
        requestId: requestId,
        requestHash: requestHash,
        responseJson: responseJson,
        createdAt: createdAt,
      );

  /// Returns a shallow copy of this [WorkspaceMutationReceipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceMutationReceipt copyWith({
    Object? id = _Undefined,
    Object? workspaceId = _Undefined,
    String? scopeKey,
    String? actorUserId,
    String? endpoint,
    String? requestId,
    String? requestHash,
    String? responseJson,
    DateTime? createdAt,
  }) {
    return WorkspaceMutationReceipt(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId is int? ? workspaceId : this.workspaceId,
      scopeKey: scopeKey ?? this.scopeKey,
      actorUserId: actorUserId ?? this.actorUserId,
      endpoint: endpoint ?? this.endpoint,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      responseJson: responseJson ?? this.responseJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
