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

abstract class RevokeWorkspaceInviteRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  RevokeWorkspaceInviteRequest._({
    required this.workspaceId,
    required this.inviteId,
  });

  factory RevokeWorkspaceInviteRequest({
    required int workspaceId,
    required int inviteId,
  }) = _RevokeWorkspaceInviteRequestImpl;

  factory RevokeWorkspaceInviteRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RevokeWorkspaceInviteRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      inviteId: jsonSerialization['inviteId'] as int,
    );
  }

  int workspaceId;

  int inviteId;

  /// Returns a shallow copy of this [RevokeWorkspaceInviteRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RevokeWorkspaceInviteRequest copyWith({
    int? workspaceId,
    int? inviteId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevokeWorkspaceInviteRequest',
      'workspaceId': workspaceId,
      'inviteId': inviteId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevokeWorkspaceInviteRequest',
      'workspaceId': workspaceId,
      'inviteId': inviteId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RevokeWorkspaceInviteRequestImpl extends RevokeWorkspaceInviteRequest {
  _RevokeWorkspaceInviteRequestImpl({
    required int workspaceId,
    required int inviteId,
  }) : super._(
         workspaceId: workspaceId,
         inviteId: inviteId,
       );

  /// Returns a shallow copy of this [RevokeWorkspaceInviteRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RevokeWorkspaceInviteRequest copyWith({
    int? workspaceId,
    int? inviteId,
  }) {
    return RevokeWorkspaceInviteRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      inviteId: inviteId ?? this.inviteId,
    );
  }
}
