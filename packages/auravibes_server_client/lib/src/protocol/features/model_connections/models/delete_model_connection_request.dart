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

abstract class DeleteModelConnectionRequest._({
  required var int workspaceId,
  required var String requestId,
  required var String connectionId,
  required var int expectedRevision,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required int expectedRevision,
  }) = _DeleteModelConnectionRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeleteModelConnectionRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      connectionId: jsonSerialization['connectionId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
    );
  }

  /// Returns a shallow copy of this [DeleteModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeleteModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'expectedRevision': expectedRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeleteModelConnectionRequestImpl({
  required int workspaceId,
  required String requestId,
  required String connectionId,
  required int expectedRevision,
}) extends DeleteModelConnectionRequest {
  this
    : super._(
        workspaceId: workspaceId,
        requestId: requestId,
        connectionId: connectionId,
        expectedRevision: expectedRevision,
      );

  /// Returns a shallow copy of this [DeleteModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeleteModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
  }) {
    return DeleteModelConnectionRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      connectionId: connectionId ?? this.connectionId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
    );
  }
}
