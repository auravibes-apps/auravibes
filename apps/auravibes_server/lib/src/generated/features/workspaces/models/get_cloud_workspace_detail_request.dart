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

abstract class GetCloudWorkspaceDetailRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GetCloudWorkspaceDetailRequest._({required this.workspaceId});

  factory GetCloudWorkspaceDetailRequest({required int workspaceId}) =
      _GetCloudWorkspaceDetailRequestImpl;

  factory GetCloudWorkspaceDetailRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GetCloudWorkspaceDetailRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
    );
  }

  int workspaceId;

  /// Returns a shallow copy of this [GetCloudWorkspaceDetailRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GetCloudWorkspaceDetailRequest copyWith({int? workspaceId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetCloudWorkspaceDetailRequest',
      'workspaceId': workspaceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GetCloudWorkspaceDetailRequest',
      'workspaceId': workspaceId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GetCloudWorkspaceDetailRequestImpl
    extends GetCloudWorkspaceDetailRequest {
  _GetCloudWorkspaceDetailRequestImpl({required int workspaceId})
    : super._(workspaceId: workspaceId);

  /// Returns a shallow copy of this [GetCloudWorkspaceDetailRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GetCloudWorkspaceDetailRequest copyWith({int? workspaceId}) {
    return GetCloudWorkspaceDetailRequest(
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }
}
