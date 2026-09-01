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

abstract class RevokeWorkspaceInviteRequest._({
  required var int workspaceId,
  required var int inviteId,
  required var String requestId,
  required var int expectedInviteRevision,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required int inviteId,
    required String requestId,
    required int expectedInviteRevision,
  }) = _RevokeWorkspaceInviteRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RevokeWorkspaceInviteRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      inviteId: jsonSerialization['inviteId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      expectedInviteRevision:
          jsonSerialization['expectedInviteRevision'] as int,
    );
  }

  /// Returns a shallow copy of this [RevokeWorkspaceInviteRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RevokeWorkspaceInviteRequest copyWith({
    int? workspaceId,
    int? inviteId,
    String? requestId,
    int? expectedInviteRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevokeWorkspaceInviteRequest',
      'workspaceId': workspaceId,
      'inviteId': inviteId,
      'requestId': requestId,
      'expectedInviteRevision': expectedInviteRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RevokeWorkspaceInviteRequestImpl({
  required int workspaceId,
  required int inviteId,
  required String requestId,
  required int expectedInviteRevision,
}) extends RevokeWorkspaceInviteRequest {
  this
    : super._(
        workspaceId: workspaceId,
        inviteId: inviteId,
        requestId: requestId,
        expectedInviteRevision: expectedInviteRevision,
      );

  /// Returns a shallow copy of this [RevokeWorkspaceInviteRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RevokeWorkspaceInviteRequest copyWith({
    int? workspaceId,
    int? inviteId,
    String? requestId,
    int? expectedInviteRevision,
  }) {
    return RevokeWorkspaceInviteRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      inviteId: inviteId ?? this.inviteId,
      requestId: requestId ?? this.requestId,
      expectedInviteRevision:
          expectedInviteRevision ?? this.expectedInviteRevision,
    );
  }
}
