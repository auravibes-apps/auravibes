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

abstract class TransferCloudWorkspaceOwnershipRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TransferCloudWorkspaceOwnershipRequest._({
    required this.workspaceId,
    required this.newOwnerUserId,
  });

  factory TransferCloudWorkspaceOwnershipRequest({
    required int workspaceId,
    required String newOwnerUserId,
  }) = _TransferCloudWorkspaceOwnershipRequestImpl;

  factory TransferCloudWorkspaceOwnershipRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TransferCloudWorkspaceOwnershipRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      newOwnerUserId: jsonSerialization['newOwnerUserId'] as String,
    );
  }

  int workspaceId;

  String newOwnerUserId;

  /// Returns a shallow copy of this [TransferCloudWorkspaceOwnershipRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TransferCloudWorkspaceOwnershipRequest copyWith({
    int? workspaceId,
    String? newOwnerUserId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TransferCloudWorkspaceOwnershipRequest',
      'workspaceId': workspaceId,
      'newOwnerUserId': newOwnerUserId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TransferCloudWorkspaceOwnershipRequest',
      'workspaceId': workspaceId,
      'newOwnerUserId': newOwnerUserId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TransferCloudWorkspaceOwnershipRequestImpl
    extends TransferCloudWorkspaceOwnershipRequest {
  _TransferCloudWorkspaceOwnershipRequestImpl({
    required int workspaceId,
    required String newOwnerUserId,
  }) : super._(
         workspaceId: workspaceId,
         newOwnerUserId: newOwnerUserId,
       );

  /// Returns a shallow copy of this [TransferCloudWorkspaceOwnershipRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TransferCloudWorkspaceOwnershipRequest copyWith({
    int? workspaceId,
    String? newOwnerUserId,
  }) {
    return TransferCloudWorkspaceOwnershipRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      newOwnerUserId: newOwnerUserId ?? this.newOwnerUserId,
    );
  }
}
