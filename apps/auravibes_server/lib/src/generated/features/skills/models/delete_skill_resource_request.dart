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
import 'package:serverpod/serverpod.dart' as _is;

abstract class DeleteSkillResourceRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DeleteSkillResourceRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.resourceId,
    required this.expectedRevision,
  });

  factory DeleteSkillResourceRequest({
    required int workspaceId,
    required String requestId,
    required String resourceId,
    required int expectedRevision,
  }) = _DeleteSkillResourceRequestImpl;

  factory DeleteSkillResourceRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeleteSkillResourceRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
    );
  }

  int workspaceId;

  String requestId;

  String resourceId;

  int expectedRevision;

  /// Returns a shallow copy of this [DeleteSkillResourceRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeleteSkillResourceRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? resourceId,
    int? expectedRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteSkillResourceRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'resourceId': resourceId,
      'expectedRevision': expectedRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeleteSkillResourceRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'resourceId': resourceId,
      'expectedRevision': expectedRevision,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DeleteSkillResourceRequestImpl extends DeleteSkillResourceRequest {
  _DeleteSkillResourceRequestImpl({
    required int workspaceId,
    required String requestId,
    required String resourceId,
    required int expectedRevision,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         resourceId: resourceId,
         expectedRevision: expectedRevision,
       );

  /// Returns a shallow copy of this [DeleteSkillResourceRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeleteSkillResourceRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? resourceId,
    int? expectedRevision,
  }) {
    return DeleteSkillResourceRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      resourceId: resourceId ?? this.resourceId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
    );
  }
}
