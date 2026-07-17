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

abstract class RemoveWorkspaceMemberRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  RemoveWorkspaceMemberRequest._({
    required this.workspaceId,
    required this.userId,
    required this.requestId,
    required this.expectedMemberRevision,
  });

  factory RemoveWorkspaceMemberRequest({
    required int workspaceId,
    required String userId,
    required String requestId,
    required int expectedMemberRevision,
  }) = _RemoveWorkspaceMemberRequestImpl;

  factory RemoveWorkspaceMemberRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RemoveWorkspaceMemberRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      expectedMemberRevision:
          jsonSerialization['expectedMemberRevision'] as int,
    );
  }

  int workspaceId;

  String userId;

  String requestId;

  int expectedMemberRevision;

  /// Returns a shallow copy of this [RemoveWorkspaceMemberRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RemoveWorkspaceMemberRequest copyWith({
    int? workspaceId,
    String? userId,
    String? requestId,
    int? expectedMemberRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RemoveWorkspaceMemberRequest',
      'workspaceId': workspaceId,
      'userId': userId,
      'requestId': requestId,
      'expectedMemberRevision': expectedMemberRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RemoveWorkspaceMemberRequest',
      'workspaceId': workspaceId,
      'userId': userId,
      'requestId': requestId,
      'expectedMemberRevision': expectedMemberRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RemoveWorkspaceMemberRequestImpl extends RemoveWorkspaceMemberRequest {
  _RemoveWorkspaceMemberRequestImpl({
    required int workspaceId,
    required String userId,
    required String requestId,
    required int expectedMemberRevision,
  }) : super._(
         workspaceId: workspaceId,
         userId: userId,
         requestId: requestId,
         expectedMemberRevision: expectedMemberRevision,
       );

  /// Returns a shallow copy of this [RemoveWorkspaceMemberRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RemoveWorkspaceMemberRequest copyWith({
    int? workspaceId,
    String? userId,
    String? requestId,
    int? expectedMemberRevision,
  }) {
    return RemoveWorkspaceMemberRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      expectedMemberRevision:
          expectedMemberRevision ?? this.expectedMemberRevision,
    );
  }
}
