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

abstract class CompleteUploadRequest implements _i1.SerializableModel {
  CompleteUploadRequest._({
    required this.workspaceId,
    required this.objectId,
  });

  factory CompleteUploadRequest({
    required int workspaceId,
    required int objectId,
  }) = _CompleteUploadRequestImpl;

  factory CompleteUploadRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CompleteUploadRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
    );
  }

  int workspaceId;

  int objectId;

  /// Returns a shallow copy of this [CompleteUploadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CompleteUploadRequest copyWith({
    int? workspaceId,
    int? objectId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompleteUploadRequest',
      'workspaceId': workspaceId,
      'objectId': objectId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CompleteUploadRequestImpl extends CompleteUploadRequest {
  _CompleteUploadRequestImpl({
    required int workspaceId,
    required int objectId,
  }) : super._(
         workspaceId: workspaceId,
         objectId: objectId,
       );

  /// Returns a shallow copy of this [CompleteUploadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CompleteUploadRequest copyWith({
    int? workspaceId,
    int? objectId,
  }) {
    return CompleteUploadRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
    );
  }
}
