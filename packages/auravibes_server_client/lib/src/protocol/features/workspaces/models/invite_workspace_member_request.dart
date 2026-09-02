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

abstract class InviteWorkspaceMemberRequest._({
  required var int workspaceId,
  required var String email,
  required var String role,
  required var String requestId,
  required var int expectedWorkspaceRevision,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String email,
    required String role,
    required String requestId,
    required int expectedWorkspaceRevision,
  }) = _InviteWorkspaceMemberRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InviteWorkspaceMemberRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      email: jsonSerialization['email'] as String,
      role: jsonSerialization['role'] as String,
      requestId: jsonSerialization['requestId'] as String,
      expectedWorkspaceRevision:
          jsonSerialization['expectedWorkspaceRevision'] as int,
    );
  }

  /// Returns a shallow copy of this [InviteWorkspaceMemberRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InviteWorkspaceMemberRequest copyWith({
    int? workspaceId,
    String? email,
    String? role,
    String? requestId,
    int? expectedWorkspaceRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InviteWorkspaceMemberRequest',
      'workspaceId': workspaceId,
      'email': email,
      'role': role,
      'requestId': requestId,
      'expectedWorkspaceRevision': expectedWorkspaceRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _InviteWorkspaceMemberRequestImpl({
  required int workspaceId,
  required String email,
  required String role,
  required String requestId,
  required int expectedWorkspaceRevision,
}) extends InviteWorkspaceMemberRequest {
  this
    : super._(
        workspaceId: workspaceId,
        email: email,
        role: role,
        requestId: requestId,
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      );

  /// Returns a shallow copy of this [InviteWorkspaceMemberRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InviteWorkspaceMemberRequest copyWith({
    int? workspaceId,
    String? email,
    String? role,
    String? requestId,
    int? expectedWorkspaceRevision,
  }) {
    return InviteWorkspaceMemberRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      email: email ?? this.email,
      role: role ?? this.role,
      requestId: requestId ?? this.requestId,
      expectedWorkspaceRevision:
          expectedWorkspaceRevision ?? this.expectedWorkspaceRevision,
    );
  }
}
