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

abstract class WorkspaceErasureRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceErasureRequest._({
    this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.ownerUserId,
    required this.requestId,
    required this.requestHash,
    required this.state,
    required this.requestedAt,
    this.completedAt,
    this.failureReason,
  });

  factory WorkspaceErasureRequest({
    int? id,
    required int workspaceId,
    required String workspaceName,
    required String ownerUserId,
    required String requestId,
    required String requestHash,
    required String state,
    required DateTime requestedAt,
    DateTime? completedAt,
    String? failureReason,
  }) = _WorkspaceErasureRequestImpl;

  factory WorkspaceErasureRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceErasureRequest(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      workspaceName: jsonSerialization['workspaceName'] as String,
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      state: jsonSerialization['state'] as String,
      requestedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['requestedAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      failureReason: jsonSerialization['failureReason'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String workspaceName;

  String ownerUserId;

  String requestId;

  String requestHash;

  String state;

  DateTime requestedAt;

  DateTime? completedAt;

  String? failureReason;

  /// Returns a shallow copy of this [WorkspaceErasureRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceErasureRequest copyWith({
    int? id,
    int? workspaceId,
    String? workspaceName,
    String? ownerUserId,
    String? requestId,
    String? requestHash,
    String? state,
    DateTime? requestedAt,
    DateTime? completedAt,
    String? failureReason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceErasureRequest',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'ownerUserId': ownerUserId,
      'requestId': requestId,
      'requestHash': requestHash,
      'state': state,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (failureReason != null) 'failureReason': failureReason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceErasureRequest',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'ownerUserId': ownerUserId,
      'requestId': requestId,
      'requestHash': requestHash,
      'state': state,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (failureReason != null) 'failureReason': failureReason,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceErasureRequestImpl extends WorkspaceErasureRequest {
  _WorkspaceErasureRequestImpl({
    int? id,
    required int workspaceId,
    required String workspaceName,
    required String ownerUserId,
    required String requestId,
    required String requestHash,
    required String state,
    required DateTime requestedAt,
    DateTime? completedAt,
    String? failureReason,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         workspaceName: workspaceName,
         ownerUserId: ownerUserId,
         requestId: requestId,
         requestHash: requestHash,
         state: state,
         requestedAt: requestedAt,
         completedAt: completedAt,
         failureReason: failureReason,
       );

  /// Returns a shallow copy of this [WorkspaceErasureRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceErasureRequest copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? workspaceName,
    String? ownerUserId,
    String? requestId,
    String? requestHash,
    String? state,
    DateTime? requestedAt,
    Object? completedAt = _Undefined,
    Object? failureReason = _Undefined,
  }) {
    return WorkspaceErasureRequest(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      state: state ?? this.state,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      failureReason: failureReason is String?
          ? failureReason
          : this.failureReason,
    );
  }
}
