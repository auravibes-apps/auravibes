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

abstract class DeleteObjectRequest implements _i1.SerializableModel {
  DeleteObjectRequest._({
    required this.workspaceId,
    required this.objectId,
    required this.requestId,
    required this.expectedRevision,
  });

  factory DeleteObjectRequest({
    required int workspaceId,
    required int objectId,
    required String requestId,
    required int expectedRevision,
  }) = _DeleteObjectRequestImpl;

  factory DeleteObjectRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeleteObjectRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
    );
  }

  int workspaceId;

  int objectId;

  String requestId;

  int expectedRevision;

  /// Returns a shallow copy of this [DeleteObjectRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeleteObjectRequest copyWith({
    int? workspaceId,
    int? objectId,
    String? requestId,
    int? expectedRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteObjectRequest',
      'workspaceId': workspaceId,
      'objectId': objectId,
      'requestId': requestId,
      'expectedRevision': expectedRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeleteObjectRequestImpl extends DeleteObjectRequest {
  _DeleteObjectRequestImpl({
    required int workspaceId,
    required int objectId,
    required String requestId,
    required int expectedRevision,
  }) : super._(
         workspaceId: workspaceId,
         objectId: objectId,
         requestId: requestId,
         expectedRevision: expectedRevision,
       );

  /// Returns a shallow copy of this [DeleteObjectRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeleteObjectRequest copyWith({
    int? workspaceId,
    int? objectId,
    String? requestId,
    int? expectedRevision,
  }) {
    return DeleteObjectRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
      requestId: requestId ?? this.requestId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
    );
  }
}
