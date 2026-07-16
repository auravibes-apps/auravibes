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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class UpdateWorkspaceMemberRoleRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  UpdateWorkspaceMemberRoleRequest._({
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.requestId,
    required this.expectedMemberRevision,
  });

  factory UpdateWorkspaceMemberRoleRequest({
    required int workspaceId,
    required String userId,
    required String role,
    required String requestId,
    required int expectedMemberRevision,
  }) = _UpdateWorkspaceMemberRoleRequestImpl;

  factory UpdateWorkspaceMemberRoleRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return UpdateWorkspaceMemberRoleRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      role: jsonSerialization['role'] as String,
      requestId: jsonSerialization['requestId'] as String,
      expectedMemberRevision:
          jsonSerialization['expectedMemberRevision'] as int,
    );
  }

  int workspaceId;

  String userId;

  String role;

  String requestId;

  int expectedMemberRevision;

  /// Returns a shallow copy of this [UpdateWorkspaceMemberRoleRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UpdateWorkspaceMemberRoleRequest copyWith({
    int? workspaceId,
    String? userId,
    String? role,
    String? requestId,
    int? expectedMemberRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UpdateWorkspaceMemberRoleRequest',
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
      'requestId': requestId,
      'expectedMemberRevision': expectedMemberRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UpdateWorkspaceMemberRoleRequest',
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
      'requestId': requestId,
      'expectedMemberRevision': expectedMemberRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _UpdateWorkspaceMemberRoleRequestImpl
    extends UpdateWorkspaceMemberRoleRequest {
  _UpdateWorkspaceMemberRoleRequestImpl({
    required int workspaceId,
    required String userId,
    required String role,
    required String requestId,
    required int expectedMemberRevision,
  }) : super._(
         workspaceId: workspaceId,
         userId: userId,
         role: role,
         requestId: requestId,
         expectedMemberRevision: expectedMemberRevision,
       );

  /// Returns a shallow copy of this [UpdateWorkspaceMemberRoleRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UpdateWorkspaceMemberRoleRequest copyWith({
    int? workspaceId,
    String? userId,
    String? role,
    String? requestId,
    int? expectedMemberRevision,
  }) {
    return UpdateWorkspaceMemberRoleRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      requestId: requestId ?? this.requestId,
      expectedMemberRevision:
          expectedMemberRevision ?? this.expectedMemberRevision,
    );
  }
}
