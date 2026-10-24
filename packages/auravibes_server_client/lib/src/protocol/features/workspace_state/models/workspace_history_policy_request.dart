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

abstract class WorkspaceHistoryPolicyRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceHistoryPolicyRequest._({
    required this.workspaceId,
    this.days,
    required this.expectedRevision,
    required this.requestId,
  });

  factory WorkspaceHistoryPolicyRequest({
    required int workspaceId,
    int? days,
    required int expectedRevision,
    required String requestId,
  }) = _WorkspaceHistoryPolicyRequestImpl;

  factory WorkspaceHistoryPolicyRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceHistoryPolicyRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      days: jsonSerialization['days'] as int?,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      requestId: jsonSerialization['requestId'] as String,
    );
  }

  int workspaceId;

  int? days;

  int expectedRevision;

  String requestId;

  /// Returns a shallow copy of this [WorkspaceHistoryPolicyRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceHistoryPolicyRequest copyWith({
    int? workspaceId,
    int? days,
    int? expectedRevision,
    String? requestId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceHistoryPolicyRequest',
      'workspaceId': workspaceId,
      if (days != null) 'days': days,
      'expectedRevision': expectedRevision,
      'requestId': requestId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceHistoryPolicyRequest',
      'workspaceId': workspaceId,
      if (days != null) 'days': days,
      'expectedRevision': expectedRevision,
      'requestId': requestId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceHistoryPolicyRequestImpl extends WorkspaceHistoryPolicyRequest {
  _WorkspaceHistoryPolicyRequestImpl({
    required int workspaceId,
    int? days,
    required int expectedRevision,
    required String requestId,
  }) : super._(
         workspaceId: workspaceId,
         days: days,
         expectedRevision: expectedRevision,
         requestId: requestId,
       );

  /// Returns a shallow copy of this [WorkspaceHistoryPolicyRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceHistoryPolicyRequest copyWith({
    int? workspaceId,
    Object? days = _Undefined,
    int? expectedRevision,
    String? requestId,
  }) {
    return WorkspaceHistoryPolicyRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      days: days is int? ? days : this.days,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      requestId: requestId ?? this.requestId,
    );
  }
}
