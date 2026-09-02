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

abstract class AcceptWorkspaceInviteRequest._({
  required var int inviteId,
  required var String requestId,
  required var int expectedInviteRevision,
}) implements _i1.SerializableModel {
  factory({
    required int inviteId,
    required String requestId,
    required int expectedInviteRevision,
  }) = _AcceptWorkspaceInviteRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AcceptWorkspaceInviteRequest(
      inviteId: jsonSerialization['inviteId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      expectedInviteRevision:
          jsonSerialization['expectedInviteRevision'] as int,
    );
  }

  /// Returns a shallow copy of this [AcceptWorkspaceInviteRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AcceptWorkspaceInviteRequest copyWith({
    int? inviteId,
    String? requestId,
    int? expectedInviteRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AcceptWorkspaceInviteRequest',
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

class _AcceptWorkspaceInviteRequestImpl({
  required int inviteId,
  required String requestId,
  required int expectedInviteRevision,
}) extends AcceptWorkspaceInviteRequest {
  this
    : super._(
        inviteId: inviteId,
        requestId: requestId,
        expectedInviteRevision: expectedInviteRevision,
      );

  /// Returns a shallow copy of this [AcceptWorkspaceInviteRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AcceptWorkspaceInviteRequest copyWith({
    int? inviteId,
    String? requestId,
    int? expectedInviteRevision,
  }) {
    return AcceptWorkspaceInviteRequest(
      inviteId: inviteId ?? this.inviteId,
      requestId: requestId ?? this.requestId,
      expectedInviteRevision:
          expectedInviteRevision ?? this.expectedInviteRevision,
    );
  }
}
