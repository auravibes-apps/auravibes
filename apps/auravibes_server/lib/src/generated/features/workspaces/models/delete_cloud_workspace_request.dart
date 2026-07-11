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

abstract class DeleteCloudWorkspaceRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DeleteCloudWorkspaceRequest._({
    required this.workspaceId,
    required this.confirmationName,
  });

  factory DeleteCloudWorkspaceRequest({
    required int workspaceId,
    required String confirmationName,
  }) = _DeleteCloudWorkspaceRequestImpl;

  factory DeleteCloudWorkspaceRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeleteCloudWorkspaceRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      confirmationName: jsonSerialization['confirmationName'] as String,
    );
  }

  int workspaceId;

  String confirmationName;

  /// Returns a shallow copy of this [DeleteCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeleteCloudWorkspaceRequest copyWith({
    int? workspaceId,
    String? confirmationName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteCloudWorkspaceRequest',
      'workspaceId': workspaceId,
      'confirmationName': confirmationName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeleteCloudWorkspaceRequest',
      'workspaceId': workspaceId,
      'confirmationName': confirmationName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeleteCloudWorkspaceRequestImpl extends DeleteCloudWorkspaceRequest {
  _DeleteCloudWorkspaceRequestImpl({
    required int workspaceId,
    required String confirmationName,
  }) : super._(
         workspaceId: workspaceId,
         confirmationName: confirmationName,
       );

  /// Returns a shallow copy of this [DeleteCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeleteCloudWorkspaceRequest copyWith({
    int? workspaceId,
    String? confirmationName,
  }) {
    return DeleteCloudWorkspaceRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      confirmationName: confirmationName ?? this.confirmationName,
    );
  }
}
