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

abstract class TransferCloudWorkspaceOwnershipRequest._({
  required var int workspaceId,
  required var String newOwnerUserId,
  required var String requestId,
  required var int expectedWorkspaceRevision,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String newOwnerUserId,
    required String requestId,
    required int expectedWorkspaceRevision,
  }) = _TransferCloudWorkspaceOwnershipRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TransferCloudWorkspaceOwnershipRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      newOwnerUserId: jsonSerialization['newOwnerUserId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      expectedWorkspaceRevision:
          jsonSerialization['expectedWorkspaceRevision'] as int,
    );
  }

  /// Returns a shallow copy of this [TransferCloudWorkspaceOwnershipRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TransferCloudWorkspaceOwnershipRequest copyWith({
    int? workspaceId,
    String? newOwnerUserId,
    String? requestId,
    int? expectedWorkspaceRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TransferCloudWorkspaceOwnershipRequest',
      'workspaceId': workspaceId,
      'newOwnerUserId': newOwnerUserId,
      'requestId': requestId,
      'expectedWorkspaceRevision': expectedWorkspaceRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TransferCloudWorkspaceOwnershipRequestImpl({
  required int workspaceId,
  required String newOwnerUserId,
  required String requestId,
  required int expectedWorkspaceRevision,
}) extends TransferCloudWorkspaceOwnershipRequest {
  this
    : super._(
        workspaceId: workspaceId,
        newOwnerUserId: newOwnerUserId,
        requestId: requestId,
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      );

  /// Returns a shallow copy of this [TransferCloudWorkspaceOwnershipRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TransferCloudWorkspaceOwnershipRequest copyWith({
    int? workspaceId,
    String? newOwnerUserId,
    String? requestId,
    int? expectedWorkspaceRevision,
  }) {
    return TransferCloudWorkspaceOwnershipRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      newOwnerUserId: newOwnerUserId ?? this.newOwnerUserId,
      requestId: requestId ?? this.requestId,
      expectedWorkspaceRevision:
          expectedWorkspaceRevision ?? this.expectedWorkspaceRevision,
    );
  }
}
